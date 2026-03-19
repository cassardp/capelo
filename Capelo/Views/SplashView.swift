import SwiftUI

struct SplashView: View {
    let onPlay: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var language: GameLanguage {
        if let saved = UserDefaults.standard.string(forKey: "gameLanguage"),
           let parsed = GameLanguage(rawValue: saved) {
            return parsed
        }
        return GameLanguage.detect()
    }

    @State private var selectedIndices: [Int] = []
    @State private var completed = false
    @State private var failed = false
    @State private var exploding = false
    @State private var titleOffset: CGFloat = -40
    @State private var titleOpacity: Double = 0
    @State private var tilesOffset: CGFloat = 40
    @State private var tilesOpacity: Double = 0
    @State private var hintOpacity: Double = 0

    private var bgColor: Color { Palette.background(for: colorScheme) }
    private var textColor: Color { Palette.text(for: colorScheme) }

    private var word: [Character] {
        Array(Strings.get("play", language: language).uppercased())
    }

    // Pre-computed random explosion vectors per tile
    @State private var explosionOffsets: [(x: CGFloat, y: CGFloat, rotation: Double)] = []

    private func generateExplosionOffsets() {
        let count = word.count
        let center = CGFloat(count - 1) / 2.0
        explosionOffsets = (0..<count).map { i in
            let spread = CGFloat(i) - center
            let x = spread * CGFloat.random(in: 60...100) + CGFloat.random(in: -30...30)
            let y = CGFloat.random(in: -300 ... -150)
            let rotation = Double(spread) * Double.random(in: 15...35)
            return (x, y, rotation)
        }
    }

    var body: some View {
        VStack(spacing: 48) {
            Text("Capelo")
                .font(.system(size: 42, weight: .heavy))
                .foregroundStyle(textColor)
                .offset(y: titleOffset)
                .opacity(titleOpacity)

            splashTiles

            Text(Strings.get("swipeToPlay", language: language))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(textColor.opacity(0.4))
                .opacity(hintOpacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(bgColor.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.4).delay(0.1)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
            withAnimation(.spring(duration: 0.5, bounce: 0.4).delay(0.3)) {
                tilesOffset = 0
                tilesOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.6).delay(0.8)) {
                hintOpacity = 1.0
            }
        }
    }

    private var splashTiles: some View {
        GeometryReader { geo in
            let tileSize = geo.size.width / 7
            let tilesWidth = tileSize * CGFloat(word.count)
            let leadingPad = (geo.size.width - tilesWidth) / 2
            HStack(spacing: CGFloat(0)) {
                ForEach(Array(word.enumerated()), id: \.offset) { index, char in
                    let offsets = index < explosionOffsets.count ? explosionOffsets[index] : (x: CGFloat(0), y: CGFloat(0), rotation: 0.0)
                    SplashTileView(
                        character: char,
                        isSelected: selectedIndices.contains(index),
                        state: tileState(for: index),
                        size: tileSize,
                        colorScheme: colorScheme
                    )
                    .offset(x: exploding ? offsets.x : 0, y: exploding ? offsets.y : 0)
                    .rotationEffect(.degrees(exploding ? offsets.rotation : 0))
                    .scaleEffect(exploding ? 0.4 : 1.0)
                    .opacity(exploding ? 0 : 1)
                }
            }
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .offset(y: tilesOffset)
            .opacity(tilesOpacity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !completed, !failed else { return }
                        let adjustedX = value.location.x - leadingPad
                        let adjusted = CGPoint(x: adjustedX, y: value.location.y)
                        handleSplashDrag(at: adjusted, tileSize: tileSize, spacing: 0)
                    }
                    .onEnded { _ in
                        guard !completed else { return }
                        if selectedIndices.count == word.count {
                            completeSplash()
                        } else if !selectedIndices.isEmpty {
                            failSplash()
                        }
                    }
            )
        }
        .aspectRatio(7, contentMode: .fit)
        .padding(.horizontal, 4)
    }

    private func tileState(for index: Int) -> SplashTileState {
        if completed { return .valid }
        if failed { return .invalid }
        return .neutral
    }

    private func handleSplashDrag(at location: CGPoint, tileSize: CGFloat, spacing: CGFloat) {
        let step = tileSize + spacing
        let rawIndex = Int(location.x / step)
        guard rawIndex >= 0, rawIndex < word.count else { return }

        let tileCenterX = CGFloat(rawIndex) * step + tileSize / 2
        let dist = abs(location.x - tileCenterX)
        guard dist <= tileSize * 0.6 else { return }

        if selectedIndices.isEmpty {
            if rawIndex == 0 {
                selectedIndices = [0]
                lightHaptic()
            }
            return
        }

        guard let lastIndex = selectedIndices.last else { return }

        // Backtrack
        if let existing = selectedIndices.firstIndex(of: rawIndex), existing < selectedIndices.count - 1 {
            selectedIndices = Array(selectedIndices.prefix(existing + 1))
            lightHaptic()
            return
        }

        // Must be next sequential tile
        if rawIndex == lastIndex + 1 {
            selectedIndices.append(rawIndex)
            lightHaptic()

            if selectedIndices.count == word.count {
                completed = true
                heavyHaptic()
                completeSplash()
            }
        }
    }

    private func failSplash() {
        failed = true
        mediumHaptic()
        withAnimation(.easeOut(duration: 0.3)) {}
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.2)) {
                selectedIndices = []
                failed = false
            }
        }
    }

    private func completeSplash() {
        generateExplosionOffsets()

        // Pause on green, then explode
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.15)) {
                hintOpacity = 0
            }
            withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
                exploding = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                titleOpacity = 0
                titleOffset = -20
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                onPlay()
            }
        }
    }

    private func lightHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
    }
    private func mediumHaptic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)
    }
    private func heavyHaptic() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
}

enum SplashTileState {
    case neutral, valid, invalid
}

struct SplashTileView: View {
    let character: Character
    let isSelected: Bool
    let state: SplashTileState
    let size: CGFloat
    let colorScheme: ColorScheme

    private var bg: Color {
        guard isSelected else {
            return colorScheme == .dark ? Palette.sand.opacity(0.12) : Palette.sand
        }
        switch state {
        case .valid: return Palette.olive
        case .invalid: return Palette.orangeRed
        case .neutral: return Palette.taupe
        }
    }

    private var fg: Color {
        if isSelected { return Palette.cream }
        return colorScheme == .dark ? Palette.sand : Palette.espresso
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(bg)
                .animation(.easeOut(duration: 0.15), value: bg)
            Text(String(character))
                .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
                .foregroundStyle(fg)
                .animation(.easeOut(duration: 0.15), value: fg)
        }
        .frame(width: size - 6, height: size - 6)
        .frame(width: size, height: size)
    }
}

private extension Bundle {
    var icon: UIImage? {
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let files = primary["CFBundleIconFiles"] as? [String],
              let name = files.last else { return nil }
        return UIImage(named: name)
    }
}
