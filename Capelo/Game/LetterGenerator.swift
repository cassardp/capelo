import Foundation

struct LetterGenerator {
    let vowels: Set<Character>
    let targetVowelRatio: Double
    private let fullPool: [Character]
    private let vowelPool: [Character]
    private let consonantPool: [Character]

    init(language: GameLanguage = .english) {
        self.vowels = language.vowels
        self.targetVowelRatio = language.targetVowelRatio
        let dist = language.distribution
        self.fullPool = Self.buildPool(from: dist)
        self.vowelPool = Self.buildPool(from: dist.filter { language.vowels.contains($0.0) })
        self.consonantPool = Self.buildPool(from: dist.filter { !language.vowels.contains($0.0) })
    }

    private static func buildPool(from dist: [(Character, Int)]) -> [Character] {
        var chars: [Character] = []
        for (char, weight) in dist {
            chars.append(contentsOf: Array(repeating: char, count: weight))
        }
        return chars
    }

    func random() -> Character {
        fullPool.randomElement()!
    }

    func random(currentVowelCount: Int, currentTotal: Int) -> Character {
        guard currentTotal > 0 else { return fullPool.randomElement()! }
        let ratio = Double(currentVowelCount) / Double(currentTotal)
        if ratio < targetVowelRatio - 0.08 {
            return vowelPool.randomElement()!
        } else if ratio > targetVowelRatio + 0.12 {
            return consonantPool.randomElement()!
        }
        return fullPool.randomElement()!
    }
}
