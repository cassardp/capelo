import Foundation

struct Tile: Identifiable, Equatable {
    let id: UUID
    let character: Character
    var row: Int
    var col: Int
    var isMatched = false
    var isBomb = false
}
