import Foundation

struct DrillPhrase: Identifiable, Equatable {
    let id: String
    let language: Language
    let promptEnglish: String
    let targetPhrase: String
    let tip: String
    let level: ConversationLevel
    let topic: ConversationTopic
}

enum PhraseBank {
    static func phrases(for language: Language, level: ConversationLevel? = nil, topic: ConversationTopic? = nil) -> [DrillPhrase] {
        all.filter { phrase in
            phrase.language == language
                && (level == nil || phrase.level.rank <= (level?.rank ?? 3))
                && (topic == nil || topic == .freeform || phrase.topic == topic || phrase.topic == .freeform)
        }
    }

    static let all: [DrillPhrase] = spanish + german + italian + tagalog

    private static func p(_ id: String, _ lang: Language, _ prompt: String, _ target: String, _ tip: String, _ level: ConversationLevel, _ topic: ConversationTopic) -> DrillPhrase {
        DrillPhrase(id: id, language: lang, promptEnglish: prompt, targetPhrase: target, tip: tip, level: level, topic: topic)
    }

    private static let spanish: [DrillPhrase] = [
        p("es-w1", .spanish, "Say: My name is…", "Me llamo…", "Casual intro.", .warmup, .dailyLife),
        p("es-w2", .spanish, "Say: Yes, I like it.", "Sí, me gusta.", "Gustar flips: it pleases me.", .warmup, .food),
        p("es-w3", .spanish, "Say: I don't know.", "No sé.", "Use this when you freeze.", .warmup, .freeform),
        p("es-w4", .spanish, "Say: Can you repeat that?", "¿Puedes repetir, por favor?", "Buys thinking time.", .warmup, .freeform),
        p("es-w5", .spanish, "Say: How are you?", "¿Cómo estás?", "Casual.", .warmup, .dailyLife),
        p("es-w6", .spanish, "Say: Give me a second.", "Dame un segundo.", "Mid-conversation pause.", .warmup, .freeform),
        p("es-w7", .spanish, "Say: How do you say…?", "¿Cómo se dice…?", "Stay in Spanish instead of switching.", .warmup, .freeform),
        p("es-b1", .spanish, "Say: I work from home.", "Trabajo desde casa.", "Present for habits.", .beginner, .work),
        p("es-b2", .spanish, "Say: I usually eat breakfast at eight.", "Suelo desayunar a las ocho.", "'Suelo' = I usually.", .beginner, .food),
        p("es-b3", .spanish, "Say: Because I was tired.", "Porque estaba cansado/a.", "Imperfect for how you felt.", .beginner, .health),
        p("es-b4", .spanish, "Say: I'm going to the store.", "Voy a la tienda.", "Ir a + place.", .beginner, .shopping),
        p("es-b5", .spanish, "Say: On weekends I hang out with friends.", "Los fines de semana salgo con amigos.", "'Salir con' = hang out.", .beginner, .family),
        p("es-b6", .spanish, "Say: I prefer tea to coffee.", "Prefiero el té al café.", "Preferir + noun.", .beginner, .food),
        p("es-b7", .spanish, "Say: I'm a little nervous when I speak.", "Me pongo un poco nervioso/a cuando hablo.", "Ponerse + adjective.", .beginner, .health),
        p("es-i1", .spanish, "Say: Last year I traveled to Spain.", "El año pasado viajé a España.", "Preterite for completed events.", .intermediate, .travel),
        p("es-i2", .spanish, "Say: I used to play soccer every Sunday.", "Jugaba al fútbol todos los domingos.", "Imperfect for habits.", .intermediate, .hobbies),
        p("es-i3", .spanish, "Say: I think that…, but on the other hand…", "Creo que…, pero por otro lado…", "Debate transition.", .intermediate, .opinions),
        p("es-i4", .spanish, "Say: If I have time, I'll call you.", "Si tengo tiempo, te llamo.", "Real condition.", .intermediate, .dailyLife),
        p("es-i5", .spanish, "Say: First I…, then I…", "Primero…, después…", "Sequencing.", .intermediate, .dailyLife),
        p("es-i6", .spanish, "Say: What I meant to say is…", "Lo que quise decir es…", "Self-repair when you freeze.", .intermediate, .freeform),
        p("es-a1", .spanish, "Say: Even though it was hard, it was worth it.", "Aunque fue difícil, valió la pena.", "Aunque + indicative.", .advanced, .opinions),
        p("es-a2", .spanish, "Say: I would have preferred to stay longer.", "Hubiera preferido quedarme más tiempo.", "Past subjunctive flavor.", .advanced, .travel),
    ]

    private static let german: [DrillPhrase] = [
        p("de-w1", .german, "Say: My name is…", "Ich heiße…", "Casual intro.", .warmup, .dailyLife),
        p("de-w2", .german, "Say: Yes, I like it.", "Ja, das gefällt mir.", "Gefallen takes dative.", .warmup, .food),
        p("de-w3", .german, "Say: I don't know.", "Ich weiß nicht.", "Keep it short.", .warmup, .freeform),
        p("de-w4", .german, "Say: Can you repeat that?", "Kannst du das bitte wiederholen?", "Informal.", .warmup, .freeform),
        p("de-b1", .german, "Say: I work from home.", "Ich arbeite von zu Hause aus.", "WFH phrase.", .beginner, .work),
        p("de-b2", .german, "Say: I'm going shopping.", "Ich gehe einkaufen.", "Gehen + infinitive.", .beginner, .shopping),
        p("de-i1", .german, "Say: Last year I traveled to Italy.", "Letztes Jahr bin ich nach Italien gereist.", "Perfekt with sein.", .intermediate, .travel),
        p("de-i2", .german, "Say: I used to play tennis every week.", "Ich habe früher jede Woche Tennis gespielt.", "'Früher' = used to.", .intermediate, .hobbies),
        p("de-a1", .german, "Say: Even though it was hard, it was worth it.", "Obwohl es schwer war, hat es sich gelohnt.", "Obwohl sends the verb to the end.", .advanced, .opinions),
    ]

    private static let italian: [DrillPhrase] = [
        p("it-w1", .italian, "Say: My name is…", "Mi chiamo…", "Reflexive.", .warmup, .dailyLife),
        p("it-w2", .italian, "Say: Yes, I like it.", "Sì, mi piace.", "Piacere flips like gustar.", .warmup, .food),
        p("it-w3", .italian, "Say: I don't know.", "Non lo so.", "Include 'lo'.", .warmup, .freeform),
        p("it-w4", .italian, "Say: Can you repeat that?", "Puoi ripetere, per favore?", "Thinking time.", .warmup, .freeform),
        p("it-b1", .italian, "Say: I work from home.", "Lavoro da casa.", "Simple and natural.", .beginner, .work),
        p("it-b2", .italian, "Say: On weekends I hang out with friends.", "Nel fine settimana esco con gli amici.", "'Uscire con'.", .beginner, .family),
        p("it-i1", .italian, "Say: Last year I traveled to Rome.", "L'anno scorso sono andato/a a Roma.", "Passato prossimo with essere.", .intermediate, .travel),
        p("it-i2", .italian, "Say: I used to play piano.", "Suonavo il pianoforte.", "Imperfetto.", .intermediate, .hobbies),
        p("it-a1", .italian, "Say: Even though it was hard, it was worth it.", "Anche se è stato difficile, ne è valsa la pena.", "Anche se + indicative.", .advanced, .opinions),
    ]

    private static let tagalog: [DrillPhrase] = [
        p("fil-w1", .tagalog, "Say: My name is…", "Ako si…", "Natural intro.", .warmup, .dailyLife),
        p("fil-w2", .tagalog, "Say: Yes, I like it.", "Oo, gusto ko.", "Gusto + ko.", .warmup, .food),
        p("fil-w3", .tagalog, "Say: I don't know.", "Hindi ko alam.", "When you freeze.", .warmup, .freeform),
        p("fil-w4", .tagalog, "Say: Can you repeat that?", "Puwede bang ulitin?", "Thinking time.", .warmup, .freeform),
        p("fil-b1", .tagalog, "Say: I work from home.", "Nagtatrabaho ako sa bahay.", "Nag- for habitual.", .beginner, .work),
        p("fil-b2", .tagalog, "Say: I'm going to the store.", "Pupunta ako sa tindahan.", "Pu- for future.", .beginner, .shopping),
        p("fil-i1", .tagalog, "Say: Last year I traveled to Cebu.", "Noong nakaraang taon, nagpunta ako sa Cebu.", "Noong for past.", .intermediate, .travel),
        p("fil-i2", .tagalog, "Say: I used to play basketball every Sunday.", "Dati, naglalaro ako ng basketball tuwing Linggo.", "'Dati' = used to.", .intermediate, .hobbies),
        p("fil-a1", .tagalog, "Say: Even though it was hard, it was worth it.", "Kahit mahirap, sulit naman.", "Kahit = even though.", .advanced, .opinions),
    ]
}
