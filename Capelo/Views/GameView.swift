import SwiftUI

struct GameView: View {
    @State private var viewModel = GameViewModel()
    @State private var barFillAnimating = false
    @State private var showPauseHint = false
    @State private var showWords = false
    @Environment(\.colorScheme) private var colorScheme

    private var bgColor: Color { Palette.background(for: colorScheme) }
    private var textColor: Color { Palette.text(for: colorScheme) }
    private var isUrgent: Bool { viewModel.timeRemaining <= 10 && viewModel.timeRemaining > 0 && viewModel.hasStarted && !viewModel.isGameOver }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(verbatim: "\(viewModel.isGameOver ? viewModel.score : viewModel.bestScore)")
                    .font(.subheadline.bold())
                    .foregroundStyle(viewModel.isNewBest ? Palette.cream : textColor.opacity(0.5))
                    .contentTransition(.numericText())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(viewModel.isNewBest ? Palette.orangeRed : textColor.opacity(0.12), in: Capsule())
                    .animation(.easeOut(duration: 0.3), value: viewModel.isNewBest)
                if viewModel.isGameOver {
                    Text("Game Over")
                        .font(.system(size: 44, weight: .heavy))
                        .foregroundStyle(textColor)
                        .transition(.asymmetric(insertion: .push(from: .bottom), removal: .identity))
                } else {
                    RollingCounter(
                        value: viewModel.score,
                        font: .system(size: 44, weight: .heavy),
                        color: textColor
                    )
                    .transition(.asymmetric(insertion: .identity, removal: .push(from: .top)))
                }
            }
            .animation(.easeOut(duration: 0.4), value: viewModel.isGameOver)
            .padding(.top, 32)

            Spacer()

            // Grid
            GridView(viewModel: viewModel)
                .padding(.horizontal, 4)
                .overlay(alignment: .top) {
                    // Current word — overlaid so it doesn't push the grid down
                    Text(viewModel.currentWord.isEmpty ? " " : viewModel.currentWord)
                        .font(.title2.bold())
                        .foregroundStyle(wordColor)
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: 0.15), value: viewModel.currentWord)
                        .offset(y: -42)
                }

            Spacer()

            // Timer bar
            RoundedRectangle(cornerRadius: 3)
                .fill(isUrgent && !viewModel.isPaused ? Palette.orangeRed.opacity(0.15) : textColor.opacity(0.15))
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    GeometryReader { barGeo in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(isUrgent && !viewModel.isPaused ? Palette.orangeRed : textColor)
                            .frame(width: barGeo.size.width * (barFillAnimating ? min(viewModel.timeRemaining / 90, 1.0) : 0))
                    }
                }
                .clipped()
                .padding(.horizontal, 12)
                .animation(.linear(duration: 0.2), value: viewModel.timeRemaining)
                .animation(.easeOut(duration: 0.3), value: isUrgent)
                .overlay {
                    if isUrgent && !viewModel.isPaused {
                        Text("\(Int(viewModel.timeRemaining))")
                            .font(.title3.monospacedDigit().bold())
                            .foregroundStyle(bgColor)
                            .contentTransition(.numericText())
                            .animation(.spring(duration: 0.3), value: Int(viewModel.timeRemaining))
                            .padding(16)
                            .background(Palette.orangeRed, in: Circle())
                            .keyframeAnimator(initialValue: CGFloat(1.0), trigger: Int(viewModel.timeRemaining)) { content, scale in
                                content.scaleEffect(scale)
                            } keyframes: { _ in
                                SpringKeyframe(1.15, duration: 0.15, spring: .bouncy)
                                SpringKeyframe(1.0, duration: 0.3, spring: .smooth)
                            }
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeOut(duration: 0.3), value: isUrgent)
                .overlay(alignment: .top) {
                    if viewModel.isPaused {
                        Text("pause")
                            .font(.caption.smallCaps())
                            .foregroundStyle(textColor.opacity(0.5))
                            .offset(y: -28)
                            .transition(.opacity)
                    } else if showPauseHint {
                        Text("tap pour pause")
                            .font(.caption.smallCaps())
                            .foregroundStyle(textColor.opacity(0.5))
                            .offset(y: -28)
                            .transition(.opacity)
                    }
                }
                .animation(.easeOut(duration: 0.5), value: viewModel.isPaused)
                .animation(.easeOut(duration: 0.5), value: showPauseHint)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .onTapGesture {
                    if viewModel.hasStarted && !viewModel.isGameOver {
                        viewModel.togglePause()
                    }
                }
                .onChange(of: viewModel.hasStarted) {
                    if viewModel.hasStarted {
                        withAnimation(.easeOut(duration: 0.4)) { barFillAnimating = true }
                        showPauseHint = true
                        Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            showPauseHint = false
                        }
                    } else {
                        barFillAnimating = false
                        showPauseHint = false
                    }
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
        .onChange(of: viewModel.isGameOver) {
            if viewModel.isGameOver && !viewModel.foundWords.isEmpty {
                showWords = true
            }
        }
        .sheet(isPresented: $showWords) {
            WordListView(
                words: viewModel.foundWords,
                score: viewModel.score,
                onRestart: {
                    showWords = false
                    withAnimation { viewModel.setupGrid() }
                }
            )
        }
    }

    private var wordColor: Color {
        switch viewModel.lastWordValid {
        case .some(true): return Palette.olive
        case .some(false): return Palette.orangeRed
        case .none: return Palette.text(for: colorScheme)
        }
    }
}
