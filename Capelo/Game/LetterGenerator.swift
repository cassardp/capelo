import Foundation

struct LetterGenerator {
    private let pool: [Character]

    init(language: GameLanguage = .english) {
        var all: [Character] = []
        for (char, weight) in language.distribution {
            all.append(contentsOf: Array(repeating: char, count: weight))
        }
        self.pool = all
    }

    func random() -> Character {
        pool.randomElement()!
    }
}
