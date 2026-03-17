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
        lightHaptic.prepare()
        mediumHaptic.prepare()
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
                score: score,
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
            updateLiveValidation()
            lightHaptic.impactOccurred(intensity: 0.4)
            return
        }

        let current = (row, col)

        // Backtrack: if user goes back to any tile already in the path, truncate
        if let index = selectedPath.firstIndex(where: { $0.0 == row && $0.1 == col }) {
            selectedPath = Array(selectedPath.prefix(index + 1))
            currentWord = String(selectedPath.map { engine.grid[$0.0][$0.1].character })
            updateLiveValidation()
            lightHaptic.impactOccurred(intensity: 0.3)
            return
        }

        // Must be adjacent to last tile (8 directions)
        let last = selectedPath.last!
        let dr = abs(last.0 - row)
        let dc = abs(last.1 - col)
        guard dr <= 1 && dc <= 1 && (dr + dc) > 0 else { return }

        selectedPath.append(current)
        currentWord = String(selectedPath.map { engine.grid[$0.0][$0.1].character })
        updateLiveValidation()
        lightHaptic.impactOccurred(intensity: 0.5)
    }

    func handleDragEnd() {
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
