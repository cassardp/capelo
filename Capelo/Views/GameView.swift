import SwiftUI

struct GameView: View {
    @State private var viewModel = GameViewModel()
    @Environment(\.colorScheme) private var colorScheme

    private var bgColor: Color { Palette.background(for: colorScheme) }
    private var textColor: Color { Palette.text(for: colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            // Best score
            Text(verbatim: "\(viewModel.bestScore)")
                .font(.subheadline.bold())
                .foregroundStyle(viewModel.isNewBest ? Palette.cream : textColor.opacity(0.5))
                .contentTransition(.numericText())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    viewModel.isNewBest ? Palette.orangeRed : textColor.opacity(0.12),
                    in: Capsule()
                )
                .animation(.easeOut(duration: 0.3), value: viewModel.isNewBest)
                .padding(.top, 32)

            // Score
            RollingCounter(
                value: viewModel.score,
                font: .system(size: 44, weight: .heavy),
                color: textColor
            )
            .padding(.top, 8)

            // Current word
            Text(viewModel.currentWord.isEmpty ? " " : viewModel.currentWord)
                .font(.title2.bold())
                .foregroundStyle(wordColor)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.15), value: viewModel.currentWord)
                .padding(.top, 8)

            Spacer()

            // Grid
            GridView(viewModel: viewModel)
                .padding(.horizontal, 4)

            Spacer()

            // Score popups
            ZStack {
                ForEach(viewModel.scorePopups) { popup in
                    Text(popup.text)
                        .font(.title3.bold())
                        .foregroundStyle(Palette.olive)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .frame(height: 30)
            .animation(.spring(duration: 0.3), value: viewModel.scorePopups.count)

            // Found words count
            if !viewModel.foundWords.isEmpty {
                Text("\(viewModel.foundWords.count) mot\(viewModel.foundWords.count > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundStyle(textColor.opacity(0.5))
                    .padding(.top, 4)
            }

            Spacer()

            // Restart button
            Button { withAnimation { viewModel.setupGrid() } } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title)
                    .foregroundStyle(textColor)
                    .frame(width: 44, height: 44)
            }
            .padding(.bottom, 32)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bgColor.ignoresSafeArea())
    }

    private var wordColor: Color {
        switch viewModel.lastWordValid {
        case .some(true): return Palette.olive
        case .some(false): return Palette.orangeRed
        case .none: return Palette.text(for: colorScheme)
        }
    }
}
