# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Capelo (internal name: Rhooo) — a French word game (Boggle-style) for iOS, built with pure SwiftUI. Players drag across a 7×7 letter grid to form French words (≥3 letters). Bombs spawn on 4+ letter words and chain-explode nearby tiles.

## Build

```bash
xcodebuild -project Capelo.xcodeproj -scheme Capelo -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16'
```

No external dependencies (pure SwiftUI + CryptoKit for HMAC).

- Xcode 26.3+, iOS 26.2 deployment target
- Swift 5.9+ (uses `@Observable` macro)

## Architecture

MVVM pattern with three layers:

- **Models** (`Models/`): `Tile` (letter on grid), `GridEngine` (7×7 grid logic, gravity, bomb expansion, tile spawning), `ScoreEntry` (Codable leaderboard entry)
- **Game** (`Game/`): `GameViewModel` (@Observable, orchestrates gameplay — drag, validation, scoring, timer, animations), `LetterGenerator` (French Scrabble frequency distribution, 40% vowel ratio), `WordValidator` (loads `french_words.txt`, 232K words), `API` (leaderboard networking with HMAC-SHA256 signing), `DeviceId` (persistent UUID via UserDefaults), `Secrets` (HMAC key)
- **Views** (`Views/`): `GameView` (main screen + timer bar), `GridView` (grid + drag gesture + selection line), `TileView` (animated tile with keyframe shake/flash), `ScoreView` (rolling counter), `SplashView` (animated launch screen), `LeaderboardView` (3-tab modal: scores/profile/info), `WordListView` (game over summary with dictionary lookup), `Palette` (color theme with hex parsing)

Entry point: `CapeloApp.swift` → `ContentView.swift` (splash overlay) → `GameView`

## Key mechanics

Scoring, timer bonuses, bomb spawning and drag thresholds are game-balance values that get tuned often: read them in `GameViewModel` / `GridEngine`, do not trust any doc for them.

## Networking & API

- Base URL: `https://gribli-api.cassard.workers.dev`
- Auth: HMAC-SHA256 signing with `X-Signature` header + millisecond timestamp
- Endpoints: `POST /scores` (submit), `GET /scores?game=capelo` (leaderboard), `PUT /profile` (username + link)
- Error handling: 409 = name taken, other = server error

## Persistence (UserDefaults)

`bestScore`, `playerName`, `playerLink`, `deviceId` (UUID generated once on first launch)

## Orientation

Portrait locked via `AppDelegate` in `CapeloApp.swift`.
