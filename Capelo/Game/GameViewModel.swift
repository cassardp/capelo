import SwiftUI

@Observable
class GameViewModel {
    var engine = GridEngine()
    var score = 0
    var selectedPath: [(Int, Int)] = []
    var currentWord: String = ""
    var isAnimating = false
    var foundWords: [String] = []
    var lastWordValid: Bool?
    var bestScore: Int {
        didSet { UserDefaults.standard.set(bestScore, forKey: "bestScore") }
    }
    var isNewBest = false
    var bombFlashTiles: Set<UUID> = []
    var timeRemaining: Double = 45
    var isGameOver = false
    var hasStarted = false
    var isPaused = false
    var timerTask: Task<Void, Never>?

    private let validator = WordValidator()
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)

    var selectedTileIds: Set<UUID> {
        Set(selectedPath.compactMap { (r, c) -> UUID? in
            guard r >= 0, r < engine.rows, c >= 0, c < engine.cols else { return nil }
            return engine.grid[r][c].id
        })
    }

    private var timerStart: Date?
    private var timerBudget: Double = 45

    init() {
        self.bestScore = UserDefaults.standard.integer(forKey: "bestScore")
        setupGrid()
        lightHaptic.prepare()
        mediumHaptic.prepare()
    }

    deinit { timerTask?.cancel() }

    func setupGrid() {
        score = 0
        selectedPath = []
        currentWord = ""
        isAnimating = false
        isNewBest = false
        isGameOver = false
        hasStarted = false
        isPaused = false
        timerTask?.cancel()
        timeRemaining = 45
        foundWords.removeAll()
        lastWordValid = nil
        engine.buildGrid()
    }

    // MARK: - Timer

    private func startTimer() {
        timerTask?.cancel()
        timerStart = Date.now
        timerBudget = timeRemaining
        timerTask = Task { @MainActor in
            while !Task.isCancelled && timeRemaining > 0 {
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                if isPaused {
                    timerStart = Date.now
                    timerBudget = timeRemaining
                    continue
                }
                let elapsed = Date.now.timeIntervalSince(timerStart!)
                timeRemaining = max(0, timerBudget - elapsed)
                if timeRemaining <= 0 { isGameOver = true }
            }
        }
    }

    func togglePause() { isPaused.toggle() }

    private func addTime(length: Int, hasBomb: Bool) {
        let base: Double = timeRemaining <= 10 ? 8.0 : 5.0
        var bonus = base + Double(max(0, length - 3)) * 3.0
        if hasBomb { bonus += 8 }
        timeRemaining = min(90, timeRemaining + bonus)
        timerStart = Date.now
        timerBudget = timeRemaining
    }

    // MARK: - Drag handling

    func handleDrag(at location: CGPoint, tileSize: CGFloat) {
        guard !isAnimating, !isGameOver, !isPaused else { return }
        if !hasStarted { hasStarted = true; startTimer() }

        // Require finger to be within 40% radius of tile center
        let centerThreshold = tileSize * 0.4
        let col = Int(location.x / tileSize)
        let row = Int(location.y / tileSize)
        guard row >= 0, row < engine.rows, col >= 0, col < engine.cols else { return }

        let centerX = CGFloat(col) * tileSize + tileSize / 2
        let centerY = CGFloat(row) * tileSize + tileSize / 2
        let dx = location.x - centerX
        let dy = location.y - centerY
        guard sqrt(dx * dx + dy * dy) <= centerThreshold else { return }

        if selectedPath.isEmpty {
            selectedPath.append((row, col))
            currentWord = String(engine.grid[row][col].character)
            lightHaptic.impactOccurred(intensity: 0.4)
            return
        }

        let current = (row, col)

        // Backtrack: if user goes back to second-to-last tile, remove last
        if selectedPath.count >= 2 {
            let prev = selectedPath[selectedPath.count - 2]
            if prev.0 == row && prev.1 == col {
                selectedPath.removeLast()
                currentWord = String(selectedPath.map { engine.grid[$0.0][$0.1].character })
                lightHaptic.impactOccurred(intensity: 0.3)
                return
            }
        }

        // Already in path?
        if selectedPath.contains(where: { $0.0 == row && $0.1 == col }) { return }

        // Must be adjacent to last tile (8 directions)
        let last = selectedPath.last!
        let dr = abs(last.0 - row)
        let dc = abs(last.1 - col)
        guard dr <= 1 && dc <= 1 && (dr + dc) > 0 else { return }

        selectedPath.append(current)
        currentWord = String(selectedPath.map { engine.grid[$0.0][$0.1].character })
        lightHaptic.impactOccurred(intensity: 0.5)
    }

    func handleDragEnd() {
        guard !isAnimating, !isGameOver else { return }
        guard selectedPath.count >= 3 else {
            resetSelection()
            return
        }

        let word = currentWord
        if validator.isValid(word) {
            Task { await processValidWord(word) }
        } else {
            lastWordValid = false
            mediumHaptic.impactOccurred(intensity: 0.8)
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                lastWordValid = nil
                resetSelection()
            }
        }
    }

    private func resetSelection() {
        selectedPath = []
        currentWord = ""
    }

    // MARK: - Word processing

    private func processValidWord(_ word: String) async {
        isAnimating = true
        lastWordValid = true

        let positions = selectedPath
        let length = word.count
        let hasBomb = positions.contains { engine.grid[$0.0][$0.1].isBomb }
        let points = 100 * (1 << max(0, length - 3)) * (hasBomb ? 3 : 1)
        score += points
        if score > bestScore {
            bestScore = score
            isNewBest = true
        }
        foundWords.append(word)

        heavyHaptic.impactOccurred(intensity: min(1.0, 0.5 + Double(length) * 0.1))
        addTime(length: length, hasBomb: hasBomb)

        // Mark word tiles
        withAnimation(.easeOut(duration: 0.18)) {
            engine.markMatched(at: positions)
        }
        resetSelection()
        lastWordValid = nil

        // Explode bombs
        let stages = engine.expandBombs(at: positions)
        if !stages.isEmpty {
            try? await Task.sleep(for: .milliseconds(200))
            for stage in stages {
                withAnimation(.easeOut(duration: 0.08)) {
                    bombFlashTiles = stage
                }
                heavyHaptic.impactOccurred(intensity: 1.0)
                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(.easeOut(duration: 0.1)) {
                    bombFlashTiles = []
                }
                try? await Task.sleep(for: .milliseconds(60))
            }
            let allBlasted = stages.reduce(into: Set<UUID>()) { $0.formUnion($1) }
            withAnimation(.easeOut(duration: 0.18)) {
                engine.markMatchedByIds(allBlasted)
            }
        }

        try? await Task.sleep(for: .milliseconds(200))

        // Gravity
        withAnimation(.spring(duration: 0.25)) {
            engine.applyGravityAndSpawn()
        }
        // Spawn bomb if word was 5+ letters
        if length >= 4 {
            engine.spawnBomb()
        }
        try? await Task.sleep(for: .milliseconds(50))

        // Drop new tiles
        withAnimation(.spring(duration: 0.25)) {
            engine.dropNewTiles()
        }
        try? await Task.sleep(for: .milliseconds(200))

        isAnimating = false
    }

}
