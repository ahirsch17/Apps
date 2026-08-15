import Foundation

struct WordCard: Identifiable, Equatable, Hashable {
    let id: String
    let language: Language
    let english: String
    let target: String
    let example: String
    let category: WordCategory
}

enum WordCategory: String, CaseIterable, Identifiable {
    case essentials, connectors, verbs, food, travel, people, time, feelings

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .essentials: return "Essentials"
        case .connectors: return "Connectors"
        case .verbs: return "Verbs"
        case .food: return "Food"
        case .travel: return "Travel"
        case .people: return "People"
        case .time: return "Time"
        case .feelings: return "Feelings"
        }
    }

    var icon: String {
        switch self {
        case .essentials: return "star.fill"
        case .connectors: return "link"
        case .verbs: return "bolt.fill"
        case .food: return "fork.knife"
        case .travel: return "airplane"
        case .people: return "person.2.fill"
        case .time: return "clock.fill"
        case .feelings: return "heart.fill"
        }
    }
}

enum WordBank {
    static func words(for language: Language, category: WordCategory? = nil) -> [WordCard] {
        all.filter { $0.language == language && (category == nil || $0.category == category) }
    }

    static let all: [WordCard] = spanish + german + italian + tagalog

    private static func w(_ id: String, _ lang: Language, _ en: String, _ target: String, _ example: String, _ cat: WordCategory) -> WordCard {
        WordCard(id: id, language: lang, english: en, target: target, example: example, category: cat)
    }

    private static let spanish: [WordCard] = [
        w("es-e1", .spanish, "yes", "sí", "Sí, claro.", .essentials),
        w("es-e2", .spanish, "no", "no", "No, gracias.", .essentials),
        w("es-e3", .spanish, "please", "por favor", "Un café, por favor.", .essentials),
        w("es-e4", .spanish, "thank you", "gracias", "Muchas gracias.", .essentials),
        w("es-e5", .spanish, "sorry / excuse me", "perdón", "Perdón, ¿dónde está…?", .essentials),
        w("es-e6", .spanish, "I don't know", "no sé", "No sé cómo decirlo.", .essentials),
        w("es-e7", .spanish, "I don't understand", "no entiendo", "No entiendo. ¿Puedes repetir?", .essentials),
        w("es-e8", .spanish, "can you repeat?", "¿puedes repetir?", "¿Puedes repetir, por favor?", .essentials),
        w("es-e9", .spanish, "how do you say…?", "¿cómo se dice…?", "¿Cómo se dice 'meeting'?", .essentials),
        w("es-e10", .spanish, "of course", "claro", "Claro, sin problema.", .essentials),
        w("es-e11", .spanish, "give me a second", "dame un segundo", "Dame un segundo, por favor.", .essentials),
        w("es-c1", .spanish, "because", "porque", "Porque estaba cansada.", .connectors),
        w("es-c2", .spanish, "but", "pero", "Me gusta, pero es caro.", .connectors),
        w("es-c3", .spanish, "also / too", "también", "Yo también quiero ir.", .connectors),
        w("es-c4", .spanish, "so / then", "entonces", "Entonces, ¿qué hacemos?", .connectors),
        w("es-c5", .spanish, "however", "sin embargo", "Sin embargo, prefiero quedarme.", .connectors),
        w("es-c6", .spanish, "for example", "por ejemplo", "Por ejemplo, el lunes.", .connectors),
        w("es-c7", .spanish, "first… then…", "primero… después…", "Primero cocino, después como.", .connectors),
        w("es-c8", .spanish, "I think that…", "creo que…", "Creo que es una buena idea.", .connectors),
        w("es-c9", .spanish, "in my opinion", "en mi opinión", "En mi opinión, es mejor así.", .connectors),
        w("es-c10", .spanish, "on the other hand", "por otro lado", "Por otro lado, es más fácil.", .connectors),
        w("es-c11", .spanish, "what I meant is…", "lo que quise decir es…", "Lo que quise decir es que no puedo.", .connectors),
        w("es-v1", .spanish, "to want", "querer", "Quiero practicar más.", .verbs),
        w("es-v2", .spanish, "to need", "necesitar", "Necesito un momento.", .verbs),
        w("es-v3", .spanish, "to go", "ir", "Voy al trabajo.", .verbs),
        w("es-v4", .spanish, "to have", "tener", "Tengo dos hermanos.", .verbs),
        w("es-v5", .spanish, "to like", "gustar", "Me gusta cocinar.", .verbs),
        w("es-v6", .spanish, "to be able to", "poder", "¿Puedo preguntar algo?", .verbs),
        w("es-v7", .spanish, "to do / make", "hacer", "Hago ejercicio por la mañana.", .verbs),
        w("es-v8", .spanish, "to say", "decir", "Quiero decir…", .verbs),
        w("es-v9", .spanish, "to live", "vivir", "Vivo cerca del centro.", .verbs),
        w("es-v10", .spanish, "to work", "trabajar", "Trabajo desde casa.", .verbs),
        w("es-f1", .spanish, "water", "agua", "Una botella de agua, por favor.", .food),
        w("es-f2", .spanish, "coffee", "café", "Un café con leche.", .food),
        w("es-f3", .spanish, "breakfast", "desayuno", "El desayuno es a las ocho.", .food),
        w("es-f4", .spanish, "I'm hungry", "tengo hambre", "Tengo hambre.", .food),
        w("es-f5", .spanish, "the bill", "la cuenta", "La cuenta, por favor.", .food),
        w("es-f6", .spanish, "delicious", "delicioso", "Está delicioso.", .food),
        w("es-t1", .spanish, "where is…?", "¿dónde está…?", "¿Dónde está la estación?", .travel),
        w("es-t2", .spanish, "ticket", "boleto", "Necesito un boleto de ida.", .travel),
        w("es-t3", .spanish, "hotel", "hotel", "Estoy en el hotel.", .travel),
        w("es-t4", .spanish, "airport", "aeropuerto", "Vamos al aeropuerto.", .travel),
        w("es-t5", .spanish, "left / right", "izquierda / derecha", "A la derecha, luego a la izquierda.", .travel),
        w("es-p1", .spanish, "friend", "amigo/a", "Es mi mejor amigo.", .people),
        w("es-p2", .spanish, "family", "familia", "Mi familia vive lejos.", .people),
        w("es-p3", .spanish, "coworker", "compañero/a de trabajo", "Hablo con mis compañeros.", .people),
        w("es-p4", .spanish, "neighbor", "vecino/a", "Mi vecina es amable.", .people),
        w("es-tm1", .spanish, "today", "hoy", "Hoy practico español.", .time),
        w("es-tm2", .spanish, "yesterday", "ayer", "Ayer fui al mercado.", .time),
        w("es-tm3", .spanish, "tomorrow", "mañana", "Mañana tengo una reunión.", .time),
        w("es-tm4", .spanish, "now", "ahora", "Ahora no puedo.", .time),
        w("es-tm5", .spanish, "later", "más tarde", "Te llamo más tarde.", .time),
        w("es-tm6", .spanish, "usually", "normalmente", "Normalmente me levanto temprano.", .time),
        w("es-fe1", .spanish, "happy", "contento/a", "Estoy contenta hoy.", .feelings),
        w("es-fe2", .spanish, "tired", "cansado/a", "Estoy muy cansado.", .feelings),
        w("es-fe3", .spanish, "nervous", "nervioso/a", "Me pongo nerviosa al hablar.", .feelings),
        w("es-fe4", .spanish, "excited", "emocionado/a", "Estoy emocionada por el viaje.", .feelings),
        w("es-fe5", .spanish, "confused", "confundido/a", "Estoy un poco confundida.", .feelings),
    ]

    private static let german: [WordCard] = [
        w("de-e1", .german, "yes", "ja", "Ja, gerne.", .essentials),
        w("de-e2", .german, "no", "nein", "Nein, danke.", .essentials),
        w("de-e3", .german, "please", "bitte", "Einen Kaffee, bitte.", .essentials),
        w("de-e4", .german, "thank you", "danke", "Vielen Dank.", .essentials),
        w("de-e5", .german, "I don't know", "ich weiß nicht", "Ich weiß nicht.", .essentials),
        w("de-e6", .german, "I don't understand", "ich verstehe nicht", "Ich verstehe nicht.", .essentials),
        w("de-c1", .german, "because", "weil", "Weil ich müde war.", .connectors),
        w("de-c2", .german, "but", "aber", "Es ist gut, aber teuer.", .connectors),
        w("de-c3", .german, "also", "auch", "Ich möchte auch gehen.", .connectors),
        w("de-c4", .german, "I think that…", "ich denke, dass…", "Ich denke, dass es geht.", .connectors),
        w("de-v1", .german, "to want", "wollen", "Ich will üben.", .verbs),
        w("de-v2", .german, "to need", "brauchen", "Ich brauche Zeit.", .verbs),
        w("de-v3", .german, "to go", "gehen", "Ich gehe zur Arbeit.", .verbs),
        w("de-v4", .german, "to have", "haben", "Ich habe zwei Geschwister.", .verbs),
        w("de-f1", .german, "coffee", "Kaffee", "Einen Kaffee, bitte.", .food),
        w("de-t1", .german, "where is…?", "wo ist…?", "Wo ist der Bahnhof?", .travel),
        w("de-p1", .german, "friend", "Freund/in", "Das ist mein Freund.", .people),
        w("de-tm1", .german, "today", "heute", "Heute übe ich Deutsch.", .time),
        w("de-tm2", .german, "yesterday", "gestern", "Gestern war ich im Park.", .time),
        w("de-tm3", .german, "tomorrow", "morgen", "Morgen habe ich Zeit.", .time),
        w("de-fe1", .german, "tired", "müde", "Ich bin müde.", .feelings),
        w("de-fe2", .german, "nervous", "nervös", "Ich werde nervös beim Sprechen.", .feelings),
    ]

    private static let italian: [WordCard] = [
        w("it-e1", .italian, "yes", "sì", "Sì, certo.", .essentials),
        w("it-e2", .italian, "no", "no", "No, grazie.", .essentials),
        w("it-e3", .italian, "please", "per favore", "Un caffè, per favore.", .essentials),
        w("it-e4", .italian, "thank you", "grazie", "Grazie mille.", .essentials),
        w("it-e5", .italian, "I don't know", "non lo so", "Non lo so.", .essentials),
        w("it-e6", .italian, "I don't understand", "non capisco", "Non capisco. Puoi ripetere?", .essentials),
        w("it-c1", .italian, "because", "perché", "Perché ero stanca.", .connectors),
        w("it-c2", .italian, "but", "ma", "Mi piace, ma è caro.", .connectors),
        w("it-c3", .italian, "also", "anche", "Voglio andare anche io.", .connectors),
        w("it-c4", .italian, "I think that…", "penso che…", "Penso che sia una buona idea.", .connectors),
        w("it-v1", .italian, "to want", "volere", "Voglio praticare di più.", .verbs),
        w("it-v2", .italian, "to go", "andare", "Vado al lavoro.", .verbs),
        w("it-v3", .italian, "to have", "avere", "Ho due fratelli.", .verbs),
        w("it-f1", .italian, "coffee", "caffè", "Un caffè, per favore.", .food),
        w("it-t1", .italian, "where is…?", "dov’è…?", "Dov’è la stazione?", .travel),
        w("it-p1", .italian, "friend", "amico/a", "È il mio migliore amico.", .people),
        w("it-tm1", .italian, "today", "oggi", "Oggi pratico italiano.", .time),
        w("it-tm2", .italian, "yesterday", "ieri", "Ieri sono andata al mercato.", .time),
        w("it-tm3", .italian, "tomorrow", "domani", "Domani ho tempo.", .time),
        w("it-fe1", .italian, "tired", "stanco/a", "Sono stanca.", .feelings),
        w("it-fe2", .italian, "nervous", "nervoso/a", "Divento nervosa quando parlo.", .feelings),
    ]

    private static let tagalog: [WordCard] = [
        w("fil-e1", .tagalog, "yes", "oo", "Oo, sige.", .essentials),
        w("fil-e2", .tagalog, "no", "hindi", "Hindi, salamat.", .essentials),
        w("fil-e3", .tagalog, "please", "pakiusap", "Pakiusap, ulitin mo.", .essentials),
        w("fil-e4", .tagalog, "thank you", "salamat", "Maraming salamat.", .essentials),
        w("fil-e5", .tagalog, "I don't know", "hindi ko alam", "Hindi ko alam.", .essentials),
        w("fil-e6", .tagalog, "I don't understand", "hindi ko maintindihan", "Hindi ko maintindihan.", .essentials),
        w("fil-c1", .tagalog, "because", "kasi", "Kasi pagod ako.", .connectors),
        w("fil-c2", .tagalog, "but", "pero", "Gusto ko, pero mahal.", .connectors),
        w("fil-c3", .tagalog, "also", "din / rin", "Gusto ko rin.", .connectors),
        w("fil-c4", .tagalog, "I think that…", "sa tingin ko…", "Sa tingin ko, okay iyon.", .connectors),
        w("fil-v1", .tagalog, "to want", "gusto", "Gusto kong mag-practice.", .verbs),
        w("fil-v2", .tagalog, "to need", "kailangan", "Kailangan ko ng oras.", .verbs),
        w("fil-v3", .tagalog, "to go", "pumunta", "Pupunta ako sa trabaho.", .verbs),
        w("fil-f1", .tagalog, "water", "tubig", "Tubig, please.", .food),
        w("fil-t1", .tagalog, "where is…?", "nasaan ang…?", "Nasaan ang istasyon?", .travel),
        w("fil-p1", .tagalog, "friend", "kaibigan", "Kaibigan ko siya.", .people),
        w("fil-tm1", .tagalog, "today", "ngayon", "Ngayon mag-aaral ako.", .time),
        w("fil-tm2", .tagalog, "yesterday", "kahapon", "Kahapon pumunta ako sa palengke.", .time),
        w("fil-tm3", .tagalog, "tomorrow", "bukas", "Bukas may oras ako.", .time),
        w("fil-fe1", .tagalog, "tired", "pagod", "Pagod ako.", .feelings),
        w("fil-fe2", .tagalog, "nervous", "kinakabahan", "Kinakabahan ako kapag nagsasalita.", .feelings),
    ]
}
