import SwiftUI

struct LearnHomeView: View {
    @EnvironmentObject private var settings: SettingsStore

    private var units: [LearnUnit] { Curriculum.units(for: settings.language) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    ForEach(Array(units.enumerated()), id: \.element.id) { idx, unit in
                        unitCard(unit, number: idx + 1)
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(colors: [SF.tealDeep.opacity(0.9), Color(.systemBackground)], startPoint: .top, endPoint: .center)
                    .ignoresSafeArea()
            )
            .navigationTitle("Learn")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(Language.allCases) { lang in
                            Button("\(lang.flag) \(lang.displayName)") { settings.language = lang }
                        }
                    } label: {
                        Text(settings.language.flag).font(.title3)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No API key needed")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(SF.mint)
            Text("Get the ball rolling")
                .font(.system(.title, design: .rounded).weight(.heavy))
            Text("Say it wrong. Remember it. Levels unlock as you finish lessons — like a path, not a dictionary.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
            HStack {
                Label("\(settings.xp) XP", systemImage: "bolt.fill")
                Spacer()
                Text("\(settings.completedLessonIDs.count) lessons done")
            }
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(SF.coral)
            .padding(.top, 4)
        }
    }

    private func unitCard(_ unit: LearnUnit, number: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(unit.emoji).font(.largeTitle)
                VStack(alignment: .leading) {
                    Text("Unit \(number)")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(SF.teal)
                    Text(unit.title)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    Text(unit.subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(unit.lessons) { lesson in
                let done = settings.completedLessonIDs.contains(lesson.id)
                NavigationLink {
                    LessonPlayerView(lesson: lesson)
                } label: {
                    HStack {
                        Image(systemName: done ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(done ? SF.mint : .secondary)
                        Text(lesson.title)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground).opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct LessonPlayerView: View {
    @EnvironmentObject private var settings: SettingsStore
    let lesson: LearnLesson

    @StateObject private var speech = SpeechRecognitionService()
    @StateObject private var tts = SpeechSynthesisService()
    @State private var index = 0
    @State private var revealed = false
    @State private var attempt = ""
    @State private var feedback: String?
    @State private var listening = false
    @Environment(\.dismiss) private var dismiss

    private var prompt: LearnPrompt { lesson.prompts[index] }

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(index + 1), total: Double(lesson.prompts.count))
                .tint(SF.coral)
                .padding()

            Spacer()

            VStack(alignment: .leading, spacing: 16) {
                Text("Say this idea")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(SF.teal)
                Text(prompt.english)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))

                if revealed {
                    Text(prompt.target)
                        .font(.system(.title, design: .rounded).weight(.semibold))
                        .foregroundStyle(SF.mint)
                    Text(prompt.tip)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Try first — messing up is the point")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                if !attempt.isEmpty {
                    Text("You: \(attempt)")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                if let feedback {
                    Text(feedback)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(SF.coral)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        revealed = true
                        tts.speak(prompt.target, language: settings.language)
                    } label: {
                        Label(revealed ? "Listen" : "Reveal", systemImage: "speaker.wave.2.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        Task { await toggleListen() }
                    } label: {
                        Label(listening ? "Stop" : "Try saying it", systemImage: listening ? "stop.fill" : "mic.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(listening ? SF.coral : SF.teal)
                }

                Button(index == lesson.prompts.count - 1 ? "Finish lesson" : "Next") {
                    advance()
                }
                .buttonStyle(.borderedProminent)
                .tint(SF.coral)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await speech.requestPermissions()
            speech.prepare(for: settings.language)
        }
    }

    private func toggleListen() async {
        if listening {
            speech.stopListening(cancel: false)
            listening = false
            attempt = speech.transcript
            revealed = true
            feedback = "Nice try. Compare & steal the phrase."
        } else {
            attempt = ""; feedback = nil; speech.transcript = ""
            do {
                // For lessons we still use a simple start; user taps stop (short drills)
                try speech.startListening()
                listening = true
                // Disable auto-complete for short drills by clearing callback
                speech.onUtteranceComplete = { text in
                    Task { @MainActor in
                        attempt = text
                        listening = false
                        revealed = true
                        feedback = "Logged. Check the answer."
                    }
                }
            } catch {
                feedback = error.localizedDescription
            }
        }
    }

    private func advance() {
        tts.stop()
        speech.stopListening(cancel: true)
        listening = false
        if index >= lesson.prompts.count - 1 {
            settings.completeLesson(lesson.id)
            dismiss()
        } else {
            index += 1
            revealed = false
            attempt = ""
            feedback = nil
        }
    }
}
