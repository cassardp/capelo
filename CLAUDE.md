# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Capelo (internal name: Rhooo) — a French word game (Boggle-style) for iOS, built with pure SwiftUI. Players drag across a 7×7 letter grid to form French words (≥3 letters). Bombs spawn on 5+ letter words.

## Build

```bash
xcodebuild -project Capelo.xcodeproj -scheme Capelo -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16'
```

No SPM dependencies, no Podfile, no external packages.

- Xcode 26.3+, iOS 26.2 deployment target
- Swift 5.9+ (uses `@Observable` macro)

## Architecture

MVVM pattern with three layers:

- **Models** (`Models/`): `Tile` (struct, letter on grid), `GridEngine` (7×7 grid logic, gravity, bomb expansion, tile spawning)
- **Game** (`Game/`): `GameViewModel` (@Observable, orchestrates gameplay — drag handling, word validation, scoring, animations), `LetterGenerator` (French Scrabble frequency distribution, vowel balancing), `WordValidator` (loads `french_words.txt` dictionary, 232K words)
- **Views** (`Views/`): `GameView` (main screen), `GridView` (grid + drag gesture + selection line), `TileView` (animated tile), `ScoreView` (rolling counter), `Palette` (color theme with hex parsing)

Entry point: `RhoooApp.swift` → `ContentView.swift` → `GameView`

## Key mechanics

- Scoring: `100 × 2^max(0, length-3) × (hasBomb ? 3 : 1)`
- Drag: 8-directional adjacency, 40% radius threshold, backtrack support
- Haptics: light/medium/heavy feedback at different interaction points
- Persistence: `UserDefaults` for best score only
- Orientation: portrait locked via AppDelegate
