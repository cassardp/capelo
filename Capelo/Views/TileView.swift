import SwiftUI

private struct ShakeOffset: Animatable {
    var x: CGFloat = 0
    var y: CGFloat = 0
    static let zero = ShakeOffset()
}

struct TileView: View {
    let tile: Tile
    let isSelected: Bool
    let isBombFlashed: Bool
    let wordValid: Bool?
    let isPaused: Bool
    let isGameOver: Bool
    let size: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    @State private var shakeTrigger = false
    @State private var wiggleTrigger = false

    private var tileBackground: Color {
        if isPaused { return colorScheme == .dark ? Palette.sand.opacity(0.12) : Palette.sand }
        if isBombFlashed { return Palette.orangeRed }
        if isSelected {
            switch wordValid {
            case .some(true): return Palette.olive
            case .some(false): return Palette.orangeRed
            case .none: return Palette.taupe
            }
        }
        if tile.isBomb { return Palette.orangeRed.opacity(0.15) }
        return colorScheme == .dark ? Palette.sand.opacity(0.12) : Palette.sand
    }

    private var tileBorder: Color? {
        return nil
    }

    private var tileText: Color {
        if isBombFlashed { return colorScheme == .dark ? Palette.warmBlack : Palette.cream }
        if isSelected { return Palette.cream }
        if tile.isBomb { return Palette.orangeRed }
        return colorScheme == .dark ? Palette.sand : Palette.espresso
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(tileBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(tileBorder ?? .clear, lineWidth: 2)
                )
                .animation(isPaused ? nil : .easeOut(duration: 0.20), value: tileBackground)
            if isPaused {
                Text("")
            } else {
                Text(String(tile.character))
                    .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
                    .foregroundStyle(tileText)
            }
        }
        .frame(width: size - 6, height: size - 6)
        .scaleEffect(isBombFlashed ? 1.15 : 1.0)
        .brightness(isBombFlashed ? 0.3 : 0)
        .animation(.easeOut(duration: 0.20), value: isSelected)
        .opacity(tile.isMatched ? 0 : 1)
        .keyframeAnimator(initialValue: Double.zero, trigger: wiggleTrigger) { content, angle in
            content.rotationEffect(.degrees(angle))
        } keyframes: { _ in
            CubicKeyframe(4, duration: 0.09)
            CubicKeyframe(-4, duration: 0.09)
            CubicKeyframe(3, duration: 0.09)
            CubicKeyframe(-2, duration: 0.09)
            CubicKeyframe(1, duration: 0.08)
            CubicKeyframe(0, duration: 0.08)
        }
        .keyframeAnimator(initialValue: ShakeOffset.zero, trigger: shakeTrigger) { content, value in
            content.offset(x: value.x, y: value.y)
        } keyframes: { _ in
            let dx: CGFloat = (tile.row + tile.col) % 2 == 0 ? 1 : -1
            let dy: CGFloat = (tile.row + tile.col) % 3 == 0 ? 1 : -1
            KeyframeTrack(\.x) {
                CubicKeyframe(4 * dx, duration: 0.15)
                CubicKeyframe(-3.5 * dx, duration: 0.15)
                CubicKeyframe(3.5 * dx, duration: 0.18)
                CubicKeyframe(-3 * dx, duration: 0.18)
                CubicKeyframe(2.5 * dx, duration: 0.2)
                CubicKeyframe(-2 * dx, duration: 0.2)
                CubicKeyframe(1.5 * dx, duration: 0.22)
                CubicKeyframe(-1 * dx, duration: 0.22)
                CubicKeyframe(0.5 * dx, duration: 0.25)
                CubicKeyframe(0, duration: 0.25)
            }
            KeyframeTrack(\.y) {
                CubicKeyframe(3 * dy, duration: 0.13)
                CubicKeyframe(-2.5 * dy, duration: 0.16)
                CubicKeyframe(2.5 * dy, duration: 0.16)
                CubicKeyframe(-2 * dy, duration: 0.19)
                CubicKeyframe(1.5 * dy, duration: 0.21)
                CubicKeyframe(-1 * dy, duration: 0.21)
                CubicKeyframe(0.5 * dy, duration: 0.24)
                CubicKeyframe(0, duration: 0.3)
            }
        }
        .onChange(of: isGameOver) {
            if isGameOver {
                Task {
                    try? await Task.sleep(for: .milliseconds((tile.row + tile.col) % 5 * 30))
                    shakeTrigger.toggle()
                }
            }
        }
        .task(id: tile.isBomb) {
            guard tile.isBomb else { return }
            let offset = Int.random(in: 500...2000)
            try? await Task.sleep(for: .milliseconds(offset))
            while !Task.isCancelled && tile.isBomb && !tile.isMatched {
                wiggleTrigger.toggle()
                let delay = Int.random(in: 2500...4500)
                try? await Task.sleep(for: .milliseconds(delay))
            }
        }
    }
}
