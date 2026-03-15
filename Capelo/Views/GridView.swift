import SwiftUI

struct SelectionLine: Shape {
    let path: [(Int, Int)]
    let tileSize: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard let first = path.first else { return p }
        p.move(to: center(for: first))
        for pos in path.dropFirst() {
            p.addLine(to: center(for: pos))
        }
        return p
    }

    private func center(for pos: (Int, Int)) -> CGPoint {
        CGPoint(
            x: CGFloat(pos.1) * tileSize + tileSize / 2,
            y: CGFloat(pos.0) * tileSize + tileSize / 2
        )
    }
}

struct GridView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            let tileSize = geo.size.width / CGFloat(viewModel.engine.cols)
            let gridHeight = tileSize * CGFloat(viewModel.engine.rows)

            ZStack(alignment: .topLeading) {
                // Selection line
                if viewModel.selectedPath.count >= 2 {
                    SelectionLine(path: viewModel.selectedPath, tileSize: tileSize)
                        .stroke(
                            Palette.blueGray.opacity(0.5),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                        )
                }

                // Tiles
                ForEach(viewModel.engine.allTiles) { tile in
                    TileView(
                        tile: tile,
                        isSelected: viewModel.selectedTileIds.contains(tile.id),
                        isBombFlashed: viewModel.bombFlashTiles.contains(tile.id),
                        size: tileSize
                    )
                    .offset(
                        x: CGFloat(tile.col) * tileSize + 2,
                        y: CGFloat(tile.row) * tileSize + 2
                    )
                    .transition(.identity)
                }
            }
            .frame(width: geo.size.width, height: gridHeight, alignment: .topLeading)
            .padding(.top, tileSize)
            .clipped()
            .padding(.top, -tileSize)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        viewModel.handleDrag(at: value.location, tileSize: tileSize)
                    }
                    .onEnded { _ in
                        viewModel.handleDragEnd()
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
