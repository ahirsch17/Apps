import SwiftUI

/// A contents page, not a stack of matching cards.
struct PathOverviewView: View {
    @EnvironmentObject private var settings: SettingsStore

    private var current: PathTopic? { settings.currentTopic }
    private var topics: [PathTopic] { SpeakPath.topics(for: settings.language) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    masthead
                    if let current, !settings.topicLocked(current) {
                        phraseSheet(current)
                    }
                    index
                    freeTalk
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
            }
            .background(SF.ink.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PATH")
                        .font(SF.label(13))
                        .tracking(2.6)
                        .foregroundStyle(SF.teal)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(Language.allCases) { lang in
                            Button("\(lang.flag)  \(lang.displayName)") { settings.language = lang }
                        }
                    } label: {
                        Text(settings.language.flag)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SF.ink, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(settings.language.displayName.uppercased())
                .font(SF.label(12))
                .tracking(1.8)
                .foregroundStyle(SF.coral)
            if let current, let number = number(of: current) {
                Text(String(format: "%02d", number))
                    .font(SF.display(64))
                    .foregroundStyle(.white)
                    .padding(.top, 4)
                Text(current.title)
                    .font(SF.displayItalic(32))
                    .foregroundStyle(.white)
                Text(current.tense)
                    .font(SF.ui(16))
                    .foregroundStyle(.white.opacity(0.6))
                Text(statusLine(for: current))
                    .font(SF.ui(14))
                    .foregroundStyle(SF.teal)
                    .padding(.top, 4)
                if !settings.lastCoach.isEmpty {
                    Text(settings.lastCoach)
                        .font(SF.displayItalic(18))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.top, 6)
                }
            } else {
                Text("Off book")
                    .font(SF.displayItalic(40))
                    .foregroundStyle(.white)
                Text("Every topic is familiar. Call is the unscripted one.")
                    .font(SF.ui(16))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private func phraseSheet(_ topic: PathTopic) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("In this topic")
                .font(SF.ui(15))
                .foregroundStyle(.white.opacity(0.72))
                .padding(.bottom, 8)
            ForEach(topic.phrases) { phrase in
                let reps = settings.reps(for: phrase.id)
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        if !phrase.cue.isEmpty {
                            Text(phrase.cue)
                                .font(SF.ui(14))
                                .foregroundStyle(.white.opacity(0.72))
                        } else if !phrase.cueEnglish.isEmpty {
                            Text(phrase.cueEnglish)
                                .font(SF.ui(14))
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        Text(phrase.line)
                            .font(SF.displayItalic(22))
                            .foregroundStyle(.white)
                        Text(phrase.english)
                            .font(SF.ui(14))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    Spacer(minLength: 12)
                    RepTicks(filled: reps)
                }
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) { Rectangle().fill(SF.line).frame(height: 1) }
            }
        }
    }

    private var index: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("All topics")
                .font(SF.ui(15))
                .foregroundStyle(.white.opacity(0.72))
                .padding(.bottom, 4)
            ForEach(Array(topics.enumerated()), id: \.element.id) { offset, topic in
                let locked = settings.topicLocked(topic)
                let passed = settings.passedScenes.contains(topic.id)
                let here = topic.id == current?.id
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(String(format: "%02d", offset + 1))
                        .font(SF.label(14))
                        .foregroundStyle(here ? SF.coral : .white.opacity(0.35))
                        .frame(width: 28, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(topic.title)
                            .font(here ? SF.displayItalic(20) : SF.ui(16))
                            .foregroundStyle(locked ? .white.opacity(0.35) : .white)
                        Text(topic.tense)
                            .font(SF.ui(12))
                            .foregroundStyle(.white.opacity(locked ? 0.25 : 0.45))
                    }
                    Spacer(minLength: 8)
                    Text(passed ? "done" : (locked ? "later" : (here ? "now" : "")))
                        .font(SF.label(12))
                        .tracking(0.8)
                        .foregroundStyle(passed ? SF.teal : .white.opacity(0.4))
                }
                .padding(.vertical, 11)
                .overlay(alignment: .bottom) { Rectangle().fill(SF.line).frame(height: 1) }
            }
        }
    }

    private var freeTalk: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("UNSCRIPTED")
                .font(SF.label(12))
                .tracking(1.5)
                .foregroundStyle(SF.coral)
            if settings.freeTalkUnlocked {
                Text("\(SpeakPath.scenesBeforeFreeTalk) conversations are done. In You, Call and Text let \(settings.character.name) respond to what you say. That part needs a key.")
                    .font(SF.ui(15))
                    .foregroundStyle(.white.opacity(0.65))
            } else {
                let left = SpeakPath.scenesBeforeFreeTalk - settings.passedScenes.count
                Text("\(left) more conversation\(left == 1 ? "" : "s") before Call opens. Until then the questions stay on a script.")
                    .font(SF.ui(15))
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .padding(.bottom, 24)
    }

    private func number(of topic: PathTopic) -> Int? {
        guard let idx = topics.firstIndex(where: { $0.id == topic.id }) else { return nil }
        return idx + 1
    }

    private func statusLine(for topic: PathTopic) -> String {
        let passed = settings.passedScenes.contains(topic.id)
        if passed { return "Familiar. Practice moves on." }
        if settings.phrasesReady(topic) { return "Phrases are in. Practice is the conversation." }
        let left = topic.phrases.filter { settings.reps(for: $0.id) < SpeakPath.repsToPass }.count
        return "\(left) line\(left == 1 ? "" : "s") still need \(SpeakPath.repsToPass) clean answers. A miss comes back at the end of the set."
    }
}
