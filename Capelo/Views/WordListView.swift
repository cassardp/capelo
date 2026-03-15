import SwiftUI
import UIKit

struct DictionaryView: UIViewControllerRepresentable {
    let term: String

    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        UIReferenceLibraryViewController(term: term)
    }

    func updateUIViewController(_ uiViewController: UIReferenceLibraryViewController, context: Context) {}
}

struct WordListView: View {
    let words: [String]
    let score: Int
    let onRestart: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var showList = false
    @State private var selectedWord: String?

    private var textColor: Color { Palette.text(for: colorScheme) }
    private var bgColor: Color { Palette.background(for: colorScheme) }

    private var uniqueWords: [String] {
        var seen = Set<String>()
        return words.filter { seen.insert($0).inserted }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 32) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 22))
                        .foregroundStyle(textColor.opacity(0.4))
                }
                Spacer()
                Button { onRestart() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 22))
                        .foregroundStyle(textColor)
                }
            }
            .padding(.top, 28)
            .padding(.bottom, 26)
            .padding(.horizontal, 20)

            ScrollView {
                VStack(spacing: 0) {
                    Text(verbatim: "\(score)")
                        .font(.system(size: 44, weight: .heavy))
                        .foregroundStyle(textColor)
                        .padding(.top, 12)
                        .offset(y: showList ? 0 : 12)
                        .opacity(showList ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.05), value: showList)

                    Text("\(uniqueWords.count) mot\(uniqueWords.count > 1 ? "s" : "") trouvé\(uniqueWords.count > 1 ? "s" : "")")
                        .font(.subheadline.smallCaps())
                        .foregroundStyle(textColor.opacity(0.4))
                        .padding(.top, 4)
                        .padding(.bottom, 20)
                        .offset(y: showList ? 0 : 12)
                        .opacity(showList ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: showList)

                    ForEach(Array(uniqueWords.enumerated()), id: \.offset) { offset, word in
                        wordRow(rank: offset + 1, word: word)
                            .offset(y: showList ? 0 : 12)
                            .opacity(showList ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.15 + Double(offset) * 0.05), value: showList)
                    }
                }
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .background(bgColor.ignoresSafeArea())
        .fontDesign(.rounded)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(item: $selectedWord) { word in
            DictionaryView(term: word.lowercased())
                .ignoresSafeArea()
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
            if hasDef { selectedWord = word }
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

                if hasDef {
                    Image(systemName: "book")
                        .font(.system(size: 13))
                        .foregroundStyle(textColor.opacity(0.4))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(textColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
