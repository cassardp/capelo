import Foundation

struct LetterGenerator {
    static let vowels: Set<Character> = ["A", "E", "I", "O", "U"]
    static let targetVowelRatio: Double = 0.40

    static let distribution: [(Character, Int)] = [
        ("E", 15), ("A", 9), ("I", 8), ("S", 8), ("N", 7),
        ("R", 7), ("T", 7), ("O", 6), ("L", 6), ("U", 6),
        ("D", 4), ("C", 3), ("M", 3), ("P", 3), ("G", 2),
        ("B", 2), ("F", 2), ("H", 2), ("V", 2),
        ("J", 1), ("Q", 1), ("K", 1), ("W", 1),
        ("X", 1), ("Y", 1), ("Z", 1)
    ]

    private static let fullPool: [Character] = buildPool(from: distribution)
    private static let vowelPool: [Character] = buildPool(from: distribution.filter { vowels.contains($0.0) })
    private static let consonantPool: [Character] = buildPool(from: distribution.filter { !vowels.contains($0.0) })

    private static func buildPool(from dist: [(Character, Int)]) -> [Character] {
        var chars: [Character] = []
        for (char, weight) in dist {
            chars.append(contentsOf: Array(repeating: char, count: weight))
        }
        return chars
    }

    static func random() -> Character {
        fullPool.randomElement()!
    }

    static func random(currentVowelCount: Int, currentTotal: Int) -> Character {
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
