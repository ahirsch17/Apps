import SwiftUI

struct LearnView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var mode: Mode = .words

    enum Mode: String, CaseIterable, Identifiable {
        case words, phrases, mistakes
        var id: String { rawValue }
        var title: String {
            switch self {
            case .words: return "Words"
            case .phrases: return "Phrases"
            case .mistakes: return "My mistakes"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                switch mode {
                case .words: WordBankView()
                case .phrases: PhraseDrillView()
                case .mistakes: MistakesView()
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Learn")
                        .font(.largeTitle.bold())
                    Text("No API key · listen then speak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    ForEach(Language.allCases) { language in
                        Button("\(language.flag)  \(language.displayName)") {
                            settings.language = language
                        }
                    }
                } label: {
                    Text("\(settings.language.flag) \(settings.language.displayName)")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
            }
            howTo
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var howTo: some View {
        HStack(spacing: 8) {
            step("1", "See it")
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
            step("2", "Listen")
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
            step("3", "Say it")
        }
        .padding(.top, 4)
    }

    private func step(_ n: String, _ label: String) -> some View {
        HStack(spacing: 6) {
            Text(n)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(SFTheme.accent)
                .clipShape(Circle())
            Text(label)
                .font(.caption.weight(.semibold))
        }
    }
}

struct WordBankView: View {
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var speech = SpeechSynthesisService()
    @StateObject private var recognition = SpeechRecognitionService()
    @State private var category: WordCategory = .essentials
    @State private var deck: [WordCard] = []
    @State private var index = 0
    @State private var showAnswer = false
    @State private var attempt = ""
    @State private var feedback: String?
    @State private var isRecording = false
    @State private var englishFirst = true

    private var current: WordCard? {
        deck.indices.contains(index) ? deck[index] : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(WordCategory.allCases) { item in
                        Button {
                            category = item
                            reload()
                        } label: {
                            Label(item.displayName, systemImage: item.icon)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(category == item ? SFTheme.accent : Color(.tertiarySystemBackground))
                                .foregroundStyle(category == item ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)

            Toggle("Hide the answer first", isOn: $englishFirst)
                .font(.subheadline)
                .padding(.horizontal)
                .padding(.bottom, 8)

            if let card = current {
                Spacer(minLength: 8)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("\(index + 1) of \(deck.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Label(card.category.displayName, systemImage: card.category.icon)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    if englishFirst && !showAnswer {
                        Text(card.english)
                            .font(.largeTitle.bold())
                        Text("Say it in \(settings.language.displayName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(card.target)
                            .font(.largeTitle.bold())
                        Text(card.english)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text(card.example)
                            .font(.body)
                            .padding(.top, 4)
                    }

                    if !attempt.isEmpty {
                        Text("You said: \(attempt)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let feedback {
                        Text(feedback)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }
                .softCard()
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button {
                            showAnswer = true
                            speech.speak(card.target, language: settings.language)
                        } label: {
                            Label(showAnswer || !englishFirst ? "Listen" : "Reveal & listen", systemImage: "speaker.wave.2.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button { Task { await toggleRecord(for: card) } } label: {
                            Label(isRecording ? "Stop" : "Say it", systemImage: isRecording ? "stop.fill" : "mic.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isRecording ? .red : SFTheme.accent)
                    }
                    HStack {
                        Button("Skip") { advance() }.buttonStyle(.bordered)
                        Button("Got it") { showAnswer = true; advance() }
                            .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            } else {
                ContentUnavailableView("No words here", systemImage: "textformat", description: Text("Try Essentials or Connectors."))
            }
        }
        .onAppear { reload() }
        .onChange(of: settings.language) { _, _ in reload() }
        .onChange(of: englishFirst) { _, _ in
            showAnswer = !englishFirst
            attempt = ""
            feedback = nil
        }
        .task {
            _ = await recognition.requestAuthorization()
            _ = await recognition.requestMicrophonePermission()
            recognition.prepare(for: settings.language)
        }
    }

    private func reload() {
        deck = WordBank.words(for: settings.language, category: category).shuffled()
        if deck.isEmpty { deck = WordBank.words(for: settings.language).shuffled() }
        index = 0
        showAnswer = !englishFirst
        attempt = ""
        feedback = nil
        recognition.prepare(for: settings.language)
    }

    private func toggleRecord(for card: WordCard) async {
        if isRecording {
            recognition.stopRecording()
            isRecording = false
            attempt = recognition.transcript
            showAnswer = true
            let spoken = normalize(attempt)
            let target = normalize(card.target)
            let ok = !spoken.isEmpty && (spoken.contains(target) || target.contains(spoken))
            feedback = ok ? "Nice — that matches." : "Listen once, then try again. Close is fine."
        } else {
            attempt = ""
            feedback = nil
            recognition.transcript = ""
            speech.stop()
            do {
                try recognition.startRecording()
                isRecording = true
            } catch { feedback = error.localizedDescription }
        }
    }

    private func advance() {
        guard !deck.isEmpty else { return }
        if index < deck.count - 1 { index += 1 }
        else { deck.shuffle(); index = 0 }
        showAnswer = !englishFirst
        attempt = ""
        feedback = nil
        speech.stop()
    }

    private func normalize(_ text: String) -> String {
        text.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .components(separatedBy: CharacterSet.punctuationCharacters)
            .joined()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct PhraseDrillView: View {
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var viewModel = DrillViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(viewModel.progressLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    viewModel.configure(language: settings.language, level: settings.level, topic: settings.topic)
                } label: { Image(systemName: "shuffle") }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            if let phrase = viewModel.current {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Label(phrase.topic.displayName, systemImage: phrase.topic.icon)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(phrase.promptEnglish)
                            .font(.title2.bold())
                        if viewModel.showAnswer {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(phrase.targetPhrase)
                                    .font(.title3.bold())
                                    .foregroundStyle(SFTheme.accent)
                                Text(phrase.tip)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .softCard()
                        }
                        if !viewModel.userAttempt.isEmpty {
                            Text("You said: \(viewModel.userAttempt)").font(.subheadline).foregroundStyle(.secondary)
                        }
                        if let feedback = viewModel.feedback {
                            Text(feedback.message)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(feedback.isClose ? .green : .orange)
                        }
                    }
                    .padding()
                }
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button { viewModel.revealAnswer() } label: {
                            Label("Reveal", systemImage: "eye").frame(maxWidth: .infinity)
                        }.buttonStyle(.bordered)
                        Button { viewModel.speakTarget() } label: {
                            Label("Listen", systemImage: "speaker.wave.2").frame(maxWidth: .infinity)
                        }.buttonStyle(.bordered)
                    }
                    Button { Task { await viewModel.toggleRecording() } } label: {
                        Label(viewModel.isRecording ? "Stop" : "Try saying it",
                              systemImage: viewModel.isRecording ? "stop.fill" : "mic.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(viewModel.isRecording ? .red : SFTheme.accent)
                    HStack {
                        Button("Skip") { viewModel.next() }.buttonStyle(.bordered)
                        Button("Got it") { viewModel.markDone() }
                            .buttonStyle(.borderedProminent)
                            .disabled(!viewModel.showAnswer)
                    }
                }
                .padding()
            } else {
                ContentUnavailableView("No phrases for this filter", systemImage: "text.bubble")
            }
        }
        .onAppear {
            viewModel.configure(language: settings.language, level: settings.level, topic: settings.topic)
        }
        .task { await viewModel.onAppear() }
        .onChange(of: settings.language) { _, _ in
            viewModel.configure(language: settings.language, level: settings.level, topic: settings.topic)
        }
    }
}

struct MistakesView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var vocabulary: VocabularyStore
    @StateObject private var speech = SpeechSynthesisService()
    @StateObject private var recognition = SpeechRecognitionService()
    @State private var current: VocabularyEntry?
    @State private var attempt = ""
    @State private var feedback: String?
    @State private var isRecording = false

    private var items: [VocabularyEntry] { vocabulary.entries(for: settings.language) }

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView(
                    "No mistakes yet",
                    systemImage: "text.book.closed",
                    description: Text("These appear after AI Chat corrections. Use Words or Phrases until then — they’re free.")
                )
            } else if let entry = current ?? items.first {
                VStack(alignment: .leading, spacing: 16) {
                    Label(entry.correctionType.label, systemImage: entry.correctionType.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if !entry.original.isEmpty {
                        Text(entry.original).strikethrough().foregroundStyle(.secondary)
                    }
                    Text(entry.corrected).font(.title2.bold())
                    Text(entry.explanation).font(.subheadline).foregroundStyle(.secondary)
                    if !attempt.isEmpty { Text("You said: \(attempt)").font(.subheadline).foregroundStyle(.secondary) }
                    if let feedback { Text(feedback).font(.subheadline.weight(.semibold)).foregroundStyle(.green) }
                    Spacer()
                    HStack(spacing: 12) {
                        Button {
                            speech.speak(entry.corrected, language: settings.language)
                            vocabulary.markReviewed(entry)
                        } label: { Label("Listen", systemImage: "speaker.wave.2").frame(maxWidth: .infinity) }
                        .buttonStyle(.bordered)
                        Button { Task { await toggleRecord(for: entry) } } label: {
                            Label(isRecording ? "Stop" : "Say it", systemImage: isRecording ? "stop.fill" : "mic.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isRecording ? .red : SFTheme.accent)
                    }
                    Button("Next") { advance(from: entry) }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .onAppear {
                    if current == nil { current = items.first }
                    recognition.prepare(for: settings.language)
                }
            }
        }
        .task {
            _ = await recognition.requestAuthorization()
            _ = await recognition.requestMicrophonePermission()
            recognition.prepare(for: settings.language)
        }
    }

    private func toggleRecord(for entry: VocabularyEntry) async {
        if isRecording {
            recognition.stopRecording()
            isRecording = false
            attempt = recognition.transcript
            feedback = "Good practice — listen once more if it didn’t match."
            vocabulary.markReviewed(entry)
        } else {
            attempt = ""; feedback = nil; recognition.transcript = ""; speech.stop()
            do { try recognition.startRecording(); isRecording = true }
            catch { feedback = error.localizedDescription }
        }
    }

    private func advance(from entry: VocabularyEntry) {
        guard let i = items.firstIndex(of: entry) else { current = items.first; return }
        let next = items.index(after: i)
        current = next < items.endIndex ? items[next] : items.first
        attempt = ""; feedback = nil; speech.stop()
    }
}
