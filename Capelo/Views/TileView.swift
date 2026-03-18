import SwiftUI

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
        if isBombFlashed { return colorScheme == .dark ? Palette.sand : Palette.espresso }
        if isSelected {
            switch wordValid {
            case .some(true): return Palette.olive
            case .some(false): return Palette.orangeRed
            case .none: return Palette.taupe
            }
        }
        if tile.isBomb { return Palette.orange.opacity(0.15) }
        return colorScheme == .dark ? Palette.sand.opacity(0.12) : Palette.sand
    }

    private var tileBorder: Color? {
        if !isPaused && !isSelected && !isBombFlashed && tile.isBomb { return Palette.orange.opacity(0.5) }
        return nil
    }

    private var tileText: Color {
        if isBombFlashed { return colorScheme == .dark ? Palette.warmBlack : Palette.cream }
        if isSelected { return Palette.cream }
        if tile.isBomb { return Palette.orange }
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
        .keyframeAnimator(initialValue: CGFloat.zero, trigger: shakeTrigger) { content, value in
            content.offset(x: value)
        } keyframes: { _ in
            let d: CGFloat = (tile.row + tile.col) % 2 == 0 ? 1 : -1
            CubicKeyframe(4 * d, duration: 0.15)
            CubicKeyframe(-3.5 * d, duration: 0.15)
            CubicKeyframe(3.5 * d, duration: 0.18)
            CubicKeyframe(-3 * d, duration: 0.18)
            CubicKeyframe(2.5 * d, duration: 0.2)
            CubicKeyframe(-2 * d, duration: 0.2)
            CubicKeyframe(1.5 * d, duration: 0.22)
            CubicKeyframe(-1 * d, duration: 0.22)
            CubicKeyframe(0.5 * d, duration: 0.25)
            CubicKeyframe(-0.2 * d, duration: 0.25)
            CubicKeyframe(0, duration: 0.3)
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
