import Foundation

enum Wiktionary {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    private static func fetch(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("Capelo/1.0 (iOS word game)", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await session.data(for: request)
        return data
    }

    static func fetchDefinition(word: String, language: GameLanguage) async -> String? {
        let lower = word.lowercased()

        for attempt in 0..<2 {
            if attempt > 0 {
                try? await Task.sleep(for: .milliseconds(300))
            }
            if Task.isCancelled { return nil }

            if let result = await fetchPage(word: lower, language: language) {
                return result
            }
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

        guard let data = try? await fetch(url: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let query = json["query"] as? [String: Any],
              let results = query["search"] as? [[String: Any]] else { return nil }

        return results.compactMap { $0["title"] as? String }
            .filter { $0.lowercased() != word }
    }

    private static func fetchPage(word: String, language: GameLanguage) async -> String? {
        let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? word
        let urlString = "https://fr.wiktionary.org/w/api.php?action=parse&page=\(encoded)&prop=wikitext&format=json&formatversion=2"

        guard let url = URL(string: urlString) else { return nil }

        do {
            let data = try await fetch(url: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

            if json["error"] != nil { return nil }

            guard let parse = json["parse"] as? [String: Any],
                  let wikitext = parse["wikitext"] as? String else { return nil }

            return extractDefinitions(from: wikitext, language: language)
        } catch is CancellationError {
            return nil
        } catch {
            return nil
        }
    }

    private static func extractDefinitions(from wikitext: String, language: GameLanguage) -> String? {
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
        return definitions.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n\n")
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
