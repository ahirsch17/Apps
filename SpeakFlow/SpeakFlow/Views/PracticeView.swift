import Speech
import SwiftUI

/// Hear a line, say the reply. A miss is corrected, then asked again after the set. Only a clean recall counts.
struct PracticeHomeView: View {
    @EnvironmentObject private var settings: SettingsStore
    /// Keeps the review on screen after a pass. Without this, the next topic replaces it immediately.
    @State private var heldTopicID: String?

    private var topic: PathTopic? {
        if let heldTopicID, let pinned = SpeakPath.topic(heldTopicID, language: settings.language) { return pinned }
        return settings.currentTopic
    }

    var body: some View {
        NavigationStack {
            Group {
                if let topic {
                    PracticeSessionView(
                        topic: topic,
                        onHoldReview: { heldTopicID = topic.id },
                        onFinishedReview: { heldTopicID = nil }
                    )
                    .id(topic.id + settings.language.rawValue)
                } else {
                    pathComplete
                }
            }
            .onChange(of: settings.language) { _, _ in heldTopicID = nil }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SF.ink.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PRACTICE")
                        .font(SF.label(13))
                        .tracking(2.6)
                        .foregroundStyle(SF.teal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SF.ink, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var pathComplete: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Text("Off the script.")
                .font(SF.displayItalic(40))
                .foregroundStyle(.white)
            Text("Every short conversation in \(settings.language.displayName) is done. You, then Call, when you want \(settings.character.name) to answer what you actually say.")
                .font(SF.ui(16))
                .foregroundStyle(.white.opacity(0.62))
            Spacer()
        }
        .padding(24)
    }
}

private struct PracticeSessionView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.tabIndex) private var tabIndex
    let topic: PathTopic
    var onHoldReview: () -> Void
    var onFinishedReview: () -> Void

    @StateObject private var speech = SpeechRecognitionService()
    @StateObject private var tts = SpeechSynthesisService()

    @State private var step: Step = .drill
    /// Phrase indexes still due this pass. A clean recall moves to the back until it has three.
    @State private var deck: [Int] = []
    /// Misses. They run after the current pass, with the answer hidden.
    @State private var later: [Int] = []
    /// How many after-set passes have already run. Caps the automatic loop.
    @State private var waves = 0
    /// Cards already taught this sitting, so a miss comes back as recall even at 0 reps.
    @State private var introduced: Set<Int> = []
    /// The card on screen is the first hearing, so the reply stays visible.
    @State private var teaching = false
    /// The listen in flight is a repeat of the line just played. It does not count.
    @State private var echoing = false
    /// True while the deck is the after-set pile.
    @State private var retryRound = false
    @State private var blankTries = 0
    @State private var beatQueue: [Int] = []
    @State private var beatIndex = 0
    /// Second pass of the questions that missed.
    @State private var sceneRetry = false
    /// The listen in flight is a repeat of the answer just played.
    @State private var echoingAnswer = false
    @State private var listening = false
    @State private var attempt = ""
    @State private var feedback: String?
    @State private var turns: [SpokenTurn] = []
    @State private var scenePassed = false
    @State private var modelSummary: String?
    @State private var modelNotes: [DialogueNote] = []
    @State private var reviewing = false
    @State private var reviewError: String?
    /// Bumps cancel a listen that was armed before the phrase changed.
    @State private var loop = 0
    @State private var started = false
    /// Audio only runs while this screen is the one on display.
    @State private var onScreen = false
    @State private var bootstrapped = false
    /// True after the screen left, so coming back restarts the same card once.
    @State private var paused = false
    @State private var listenError: String?
    /// A miss on a recall card shows the line so the retry is a repeat, not a guess.
    @State private var revealed = false

    private enum Step { case drill, rest, talk, review }

    private var phrase: PathPhrase {
        let idx = deck.first ?? 0
        return topic.phrases[min(idx, topic.phrases.count - 1)]
    }

    private var fromMemory: Bool { !teaching && !revealed }

    private var cardMark: String {
        if revealed { return "Say it back" }
        if teaching { return "Hear it" }
        if retryRound { return "Once more" }
        return "Answer"
    }

    /// What they hear. A question you start has no spoken cue, so the English situation is the card.
    private var heardLine: String {
        phrase.cue.isEmpty ? phrase.cueEnglish : phrase.cue
    }
    private var beat: PathBeat { topic.beats[min(beatIndex, topic.beats.count - 1)] }
    private var showEnglish: Bool {
        (SpeakPath.topics(for: settings.language).firstIndex(where: { $0.id == topic.id }) ?? 0) < 2
    }

    var body: some View {
        VStack(spacing: 0) {
            topicBar
            switch step {
            case .drill: drill
            case .rest: rest
            case .talk: talk
            case .review: review
            }
        }
        .task {
            guard !started else { return }
            started = true
            await speech.requestPermissions()
            speech.prepare(for: settings.language)
            kick()
        }
        .onAppear {
            guard tabIndex == 0 else { return }
            onScreen = true
            guard paused else {
                kick()
                return
            }
            paused = false
            if bootstrapped { resumeCurrent() } else { kick() }
        }
        .onChange(of: tabIndex) { old, new in
            if new == 0, old != 0 {
                onScreen = true
                guard paused else { return }
                paused = false
                if bootstrapped { resumeCurrent() } else { kick() }
            } else if new != 0 {
                onScreen = false
                paused = true
                stopLoop()
            }
        }
        .onDisappear {
            paused = true
            stopLoop()
        }
    }

    private var topicBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(topic.tense)
                .font(SF.ui(15))
                .foregroundStyle(SF.coral)
            Text(topic.title)
                .font(SF.display(26))
                .foregroundStyle(.white)
            lessonTrack
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.top, 8)
    }

    /// Grows only when a clean answer is saved. Misses do not move it.
    private var lessonTrack: some View {
        let total = max(topic.phrases.count * SpeakPath.repsToPass, 1)
        let done = topic.phrases.reduce(0) { $0 + settings.reps(for: $1.id) }
        let fraction = min(1, CGFloat(done) / CGFloat(total))
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.white.opacity(0.16))
                Rectangle().fill(SF.teal).frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 3)
        .accessibilityLabel("\(done) of \(total) clean answers")
    }

    private var drill: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Text(cardMark)
                        .font(SF.ui(15))
                        .foregroundStyle(SF.teal)
                    RepTicks(filled: settings.reps(for: phrase.id))
                }
                Text(heardLine)
                    .font(fromMemory ? SF.displayItalic(44) : SF.display(22))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .id(phrase.id)
                if !phrase.cue.isEmpty && (showEnglish || fromMemory) {
                    Text(phrase.cueEnglish)
                        .font(SF.ui(17))
                        .foregroundStyle(.white.opacity(0.72))
                }
                if !fromMemory {
                    Text(phrase.line)
                        .font(SF.displayItalic(48))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                    if !phrase.tip.isEmpty {
                        Text(phrase.tip)
                            .font(SF.ui(16))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
                if revealed {
                    Text("This one comes back at the end.")
                        .font(SF.ui(16))
                        .foregroundStyle(SF.coral)
                }
                if !attempt.isEmpty {
                    Text(attempt)
                        .font(SF.ui(16))
                        .foregroundStyle(.white.opacity(0.75))
                }
                if let feedback {
                    Text(feedback)
                        .font(SF.uiBold(15))
                        .foregroundStyle(SF.coral)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            statusLine
        }
    }

    private var rest: some View {
        let due = topic.phrases.indices.filter { settings.reps(for: topic.phrases[$0].id) < SpeakPath.repsToPass }
        return VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("Same lines. From memory.")
                .font(SF.displayItalic(32))
                .foregroundStyle(.white)
                .padding(.bottom, 8)
            Text("A repeat right after you hear it does not count. These still need a clean answer.")
                .font(SF.ui(15))
                .foregroundStyle(.white.opacity(0.55))
                .padding(.bottom, 16)
            ForEach(due, id: \.self) { idx in
                Text(topic.phrases[idx].line)
                    .font(SF.displayItalic(26))
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .bottom) { Rectangle().fill(SF.line).frame(height: 1) }
            }
            Button("Once more") { resumeDue() }
                .buttonStyle(StampButton())
                .padding(.top, 22)
            Spacer()
        }
        .padding(22)
    }

    private var talk: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 14) {
                Text(sceneRetry ? "Once more" : "\(beatIndex + 1) of \(topic.beats.count)")
                    .font(SF.ui(15))
                    .foregroundStyle(SF.teal)
                Text(beat.ask)
                    .font(SF.displayItalic(44))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                if showEnglish {
                    Text(beat.askEnglish)
                        .font(SF.ui(17))
                        .foregroundStyle(.white.opacity(0.72))
                }
                if !attempt.isEmpty {
                    Text(attempt)
                        .font(SF.ui(17))
                        .foregroundStyle(.white.opacity(0.8))
                }
                if let feedback {
                    Text(feedback)
                        .font(SF.uiBold(15))
                        .foregroundStyle(SF.coral)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            statusLine
        }
    }

    private var statusLine: some View {
        VStack(alignment: .leading, spacing: 8) {
            if listenError == nil {
                Rectangle()
                    .fill(listening ? SF.coral : SF.teal)
                    .frame(width: 28, height: 3)
                Text(listening ? "Your turn" : "Listen")
                    .font(SF.ui(16))
                    .foregroundStyle(listening ? SF.coral : SF.teal)
            }
            if let listenError {
                Text(listenError)
                    .font(SF.ui(15))
                    .foregroundStyle(SF.coral)
                Button("Try again") { retryAudio() }
                    .buttonStyle(StampButton(filled: false))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
    }

    /// Starts the session once permissions are in and the screen is visible.
    private func kick() {
        guard started, onScreen, !bootstrapped else { return }
        bootstrapped = true
        landOnCurrentPhrase()
    }

    private func resumeCurrent() {
        listenError = nil
        stopLoop()
        switch step {
        case .drill:
            guard !deck.isEmpty else { return }
            presentCard()
        case .talk:
            echoingAnswer = false
            speakThenListen(topic.beats[beatIndex].ask, kind: .answer)
        case .rest, .review:
            break
        }
    }

    private func retryAudio() {
        listenError = nil
        Task {
            await speech.requestPermissions()
            speech.prepare(for: settings.language)
            resumeCurrent()
        }
    }

    private var review: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(scenePassed ? "That round counts." : "Not yet.")
                    .font(SF.display(32))
                    .foregroundStyle(.white)
                if !scenePassed {
                    Text("The misses were asked again after the set. Again runs only those.")
                        .font(SF.ui(15))
                        .foregroundStyle(.white.opacity(0.55))
                }
                Text(topic.tensePlain)
                    .font(SF.ui(15))
                    .foregroundStyle(.white.opacity(0.55))

                ForEach(turns) { turn in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(turn.ask)
                            .font(SF.displayItalic(20))
                            .foregroundStyle(.white)
                        Text(turn.heard.isEmpty ? "Heard nothing" : turn.heard)
                            .font(SF.ui(15))
                            .foregroundStyle(.white.opacity(0.7))
                        Text(turn.ok ? "Clean" : "Aim for \(turn.coach)")
                            .font(SF.label(13))
                            .tracking(0.6)
                            .foregroundStyle(turn.ok ? SF.teal : SF.coral)
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .bottom) { Rectangle().fill(SF.line).frame(height: 1) }
                }

                let local = DialogueReviewer.localNotes(topic: topic, turns: turns)
                if !local.isEmpty {
                    notesBlock(title: "From the transcript", notes: local)
                }

                if let modelSummary {
                    Text(modelSummary)
                        .font(SF.ui(16))
                        .foregroundStyle(.white)
                    if !modelNotes.isEmpty {
                        notesBlock(title: settings.character.name, notes: modelNotes)
                    }
                } else if settings.hasAPIKey && turns.contains(where: { !$0.ok }) {
                    Button(reviewing ? "Reading" : "Ask \(settings.character.name)") {
                        Task { await askModel() }
                    }
                    .buttonStyle(StampButton(filled: false))
                    .disabled(reviewing)
                } else if !settings.hasAPIKey && turns.contains(where: { !$0.ok }) {
                    Text("A key in You lets \(settings.character.name) read the misses. The lines above are already what the mic wrote.")
                        .font(SF.ui(13))
                        .foregroundStyle(.white.opacity(0.45))
                }
                if let reviewError {
                    Text(reviewError)
                        .font(SF.ui(13))
                        .foregroundStyle(SF.coral)
                }

                Button(scenePassed ? "Keep going" : "Again") {
                    if scenePassed {
                        onFinishedReview()
                    } else {
                        let missed = missedBeatIndexes()
                        startScene(only: missed.isEmpty ? nil : missed)
                    }
                }
                .buttonStyle(StampButton())
                .padding(.top, 4)
            }
            .padding()
        }
    }

    private func notesBlock(title: String, notes: [DialogueNote]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(SF.label(12))
                .tracking(1.4)
                .foregroundStyle(SF.teal)
            ForEach(notes) { note in
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.issue.uppercased())
                        .font(SF.label(11))
                        .tracking(1)
                        .foregroundStyle(SF.coral)
                    if !note.heard.isEmpty {
                        Text(note.heard)
                            .font(SF.ui(15))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    if !note.say.isEmpty {
                        Text(note.say)
                            .font(SF.displayItalic(18))
                            .foregroundStyle(.white)
                    }
                    Text(note.why)
                        .font(SF.ui(13))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func landOnCurrentPhrase() {
        later = []
        waves = 0
        introduced = []
        retryRound = false
        echoing = false
        deck = topic.phrases.indices.filter { settings.reps(for: topic.phrases[$0].id) < SpeakPath.repsToPass }
        if deck.isEmpty {
            startScene()
        } else {
            step = .drill
            presentCard()
        }
    }

    private func resumeDue() {
        waves = 0
        later = []
        retryRound = true
        deck = topic.phrases.indices.filter { settings.reps(for: topic.phrases[$0].id) < SpeakPath.repsToPass }
        step = .drill
        presentCard()
    }

    /// First hearing shows the reply. Every later card is recall, including a miss that is still at 0.
    private func presentCard() {
        revealed = false
        echoing = false
        blankTries = 0
        attempt = ""
        feedback = nil
        guard let idx = deck.first else {
            continueDeck()
            return
        }
        let item = topic.phrases[idx]
        let known = introduced.contains(idx) || settings.reps(for: item.id) > 0
        introduced.insert(idx)
        if !known {
            teaching = true
            if item.cue.isEmpty {
                speakThenListen(item.line, kind: .phrase)
            } else {
                speakCueThenAnswer(item)
            }
        } else {
            teaching = false
            if item.cue.isEmpty {
                listenOnly(kind: .phrase)
            } else {
                speakThenListen(item.cue, kind: .phrase)
            }
        }
    }

    /// A clean recall counts. An echo of the correction waits until after the set.
    private func finishCard(index: Int, countIt: Bool) {
        guard !deck.isEmpty else { return }
        deck.removeFirst()
        if countIt {
            let reps = settings.notePhraseRep(topic.phrases[index].id)
            if reps < SpeakPath.repsToPass {
                deck.append(index)
            }
        } else if !later.contains(index) {
            later.append(index)
        }
        continueDeck()
    }

    private func continueDeck() {
        if !deck.isEmpty {
            presentCard()
            return
        }
        if later.isEmpty {
            startScene()
            return
        }
        if waves >= 3 {
            step = .rest
            stopLoop()
            return
        }
        waves += 1
        retryRound = true
        deck = later
        later = []
        presentCard()
    }

    private func beginCorrection(note: String? = nil) {
        echoing = true
        teaching = false
        revealed = true
        feedback = note
        speakThenListen(phrase.line, kind: .phrase)
    }

    /// Question first, then the reply, then the mic. One loop id covers both utterances.
    private func speakCueThenAnswer(_ item: PathPhrase) {
        loop += 1
        let id = loop
        speech.stopListening(cancel: true)
        listening = false
        let cue = item.cue.replacingOccurrences(of: "…", with: "")
        let line = item.line.replacingOccurrences(of: "…", with: "")
        tts.speak(cue, language: settings.language) {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 280_000_000)
                guard id == loop, step == .drill else { return }
                tts.speak(line, language: settings.language) {
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 450_000_000)
                        guard id == loop, step == .drill else { return }
                        listen(kind: .phrase, id: id)
                    }
                }
            }
        }
    }

    private func listenOnly(kind: ListenKind) {
        loop += 1
        let id = loop
        tts.stop(invokeFinish: false)
        speech.stopListening(cancel: true)
        listening = false
        listen(kind: kind, id: id)
    }

    /// `only` replays the questions that are still missed. Nil starts the whole scene.
    private func startScene(only missed: [Int]? = nil) {
        beatQueue = missed ?? Array(topic.beats.indices)
        sceneRetry = missed != nil
        echoingAnswer = false
        if missed == nil { turns = [] }
        attempt = ""
        feedback = nil
        modelSummary = nil
        modelNotes = []
        reviewError = nil
        scenePassed = false
        step = .talk
        askNext()
    }

    private func beatCleared(_ index: Int) -> Bool {
        let id = topic.beats[index].id
        return turns.contains { $0.beatID == id && $0.ok }
    }

    private func missedBeatIndexes() -> [Int] {
        topic.beats.indices.filter { !beatCleared($0) }
    }

    private func askNext() {
        echoingAnswer = false
        attempt = ""
        feedback = nil
        guard !beatQueue.isEmpty else {
            closeScene()
            return
        }
        beatIndex = beatQueue.removeFirst()
        speakThenListen(topic.beats[beatIndex].ask, kind: .answer)
    }

    private func closeScene() {
        let missed = missedBeatIndexes()
        if !missed.isEmpty && !sceneRetry {
            sceneRetry = true
            beatQueue = missed
            askNext()
            return
        }
        scenePassed = missed.isEmpty
        if scenePassed {
            onHoldReview()
            settings.passScene(topic.id)
        }
        step = .review
        stopLoop()
        if let miss = turns.first(where: { !$0.ok }) {
            settings.rememberCoach("Next time, say \(miss.coach).")
        }
        if turns.contains(where: { !$0.ok }), settings.hasAPIKey {
            reviewing = true
            Task { await askModel() }
        }
    }

    private enum ListenKind { case phrase, answer }

    private func stopLoop() {
        loop += 1
        tts.stop()
        speech.stopListening(cancel: true)
        listening = false
    }

    /// Say the line, then open the mic. No tap between turns.
    private func speakThenListen(_ text: String, kind: ListenKind) {
        loop += 1
        let id = loop
        speech.stopListening(cancel: true)
        listening = false
        let spoken = text.replacingOccurrences(of: "…", with: "")
        tts.speak(spoken, language: settings.language) {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 450_000_000)
                guard id == loop else { return }
                guard step == .drill || step == .talk else { return }
                listen(kind: kind, id: id)
            }
        }
    }

    private func listen(kind: ListenKind, id: Int) {
        guard id == loop else { return }
        guard speech.isAuthorized else {
            listening = false
            listenError = "The mic is off for SpeakFlow. Turn it on in Settings, then try again."
            return
        }
        speech.transcript = ""
        speech.onUtteranceComplete = { text in
            Task { @MainActor in
                guard id == loop else { return }
                listening = false
                take(text, kind: kind)
            }
        }
        speech.onListenFailed = { message in
            Task { @MainActor in
                guard id == loop else { return }
                listening = false
                listenError = message
            }
        }
        let taskHint: SFSpeechRecognitionTaskHint = kind == .phrase ? .confirmation : .dictation
        do {
            try speech.startListening(style: .call, hints: recognitionHints(kind), taskHint: taskHint)
            listening = true
            listenError = nil
        } catch {
            listenError = error.localizedDescription
        }
    }

    private func recognitionHints(_ kind: ListenKind) -> [String] {
        switch kind {
        case .phrase:
            return [phrase.line.replacingOccurrences(of: "…", with: "")]
                .filter { !$0.isEmpty }
        case .answer:
            return topic.phrases.map { $0.line.replacingOccurrences(of: "…", with: "") } + [beat.coach]
        }
    }

    private func take(_ text: String, kind: ListenKind) {
        attempt = text
        switch kind {
        case .phrase:
            guard let index = deck.first else { return }
            let echoedCue = !phrase.cue.isEmpty
                && SpeechGrade.normalize(phrase.line) != SpeechGrade.normalize(phrase.cue)
                && SpeechGrade.isEcho(answer: text, question: phrase.cue)
            let others = topic.phrases.filter { $0.id != phrase.id }
            let decoys = others.flatMap { SpeechGrade.words($0.line) }.filter { $0.count > 3 }
            let decoyStems = others.flatMap(\.mustHear)
            let hit = !echoedCue && SpeechGrade.credits(
                text,
                line: phrase.line,
                stems: phrase.mustHear,
                decoys: decoys,
                decoyStems: decoyStems
            )
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                blankTries += 1
                if blankTries >= 3 {
                    blankTries = 0
                    if echoing { finishCard(index: index, countIt: false) } else { beginCorrection() }
                } else {
                    listenOnly(kind: .phrase)
                }
            } else if hit {
                finishCard(index: index, countIt: !echoing)
            } else if echoing {
                finishCard(index: index, countIt: false)
            } else {
                beginCorrection(note: SpeechGrade.genderNote(heard: text, line: phrase.line))
            }
        case .answer:
            let echoed = SpeechGrade.isEcho(answer: text, question: beat.ask)
            let ok = !echoed && SpeechGrade.accepted(text, beat: beat, topic: topic)
            if ok && !echoingAnswer {
                turns.append(SpokenTurn(beatID: beat.id, ask: beat.ask, heard: text, coach: beat.coach, ok: true))
                askNext()
            } else if !echoingAnswer {
                echoingAnswer = true
                feedback = SpeechGrade.genderNote(heard: text, line: beat.coach) ?? beat.coach
                speakThenListen(beat.coach, kind: .answer)
            } else {
                if sceneRetry {
                    turns.append(SpokenTurn(beatID: beat.id, ask: beat.ask, heard: text, coach: beat.coach, ok: false))
                }
                askNext()
            }
        }
    }

    private func askModel() async {
        reviewing = true
        reviewError = nil
        defer { reviewing = false }
        let tutor = settings.character.name
        let lines = turns.map { turn in
            "\(tutor): \(turn.ask)\nHeard: \(turn.heard.isEmpty ? "(silence)" : turn.heard)\nA good answer: \(turn.coach)\nMatched: \(turn.ok ? "yes" : "no")"
        }.joined(separator: "\n\n")
        let known = topic.phrases.map(\.line).joined(separator: "; ")
        let system = """
        You coach speaking, not writing. The learner is practicing \(settings.language.langLabel) out loud with \(tutor).
        You only see the speech-to-text transcript, not audio.
        Pronunciation notes only when the heard line differs from the good answer. Do not invent sounds.
        Do not explain a grammar table. Give the line they should say next time.
        Topic: \(topic.tense). \(topic.tensePlain)
        Phrases from this round: \(known)
        Return JSON: {"summary":"one spoken tip for next time","notes":[{"heard":"","issue":"tense|word|pronunciation","say":"the line to say","why":"under 12 English words"}]}
        Omit lines that were fine. Max 2 notes.
        """
        do {
            let raw = try await OpenAIService().chat(
                apiKey: settings.apiKey,
                model: settings.model,
                system: system,
                messages: [(role: "user", content: lines)],
                temperature: 0.2
            )
            if let parsed = DialogueReviewer.parseModelJSON(raw) {
                modelSummary = parsed.summary
                modelNotes = parsed.notes
                settings.rememberCoach(parsed.summary)
            } else {
                reviewError = "\(tutor) answered, but not in a shape I could show."
            }
        } catch {
            reviewError = error.localizedDescription
        }
    }
}
