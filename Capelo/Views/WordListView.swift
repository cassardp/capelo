import SwiftUI
import UIKit

struct WordListView: View {
    let words: [String]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.gameLanguage) private var language
    @State private var showList = false
    @State private var selectedWord: String?

    private var textColor: Color { Palette.text(for: colorScheme) }
    private var bgColor: Color { Palette.background(for: colorScheme) }

    private var uniqueWords: [String] {
        var seen = Set<String>()
        return words.filter { seen.insert($0).inserted }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("\(uniqueWords.count) \(Strings.get(uniqueWords.count == 1 ? "word" : "words", language: language))")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(textColor)
                    .padding(.top, 32)
                    .padding(.bottom, 4)
                    .offset(y: showList ? 0 : 12)
                    .opacity(showList ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.05), value: showList)

                Text(Strings.get("tapDefinition", language: language))
                    .font(.footnote)
                    .foregroundStyle(textColor.opacity(0.3))
                    .padding(.bottom, 20)
                    .offset(y: showList ? 0 : 12)
                    .opacity(showList ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.08), value: showList)

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
        .background(bgColor.ignoresSafeArea())
        .fontDesign(.rounded)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .sheet(item: $selectedWord) { word in
            DefinitionView(word: word)
        }
        .task {
            withAnimation(.easeOut(duration: 0.5)) {
                showList = true
            }
        }
    }

    private func wordRow(rank: Int, word: String) -> some View {
        let hasDef = UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: word.lowercased())
        return Button {
            selectedWord = word
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

                Image(systemName: "questionmark")
                    .font(.system(size: 13))
                    .foregroundStyle(textColor.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(textColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
    }
}

struct DefinitionView: View {
    let word: String
    @State private var definition: String?
    @State private var isLoading = true
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.gameLanguage) private var language

    private var textColor: Color { Palette.text(for: colorScheme) }
    private var bgColor: Color { Palette.background(for: colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            Text(word.uppercased())
                .font(.title2.weight(.bold))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .padding(.top, 28)
                .padding(.bottom, 20)

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if let definition {
                ScrollView {
                    Text(definition)
                        .font(.body)
                        .foregroundStyle(textColor.opacity(0.8))
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            } else {
                Spacer()
                Text(Strings.get("noDefinition", language: language))
                    .font(.body)
                    .foregroundStyle(textColor.opacity(0.4))
                Spacer()
            }
        }
        .background(bgColor.ignoresSafeArea())
        .fontDesign(.rounded)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            definition = await Wiktionary.fetchDefinition(word: word, language: language)
            isLoading = false
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
