import Foundation

struct WordValidator {
    private let words: Set<String>

    init() {
        guard let url = Bundle.main.url(forResource: "french_words", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            fatalError("Missing french_words.txt")
        }
        words = Set(
            content.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        )
    }

    func isValid(_ word: String) -> Bool {
        words.contains(word.uppercased())
    }
}
