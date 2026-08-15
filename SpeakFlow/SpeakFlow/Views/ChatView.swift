import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var settings: SettingsStore
    @ObservedObject var viewModel: ConversationViewModel
    var onOpenProfile: () -> Void

    @State private var showSessionSheet = false
    @State private var isHoldingMic = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sessionBar

                if !settings.hasAPIKey {
                    lockedState
                } else {
                    conversationBody
                }
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("New conversation", systemImage: "arrow.counterclockwise") {
                            Task { await viewModel.resetConversation() }
                        }
                        Button("Replay last question", systemImage: "speaker.wave.2") {
                            viewModel.replayLastTutorMessage()
                        }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
            .sheet(isPresented: $showSessionSheet) {
                SessionSetupSheet {
                    showSessionSheet = false
                    viewModel.onSessionSettingsChanged()
                }
            }
            .sheet(isPresented: $viewModel.showStuckSheet) {
                StuckHelpSheet(viewModel: viewModel)
            }
        }
    }

    private var sessionBar: some View {
        Button { showSessionSheet = true } label: {
            HStack(spacing: 8) {
                Text("\(settings.language.flag) \(settings.language.displayName)")
                    .font(.subheadline.weight(.semibold))
                chip(settings.level.displayName)
                chip(settings.topic.displayName)
                Spacer()
                Image(systemName: "chevron.down").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
        }
        .buttonStyle(.plain)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.tertiarySystemBackground))
            .clipShape(Capsule())
    }

    private var lockedState: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle().fill(SFTheme.accent.opacity(0.12)).frame(width: 96, height: 96)
                Image(systemName: "sparkles").font(.system(size: 36)).foregroundStyle(SFTheme.accent)
            }
            Text("AI conversation is optional")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Learn (Words + Phrases) is free forever. Add your own OpenAI key in Profile when you want a live tutor — typically about a tenth of a cent per exchange.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Button {
                onOpenProfile()
            } label: {
                Text("Add API key in Profile")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var conversationBody: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(message: message, language: settings.language)
                                .id(message.id)
                        }
                        if viewModel.isProcessing {
                            ProgressView("Thinking…").padding().id("loading")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in scroll(proxy) }
                .onChange(of: viewModel.isProcessing) { _, _ in scroll(proxy) }
            }

            if let suggestion = viewModel.levelUpSuggestion {
                VStack(spacing: 8) {
                    Text(suggestion).font(.subheadline).multilineTextAlignment(.center)
                    HStack {
                        Button("Not yet") { viewModel.dismissLevelUp() }.buttonStyle(.bordered)
                        Button("Level up") { viewModel.acceptLevelUp() }.buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color(.tertiarySystemBackground))
            }

            if let error = viewModel.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center).padding(.horizontal)
            }

            scaffoldBar
            micBar
        }
    }

    private var scaffoldBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !viewModel.starters.isEmpty && !viewModel.speechRecognition.isRecording && !viewModel.isProcessing {
                Text("Start with…")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.starters, id: \.self) { starter in
                            Button { viewModel.selectStarter(starter) } label: {
                                Text(starter)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(viewModel.selectedStarter == starter ? SFTheme.accent : Color(.secondarySystemBackground))
                                    .foregroundStyle(viewModel.selectedStarter == starter ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top, 8)
    }

    private var micBar: some View {
        VStack(spacing: 10) {
            if viewModel.speechRecognition.isRecording {
                Text(viewModel.speechRecognition.transcript.isEmpty ? "Listening… hold to keep talking" : viewModel.speechRecognition.transcript)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            HStack(spacing: 20) {
                sideButton(icon: "lifepreserver", title: "Stuck") {
                    Task { await viewModel.requestStuckHelp() }
                }
                .disabled(viewModel.isProcessing || viewModel.isLoadingHelp || viewModel.lastTutorText.isEmpty)

                holdButton

                sideButton(icon: "speaker.wave.2.fill", title: "Replay") {
                    viewModel.replayLastTutorMessage()
                }
                .disabled(viewModel.lastTutorText.isEmpty)
            }
            Text(hint)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)
        }
        .padding(.top, 4)
    }

    private func sideButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption2.weight(.semibold))
            }
            .frame(width: 64, height: 64)
            .background(Color(.secondarySystemBackground))
            .clipShape(Circle())
        }
    }

    private var holdButton: some View {
        ZStack {
            Circle()
                .fill(viewModel.speechRecognition.isRecording || isHoldingMic ? Color.red : SFTheme.accent)
                .frame(width: 80, height: 80)
                .shadow(radius: viewModel.speechRecognition.isRecording ? 10 : 4)
                .scaleEffect(isHoldingMic ? 1.06 : 1)
            VStack(spacing: 2) {
                Image(systemName: "mic.fill").font(.title)
                Text(viewModel.speechRecognition.isRecording ? "Release" : "Hold")
                    .font(.caption2.bold())
            }
            .foregroundStyle(.white)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isHoldingMic, viewModel.canSpeak else { return }
                    isHoldingMic = true
                    viewModel.beginRecording()
                }
                .onEnded { _ in
                    guard isHoldingMic else { return }
                    isHoldingMic = false
                    Task { await viewModel.endRecordingAndSend() }
                }
        )
        .disabled(viewModel.isProcessing)
        .opacity(viewModel.isProcessing ? 0.45 : 1)
    }

    private var hint: String {
        if viewModel.isLoadingHelp { return "Getting a ready-to-say answer…" }
        if viewModel.speechRecognition.isRecording { return "Keep holding. Release when finished." }
        if viewModel.isProcessing { return "Getting feedback and the next question…" }
        if !viewModel.starters.isEmpty { return "Tap a starter if you freeze, then hold the mic." }
        return "Hold the mic to answer. Tap Stuck if you freeze."
    }

    private func scroll(_ proxy: ScrollViewProxy) {
        withAnimation {
            if viewModel.isProcessing { proxy.scrollTo("loading", anchor: .bottom) }
            else if let last = viewModel.messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
        }
    }
}

struct SessionSetupSheet: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    var onStart: () -> Void
    @State private var language: Language = .spanish
    @State private var level: ConversationLevel = .warmup
    @State private var topic: ConversationTopic = .freeform

    var body: some View {
        NavigationStack {
            Form {
                Section("Language") {
                    Picker("Language", selection: $language) {
                        ForEach(Language.allCases) { Text("\($0.flag) \($0.displayName)").tag($0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section {
                    Picker("Level", selection: $level) {
                        ForEach(ConversationLevel.allCases) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    Text(level.subtitle).font(.caption).foregroundStyle(.secondary)
                } header: { Text("Level") }
                Section {
                    Picker("Topic", selection: $topic) {
                        ForEach(ConversationTopic.allCases) { Label($0.displayName, systemImage: $0.icon).tag($0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: { Text("Topic") }
            }
            .navigationTitle("Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        settings.language = language
                        settings.level = level
                        settings.topic = topic
                        onStart()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                language = settings.language
                level = settings.level
                topic = settings.topic
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct StuckHelpSheet: View {
    @ObservedObject var viewModel: ConversationViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                if let help = viewModel.stuckHelp {
                    Text("Say this").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Text(help.suggestedAnswer).font(.title3.bold())
                    Text(help.englishGloss).font(.subheadline).foregroundStyle(.secondary)
                    Text(help.tip).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button { viewModel.practiceStuckAnswer() } label: {
                        Label("Listen again", systemImage: "speaker.wave.2.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    Button { viewModel.useStuckAnswerAsStarter() } label: {
                        Label("I'll shadow this", systemImage: "mic.fill").frame(maxWidth: .infinity).padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    ProgressView("Loading…")
                    Spacer()
                }
            }
            .padding()
            .navigationTitle("You're stuck — that's okay")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
        .presentationDetents([.medium])
    }
}
