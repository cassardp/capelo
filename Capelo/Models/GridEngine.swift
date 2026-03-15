import Foundation

struct GridEngine {
    var grid: [[Tile]] = []
    let rows: Int
    let cols: Int

    var allTiles: [Tile] { grid.flatMap { $0 } }

    init(rows: Int = 7, cols: Int = 7) {
        self.rows = rows
        self.cols = cols
    }

    mutating func buildGrid() {
        grid = []
        for row in 0..<rows {
            var rowTiles: [Tile] = []
            for col in 0..<cols {
                rowTiles.append(Tile(
                    id: UUID(),
                    character: LetterGenerator.random(),
                    row: row,
                    col: col
                ))
            }
            grid.append(rowTiles)
        }
        let bombCount = Int.random(in: 1...2)
        var placed = 0
        while placed < bombCount {
            let r = Int.random(in: 0..<rows)
            let c = Int.random(in: 0..<cols)
            guard !grid[r][c].isBomb else { continue }
            grid[r][c].isBomb = true
            placed += 1
        }
    }

    func neighbors(of row: Int, col: Int) -> [(Int, Int)] {
        var result: [(Int, Int)] = []
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let r = row + dr, c = col + dc
                guard r >= 0, r < rows, c >= 0, c < cols else { continue }
                result.append((r, c))
            }
        }
        return result
    }

    mutating func markMatched(at positions: [(Int, Int)]) {
        for (row, col) in positions {
            grid[row][col].isMatched = true
        }
    }

    func expandBombs(at positions: [(Int, Int)]) -> [Set<UUID>] {
        var stages: [Set<UUID>] = []
        for (row, col) in positions {
            guard grid[row][col].isBomb else { continue }
            var blast = Set<UUID>()
            for dr in -1...1 {
                for dc in -1...1 {
                    let r = row + dr, c = col + dc
                    guard r >= 0, r < rows, c >= 0, c < cols else { continue }
                    blast.insert(grid[r][c].id)
                }
            }
            stages.append(blast)
        }
        return stages
    }

    mutating func markMatchedByIds(_ ids: Set<UUID>) {
        for row in 0..<rows {
            for col in 0..<cols {
                if ids.contains(grid[row][col].id) {
                    grid[row][col].isMatched = true
                }
            }
        }
    }

    mutating func spawnBomb() {
        var newTiles: [(Int, Int)] = []
        for row in 0..<rows {
            for col in 0..<cols where grid[row][col].row < 0 {
                newTiles.append((row, col))
            }
        }
        guard let (r, c) = newTiles.randomElement() else { return }
        grid[r][c].isBomb = true
    }

    private func vowelCount() -> (vowels: Int, total: Int) {
        var v = 0, t = 0
        for row in grid {
            for tile in row where !tile.isMatched {
                t += 1
                if LetterGenerator.vowels.contains(tile.character) { v += 1 }
            }
        }
        return (v, t)
    }

    mutating func applyGravityAndSpawn() {
        var stats = vowelCount()

        for col in 0..<cols {
            var surviving: [Tile] = []
            for row in (0..<rows).reversed() {
                if !grid[row][col].isMatched {
                    surviving.append(grid[row][col])
                }
            }
            for i in 0..<surviving.count {
                let newRow = rows - 1 - i
                surviving[i].row = newRow
                surviving[i].col = col
                grid[newRow][col] = surviving[i]
            }
            let emptyCount = rows - surviving.count
            for i in 0..<emptyCount {
                let char = LetterGenerator.random(
                    currentVowelCount: stats.vowels,
                    currentTotal: stats.total
                )
                stats.total += 1
                if LetterGenerator.vowels.contains(char) { stats.vowels += 1 }
                grid[i][col] = Tile(
                    id: UUID(),
                    character: char,
                    row: i - emptyCount,
                    col: col
                )
            }
        }
    }

    mutating func dropNewTiles() {
        for col in 0..<cols {
            for row in 0..<rows {
                if grid[row][col].row < 0 {
                    grid[row][col].row = row
                }
            }
        }
    }
}
