import SwiftUI

@Observable
class GameViewModel {
    var language: GameLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "gameLanguage")
            setupGrid()
        }
    }
    var engine: GridEngine
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
    var playerName: String {
        didSet { UserDefaults.standard.set(playerName, forKey: "playerName") }
    }
    var playerLink: String {
        didSet { UserDefaults.standard.set(playerLink, forKey: "playerLink") }
    }
    var bonusText: String = ""
    var bonusPoints: Int = 0
    var bonusTrigger: Int = 0
    var bombFlashTiles: Set<UUID> = []
    var timeRemaining: Double = 45
    var isGameOver = false
    var hasStarted = false
    var isPaused = false
    var timerTask: Task<Void, Never>?

    private var validator: WordValidator
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
    private var lastDragLocation: CGPoint?

    init() {
        let lang: GameLanguage
        if let saved = UserDefaults.standard.string(forKey: "gameLanguage"),
           let parsed = GameLanguage(rawValue: saved) {
            lang = parsed
        } else {
            lang = GameLanguage.detect()
            UserDefaults.standard.set(lang.rawValue, forKey: "gameLanguage")
        }
        self.language = lang
        self.engine = GridEngine(language: lang)
        self.validator = WordValidator(language: lang)
        self.bestScore = UserDefaults.standard.integer(forKey: "bestScore")
        self.playerName = UserDefaults.standard.string(forKey: "playerName") ?? ""
        self.playerLink = UserDefaults.standard.string(forKey: "playerLink") ?? ""
        setupGrid()
    }

    deinit { timerTask?.cancel() }

    func setupGrid() {
        engine = GridEngine(language: language)
        validator = WordValidator(language: language)
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
        bonusText = ""
        bonusPoints = 0
        engine.buildGrid()
    }

    // MARK: - Timer

    func submitScore() {
        guard !playerName.isEmpty, score > 0 else { return }
        Task {
            try? await API.submitScore(
                playerName: playerName,
                score: max(score, bestScore),
                link: playerLink.isEmpty ? nil : playerLink,
                deviceId: deviceId
            )
        }
    }

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
                if timeRemaining <= 0 {
                    selectedPath = []
                    currentWord = ""
                    lastWordValid = nil
                    isGameOver = true
                }
            }
        }
    }

    func startGame() {
        guard !hasStarted, !isGameOver else { return }
        hasStarted = true
        lightHaptic.prepare()
        mediumHaptic.prepare()
        heavyHaptic.prepare()
        startTimer()
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
        if !hasStarted { startGame() }

        let prevLocation = lastDragLocation
        lastDragLocation = location

        // Interpolate between previous and current touch to catch fast swipes
        if let prev = prevLocation, selectedPath.count > 0 {
            let dist = hypot(location.x - prev.x, location.y - prev.y)
            let step = tileSize * 0.3
            if dist > step {
                let steps = Int(dist / step)
                for i in 1..<steps {
                    let t = CGFloat(i) / CGFloat(steps)
                    let interp = CGPoint(
                        x: prev.x + (location.x - prev.x) * t,
                        y: prev.y + (location.y - prev.y) * t
                    )
                    trySelectTile(at: interp, tileSize: tileSize)
                }
            }
        }

        trySelectTile(at: location, tileSize: tileSize)
    }

    private func trySelectTile(at location: CGPoint, tileSize: CGFloat) {
        let centerThreshold = tileSize * 0.45

        // No path yet: pick the tile under the touch (larger threshold for first tap)
        if selectedPath.isEmpty {
            let col = Int(location.x / tileSize)
            let row = Int(location.y / tileSize)
            guard row >= 0, row < engine.rows, col >= 0, col < engine.cols else { return }
            let cx = CGFloat(col) * tileSize + tileSize / 2
            let cy = CGFloat(row) * tileSize + tileSize / 2
            guard hypot(location.x - cx, location.y - cy) <= tileSize * 0.55 else { return }
            addTileToPath(row: row, col: col, tileSize: tileSize)
            return
        }

        // Path exists: only consider tiles adjacent to the last selected tile
        // Use normalized distances + strong direction penalty to avoid cardinal bias
        let last = selectedPath.last!
        let lastCx = CGFloat(last.1) * tileSize + tileSize / 2
        let lastCy = CGFloat(last.0) * tileSize + tileSize / 2
        let dx = location.x - lastCx
        let dy = location.y - lastCy
        let dragLen = hypot(dx, dy)

        // Dead zone: ignore micro-movements near last tile center
        guard dragLen > tileSize * 0.3 else { return }

        var bestScore = CGFloat.greatestFiniteMagnitude
        var bestR = -1, bestC = -1

        let sqrt2 = CGFloat(1.41421356)

        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let r = last.0 + dr, c = last.1 + dc
                guard r >= 0, r < engine.rows, c >= 0, c < engine.cols else { continue }
                let cx = CGFloat(c) * tileSize + tileSize / 2
                let cy = CGFloat(r) * tileSize + tileSize / 2
                let d = hypot(location.x - cx, location.y - cy)

                // Normalize distance: divide by theoretical distance to neighbor center
                // so cardinal (1×tileSize) and diagonal (√2×tileSize) are on equal footing
                let isDiag = abs(dr) == 1 && abs(dc) == 1
                let theoreticalDist = isDiag ? tileSize * sqrt2 : tileSize
                let normalizedDist = d / theoreticalDist

                // Direction alignment via dot product
                let tileDir = CGPoint(x: CGFloat(dc), y: CGFloat(dr))
                let dirLen = hypot(tileDir.x, tileDir.y)
                let alignment = (dx * tileDir.x + dy * tileDir.y) / (dragLen * dirLen)

                // Strong penalty for misaligned tiles (0.45 instead of 0.25)
                let penalty = max(0, 1 - alignment) * 0.45
                let score = normalizedDist + penalty

                if score < bestScore { bestScore = score; bestR = r; bestC = c }
            }
        }

        // Uniform threshold on raw distance, relaxed for diagonals by √2
        let isDiagonal = abs(bestR - last.0) == 1 && abs(bestC - last.1) == 1
        let effectiveThreshold = isDiagonal ? centerThreshold * sqrt2 : centerThreshold
        let bestCx = CGFloat(bestC) * tileSize + tileSize / 2
        let bestCy = CGFloat(bestR) * tileSize + tileSize / 2
        let bestDist = hypot(location.x - bestCx, location.y - bestCy)
        guard bestR >= 0, bestDist <= effectiveThreshold else { return }
        addTileToPath(row: bestR, col: bestC, tileSize: tileSize)
    }

    private func addTileToPath(row: Int, col: Int, tileSize: CGFloat) {
        if selectedPath.isEmpty {
            selectedPath.append((row, col))
            currentWord = String(engine.grid[row][col].character)
            updateLiveValidation()
            lightHaptic.impactOccurred(intensity: 0.4)
            return
        }

        // Backtrack: if user goes back to any tile already in the path, truncate
        if let index = selectedPath.firstIndex(where: { $0.0 == row && $0.1 == col }) {
            if index < selectedPath.count - 1 {
                selectedPath = Array(selectedPath.prefix(index + 1))
                currentWord = String(selectedPath.map { engine.grid[$0.0][$0.1].character })
                updateLiveValidation()
                lightHaptic.impactOccurred(intensity: 0.3)
            }
            return
        }

        let last = selectedPath.last!
        let dr = abs(last.0 - row)
        let dc = abs(last.1 - col)

        // Auto-bridge: if 2 tiles away in a straight line, insert the middle tile
        if (dr == 2 && dc == 0) || (dr == 0 && dc == 2) || (dr == 2 && dc == 2) {
            let midR = (last.0 + row) / 2
            let midC = (last.1 + col) / 2
            if !selectedPath.contains(where: { $0.0 == midR && $0.1 == midC }) {
                selectedPath.append((midR, midC))
                lightHaptic.impactOccurred(intensity: 0.5)
            }
        }

        // Must be adjacent to last tile (8 directions) — recheck after possible bridge
        let actualLast = selectedPath.last!
        let finalDr = abs(actualLast.0 - row)
        let finalDc = abs(actualLast.1 - col)
        guard finalDr <= 1 && finalDc <= 1 && (finalDr + finalDc) > 0 else { return }

        selectedPath.append((row, col))
        currentWord = String(selectedPath.map { engine.grid[$0.0][$0.1].character })
        updateLiveValidation()
        lightHaptic.impactOccurred(intensity: 0.5)
    }

    func handleDragEnd() {
        lastDragLocation = nil
        guard !isAnimating, !isGameOver else { return }
        guard selectedPath.count >= 3 else {
            Task { await animatedDeselect() }
            return
        }

        let word = currentWord
        if validator.isValid(word) {
            Task { await processValidWord(word) }
        } else {
            lastWordValid = false
            mediumHaptic.impactOccurred(intensity: 0.8)
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                await animatedDeselect(keepColor: true)
            }
        }
    }

    private func resetSelection() {
        selectedPath = []
        currentWord = ""
    }

    private func animatedDeselect(keepColor: Bool = false) async {
        let savedValid = lastWordValid
        currentWord = ""
        if !keepColor { lastWordValid = nil }
        while !selectedPath.isEmpty {
            selectedPath.removeLast()
            if keepColor { lastWordValid = savedValid }
            try? await Task.sleep(for: .milliseconds(70))
        }
        lastWordValid = nil
    }

    private func updateLiveValidation() {
        if currentWord.count >= 3 {
            lastWordValid = validator.isValid(currentWord)
        } else {
            lastWordValid = nil
        }
    }

    // MARK: - Word processing

    private func processValidWord(_ word: String) async {
        isAnimating = true
        lastWordValid = true

        let positions = selectedPath
        let length = word.count
        let hasBomb = positions.contains { engine.grid[$0.0][$0.1].isBomb }
        let multiplier = max(1, length - 3)
        let points = 100 * length * multiplier * (hasBomb ? 3 : 1)
        score += points
        if score > bestScore {
            bestScore = score
            isNewBest = true
        }
        foundWords.append(word)

        heavyHaptic.impactOccurred(intensity: min(1.0, 0.5 + Double(length) * 0.1))
        addTime(length: length, hasBomb: hasBomb)

        // Show points
        currentWord = ""
        bonusPoints = points
        bonusText = "+\(points)"
        bonusTrigger += 1

        // Mark word tiles
        withAnimation(.easeOut(duration: 0.18)) {
            engine.markMatched(at: positions)
        }
        selectedPath = []

        // Explode bombs
        let stages = engine.expandBombs(at: positions)
        if !stages.isEmpty {
            try? await Task.sleep(for: .milliseconds(200))
            var allBlasted = Set<UUID>()
            let wordTileIds = Set(positions.map { engine.grid[$0.0][$0.1].id })
            for stage in stages {
                withAnimation(.easeOut(duration: 0.08)) {
                    bombFlashTiles = stage
                }
                heavyHaptic.impactOccurred(intensity: 1.0)

                let newTiles = stage.subtracting(wordTileIds)
                let stagePoints = newTiles.count * 50
                score += stagePoints
                if score > bestScore {
                    bestScore = score
                    isNewBest = true
                }
                bonusPoints += stagePoints
                bonusText = "+\(bonusPoints)"
                bonusTrigger += 1

                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(.easeOut(duration: 0.1)) {
                    bombFlashTiles = []
                }
                allBlasted.formUnion(stage)
                try? await Task.sleep(for: .milliseconds(60))
            }
            withAnimation(.easeOut(duration: 0.18)) {
                engine.markMatchedByIds(allBlasted)
            }
        }

        try? await Task.sleep(for: .milliseconds(400))
        bonusText = ""
        bonusPoints = 0

        // Gravity
        withAnimation(.spring(duration: 0.25)) {
            engine.applyGravityAndSpawn()
        }
        // Spawn bombs based on word length + bonus if chain explosion
        let bombCount: Int = switch length {
        case 4: 1
        case 5: 2
        case 6: 3
        default: length >= 7 ? 4 : 0
        }
        let totalBombs = bombCount + (hasBomb && bombCount > 0 ? 1 : 0)
        for _ in 0..<totalBombs {
            engine.spawnBomb()
        }
        try? await Task.sleep(for: .milliseconds(50))

        // Drop new tiles
        withAnimation(.spring(duration: 0.25)) {
            engine.dropNewTiles()
        }
        try? await Task.sleep(for: .milliseconds(200))

        currentWord = ""
        lastWordValid = nil
        isAnimating = false
    }

}
