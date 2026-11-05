import Foundation

/// Spoken ladders for the other tutors. Same shape as Spanish: say it, then answer with it.
enum GermanPath {
    static let topics: [PathTopic] = [
        PathTopic(
            id: "de-you",
            title: "Introducing yourself",
            emoji: "👋",
            tense: "They ask who you are",
            tensePlain: "Ich heiße… Ich bin zwanzig Jahre alt. Ich komme aus den USA. Freut mich.",
            phrases: [
                PathPhrase(id: "de-you-name", english: "My name is…", line: "Ich heiße…", mustHear: ["heisse"], tip: "Then your name.", cue: "Wie heißt du?", cueEnglish: "What's your name?"),
                PathPhrase(id: "de-you-age", english: "I'm twenty years old", line: "Ich bin zwanzig Jahre alt", mustHear: ["bin", "jahre"], cue: "Wie alt bist du?", cueEnglish: "How old are you?"),
                PathPhrase(id: "de-you-from", english: "I'm from the USA", line: "Ich komme aus den USA", mustHear: ["komme", "usa"], cue: "Woher kommst du?", cueEnglish: "Where are you from?"),
                PathPhrase(id: "de-you-meet", english: "Nice to meet you", line: "Freut mich", mustHear: ["freut", "mich"], cue: "Ich heiße Anna.", cueEnglish: "She told you her name.")
            ],
            beats: [
                PathBeat(id: "de-you-q1", ask: "Wie heißt du?", askEnglish: "What's your name?", accept: ["heisse"], coach: "Ich heiße…"),
                PathBeat(id: "de-you-q2", ask: "Wie alt bist du?", askEnglish: "How old are you?", accept: ["jahre"], coach: "Ich bin zwanzig Jahre alt"),
                PathBeat(id: "de-you-q3", ask: "Woher kommst du?", askEnglish: "Where are you from?", accept: ["komme"], coach: "Ich komme aus…")
            ]
        ),
        PathTopic(
            id: "de-feel",
            title: "How are you",
            emoji: "💬",
            tense: "They ask how you are",
            tensePlain: "Mir geht's gut. Ich bin müde. Ich bin nervös. Und du?",
            phrases: [
                PathPhrase(id: "de-feel-ok", english: "I'm well", line: "Mir geht's gut", mustHear: ["geht", "gut"], cue: "Wie geht's dir?", cueEnglish: "How are you?"),
                PathPhrase(id: "de-feel-tired", english: "I'm tired", line: "Ich bin müde", mustHear: ["bin", "mude"], cue: "Bist du müde?", cueEnglish: "Are you tired?"),
                PathPhrase(id: "de-feel-nervous", english: "I'm nervous", line: "Ich bin nervös", mustHear: ["bin", "nervos"], cue: "Bist du nervös?", cueEnglish: "Are you nervous?"),
                PathPhrase(id: "de-feel-you", english: "And you?", line: "Und du?", mustHear: ["und", "du"], cue: "Mir geht's gut.", cueEnglish: "She said she's well.")
            ],
            beats: [
                PathBeat(id: "de-feel-q1", ask: "Wie geht's dir?", askEnglish: "How are you?", accept: ["gut", "mude", "nervos"], coach: "Mir geht's gut"),
                PathBeat(id: "de-feel-q2", ask: "Bist du müde?", askEnglish: "Are you tired?", accept: ["mude", "gut"], coach: "Ich bin müde, or Mir geht's gut"),
                PathBeat(id: "de-feel-q3", ask: "Und du, bist du nervös?", askEnglish: "And you, are you nervous?", accept: ["nervos", "gut"], coach: "Ich bin nervös")
            ]
        ),
        PathTopic(
            id: "de-weather",
            title: "Weather",
            emoji: "🌤",
            tense: "They ask about the weather",
            tensePlain: "Es ist sonnig. Es ist kalt. Es ist warm. Es regnet.",
            phrases: [
                PathPhrase(id: "de-wx-sun", english: "It's sunny", line: "Es ist sonnig", mustHear: ["sonnig"], cue: "Wie ist das Wetter?", cueEnglish: "How's the weather?"),
                PathPhrase(id: "de-wx-cold", english: "It's cold", line: "Es ist kalt", mustHear: ["kalt"], cue: "Ist es kalt?", cueEnglish: "Is it cold?"),
                PathPhrase(id: "de-wx-warm", english: "It's warm", line: "Es ist warm", mustHear: ["warm"], cue: "Ist es warm?", cueEnglish: "Is it warm?"),
                PathPhrase(id: "de-wx-rain", english: "It's raining", line: "Es regnet", mustHear: ["regnet"], cue: "Regnet es?", cueEnglish: "Is it raining?")
            ],
            beats: [
                PathBeat(id: "de-wx-q1", ask: "Wie ist das Wetter?", askEnglish: "How's the weather?", accept: ["sonnig", "kalt", "warm", "regnet"], coach: "Es ist sonnig, or Es regnet"),
                PathBeat(id: "de-wx-q2", ask: "Ist es kalt oder warm?", askEnglish: "Is it cold or warm?", accept: ["kalt", "warm"], coach: "Es ist kalt"),
                PathBeat(id: "de-wx-q3", ask: "Regnet es?", askEnglish: "Is it raining?", accept: ["regnet", "sonnig"], coach: "Ja, es regnet, or Nein, es ist sonnig")
            ]
        ),
        PathTopic(
            id: "de-work",
            title: "Work and study",
            emoji: "💼",
            tense: "They ask what you do",
            tensePlain: "Ich arbeite. Ich studiere. Ich arbeite und studiere. Was machst du?",
            phrases: [
                PathPhrase(id: "de-work-work", english: "I work", line: "Ich arbeite", mustHear: ["arbeite"], cue: "Was machst du?", cueEnglish: "What are you doing?"),
                PathPhrase(id: "de-work-study", english: "I study", line: "Ich studiere", mustHear: ["studiere"], cue: "Studiest du?", cueEnglish: "Do you study?"),
                PathPhrase(id: "de-work-both", english: "I work and I study", line: "Ich arbeite und studiere", mustHear: ["arbeite", "studiere"], cue: "Arbeitest du oder studierst du?", cueEnglish: "Do you work or study?"),
                PathPhrase(id: "de-work-what", english: "What are you doing?", line: "Was machst du?", mustHear: ["machst"], cueEnglish: "Ask what they're doing.")
            ],
            beats: [
                PathBeat(id: "de-work-q1", ask: "Was machst du?", askEnglish: "What are you doing?", accept: ["arbeite", "studiere"], coach: "Ich arbeite, or Ich studiere"),
                PathBeat(id: "de-work-q2", ask: "Arbeitest du oder studierst du?", askEnglish: "Do you work or study?", accept: ["arbeite", "studiere"], coach: "Ich arbeite und studiere"),
                PathBeat(id: "de-work-q3", ask: "Wo arbeitest du?", askEnglish: "Where do you work?", accept: ["arbeite"], coach: "Ich arbeite in…")
            ]
        )
    ]
}

enum ItalianPath {
    static let topics: [PathTopic] = [
        PathTopic(
            id: "it-you",
            title: "Introducing yourself",
            emoji: "👋",
            tense: "They ask who you are",
            tensePlain: "Mi chiamo… Ho venti anni. Vengo dall'America. Piacere.",
            phrases: [
                PathPhrase(id: "it-you-name", english: "My name is…", line: "Mi chiamo…", mustHear: ["chiamo"], tip: "Then your name.", cue: "Come ti chiami?", cueEnglish: "What's your name?"),
                PathPhrase(id: "it-you-age", english: "I'm twenty years old", line: "Ho venti anni", mustHear: ["ho", "anni"], cue: "Quanti anni hai?", cueEnglish: "How old are you?"),
                PathPhrase(id: "it-you-from", english: "I'm from America", line: "Vengo dall'America", mustHear: ["vengo"], cue: "Di dove sei?", cueEnglish: "Where are you from?"),
                PathPhrase(id: "it-you-meet", english: "Nice to meet you", line: "Piacere", mustHear: ["piacere"], cue: "Mi chiamo Giulia.", cueEnglish: "She told you her name.")
            ],
            beats: [
                PathBeat(id: "it-you-q1", ask: "Come ti chiami?", askEnglish: "What's your name?", accept: ["chiamo"], coach: "Mi chiamo…"),
                PathBeat(id: "it-you-q2", ask: "Quanti anni hai?", askEnglish: "How old are you?", accept: ["anni"], coach: "Ho venti anni"),
                PathBeat(id: "it-you-q3", ask: "Di dove sei?", askEnglish: "Where are you from?", accept: ["vengo"], coach: "Vengo dall'America")
            ]
        ),
        PathTopic(
            id: "it-feel",
            title: "How are you",
            emoji: "💬",
            tense: "They ask how you are",
            tensePlain: "Sto bene. Sono stanco. Sono nervoso. E tu?",
            phrases: [
                PathPhrase(id: "it-feel-ok", english: "I'm well", line: "Sto bene", mustHear: ["sto", "bene"], cue: "Come stai?", cueEnglish: "How are you?"),
                PathPhrase(id: "it-feel-tired", english: "I'm tired", line: "Sono stanco", mustHear: ["sono", "stanc"], cue: "Sei stanco?", cueEnglish: "Are you tired?"),
                PathPhrase(id: "it-feel-nervous", english: "I'm nervous", line: "Sono nervoso", mustHear: ["sono", "nervos"], cue: "Sei nervoso?", cueEnglish: "Are you nervous?"),
                PathPhrase(id: "it-feel-you", english: "And you?", line: "E tu?", mustHear: ["tu"], cue: "Sto bene.", cueEnglish: "She said she's well.")
            ],
            beats: [
                PathBeat(id: "it-feel-q1", ask: "Come stai?", askEnglish: "How are you?", accept: ["sto", "bene"], coach: "Sto bene"),
                PathBeat(id: "it-feel-q2", ask: "Sei stanco?", askEnglish: "Are you tired?", accept: ["stanc", "bene"], coach: "Sono stanco, or Sto bene"),
                PathBeat(id: "it-feel-q3", ask: "Sei nervoso?", askEnglish: "Are you nervous?", accept: ["nervos", "bene"], coach: "Sono nervoso, or No, sto bene")
            ]
        ),
        PathTopic(
            id: "it-weather",
            title: "Weather",
            emoji: "🌤",
            tense: "They ask about the weather",
            tensePlain: "C'è il sole. Fa freddo. Fa caldo. Sta piovendo.",
            phrases: [
                PathPhrase(id: "it-wx-sun", english: "It's sunny", line: "C'è il sole", mustHear: ["sole"], cue: "Che tempo fa?", cueEnglish: "What's the weather like?"),
                PathPhrase(id: "it-wx-cold", english: "It's cold", line: "Fa freddo", mustHear: ["freddo"], cue: "Fa freddo?", cueEnglish: "Is it cold?"),
                PathPhrase(id: "it-wx-hot", english: "It's hot", line: "Fa caldo", mustHear: ["caldo"], cue: "Fa caldo?", cueEnglish: "Is it hot?"),
                PathPhrase(id: "it-wx-rain", english: "It's raining", line: "Sta piovendo", mustHear: ["piovendo"], cue: "Sta piovendo?", cueEnglish: "Is it raining?")
            ],
            beats: [
                PathBeat(id: "it-wx-q1", ask: "Che tempo fa?", askEnglish: "What's the weather like?", accept: ["sole", "freddo", "caldo", "piovendo"], coach: "C'è il sole, or Fa freddo"),
                PathBeat(id: "it-wx-q2", ask: "Fa freddo o caldo?", askEnglish: "Is it cold or hot?", accept: ["freddo", "caldo"], coach: "Fa freddo"),
                PathBeat(id: "it-wx-q3", ask: "Sta piovendo?", askEnglish: "Is it raining?", accept: ["piovendo", "sole"], coach: "Sì, sta piovendo, or No, c'è il sole")
            ]
        ),
        PathTopic(
            id: "it-work",
            title: "Work and study",
            emoji: "💼",
            tense: "They ask what you do",
            tensePlain: "Lavoro. Studio. Lavoro e studio. Che cosa fai?",
            phrases: [
                PathPhrase(id: "it-work-work", english: "I work", line: "Lavoro", mustHear: ["lavoro"], cue: "Che cosa fai?", cueEnglish: "What do you do?"),
                PathPhrase(id: "it-work-study", english: "I study", line: "Studio", mustHear: ["studio"], cue: "Studi?", cueEnglish: "Do you study?"),
                PathPhrase(id: "it-work-both", english: "I work and I study", line: "Lavoro e studio", mustHear: ["lavoro", "studio"], cue: "Studi o lavori?", cueEnglish: "Do you study or work?"),
                PathPhrase(id: "it-work-what", english: "What do you do?", line: "Che cosa fai?", mustHear: ["cosa", "fai"], cueEnglish: "Ask what they do.")
            ],
            beats: [
                PathBeat(id: "it-work-q1", ask: "Che cosa fai?", askEnglish: "What do you do?", accept: ["lavoro", "studio"], coach: "Lavoro, or Studio"),
                PathBeat(id: "it-work-q2", ask: "Studi o lavori?", askEnglish: "Do you study or work?", accept: ["studio", "lavoro"], coach: "Lavoro e studio"),
                PathBeat(id: "it-work-q3", ask: "Dove lavori?", askEnglish: "Where do you work?", accept: ["lavoro"], coach: "Lavoro a…")
            ]
        )
    ]
}

enum TagalogPath {
    static let topics: [PathTopic] = [
        PathTopic(
            id: "fil-you",
            title: "Introducing yourself",
            emoji: "👋",
            tense: "They ask who you are",
            tensePlain: "Ako si… Bente anyos ako. Taga-Amerika ako. Masaya akong makilala ka.",
            phrases: [
                PathPhrase(id: "fil-you-name", english: "My name is…", line: "Ako si…", mustHear: ["ako", "si"], tip: "Then your name.", cue: "Ano ang pangalan mo?", cueEnglish: "What's your name?"),
                PathPhrase(id: "fil-you-age", english: "I'm twenty years old", line: "Bente anyos ako", mustHear: ["bente", "anyos"], cue: "Ilang taon ka na?", cueEnglish: "How old are you?"),
                PathPhrase(id: "fil-you-from", english: "I'm from America", line: "Taga-Amerika ako", mustHear: ["taga"], cue: "Taga-saan ka?", cueEnglish: "Where are you from?"),
                PathPhrase(id: "fil-you-meet", english: "Nice to meet you", line: "Masaya akong makilala ka", mustHear: ["masaya", "makilala"], cue: "Ako si Maria.", cueEnglish: "She told you her name.")
            ],
            beats: [
                PathBeat(id: "fil-you-q1", ask: "Ano ang pangalan mo?", askEnglish: "What's your name?", accept: ["si"], coach: "Ako si…"),
                PathBeat(id: "fil-you-q2", ask: "Ilang taon ka na?", askEnglish: "How old are you?", accept: ["anyos"], coach: "Bente anyos ako"),
                PathBeat(id: "fil-you-q3", ask: "Taga-saan ka?", askEnglish: "Where are you from?", accept: ["taga"], coach: "Taga-Amerika ako")
            ]
        ),
        PathTopic(
            id: "fil-feel",
            title: "How are you",
            emoji: "💬",
            tense: "They ask how you are",
            tensePlain: "Ayos lang ako. Pagod ako. Kinakabahan ako. Ikaw?",
            phrases: [
                PathPhrase(id: "fil-feel-ok", english: "I'm okay", line: "Ayos lang ako", mustHear: ["ayos"], cue: "Kumusta ka?", cueEnglish: "How are you?"),
                PathPhrase(id: "fil-feel-tired", english: "I'm tired", line: "Pagod ako", mustHear: ["pagod"], cue: "Pagod ka ba?", cueEnglish: "Are you tired?"),
                PathPhrase(id: "fil-feel-nervous", english: "I'm nervous", line: "Kinakabahan ako", mustHear: ["kinakabahan"], cue: "Kinakabahan ka ba?", cueEnglish: "Are you nervous?"),
                PathPhrase(id: "fil-feel-you", english: "And you?", line: "Ikaw?", mustHear: ["ikaw"], cue: "Ayos lang ako.", cueEnglish: "She said she's okay.")
            ],
            beats: [
                PathBeat(id: "fil-feel-q1", ask: "Kumusta ka?", askEnglish: "How are you?", accept: ["ayos", "pagod", "kinakabahan"], coach: "Ayos lang ako"),
                PathBeat(id: "fil-feel-q2", ask: "Pagod ka ba?", askEnglish: "Are you tired?", accept: ["pagod", "ayos"], coach: "Pagod ako, or Ayos lang ako"),
                PathBeat(id: "fil-feel-q3", ask: "Kinakabahan ka ba?", askEnglish: "Are you nervous?", accept: ["kinakabahan", "ayos"], coach: "Kinakabahan ako")
            ]
        ),
        PathTopic(
            id: "fil-weather",
            title: "Weather",
            emoji: "🌤",
            tense: "They ask about the weather",
            tensePlain: "Maaraw ngayon. Malamig. Mainit. Umuulan.",
            phrases: [
                PathPhrase(id: "fil-wx-sun", english: "It's sunny", line: "Maaraw ngayon", mustHear: ["maaraw"], cue: "Kumusta ang panahon?", cueEnglish: "How's the weather?"),
                PathPhrase(id: "fil-wx-cold", english: "It's cold", line: "Malamig", mustHear: ["malamig"], cue: "Malamig ba?", cueEnglish: "Is it cold?"),
                PathPhrase(id: "fil-wx-hot", english: "It's hot", line: "Mainit", mustHear: ["mainit"], cue: "Mainit ba?", cueEnglish: "Is it hot?"),
                PathPhrase(id: "fil-wx-rain", english: "It's raining", line: "Umuulan", mustHear: ["umuulan"], cue: "Umuulan ba?", cueEnglish: "Is it raining?")
            ],
            beats: [
                PathBeat(id: "fil-wx-q1", ask: "Kumusta ang panahon?", askEnglish: "How's the weather?", accept: ["maaraw", "malamig", "mainit", "umuulan"], coach: "Maaraw ngayon, or Umuulan"),
                PathBeat(id: "fil-wx-q2", ask: "Malamig ba o mainit?", askEnglish: "Is it cold or hot?", accept: ["malamig", "mainit"], coach: "Malamig"),
                PathBeat(id: "fil-wx-q3", ask: "Umuulan ba?", askEnglish: "Is it raining?", accept: ["umuulan", "maaraw"], coach: "Oo, umuulan, or Hindi, maaraw")
            ]
        ),
        PathTopic(
            id: "fil-work",
            title: "Work and study",
            emoji: "💼",
            tense: "They ask what you do",
            tensePlain: "Nagtatrabaho ako. Nag-aaral ako. Nagtatrabaho at nag-aaral ako. Ano ang trabaho mo?",
            phrases: [
                PathPhrase(id: "fil-work-work", english: "I work", line: "Nagtatrabaho ako", mustHear: ["nagtatrabaho"], cue: "Ano ang trabaho mo?", cueEnglish: "What's your job?"),
                PathPhrase(id: "fil-work-study", english: "I study", line: "Nag-aaral ako", mustHear: ["aaral"], cue: "Nag-aaral ka ba?", cueEnglish: "Do you study?"),
                PathPhrase(id: "fil-work-both", english: "I work and I study", line: "Nagtatrabaho at nag-aaral ako", mustHear: ["nagtatrabaho", "aaral"], cue: "Nagtatrabaho ka ba o nag-aaral?", cueEnglish: "Do you work or study?"),
                PathPhrase(id: "fil-work-what", english: "What's your job?", line: "Ano ang trabaho mo?", mustHear: ["trabaho"], cueEnglish: "Ask what their job is.")
            ],
            beats: [
                PathBeat(id: "fil-work-q1", ask: "Ano ang trabaho mo?", askEnglish: "What's your job?", accept: ["nagtatrabaho", "aaral"], coach: "Nagtatrabaho ako, or Nag-aaral ako"),
                PathBeat(id: "fil-work-q2", ask: "Nagtatrabaho ka ba o nag-aaral?", askEnglish: "Do you work or study?", accept: ["nagtatrabaho", "aaral"], coach: "Nagtatrabaho at nag-aaral ako"),
                PathBeat(id: "fil-work-q3", ask: "Saan ka nagtatrabaho?", askEnglish: "Where do you work?", accept: ["nagtatrabaho"], coach: "Nagtatrabaho ako sa…")
            ]
        )
    ]
}
