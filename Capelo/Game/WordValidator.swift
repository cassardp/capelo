import Foundation

struct WordValidator {
    private let words: Set<String>

    init(language: GameLanguage = .english) {
        let resource = language.dictionaryResource
        guard let url = Bundle.main.url(forResource: resource, withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            fatalError("Missing \(resource).txt")
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
