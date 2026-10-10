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
        u("de-1", .german, "Don't freeze", "Buy time. Stay in German.", "🧊", [
            l("de-1a", "Basics", [
                p("d1", "I don't know", "Ich weiß nicht", "Keep it short."),
                p("d2", "Can you repeat?", "Kannst du das wiederholen?", "Thinking time."),
                p("d3", "because", "weil", "Verb goes to the end."),
                p("d4", "I think that…", "Ich denke, dass…", "Opinion.")
            ]),
            l("de-1b", "Keep it going", [
                p("d8", "Give me a second", "Einen Moment, bitte", "Pause without panic."),
                p("d9", "How do you say…?", "Wie sagt man…?", "Ask in German."),
                p("d10", "but", "aber", "Contrast — word order stays normal."),
                p("d11", "also / too", "auch", "Add one more idea."),
                p("d12", "so / then", "also", "False friend: German also = so.")
            ])
        ]),
        u("de-2", .german, "Daily", "Present-tense muscle memory", "☀️", [
            l("de-2a", "You", [
                p("d5", "My name is…", "Ich heiße…", "Intro."),
                p("d6", "I work from home", "Ich arbeite von zu Hause aus", "WFH."),
                p("d7", "I'm tired", "Ich bin müde", "Feelings.")
            ]),
            l("de-2b", "Food & plans", [
                p("d13", "I live in…", "Ich wohne in…", "wohnen = live somewhere."),
                p("d14", "I'm hungry", "Ich habe Hunger", "Haben + noun, like Spanish tener."),
                p("d15", "I like coffee", "Ich trinke gern Kaffee", "Verb + gern = like doing it."),
                p("d16", "I'm going shopping", "Ich gehe einkaufen", "Second verb goes last."),
                p("d17", "See you later", "Bis später", "Clean exit.")
            ])
        ]),
        u("de-3", .german, "Tell a story", "Past tense without freezing", "📖", [
            l("de-3a", "Yesterday", [
                p("d18", "Yesterday I was in…", "Gestern war ich in…", "Verb stays second, so ich moves after war."),
                p("d19", "I was tired", "Ich war müde", "war = was. Easiest past there is."),
                p("d20", "I played soccer", "Ich habe Fußball gespielt", "haben … ge-…-t: participle goes last."),
                p("d21", "It was worth it", "Es hat sich gelohnt", "Great closer.")
            ])
        ]),
        u("de-4", .german, "Have an opinion", "Sound like a real adult", "💡", [
            l("de-4a", "Take a stance", [
                p("d22", "In my opinion…", "Meiner Meinung nach…", "Verb comes right after: …ist das gut."),
                p("d23", "On the other hand…", "Andererseits…", "Debate move."),
                p("d24", "Even though…", "Obwohl…", "Like weil — verb to the end."),
                p("d25", "For example…", "Zum Beispiel…", "Support your point.")
            ])
        ])
    ]

    static let italian: [LearnUnit] = [
        u("it-1", .italian, "Don't freeze", "Buy time. Stay in Italian.", "🧊", [
            l("it-1a", "Basics", [
                p("i1", "I don't know", "Non lo so", "Include lo."),
                p("i2", "Can you repeat?", "Puoi ripetere?", "Pause."),
                p("i3", "because", "perché", "Finish the thought."),
                p("i4", "I think that…", "Penso che…", "Opinion.")
            ]),
            l("it-1b", "Keep it going", [
                p("i8", "Give me a second", "Un attimo", "Pause without panic."),
                p("i9", "How do you say…?", "Come si dice…?", "Ask in Italian."),
                p("i10", "but", "ma", "Contrast = real conversation."),
                p("i11", "also / too", "anche", "Add one more idea."),
                p("i12", "so / then", "allora", "Italians open half their sentences with it.")
            ])
        ]),
        u("it-2", .italian, "Daily", "Present-tense muscle memory", "☀️", [
            l("it-2a", "You", [
                p("i5", "My name is…", "Mi chiamo…", "Reflexive."),
                p("i6", "I work from home", "Lavoro da casa", "Natural."),
                p("i7", "I'm tired", "Sono stanco/a", "Feelings.")
            ]),
            l("it-2b", "Food & plans", [
                p("i13", "I live in…", "Abito a…", "a + city, in + country."),
                p("i14", "I'm hungry", "Ho fame", "Avere + noun, like Spanish tener."),
                p("i15", "I like coffee", "Mi piace il caffè", "Piacere flips like gustar."),
                p("i16", "I'm going to the store", "Vado al negozio", "a + il = al."),
                p("i17", "See you later", "A dopo", "Clean exit.")
            ])
        ]),
        u("it-3", .italian, "Tell a story", "Past tense without freezing", "📖", [
            l("it-3a", "Yesterday", [
                p("i18", "Yesterday I went to…", "Ieri sono andato/a a…", "Movement verbs use essere."),
                p("i19", "I was tired", "Ero stanco/a", "Imperfect for states."),
                p("i20", "I used to play…", "Giocavo…", "Habitual past."),
                p("i21", "It was worth it", "Ne è valsa la pena", "Great closer.")
            ])
        ]),
        u("it-4", .italian, "Have an opinion", "Sound like a real adult", "💡", [
            l("it-4a", "Take a stance", [
                p("i22", "In my opinion…", "Secondo me…", "The most natural opener."),
                p("i23", "On the other hand…", "D'altra parte…", "Debate move."),
                p("i24", "Even though…", "Anche se…", "Simple and everywhere."),
                p("i25", "For example…", "Per esempio…", "Support your point.")
            ])
        ])
    ]

    static let tagalog: [LearnUnit] = [
        u("fil-1", .tagalog, "Don't freeze", "Buy time. Stay in Tagalog.", "🧊", [
            l("fil-1a", "Basics", [
                p("f1", "I don't know", "Hindi ko alam", "When stuck."),
                p("f2", "Can you repeat?", "Puwede bang ulitin?", "Pause."),
                p("f3", "because", "kasi", "Finish the thought."),
                p("f4", "I think…", "Sa tingin ko…", "Opinion.")
            ]),
            l("fil-1b", "Keep it going", [
                p("f8", "Wait a moment", "Sandali lang", "Pause without panic."),
                p("f9", "What does … mean?", "Ano ang ibig sabihin ng…?", "Ask in Tagalog."),
                p("f10", "but", "pero", "Borrowed from Spanish — easy win."),
                p("f11", "also / too", "din/rin", "rin after vowels, din after consonants."),
                p("f12", "and then", "tapos", "Glue for stories.")
            ])
        ]),
        u("fil-2", .tagalog, "Daily", "Everyday chat", "☀️", [
            l("fil-2a", "You", [
                p("f5", "My name is…", "Ako si…", "Intro."),
                p("f6", "I work from home", "Nagtatrabaho ako sa bahay", "Habitual."),
                p("f7", "I'm tired", "Pagod ako", "Feelings.")
            ]),
            l("fil-2b", "Food & plans", [
                p("f13", "I live in…", "Nakatira ako sa…", "sa = in / at."),
                p("f14", "I'm hungry", "Gutom na ako", "na = already / now."),
                p("f15", "I like coffee", "Gusto ko ng kape", "Gusto ko + ng + thing."),
                p("f16", "I'm going to the store", "Pupunta ako sa tindahan", "pupunta = going to go."),
                p("f17", "See you later", "Kita tayo mamaya", "mamaya = later today.")
            ])
        ]),
        u("fil-3", .tagalog, "Tell a story", "Past tense without freezing", "📖", [
            l("fil-3a", "Yesterday", [
                p("f18", "Yesterday I went to…", "Kahapon, pumunta ako sa…", "-um- verbs: pumunta = went."),
                p("f19", "I already ate", "Kumain na ako", "na marks it as done."),
                p("f20", "I was tired yesterday", "Pagod ako kahapon", "No word for was — the time word does the work."),
                p("f21", "It was so fun!", "Ang saya!", "Ang + adjective = so …!")
            ])
        ]),
        u("fil-4", .tagalog, "Have an opinion", "Sound like a real adult", "💡", [
            l("fil-4a", "Take a stance", [
                p("f22", "In my opinion…", "Sa palagay ko…", "Opinion opener."),
                p("f23", "On the other hand…", "Sa kabilang banda…", "Debate move."),
                p("f24", "Even though…", "Kahit na…", "Kahit = even."),
                p("f25", "For example…", "Halimbawa…", "Support your point.")
            ])
        ])
    ]
}
