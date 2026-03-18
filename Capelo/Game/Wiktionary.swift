import Foundation

enum Wiktionary {
    static func fetchDefinition(word: String, language: GameLanguage) async -> [String]? {
        let lower = word.lowercased()

        if let result = await fetchPage(word: lower, language: language) {
            return result
        }

        guard let variants = await searchVariants(word: lower, language: language) else { return nil }
        for variant in variants {
            if let result = await fetchPage(word: variant, language: language) {
                return result
            }
        }
        return nil
    }

    private static func searchVariants(word: String, language: GameLanguage) async -> [String]? {
        let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? word
        let urlString = "https://fr.wiktionary.org/w/api.php?action=query&list=search&srsearch=\(encoded)&srnamespace=0&srlimit=5&format=json&formatversion=2"

        guard let url = URL(string: urlString) else { return nil }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let query = json["query"] as? [String: Any],
              let results = query["search"] as? [[String: Any]] else { return nil }

        return results.compactMap { $0["title"] as? String }
            .filter { $0.lowercased() != word }
    }

    private static func fetchPage(word: String, language: GameLanguage) async -> [String]? {
        let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? word
        let urlString = "https://fr.wiktionary.org/w/api.php?action=parse&page=\(encoded)&prop=wikitext&format=json&formatversion=2"

        guard let url = URL(string: urlString) else { return nil }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let parse = json["parse"] as? [String: Any],
              let wikitext = parse["wikitext"] as? String else { return nil }

        return extractDefinitions(from: wikitext, language: language)
    }

    private static func extractDefinitions(from wikitext: String, language: GameLanguage) -> [String]? {
        let lines = wikitext.components(separatedBy: "\n")
        var inTargetLang = false
        var definitions: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.contains("{{langue|") {
                if trimmed.contains("{{langue|\(language.wikiCode)}}") {
                    inTargetLang = true
                } else if inTargetLang {
                    break
                }
                continue
            }

            guard inTargetLang else { continue }

            if trimmed.hasPrefix("#") && !trimmed.hasPrefix("#*") && !trimmed.hasPrefix("#:") && !trimmed.hasPrefix("##") {
                let raw = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                let cleaned = cleanWikiMarkup(raw)
                if !cleaned.isEmpty {
                    definitions.append(cleaned)
                }
                if definitions.count >= 6 { break }
            }
        }

        guard !definitions.isEmpty else { return nil }
        return definitions
    }

    private static func cleanWikiMarkup(_ text: String) -> String {
        var s = text
        let pipeLink = try? NSRegularExpression(pattern: "\\[\\[[^\\]]*?\\|([^\\]]*)\\]\\]")
        s = pipeLink?.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "$1") ?? s
        s = s.replacingOccurrences(of: "[[", with: "").replacingOccurrences(of: "]]", with: "")
        var depth = 0
        var result = ""
        var i = s.startIndex
        while i < s.endIndex {
            let next = s.index(after: i)
            if next < s.endIndex && s[i] == "{" && s[next] == "{" {
                depth += 1
                i = s.index(after: next)
                continue
            }
            if next < s.endIndex && s[i] == "}" && s[next] == "}" {
                depth = max(0, depth - 1)
                i = s.index(after: next)
                continue
            }
            if depth == 0 {
                result.append(s[i])
            }
            i = s.index(after: i)
        }
        s = result
        s = s.replacingOccurrences(of: "'''", with: "").replacingOccurrences(of: "''", with: "")
        s = s.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return s
    }
}
