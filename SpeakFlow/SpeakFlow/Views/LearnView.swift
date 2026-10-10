import SwiftUI

struct LearnHomeView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var phrasebook: PhrasebookStore

    private var units: [LearnUnit] { Curriculum.units(for: settings.language) }
    private var nextLessonID: String? {
        units.flatMap(\.lessons).first { !settings.completedLessonIDs.contains($0.id) }?.id
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    reviewCard
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
            Text("Say it out loud, miss it, try again. Anything you miss lands in Review so it comes back right when you're about to forget it.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
            HStack(spacing: 14) {
                Label("\(settings.currentStreak)-day streak", systemImage: settings.practicedToday ? "flame.fill" : "flame")
                Label("\(settings.xp) XP", systemImage: "bolt.fill")
                Spacer()
                Text("\(lessonsDone)/\(lessonsTotal) lessons")
            }
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(SF.coral)
            .padding(.top, 4)
        }
    }

    private var lessonsTotal: Int { units.reduce(0) { $0 + $1.lessons.count } }
    private var lessonsDone: Int {
        units.flatMap(\.lessons).filter { settings.completedLessonIDs.contains($0.id) }.count
    }

    private var reviewCard: some View {
        let due = phrasebook.dueCount(for: settings.language)
        let saved = phrasebook.phrases(for: settings.language).count
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "rectangle.stack.fill")
                    .font(.title2)
                    .foregroundStyle(SF.mint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Review")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    Text(reviewSubtitle(due: due, saved: saved))
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if saved > 0 {
                    NavigationLink {
                        PhrasebookListView()
                    } label: {
                        Text("All \(saved)")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                    }
                }
            }
            if due > 0 {
                NavigationLink {
                    ReviewSessionView()
                } label: {
                    Label("Review \(min(due, 12)) now", systemImage: "play.fill")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(SF.mint)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground).opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func reviewSubtitle(due: Int, saved: Int) -> String {
        if saved == 0 { return "Corrections from Call & Text and phrases you miss here collect in your deck." }
        if due == 0 { return "All caught up. \(saved) phrase\(saved == 1 ? "" : "s") saved." }
        return "\(due) due · spaced so they stick"
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
                let isNext = lesson.id == nextLessonID
                NavigationLink {
                    LessonPlayerView(lesson: lesson)
                } label: {
                    HStack {
                        Image(systemName: done ? "checkmark.circle.fill" : (isNext ? "play.circle.fill" : "circle"))
                            .foregroundStyle(done ? SF.mint : (isNext ? SF.coral : .secondary))
                        Text(lesson.title)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(.primary)
                        Spacer()
                        if isNext {
                            Text("Up next")
                                .font(.system(.caption2, design: .rounded).weight(.bold))
                                .foregroundStyle(SF.coral)
                        }
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

/// Snapshots the due deck once so rating cards (which changes what's due) can't reshuffle the session mid-way.
struct ReviewSessionView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var phrasebook: PhrasebookStore
    @State private var deck: [SavedPhrase]?

    var body: some View {
        Group {
            if let deck {
                if deck.isEmpty {
                    ContentUnavailableView("All caught up", systemImage: "checkmark.circle", description: Text("Nothing due right now."))
                } else {
                    LessonPlayerView(review: deck)
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if deck == nil { deck = phrasebook.dueDeck(for: settings.language) }
        }
    }
}

struct PhrasebookListView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var phrasebook: PhrasebookStore
    @StateObject private var tts = SpeechSynthesisService()

    var body: some View {
        List {
            ForEach(phrasebook.phrases(for: settings.language)) { phrase in
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(phrase.phrase)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                        if !phrase.prompt.isEmpty {
                            Text(phrase.prompt)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        Text("\(phrase.source.label) · \(dueLabel(phrase))")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Button {
                        tts.speak(phrase.phrase, language: phrase.language, slow: settings.slowSpeech)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill").foregroundStyle(SF.teal)
                    }
                    .buttonStyle(.borderless)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        phrasebook.remove(phrase.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Phrasebook")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func dueLabel(_ phrase: SavedPhrase) -> String {
        if phrase.dueAt <= .now { return "due now" }
        return "next " + phrase.dueAt.formatted(.relative(presentation: .named))
    }
}

struct LessonPlayerView: View {
    private enum Kind {
        case lesson(LearnLesson)
        case review([SavedPhrase])
    }

    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var phrasebook: PhrasebookStore
    private let kind: Kind
    private let title: String
    private let prompts: [LearnPrompt]

    @StateObject private var speech = SpeechRecognitionService()
    @StateObject private var tts = SpeechSynthesisService()
    @State private var index = 0
    @State private var revealed = false
    @State private var attempt = ""
    @State private var feedback: String?
    @State private var passed = false
    @State private var listening = false
    @State private var remembered = 0
    @Environment(\.dismiss) private var dismiss

    init(lesson: LearnLesson) {
        kind = .lesson(lesson)
        title = lesson.title
        prompts = lesson.prompts
    }

    init(review deck: [SavedPhrase]) {
        kind = .review(deck)
        title = "Review"
        prompts = deck.map {
            LearnPrompt(id: $0.id.uuidString, english: $0.prompt.isEmpty ? "Say it again" : $0.prompt, target: $0.phrase, tip: $0.note)
        }
    }

    private var isReview: Bool {
        if case .review = kind { return true }
        return false
    }
    private var micSupported: Bool { SpeechRecognitionService.supports(settings.language) }
    /// Review, and languages without speech recognition, use self-rating instead of auto-grading.
    private var selfRated: Bool { isReview || !micSupported }
    private var prompt: LearnPrompt { prompts[min(index, prompts.count - 1)] }
    private var isLast: Bool { index >= prompts.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(index + 1), total: Double(max(prompts.count, 1)))
                .tint(SF.coral)
                .padding()

            Spacer()

            VStack(alignment: .leading, spacing: 16) {
                Text(isReview ? "Say this in \(settings.language.displayName)" : "Say this idea")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(SF.teal)
                Text(prompt.english)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .minimumScaleFactor(0.6)

                if revealed {
                    Text(prompt.target)
                        .font(.system(.title, design: .rounded).weight(.semibold))
                        .foregroundStyle(SF.mint)
                    if !prompt.tip.isEmpty {
                        Text(prompt.tip)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
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
                        .foregroundStyle(passed ? SF.mint : SF.coral)
                }
                if !micSupported {
                    Text("Speech recognition doesn't support \(settings.language.displayName) yet — say it out loud, then Reveal and rate yourself.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        reveal()
                    } label: {
                        Label(revealed ? "Listen" : "Reveal", systemImage: "speaker.wave.2.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if micSupported {
                        Button {
                            Task { await toggleListen() }
                        } label: {
                            Label(listening ? "Stop" : "Try saying it", systemImage: listening ? "stop.fill" : "mic.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(listening ? SF.coral : SF.teal)
                    }
                }

                if selfRated {
                    HStack(spacing: 12) {
                        Button {
                            advance(remembered: false)
                        } label: {
                            Text("Need practice").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(SF.coral)

                        Button {
                            advance(remembered: true)
                        } label: {
                            Text("Got it").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SF.mint)
                        .disabled(!revealed && !passed)
                    }
                } else {
                    Button {
                        advance(remembered: passed)
                    } label: {
                        Text(isLast ? "Finish lesson" : "Next").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SF.coral)
                }
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            speech.prepare(for: settings.language)
            if micSupported {
                await speech.requestPermissions()
            }
        }
        .onDisappear {
            tts.stop()
            speech.stopListening(cancel: true)
        }
    }

    private func reveal() {
        if listening {
            speech.stopListening(cancel: true)
            listening = false
        }
        revealed = true
        tts.speak(prompt.target, language: settings.language, slow: settings.slowSpeech)
    }

    private func toggleListen() async {
        if listening {
            speech.stopListening(cancel: false)
            listening = false
            attempt = speech.transcript
            revealed = true
            applyGrade(PhraseGrader.grade(attempt: attempt, target: prompt.target))
        } else {
            tts.stop()
            attempt = ""; feedback = nil; speech.transcript = ""
            let promptIndex = index
            let target = prompt.target
            speech.onUtteranceComplete = { text in
                Task { @MainActor in
                    guard promptIndex == index else { return }
                    attempt = text
                    listening = false
                    revealed = true
                    applyGrade(PhraseGrader.grade(attempt: text, target: target))
                }
            }
            speech.onError = { message in
                Task { @MainActor in
                    guard promptIndex == index else { return }
                    listening = false
                    feedback = message
                    passed = false
                }
            }
            do {
                try speech.startListening(style: .drill)
                listening = true
            } catch {
                feedback = error.localizedDescription
            }
        }
    }

    private func applyGrade(_ result: PhraseGrader.Result) {
        feedback = result.message
        // A pass sticks even if a later attempt goes worse.
        passed = passed || result.passed
    }

    private func advance(remembered gotIt: Bool) {
        tts.stop()
        speech.stopListening(cancel: true)
        listening = false

        switch kind {
        case .lesson:
            if !gotIt {
                phrasebook.add(phrase: prompt.target, prompt: prompt.english, note: prompt.tip, language: settings.language, source: .lesson)
            }
        case .review(let deck):
            if deck.indices.contains(index) {
                phrasebook.record(deck[index].id, remembered: gotIt)
            }
            if gotIt { remembered += 1 }
        }

        if isLast {
            finish()
        } else {
            index += 1
            revealed = false
            attempt = ""
            feedback = nil
            passed = false
        }
    }

    private func finish() {
        switch kind {
        case .lesson(let lesson):
            settings.completeLesson(lesson.id)
        case .review:
            settings.recordPractice()
            settings.xp += 2 * remembered
        }
        dismiss()
    }
}
