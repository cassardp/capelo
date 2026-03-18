import SwiftUI
import UIKit

struct WordListView: View {
    let words: [String]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.gameLanguage) private var language
    @State private var showList = false
    @State private var expandedWord: String?
    @State private var definitions: [String: [String]?] = [:]

    private var textColor: Color { Palette.text(for: colorScheme) }
    private var bgColor: Color { Palette.background(for: colorScheme) }

    private var uniqueWords: [String] {
        var seen = Set<String>()
        return words.filter { seen.insert($0).inserted }
    }

    var body: some View {
        Group {
            if uniqueWords.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "book")
                        .font(.system(size: 48))
                        .foregroundStyle(textColor.opacity(0.2))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        Text("\(uniqueWords.count) \(Strings.get(uniqueWords.count == 1 ? "word" : "words", language: language))")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundStyle(textColor)
                            .padding(.top, 32)
                            .padding(.bottom, 20)
                            .offset(y: showList ? 0 : 12)
                            .opacity(showList ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.05), value: showList)

                        ForEach(Array(uniqueWords.enumerated()), id: \.offset) { offset, word in
                            wordRow(rank: offset + 1, word: word)
                                .offset(y: showList ? 0 : 12)
                                .opacity(showList ? 1 : 0)
                                .animation(.easeOut(duration: 0.4).delay(0.1 + Double(offset) * 0.05), value: showList)
                        }
                    }
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
        }
        .background(bgColor.ignoresSafeArea())
        .fontDesign(.rounded)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .task {
            withAnimation(.easeOut(duration: 0.5)) {
                showList = true
            }
            let lang = language
            let wordsToFetch = uniqueWords
            await withTaskGroup(of: (String, [String]?).self) { group in
                for word in wordsToFetch {
                    group.addTask {
                        let def = await Wiktionary.fetchDefinition(word: word, language: lang)
                        return (word, def)
                    }
                }
                for await (word, def) in group {
                    definitions[word] = def
                }
            }
        }
    }

    private func wordRow(rank: Int, word: String) -> some View {
        let isExpanded = expandedWord == word
        let hasDef = definitions.keys.contains(word)
        let definition: [String]? = definitions[word] ?? nil

        return VStack(spacing: 8) {
            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    expandedWord = isExpanded ? nil : word
                }
            } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(hasDef ? Palette.olive : textColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text("\(rank)")
                                .font(.system(size: 16, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(hasDef ? Palette.cream : textColor.opacity(0.5))
                        )

                    Text(word)
                        .font(.body.weight(.medium))
                        .foregroundStyle(textColor)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(textColor.opacity(0.4))
                        .contentTransition(.symbolEffect(.replace))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(textColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }

            if isExpanded {
                Group {
                    if let defs = definition, !defs.isEmpty {
                        Text(defs.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "  ·  "))
                            .font(.body)
                            .foregroundStyle(textColor.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(Strings.get("noDefinition", language: language))
                            .font(.body)
                            .foregroundStyle(textColor.opacity(0.3))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(textColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
