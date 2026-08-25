import Foundation

/// Offline Duolingo-style curriculum — no API required.
struct LearnUnit: Identifiable, Hashable {
    let id: String
    let language: Language
    let title: String
    let subtitle: String
    let emoji: String
    let lessons: [LearnLesson]
}

struct LearnLesson: Identifiable, Hashable {
    let id: String
    let title: String
    let prompts: [LearnPrompt]
}

struct LearnPrompt: Identifiable, Hashable {
    let id: String
    let english: String
    let target: String
    let tip: String
}

enum Curriculum {
    static func units(for language: Language) -> [LearnUnit] {
        switch language {
        case .spanish: return spanish
        case .german: return german
        case .italian: return italian
        case .tagalog: return tagalog
        }
    }

    private static func u(_ id: String, _ lang: Language, _ title: String, _ sub: String, _ emoji: String, _ lessons: [LearnLesson]) -> LearnUnit {
        LearnUnit(id: id, language: lang, title: title, subtitle: sub, emoji: emoji, lessons: lessons)
    }
    private static func l(_ id: String, _ title: String, _ prompts: [LearnPrompt]) -> LearnLesson {
        LearnLesson(id: id, title: title, prompts: prompts)
    }
    private static func p(_ id: String, _ en: String, _ target: String, _ tip: String) -> LearnPrompt {
        LearnPrompt(id: id, english: en, target: target, tip: tip)
    }

    static let spanish: [LearnUnit] = [
        u("es-1", .spanish, "Survive the freeze", "Buy time. Stay in Spanish.", "🧊", [
            l("es-1a", "Escape hatches", [
                p("1", "I don't know", "No sé", "Say this instead of switching to English."),
                p("2", "Can you repeat?", "¿Puedes repetir?", "Buys thinking time."),
                p("3", "Give me a second", "Dame un segundo", "Pause without panic."),
                p("4", "How do you say…?", "¿Cómo se dice…?", "Ask in Spanish."),
                p("5", "What I meant is…", "Lo que quise decir es…", "Self-repair mid-sentence.")
            ]),
            l("es-1b", "Connectors that unlock talking", [
                p("6", "because", "porque", "Finish the thought."),
                p("7", "but", "pero", "Contrast = real conversation."),
                p("8", "also", "también", "Add one more idea."),
                p("9", "so / then", "entonces", "Move the chat forward."),
                p("10", "I think that…", "Creo que…", "Opinion starter.")
            ])
        ]),
        u("es-2", .spanish, "Daily life", "Present-tense muscle memory", "☀️", [
            l("es-2a", "About you", [
                p("11", "My name is…", "Me llamo…", "Casual intro."),
                p("12", "I live in…", "Vivo en…", "Present habit."),
                p("13", "I work from home", "Trabajo desde casa", "Everyday."),
                p("14", "I'm a little nervous", "Estoy un poco nervioso/a", "Honesty wins.")
            ]),
            l("es-2b", "Food & plans", [
                p("15", "I'm hungry", "Tengo hambre", "Tener + noun."),
                p("16", "I like coffee", "Me gusta el café", "Gustar flips."),
                p("17", "I'm going to the store", "Voy a la tienda", "Ir a + place."),
                p("18", "See you later", "Hasta luego", "Clean exit.")
            ])
        ]),
        u("es-3", .spanish, "Tell a story", "Past tense without freezing", "📖", [
            l("es-3a", "Yesterday", [
                p("19", "Yesterday I went…", "Ayer fui a…", "Preterite for one event."),
                p("20", "I was tired", "Estaba cansado/a", "Imperfect for state."),
                p("21", "I used to play…", "Jugaba…", "Habitual past."),
                p("22", "It was worth it", "Valió la pena", "Great closer.")
            ])
        ]),
        u("es-4", .spanish, "Have an opinion", "Sound like a real adult", "💡", [
            l("es-4a", "Take a stance", [
                p("23", "In my opinion…", "En mi opinión…", "Soft opener."),
                p("24", "On the other hand…", "Por otro lado…", "Debate move."),
                p("25", "Even though…", "Aunque…", "Complex but useful."),
                p("26", "For example…", "Por ejemplo…", "Support your point.")
            ])
        ])
    ]

    static let german: [LearnUnit] = [
        u("de-1", .german, "Don't freeze", "Survival phrases", "🧊", [
            l("de-1a", "Basics", [
                p("d1", "I don't know", "Ich weiß nicht", "Keep it short."),
                p("d2", "Can you repeat?", "Kannst du das wiederholen?", "Thinking time."),
                p("d3", "because", "weil", "Verb goes to the end."),
                p("d4", "I think that…", "Ich denke, dass…", "Opinion.")
            ])
        ]),
        u("de-2", .german, "Daily", "Simple present", "☀️", [
            l("de-2a", "You", [
                p("d5", "My name is…", "Ich heiße…", "Intro."),
                p("d6", "I work from home", "Ich arbeite von zu Hause aus", "WFH."),
                p("d7", "I'm tired", "Ich bin müde", "Feelings.")
            ])
        ])
    ]

    static let italian: [LearnUnit] = [
        u("it-1", .italian, "Don't freeze", "Survival phrases", "🧊", [
            l("it-1a", "Basics", [
                p("i1", "I don't know", "Non lo so", "Include lo."),
                p("i2", "Can you repeat?", "Puoi ripetere?", "Pause."),
                p("i3", "because", "perché", "Finish the thought."),
                p("i4", "I think that…", "Penso che…", "Opinion.")
            ])
        ]),
        u("it-2", .italian, "Daily", "Simple present", "☀️", [
            l("it-2a", "You", [
                p("i5", "My name is…", "Mi chiamo…", "Reflexive."),
                p("i6", "I work from home", "Lavoro da casa", "Natural."),
                p("i7", "I'm tired", "Sono stanco/a", "Feelings.")
            ])
        ])
    ]

    static let tagalog: [LearnUnit] = [
        u("fil-1", .tagalog, "Don't freeze", "Survival phrases", "🧊", [
            l("fil-1a", "Basics", [
                p("f1", "I don't know", "Hindi ko alam", "When stuck."),
                p("f2", "Can you repeat?", "Puwede bang ulitin?", "Pause."),
                p("f3", "because", "kasi", "Finish the thought."),
                p("f4", "I think…", "Sa tingin ko…", "Opinion.")
            ])
        ]),
        u("fil-2", .tagalog, "Daily", "Everyday chat", "☀️", [
            l("fil-2a", "You", [
                p("f5", "My name is…", "Ako si…", "Intro."),
                p("f6", "I work from home", "Nagtatrabaho ako sa bahay", "Habitual."),
                p("f7", "I'm tired", "Pagod ako", "Feelings.")
            ])
        ])
    ]
}
