import SwiftUI

struct BonusAnimValues {
    var scale: CGFloat = 1.0
    var brightness: Double = 0.0
    var opacity: Double = 1.0
}

struct GameView: View {
    @State private var viewModel = GameViewModel()
    @State private var barFillAnimating = false
@State private var showLeaderboard = false
    @State private var leaderboardStartTab = 0
    @State private var showRestartConfirm = false
    @State private var showWordList = false
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
                    .background(viewModel.isNewBest ? Palette.orangeRed : (colorScheme == .dark ? textColor.opacity(0.12) : Palette.sand), in: Capsule())
                    .keyframeAnimator(initialValue: CGFloat(1.0), trigger: viewModel.isNewBest) { content, scale in
                        content.scaleEffect(scale)
                    } keyframes: { _ in
                        SpringKeyframe(1.3, duration: 0.15, spring: .bouncy)
                        SpringKeyframe(1.0, duration: 0.25, spring: .smooth)
                    }
                    .animation(.easeOut(duration: 0.3), value: viewModel.isNewBest)
                if viewModel.isGameOver {
                    Text(Strings.get("gameOver", language: viewModel.language))
                        .font(.system(size: 44, weight: .heavy))
                        .foregroundStyle(textColor)
                        .transition(.blurReplace)
                } else if viewModel.isPaused {
                    Text(Strings.get("paused", language: viewModel.language))
                        .font(.system(size: 44, weight: .heavy))
                        .foregroundStyle(textColor)
                        .transition(.blurReplace)
                } else if !viewModel.currentWord.isEmpty {
                    Text(viewModel.currentWord)
                        .font(.system(size: min(44, max(24, 44 - CGFloat(max(0, viewModel.currentWord.count - 9)) * 2)), weight: .heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(height: 52)
                        .foregroundStyle(wordColor)
                        .keyframeAnimator(initialValue: CGFloat(1.0), trigger: viewModel.currentWord.count) { content, scale in
                            content.scaleEffect(scale)
                        } keyframes: { _ in
                            SpringKeyframe(1.06, duration: 0.1, spring: .bouncy)
                            SpringKeyframe(1.0, duration: 0.15, spring: .smooth)
                        }
                        .transition(.blurReplace)
                } else if !viewModel.bonusText.isEmpty {
                    Text(viewModel.bonusText)
                        .font(.system(size: 44, weight: .heavy))
                        .foregroundStyle(Palette.orange)
                        .keyframeAnimator(
                            initialValue: BonusAnimValues(),
                            trigger: viewModel.bonusTrigger
                        ) { content, values in
                            content
                                .scaleEffect(values.scale)
                                .opacity(values.opacity)
                                .brightness(values.brightness)
                        } keyframes: { _ in
                            KeyframeTrack(\.scale) {
                                SpringKeyframe(1.2, duration: 0.12, spring: .bouncy)
                                SpringKeyframe(1.0, duration: 0.2, spring: .smooth)
                            }
                            KeyframeTrack(\.brightness) {
                                LinearKeyframe(0.6, duration: 0.08)
                                LinearKeyframe(0.0, duration: 0.2)
                            }
                            KeyframeTrack(\.opacity) {
                                LinearKeyframe(1.0, duration: 0.3)
                            }
                        }
                        .transition(.blurReplace)
                } else {
                    RollingCounter(
                        value: viewModel.score,
                        font: .system(size: 44, weight: .heavy),
                        color: textColor
                    )
                    .transition(.blurReplace)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isGameOver)
            .animation(.easeInOut(duration: 0.2), value: viewModel.currentWord.isEmpty)
            .animation(.easeInOut(duration: 0.25), value: viewModel.bonusText.isEmpty)
            .padding(.top, 32)

            Spacer()

            // Grid
            GridView(viewModel: viewModel)
                .padding(.horizontal, 4)

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


                .opacity(viewModel.isPaused ? 0.3 : 1)
                .animation(.easeOut(duration: 0.3), value: viewModel.isPaused)
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
                    } else {
                        barFillAnimating = false
                    }
                }

            Spacer()

            // Bottom toolbar
            ZStack {
                // Center: Main action (always truly centered)
                Button {
                    if viewModel.isGameOver {
                        withAnimation { viewModel.setupGrid() }
                    } else if viewModel.hasStarted {
                        viewModel.togglePause()
                    } else {
                        viewModel.startGame()
                    }
                } label: {
                    Image(systemName: mainActionIcon)
                        .font(.system(size: 32))
                        .foregroundStyle(textColor)
                        .frame(width: 60, height: 60)
                        .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                }
                .buttonStyle(CircleHighlightButtonStyle())

                // Side icons
                HStack {
                    // Left: Word list (during/after game) or Language picker (before game)
                    if viewModel.hasStarted || viewModel.isGameOver {
                        Button {
                            showWordList = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if viewModel.hasStarted && !viewModel.isGameOver && !viewModel.isPaused {
                                    viewModel.togglePause()
                                }
                            }
                        } label: {
                            Image(systemName: "book")
                                .font(.title2)
                                .foregroundStyle(textColor)
                                .frame(width: 44, height: 44)
                        }
                        .transition(.opacity)
                    } else {
                        Menu {
                            ForEach(GameLanguage.allCases, id: \.self) { lang in
                                Button {
                                    viewModel.language = lang
                                } label: {
                                    Label(lang.displayName, systemImage: lang == viewModel.language ? "checkmark" : "globe")
                                }
                            }
                        } label: {
                            Text(viewModel.language.shortCode)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(textColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(textColor.opacity(0.3), lineWidth: 1)
                                )
                                .transaction { $0.disablesAnimations = true }
                        }
                        .buttonStyle(.borderless)
                        .menuStyle(.borderlessButton)
                        .transition(.opacity)
                    }

                    Spacer()

                    // Right: contextual single icon
                    if viewModel.hasStarted && !viewModel.isGameOver && !viewModel.isPaused {
                        Button { showRestartConfirm = true } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title2)
                                .foregroundStyle(textColor)
                                .frame(width: 44, height: 44)
                        }
                        .transition(.opacity)
                    } else {
                        Button {
                            leaderboardStartTab = viewModel.playerName.isEmpty ? 1 : 0
                            showLeaderboard = true
                        } label: {
                            Image(systemName: "star")
                                .font(.title2)
                                .foregroundStyle(textColor)
                                .frame(width: 44, height: 44)
                        }
                        .transition(.opacity)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 24)
            .animation(.easeOut(duration: 0.3), value: viewModel.isGameOver)
            .animation(.easeOut(duration: 0.3), value: viewModel.hasStarted)
            .animation(.easeOut(duration: 0.3), value: viewModel.isPaused)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bgColor.ignoresSafeArea())
        .environment(\.gameLanguage, viewModel.language)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            if viewModel.hasStarted && !viewModel.isGameOver && !viewModel.isPaused {
                viewModel.togglePause()
            }
        }
        .onChange(of: viewModel.isGameOver) {
            if viewModel.isGameOver {
                viewModel.submitScore()
                if viewModel.isNewBest {
                    leaderboardStartTab = viewModel.playerName.isEmpty ? 1 : 0
                    Task {
                        try? await Task.sleep(for: .seconds(2.5))
                        showLeaderboard = true
                    }
                }
            }
        }
        .overlay {
            if showRestartConfirm {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showRestartConfirm = false } }
                VStack(spacing: 20) {
                    Text(Strings.get("newGame", language: viewModel.language))
                        .font(.title2.bold())
                        .foregroundStyle(textColor)
                    Text(Strings.get("currentGameLost", language: viewModel.language))
                        .font(.subheadline)
                        .foregroundStyle(textColor.opacity(0.7))
                    HStack(spacing: 16) {
                        Button {
                            withAnimation { showRestartConfirm = false }
                        } label: {
                            Text(Strings.get("cancel", language: viewModel.language))
                                .font(.body.bold())
                                .foregroundStyle(textColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(textColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                        }
                        Button {
                            withAnimation {
                                showRestartConfirm = false
                                viewModel.setupGrid()
                            }
                        } label: {
                            Text(Strings.get("restart", language: viewModel.language))
                                .font(.body.bold())
                                .foregroundStyle(bgColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Palette.orangeRed, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(24)
                .background(bgColor, in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.2), radius: 20)
                .padding(.horizontal, 40)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: showRestartConfirm)
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView(
                playerName: $viewModel.playerName,
                playerLink: $viewModel.playerLink,
                language: Binding(get: { viewModel.language }, set: { viewModel.language = $0 }),
                startTab: leaderboardStartTab,
                highlightPlayerName: viewModel.isNewBest && !viewModel.playerName.isEmpty ? viewModel.playerName : nil,
                onSave: {
                    UserDefaults.standard.set(viewModel.playerName, forKey: "playerName")
                    UserDefaults.standard.set(viewModel.playerLink, forKey: "playerLink")
                }
            )
        }
        .sheet(isPresented: $showWordList) {
            WordListView(words: viewModel.foundWords)
                .environment(\.gameLanguage, viewModel.language)
        }
    }

    private var mainActionIcon: String {
        if viewModel.isGameOver {
            return "arrow.counterclockwise"
        } else if viewModel.hasStarted && !viewModel.isPaused {
            return "pause.fill"
        } else {
            return "play.fill"
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

struct CircleHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Circle()
                    .fill(Color.gray.opacity(configuration.isPressed ? 0.3 : 0))
                    .frame(width: 56, height: 56)
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
