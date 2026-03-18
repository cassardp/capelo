import SwiftUI

enum GameLanguage: String, CaseIterable, Codable {
    case english, french, spanish, portuguese

    var displayName: String {
        switch self {
        case .english: "English"
        case .french: "Français"
        case .spanish: "Español"
        case .portuguese: "Português"
        }
    }

    var shortCode: String {
        switch self {
        case .english: "EN"
        case .french: "FR"
        case .spanish: "ES"
        case .portuguese: "PT"
        }
    }

    var wikiCode: String {
        switch self {
        case .english: "en"
        case .french: "fr"
        case .spanish: "es"
        case .portuguese: "pt"
        }
    }

    var flag: String {
        switch self {
        case .english: "🇬🇧"
        case .french: "🇫🇷"
        case .spanish: "🇪🇸"
        case .portuguese: "🇧🇷"
        }
    }

    var dictionaryResource: String {
        switch self {
        case .english: "english_words"
        case .french: "french_words"
        case .spanish: "spanish_words"
        case .portuguese: "portuguese_words"
        }
    }

    var distribution: [(Character, Int)] {
        switch self {
        case .french:
            [("E",15),("A",9),("I",8),("S",8),("N",7),("R",7),("T",7),("O",6),("L",6),("U",6),("D",4),("C",3),("M",3),("P",3),("G",2),("B",2),("F",2),("H",2),("V",2),("J",1),("Q",1),("K",1),("W",1),("X",1),("Y",1),("Z",1)]
        case .english:
            [("E",12),("A",9),("I",9),("O",8),("N",6),("R",6),("T",6),("L",4),("S",4),("U",4),("D",4),("G",3),("B",2),("C",2),("M",2),("P",2),("F",2),("H",2),("V",2),("W",2),("Y",2),("K",1),("J",1),("X",1),("Q",1),("Z",1)]
        case .spanish:
            [("A",12),("E",12),("O",9),("S",6),("I",6),("N",5),("R",5),("U",5),("L",4),("T",4),("D",5),("C",4),("G",2),("B",2),("M",2),("P",2),("H",2),("F",1),("V",1),("Y",1),("Q",1),("J",1),("X",1),("Z",1)]
        case .portuguese:
            [("A",14),("E",11),("I",10),("O",10),("S",8),("U",7),("M",6),("R",6),("T",5),("D",5),("L",5),("C",4),("P",4),("N",4),("B",3),("F",2),("G",2),("H",2),("V",2),("J",2),("Q",1),("X",1),("Z",1)]
        }
    }

    var vowels: Set<Character> { ["A", "E", "I", "O", "U"] }

    static func detect() -> GameLanguage {
        guard let code = Locale.current.language.languageCode?.identifier else { return .english }
        switch code {
        case "fr": return .french
        case "es": return .spanish
        case "pt": return .portuguese
        default: return .english
        }
    }
}

private struct GameLanguageKey: EnvironmentKey {
    static let defaultValue: GameLanguage = .english
}

extension EnvironmentValues {
    var gameLanguage: GameLanguage {
        get { self[GameLanguageKey.self] }
        set { self[GameLanguageKey.self] = newValue }
    }
}
