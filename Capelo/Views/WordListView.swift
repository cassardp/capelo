import SwiftUI

struct WordListView: View {
    let words: [String]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.gameLanguage) private var language
    @Environment(PaletteStore.self) private var palette
    @State private var showList = false
    @State private var lookupWord: String?
    @State private var definitions: [String: [String]?] = [:]
    @State private var loadingWord: String?

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
                VStack(spacing: 0) {
                    VStack(spacing: 6) {
                        Text("\(uniqueWords.count) \(Strings.get(uniqueWords.count == 1 ? "word" : "words", language: language))")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundStyle(textColor)

                        Text(Strings.get("tapToDefine", language: language))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(textColor.opacity(0.35))
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 20)
                    .offset(y: showList ? 0 : 12)
                    .opacity(showList ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.05), value: showList)

                    ScrollView {
                        VStack(spacing: 0) {
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
        }
        .background(bgColor.ignoresSafeArea())
        .fontDesign(.rounded)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .task {
            withAnimation(.easeOut(duration: 0.5)) {
                showList = true
            }
        }
        .overlay {
            if let word = lookupWord {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { lookupWord = nil } }
                definitionPopup(word: word)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: lookupWord)
    }

    private func lookupDefinition(word: String) {
        lookupWord = word
        if !definitions.keys.contains(word) {
            loadingWord = word
            let lang = language
            Task {
                let def = await Wiktionary.fetchDefinition(word: word, language: lang)
                definitions[word] = def
                loadingWord = nil
            }
        }
    }

    private func wordRow(rank: Int, word: String) -> some View {
        Button { lookupDefinition(word: word) } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(palette.olive)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("\(rank)")
                            .font(.system(size: 16, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(Palette.cream)
                    )

                Text(word)
                    .font(.body.weight(.medium))
                    .foregroundStyle(textColor)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "book")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(textColor.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(textColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
    }

    private func definitionPopup(word: String) -> some View {
        let definition: [String]? = definitions[word] ?? nil
        let isLoading = loadingWord == word

        return VStack(spacing: 16) {
            Text(word)
                .font(.title2.bold())
                .foregroundStyle(textColor)

            if isLoading {
                ProgressView()
                    .padding(.vertical, 8)
            } else if let defs = definition, !defs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(defs.enumerated()), id: \.offset) { i, def in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(i + 1).")
                                .font(.subheadline.bold())
                                .foregroundStyle(textColor.opacity(0.5))
                            Text(def)
                                .font(.subheadline)
                                .foregroundStyle(textColor.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            } else {
                Text(Strings.get("noDefinition", language: language))
                    .font(.subheadline)
                    .foregroundStyle(textColor.opacity(0.3))
                    .padding(.vertical, 8)
            }

            Button {
                withAnimation { lookupWord = nil }
            } label: {
                Text("OK")
                    .font(.body.bold())
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(textColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(24)
        .background(bgColor, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 20)
        .padding(.horizontal, 40)
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
