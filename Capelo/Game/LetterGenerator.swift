import Foundation

struct LetterGenerator {
    let vowels: Set<Character>
    private let pool: [Character]
    private let vowelPool: [Character]
    private let consonantPool: [Character]
    private let maxPerLetter: [Character: Int]

    init(language: GameLanguage = .english) {
        self.vowels = language.vowels
        let dist = language.distribution
        var all: [Character] = []
        var vp: [Character] = []
        var cp: [Character] = []
        var maxes: [Character: Int] = [:]
        for (char, weight) in dist {
            all.append(contentsOf: Array(repeating: char, count: weight))
            if language.vowels.contains(char) {
                vp.append(contentsOf: Array(repeating: char, count: weight))
            } else {
                cp.append(contentsOf: Array(repeating: char, count: weight))
            }
            maxes[char] = weight >= 6 ? 4 : (weight >= 3 ? 3 : 2)
        }
        self.pool = all
        self.vowelPool = vp
        self.consonantPool = cp
        self.maxPerLetter = maxes
    }

    func random(currentVowelCount: Int, currentTotal: Int, letterCounts: [Character: Int] = [:]) -> Character {
        let source: [Character]
        if currentTotal > 0 {
            let ratio = Double(currentVowelCount) / Double(currentTotal)
            if ratio < 0.35 { source = vowelPool }
            else if ratio > 0.50 { source = consonantPool }
            else { source = pool }
        } else {
            source = pool
        }

        for _ in 0..<20 {
            let char = source.randomElement()!
            let count = letterCounts[char] ?? 0
            if count < maxPerLetter[char, default: 2] { return char }
        }
        return source.randomElement()!
    }
}
