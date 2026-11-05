import Foundation

/// Teach a phrase, check it off after a few clean repeats, then use it in a short spoken exchange.
struct PathPhrase: Identifiable, Hashable {
    let id: String
    let english: String
    /// The line they say out loud. Named for the target language, not only Spanish.
    let line: String
    /// Substrings that must show up in the transcript. The ending on the line still has to match.
    let mustHear: [String]
    let tip: String
    /// What the other person says. Empty when this card is a question you start.
    let cue: String
    let cueEnglish: String

    init(
        id: String,
        english: String,
        line: String,
        mustHear: [String],
        tip: String = "",
        cue: String = "",
        cueEnglish: String = ""
    ) {
        self.id = id
        self.english = english
        self.line = line
        self.mustHear = mustHear
        self.tip = tip
        self.cue = cue
        self.cueEnglish = cueEnglish
    }
}

struct PathBeat: Identifiable, Hashable {
    let id: String
    let ask: String
    let askEnglish: String
    /// Any one of these is a good answer.
    let accept: [String]
    let coach: String
}

struct PathTopic: Identifiable, Hashable {
    let id: String
    let title: String
    let emoji: String
    /// The situation on the path. A conversation, not a chart.
    let tense: String
    /// The lines from this topic, said back in the review.
    let tensePlain: String
    let phrases: [PathPhrase]
    let beats: [PathBeat]
}

enum SpanishPath {
    static let repsToPass = 3
    /// Scripted rounds to finish before Call / Text leave the script.
    static let scenesBeforeFreeTalk = 4

    static let topics: [PathTopic] = [
        PathTopic(
            id: "es-you",
            title: "Introducing yourself",
            emoji: "👋",
            tense: "They ask who you are",
            tensePlain: "Me llamo… Tengo veinte años. Soy de Estados Unidos. Mucho gusto.",
            phrases: [
                PathPhrase(id: "es-you-name", english: "My name is…", line: "Me llamo…", mustHear: ["llamo"], tip: "Then your name.", cue: "¿Cómo te llamas?", cueEnglish: "What's your name?"),
                PathPhrase(id: "es-you-age", english: "I'm twenty years old", line: "Tengo veinte años", mustHear: ["tengo", "anos"], cue: "¿Cuántos años tienes?", cueEnglish: "How old are you?"),
                PathPhrase(id: "es-you-from", english: "I'm from the United States", line: "Soy de Estados Unidos", mustHear: ["soy", "de"], cue: "¿De dónde eres?", cueEnglish: "Where are you from?"),
                PathPhrase(id: "es-you-meet", english: "Nice to meet you", line: "Mucho gusto", mustHear: ["mucho", "gusto"], cue: "Me llamo María.", cueEnglish: "She told you her name.")
            ],
            beats: [
                PathBeat(id: "es-you-q1", ask: "¿Cómo te llamas?", askEnglish: "What's your name?", accept: ["llamo"], coach: "Me llamo…"),
                PathBeat(id: "es-you-q2", ask: "¿Cuántos años tienes?", askEnglish: "How old are you?", accept: ["tengo", "anos"], coach: "Tengo veinte años"),
                PathBeat(id: "es-you-q3", ask: "¿De dónde eres?", askEnglish: "Where are you from?", accept: ["soy", "de"], coach: "Soy de…")
            ]
        ),
        PathTopic(
            id: "es-feel",
            title: "How are you",
            emoji: "💬",
            tense: "They ask how you are",
            tensePlain: "Estoy bien. Estoy cansado. Estoy nervioso. ¿Y tú?",
            phrases: [
                PathPhrase(id: "es-feel-ok", english: "I'm well", line: "Estoy bien", mustHear: ["estoy", "bien"], cue: "¿Cómo estás?", cueEnglish: "How are you?"),
                PathPhrase(id: "es-feel-tired", english: "I'm tired", line: "Estoy cansado", mustHear: ["estoy", "cansad"], cue: "¿Estás cansado?", cueEnglish: "Are you tired?"),
                PathPhrase(id: "es-feel-nervous", english: "I'm nervous", line: "Estoy nervioso", mustHear: ["estoy", "nervios"], cue: "¿Estás nervioso?", cueEnglish: "Are you nervous?"),
                PathPhrase(id: "es-feel-you", english: "And you?", line: "¿Y tú?", mustHear: ["tu"], cue: "Estoy bien.", cueEnglish: "She said she's well.")
            ],
            beats: [
                PathBeat(id: "es-feel-q1", ask: "¿Cómo estás?", askEnglish: "How are you?", accept: ["bien", "cansad", "nervios"], coach: "Estoy bien"),
                PathBeat(id: "es-feel-q2", ask: "¿Estás cansado?", askEnglish: "Are you tired?", accept: ["cansad", "bien"], coach: "Estoy cansado, or No, estoy bien"),
                PathBeat(id: "es-feel-q3", ask: "¿Estás nervioso?", askEnglish: "Are you nervous?", accept: ["nervios", "bien"], coach: "Estoy nervioso, or No, estoy bien")
            ]
        ),
        PathTopic(
            id: "es-weather",
            title: "Weather",
            emoji: "🌤",
            tense: "They ask about the weather",
            tensePlain: "Hace sol. Hace frío. Hace calor. Está lloviendo.",
            phrases: [
                PathPhrase(id: "es-wx-sun", english: "It's sunny", line: "Hace sol", mustHear: ["hace", "sol"], cue: "¿Qué tiempo hace?", cueEnglish: "What's the weather like?"),
                PathPhrase(id: "es-wx-cold", english: "It's cold", line: "Hace frío", mustHear: ["hace", "frio"], cue: "¿Hace frío?", cueEnglish: "Is it cold?"),
                PathPhrase(id: "es-wx-hot", english: "It's hot", line: "Hace calor", mustHear: ["hace", "calor"], cue: "¿Hace calor?", cueEnglish: "Is it hot?"),
                PathPhrase(id: "es-wx-rain", english: "It's raining", line: "Está lloviendo", mustHear: ["esta", "lloviendo"], cue: "¿Está lloviendo?", cueEnglish: "Is it raining?")
            ],
            beats: [
                PathBeat(id: "es-wx-q1", ask: "¿Qué tiempo hace?", askEnglish: "What's the weather like?", accept: ["sol", "frio", "calor", "lloviendo"], coach: "Hace sol, or Está lloviendo"),
                PathBeat(id: "es-wx-q2", ask: "¿Hace frío o calor?", askEnglish: "Is it cold or hot?", accept: ["frio", "calor"], coach: "Hace frío, or Hace calor"),
                PathBeat(id: "es-wx-q3", ask: "¿Está lloviendo?", askEnglish: "Is it raining?", accept: ["lloviendo", "sol"], coach: "Sí, está lloviendo, or No, hace sol")
            ]
        ),
        PathTopic(
            id: "es-way",
            title: "Directions",
            emoji: "🧭",
            tense: "They ask the way",
            tensePlain: "¿Dónde está el baño? Está a la derecha. Sigue recto. Está cerca.",
            phrases: [
                PathPhrase(id: "es-way-where", english: "Where is the bathroom?", line: "¿Dónde está el baño?", mustHear: ["donde", "esta"], cueEnglish: "Ask where the bathroom is."),
                PathPhrase(id: "es-way-right", english: "It's on the right", line: "Está a la derecha", mustHear: ["derecha"], tip: "Izquierda is left.", cue: "¿Dónde está el baño?", cueEnglish: "Where is the bathroom?"),
                PathPhrase(id: "es-way-straight", english: "Go straight", line: "Sigue recto", mustHear: ["sigue", "recto"], cue: "¿Cómo llego?", cueEnglish: "How do I get there?"),
                PathPhrase(id: "es-way-near", english: "It's close", line: "Está cerca", mustHear: ["esta", "cerca"], cue: "¿Está lejos?", cueEnglish: "Is it far?")
            ],
            beats: [
                PathBeat(id: "es-way-q1", ask: "¿Dónde está el baño?", askEnglish: "Where is the bathroom?", accept: ["derecha", "cerca", "recto"], coach: "Está a la derecha"),
                PathBeat(id: "es-way-q2", ask: "¿Cómo llego?", askEnglish: "How do I get there?", accept: ["sigue", "recto"], coach: "Sigue recto"),
                PathBeat(id: "es-way-q3", ask: "¿Está lejos?", askEnglish: "Is it far?", accept: ["cerca", "lejos"], coach: "No, está cerca, or Está lejos")
            ]
        ),
        PathTopic(
            id: "es-animals",
            title: "Pets",
            emoji: "🐾",
            tense: "They ask about a pet",
            tensePlain: "Me gusta el perro. Me gusta el gato. Tengo un gato.",
            phrases: [
                PathPhrase(id: "es-an-like", english: "I like the dog", line: "Me gusta el perro", mustHear: ["gusta", "perro"], cue: "¿Te gustan los perros?", cueEnglish: "Do you like dogs?"),
                PathPhrase(id: "es-an-catlike", english: "I like the cat", line: "Me gusta el gato", mustHear: ["gusta", "gato"], cue: "¿Te gusta el gato?", cueEnglish: "Do you like the cat?"),
                PathPhrase(id: "es-an-have", english: "I have a cat", line: "Tengo un gato", mustHear: ["tengo", "gato"], cue: "¿Tienes un gato?", cueEnglish: "Do you have a cat?"),
                PathPhrase(id: "es-an-which", english: "I like the dog more", line: "Me gusta más el perro", mustHear: ["gusta", "perro"], cue: "¿Cuál te gusta más?", cueEnglish: "Which do you like more?")
            ],
            beats: [
                PathBeat(id: "es-an-q1", ask: "¿Te gustan los perros?", askEnglish: "Do you like dogs?", accept: ["perro"], coach: "Sí, me gusta el perro"),
                PathBeat(id: "es-an-q2", ask: "¿Tienes un perro o un gato?", askEnglish: "Do you have a dog or a cat?", accept: ["tengo+gato", "tengo+perro"], coach: "Tengo un gato, or Tengo un perro"),
                PathBeat(id: "es-an-q3", ask: "¿Cuál te gusta más?", askEnglish: "Which do you like more?", accept: ["gusta"], coach: "Me gusta el perro")
            ]
        ),
        PathTopic(
            id: "es-work",
            title: "Work and study",
            emoji: "💼",
            tense: "They ask what you do",
            tensePlain: "Trabajo. Estudio. Trabajo y estudio. ¿Qué haces?",
            phrases: [
                PathPhrase(id: "es-work-work", english: "I work", line: "Trabajo", mustHear: ["trabajo"], cue: "¿Qué haces?", cueEnglish: "What do you do?"),
                PathPhrase(id: "es-work-study", english: "I study", line: "Estudio", mustHear: ["estudio"], cue: "¿Estudias?", cueEnglish: "Do you study?"),
                PathPhrase(id: "es-work-both", english: "I work and I study", line: "Trabajo y estudio", mustHear: ["trabajo", "estudio"], cue: "¿Estudias o trabajas?", cueEnglish: "Do you study or work?"),
                PathPhrase(id: "es-work-what", english: "What do you do?", line: "¿Qué haces?", mustHear: ["haces"], cueEnglish: "Ask what they do.")
            ],
            beats: [
                PathBeat(id: "es-work-q1", ask: "¿Qué haces?", askEnglish: "What do you do?", accept: ["trabajo", "estudio"], coach: "Trabajo, or Estudio"),
                PathBeat(id: "es-work-q2", ask: "¿Estudias o trabajas?", askEnglish: "Do you study or work?", accept: ["trabajo", "estudio"], coach: "Trabajo y estudio"),
                PathBeat(id: "es-work-q3", ask: "¿Dónde trabajas?", askEnglish: "Where do you work?", accept: ["trabajo"], coach: "Trabajo en…")
            ]
        ),
        PathTopic(
            id: "es-past",
            title: "Yesterday",
            emoji: "📖",
            tense: "They ask about yesterday",
            tensePlain: "Ayer fui al trabajo. Estaba cansado. Hizo sol. Fue un buen día.",
            phrases: [
                PathPhrase(id: "es-past-went", english: "Yesterday I went to work", line: "Ayer fui al trabajo", mustHear: ["ayer", "fui"], cue: "¿Qué hiciste ayer?", cueEnglish: "What did you do yesterday?"),
                PathPhrase(id: "es-past-was", english: "I was tired", line: "Estaba cansado", mustHear: ["estaba", "cansad"], cue: "¿Cómo estabas?", cueEnglish: "How were you?"),
                PathPhrase(id: "es-past-sun", english: "It was sunny", line: "Hizo sol", mustHear: ["hizo", "sol"], cue: "¿Qué tiempo hizo?", cueEnglish: "What was the weather?"),
                PathPhrase(id: "es-past-good", english: "It was a good day", line: "Fue un buen día", mustHear: ["fue"], cue: "¿Qué tal el día?", cueEnglish: "How was the day?")
            ],
            beats: [
                PathBeat(id: "es-past-q1", ask: "¿Qué hiciste ayer?", askEnglish: "What did you do yesterday?", accept: ["fui"], coach: "Ayer fui al trabajo"),
                PathBeat(id: "es-past-q2", ask: "¿Cómo estabas?", askEnglish: "How were you?", accept: ["estaba"], coach: "Estaba cansado"),
                PathBeat(id: "es-past-q3", ask: "¿Qué tiempo hizo?", askEnglish: "What was the weather?", accept: ["hizo"], coach: "Hizo sol")
            ]
        )
    ]

    static func topic(_ id: String) -> PathTopic? {
        topics.first { $0.id == id }
    }
}

enum SpeakPath {
    static let repsToPass = SpanishPath.repsToPass
    static let scenesBeforeFreeTalk = SpanishPath.scenesBeforeFreeTalk

    static func topics(for language: Language) -> [PathTopic] {
        switch language {
        case .spanish: return SpanishPath.topics
        case .german: return GermanPath.topics
        case .italian: return ItalianPath.topics
        case .tagalog: return TagalogPath.topics
        }
    }

    static func topic(_ id: String, language: Language) -> PathTopic? {
        topics(for: language).first { $0.id == id }
    }
}

enum SpeechGrade {
    static func normalize(_ s: String) -> String {
        let folded = s.lowercased()
            .replacingOccurrences(of: "ß", with: "ss")
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "en"))
        let mapped = folded
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "’", with: "")
            .map { ch -> Character in
                if ch.isLetter || ch.isNumber || ch.isWhitespace { return ch }
                return " "
            }
        return String(mapped)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    static func words(_ s: String) -> [String] {
        normalize(s).split(separator: " ").map(String.init)
    }

    /// Whole word, plus a short ending (cansado, gustan, perros). Not a substring.
    static func wordHits(_ word: String, token: String) -> Bool {
        let t = normalize(token)
        guard !t.isEmpty else { return false }
        if word == t { return true }
        guard t.count >= 4, word.hasPrefix(t) else { return false }
        let rest = String(word.dropFirst(t.count))
        return ["a", "o", "as", "os", "an", "en", "s", "n"].contains(rest)
    }

    /// A repeat counts when every required piece shows up as its own word.
    static func matches(_ transcript: String, mustHear: [String]) -> Bool {
        let heard = words(transcript)
        guard !heard.isEmpty, !mustHear.isEmpty else { return false }
        return mustHear.allSatisfy { token in
            heard.contains { wordHits($0, token: token) }
        }
    }

    /// A dialogue answer counts when any accept-group is fully present.
    /// Join required pieces with "+", as in "ayer+fui".
    static func matchesAny(_ transcript: String, accept: [String]) -> Bool {
        accept.contains { group in
            let parts = group.split(separator: "+").map(String.init)
            return matches(transcript, mustHear: parts)
        }
    }

    /// The line counts when its real words are there. A mic slip on a word can pass.
    /// A different word does not, including a different ending that changes the meaning.
    static func credits(
        _ transcript: String,
        line: String,
        stems: [String] = [],
        decoys: [String] = [],
        decoyStems: [String] = []
    ) -> Bool {
        let target = words(line.replacingOccurrences(of: "…", with: " "))
        let heard = words(transcript)
        guard !target.isEmpty, !heard.isEmpty else { return false }
        if polarityClash(heard: heard, target: target) { return false }

        if swappedArticle(heard: heard, target: target) != nil { return false }

        let required = target.filter { !optionalWords.contains($0) }
        let must = required.isEmpty ? target : required
        var used = Array(repeating: false, count: heard.count)
        for token in must {
            guard let index = heard.indices.first(where: { i in
                !used[i] && wordAccepts(heard: heard[i], target: token, stems: stems)
            }) else { return false }
            used[index] = true
        }

        let banned = Set(decoys.map(normalize)).subtracting(target)
        let foreignStems = decoyStems.map(normalize).filter { stem in
            stem.count >= 4 && !target.contains { $0.hasPrefix(stem) }
        }
        for (index, word) in heard.enumerated() where !used[index] {
            if banned.contains(word) { return false }
            if foreignStems.contains(where: { wordHits(word, token: $0) }) { return false }
        }
        return true
    }

    /// A question passes only when the transcript is one of the taught replies, not a single shared word.
    static func accepted(_ transcript: String, beat: PathBeat, topic: PathTopic) -> Bool {
        let keys = targetKeys(beat: beat, topic: topic)
        let allowed = Set(keys.flatMap { words($0.line) })
        let keyLines = Set(keys.map { normalize($0.line) })
        let outside = topic.phrases.filter { !keyLines.contains(normalize($0.line)) }
        let decoys = outside.flatMap { words($0.line) }.filter { $0.count > 3 && !allowed.contains($0) }
        let decoyStems = outside.flatMap(\.mustHear)
        return keys.contains {
            credits(transcript, line: $0.line, stems: $0.stems, decoys: decoys, decoyStems: decoyStems)
        }
    }

    private struct LineKey {
        let line: String
        let stems: [String]
    }

    private static func targetKeys(beat: PathBeat, topic: PathTopic) -> [LineKey] {
        var keys: [LineKey] = []
        let coachLines = beat.coach
            .replacingOccurrences(of: " or ", with: "|")
            .split(separator: "|")
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " ,")) }
            .filter { !$0.isEmpty }
        for line in coachLines {
            keys.append(LineKey(line: line, stems: stems(for: line, topic: topic)))
        }
        for group in beat.accept {
            let parts = group.split(separator: "+").map(String.init)
            for phrase in topic.phrases where matches(phrase.line, mustHear: parts) {
                keys.append(LineKey(line: phrase.line, stems: phrase.mustHear))
            }
        }
        var seen: Set<String> = []
        return keys.filter { seen.insert(normalize($0.line)).inserted }
    }

    private static func stems(for line: String, topic: PathTopic) -> [String] {
        let heard = words(line)
        return topic.phrases.first { phrase in
            let parts = words(phrase.line)
            return !parts.isEmpty && parts.allSatisfy { part in
                heard.contains { wordAccepts(heard: $0, target: part, stems: phrase.mustHear) }
            }
        }?.mustHear ?? []
    }

    private static let optionalWords: Set<String> = [
        "el", "la", "los", "las", "un", "una", "unos", "unas", "y", "e", "o", "a", "en", "al", "del", "con", "por",
        "il", "lo", "i", "gli", "le", "ed",
        "der", "die", "das", "den", "ein", "eine", "und",
        "ang", "ng", "na",
        "the", "of", "and"
    ]

    /// Negatives only. "Sí" in front of a correct line is still that line.
    private static let polarityWords: Set<String> = [
        "no", "nein", "nicht", "non", "hindi"
    ]

    private static func polarityClash(heard: [String], target: [String]) -> Bool {
        let targetSet = Set(target)
        return heard.contains { polarityWords.contains($0) && !targetSet.contains($0) }
    }

    /// Masculine and feminine are different words here. A swapped ending or article does not pass.
    static func genderNote(heard: String, line: String) -> String? {
        let heardWords = words(heard)
        let options = line
            .replacingOccurrences(of: " or ", with: "|")
            .split(separator: "|")
            .map { words(String($0)) }
        for target in options {
            if let pair = swappedEnding(heard: heardWords, target: target) {
                return "\(spoken(pair.wrong)) is \(genderName(pair.wrong)). Say \(pair.right)."
            }
            if let pair = swappedArticle(heard: heardWords, target: target) {
                return "\(spoken(pair.wrong)) is \(genderName(pair.wrong)). Say \(pair.right)."
            }
        }
        return nil
    }

    private static func wordAccepts(heard: String, target: String, stems: [String]) -> Bool {
        if isGenderSwap(heard, target) { return false }
        if heard == target || sttNeighbor(heard, target) { return true }
        return stems.contains { stem in
            let token = normalize(stem)
            return token.count >= 4
                && target.hasPrefix(token)
                && token.count < target.count
                && wordHits(heard, token: token)
        }
    }

    /// Mishearings: dropped h, ll/y, b/v, one slipped letter. Not a different ending.
    private static func sttNeighbor(_ heard: String, _ target: String) -> Bool {
        let h = foldSTT(heard)
        let t = foldSTT(target)
        if h == t { return true }
        if isGenderSwap(h, t) || isConjugationSwap(h, t) { return false }
        if t.hasSuffix("s"), h == String(t.dropLast()), h.count >= 3 { return true }
        if h.count == t.count + 1, h.hasPrefix(t), let extra = h.last, "snt".contains(extra) {
            return false
        }
        return editDistance(h, t) == 1 && min(h.count, t.count) >= 4
    }

    private static func foldSTT(_ s: String) -> String {
        var t = s
        if t.hasPrefix("ll") { t = "y" + t.dropFirst(2) }
        else if t.hasPrefix("j") { t = "y" + t.dropFirst(1) }
        if t.hasPrefix("h") { t.removeFirst() }
        return t
            .replacingOccurrences(of: "v", with: "b")
            .replacingOccurrences(of: "z", with: "s")
    }

    /// Verb endings that look like o/a but are not gender.
    private static let notGender: Set<String> = [
        "llamo", "llama", "llamas", "tengo", "tiene", "tienes", "estoy", "estas", "esta",
        "soy", "eres", "es", "gusto", "gusta", "gustan", "hago", "hace", "haces",
        "trabajo", "trabaja", "trabajas", "estudio", "estudia", "estudias",
        "sigo", "sigue", "vengo", "viene", "fue", "fui", "estaba", "estabas", "hizo",
        "chiamo", "chiama", "sono", "sto", "stai", "sei", "ho", "hai", "vengo",
        "lavoro", "lavora", "studio", "studia", "fa",
        "bin", "bist", "ist", "heisse", "heisst", "komme", "kommst", "geht",
        "arbeite", "arbeitest", "studiere", "studierst", "macht", "machst", "regnet"
    ]

    private static func isGenderSwap(_ a: String, _ b: String) -> Bool {
        let pairs = [("o", "a"), ("os", "as"), ("a", "o"), ("as", "os")]
        for (left, right) in pairs {
            guard a.hasSuffix(left), b.hasSuffix(right) else { continue }
            let stemA = String(a.dropLast(left.count))
            let stemB = String(b.dropLast(right.count))
            if stemA == stemB, stemA.count >= 3 { return true }
        }
        let apocope: Set<String> = ["buen", "mal", "primer", "tercer", "algun", "ningun"]
        if apocope.contains(a), b == a + "a" || b == a + "o" { return true }
        if apocope.contains(b), a == b + "a" || a == b + "o" { return true }
        return false
    }

    private static func swappedEnding(heard: [String], target: [String]) -> (wrong: String, right: String)? {
        for right in target {
            for wrong in heard where isGenderSwap(wrong, right) && !notGender.contains(wrong) && !notGender.contains(right) {
                return (wrong, right)
            }
        }
        return nil
    }

    /// el/la, un/una, and the same split in Italian and German.
    private static func swappedArticle(heard: [String], target: [String]) -> (wrong: String, right: String)? {
        let groups: [[String]] = [
            ["el", "la"],
            ["los", "las"],
            ["un", "una"],
            ["unos", "unas"],
            ["der", "die", "das"],
            ["ein", "eine"],
            ["il", "lo", "la"],
            ["uno", "una"],
            ["gli", "le"]
        ]
        let heardSet = Set(heard)
        let targetSet = Set(target)
        for group in groups {
            let inTarget = group.filter { targetSet.contains($0) }
            guard inTarget.count == 1, let right = inTarget.first else { continue }
            if let wrong = group.first(where: { heardSet.contains($0) && $0 != right }) {
                return (wrong, right)
            }
        }
        return nil
    }

    private static func genderName(_ word: String) -> String {
        if word == "das" { return "neuter" }
        let feminine: Set<String> = ["la", "las", "una", "unas", "die", "eine", "le"]
        let masculine: Set<String> = ["el", "los", "un", "unos", "der", "ein", "il", "lo", "gli", "uno"]
        if feminine.contains(word) || word.hasSuffix("a") || word.hasSuffix("as") { return "feminine" }
        if masculine.contains(word) || word.hasSuffix("o") || word.hasSuffix("os") { return "masculine" }
        return "the other gender"
    }

    private static func spoken(_ word: String) -> String {
        guard let first = word.first else { return word }
        return first.uppercased() + word.dropFirst()
    }

    private static func isConjugationSwap(_ a: String, _ b: String) -> Bool {
        let vowels: Set<Character> = ["a", "e", "o"]
        let aa = Array(a)
        let bb = Array(b)
        guard aa.count == bb.count, aa.count >= 4 else { return false }
        let diffs = zip(aa, bb).enumerated().filter { $0.element.0 != $0.element.1 }
        guard diffs.count == 1, let diff = diffs.first else { return false }
        return diff.offset == aa.count - 1 && vowels.contains(diff.element.0) && vowels.contains(diff.element.1)
    }

    private static func editDistance(_ a: String, _ b: String) -> Int {
        let aa = Array(a)
        let bb = Array(b)
        if aa.isEmpty { return bb.count }
        if bb.isEmpty { return aa.count }
        var prevPrev = Array(repeating: 0, count: bb.count + 1)
        var prev = Array(0...bb.count)
        var curr = Array(repeating: 0, count: bb.count + 1)
        for i in 1...aa.count {
            curr[0] = i
            for j in 1...bb.count {
                let cost = aa[i - 1] == bb[j - 1] ? 0 : 1
                var best = min(curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost)
                if i > 1, j > 1, aa[i - 1] == bb[j - 2], aa[i - 2] == bb[j - 1] {
                    best = min(best, prevPrev[j - 2] + 1)
                }
                curr[j] = best
            }
            prevPrev = prev
            prev = curr
        }
        return prev[bb.count]
    }

    /// Repeating the question is not an answer. A shorter real answer still counts.
    static func isEcho(answer: String, question: String) -> Bool {
        let a = normalize(answer)
        let q = normalize(question)
        guard !a.isEmpty, !q.isEmpty else { return false }
        if a == q { return true }
        let aCount = a.split(separator: " ").count
        let qCount = q.split(separator: " ").count
        return q.contains(a) && aCount >= max(3, qCount - 1)
    }
}

struct SpokenTurn: Identifiable, Equatable {
    let id = UUID()
    let beatID: String
    let ask: String
    let heard: String
    let coach: String
    let ok: Bool
}

struct DialogueNote: Identifiable, Equatable {
    var id: String { "\(issue)|\(heard)|\(say)|\(why)" }
    let issue: String
    let heard: String
    let say: String
    let why: String
}

enum DialogueReviewer {
    /// Notes that don't need a key. Pronunciation here means the mic wrote a different word.
    static func localNotes(topic: PathTopic, turns: [SpokenTurn]) -> [DialogueNote] {
        var notes: [DialogueNote] = []
        let blob = SpeechGrade.normalize(turns.map(\.heard).joined(separator: " "))
        if blob.contains("soy bien") || blob.contains("soy mal") || blob.contains("soy cansad") || blob.contains("soy nervios") {
            notes.append(DialogueNote(
                issue: "line",
                heard: "soy…",
                say: "Estoy bien",
                why: "Say estoy bien."
            ))
        }
        if blob.contains("estoy de") {
            notes.append(DialogueNote(
                issue: "line",
                heard: "estoy de",
                say: "Soy de…",
                why: "Say soy de."
            ))
        }
        if blob.contains("yo gusto") {
            notes.append(DialogueNote(
                issue: "line",
                heard: "yo gusto",
                say: "Me gusta el perro",
                why: "Say me gusta el perro."
            ))
        }
        for turn in turns where !turn.ok {
            if let call = SpeechGrade.genderNote(heard: turn.heard, line: turn.coach) {
                notes.append(DialogueNote(
                    issue: "gender",
                    heard: turn.heard,
                    say: turn.coach,
                    why: call
                ))
                continue
            }
            if turn.heard.isEmpty {
                notes.append(DialogueNote(
                    issue: "pronunciation",
                    heard: "(nothing landed)",
                    say: turn.coach,
                    why: "The mic didn't get a phrase. Say \(turn.coach) as a whole."
                ))
            } else {
                notes.append(DialogueNote(
                    issue: "pronunciation",
                    heard: turn.heard,
                    say: turn.coach,
                    why: "The mic wrote something else, so those sounds didn't match \(turn.coach)."
                ))
            }
        }
        return notes
    }

    static func parseModelJSON(_ raw: String) -> (summary: String, notes: [DialogueNote])? {
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let summary = obj["summary"] as? String
        else { return nil }
        let rows = obj["notes"] as? [[String: Any]] ?? []
        let notes: [DialogueNote] = rows.compactMap { row in
            guard let why = row["why"] as? String, !why.isEmpty else { return nil }
            return DialogueNote(
                issue: (row["issue"] as? String) ?? "word",
                heard: (row["heard"] as? String) ?? "",
                say: (row["say"] as? String) ?? "",
                why: why
            )
        }
        return (summary, notes)
    }
}
