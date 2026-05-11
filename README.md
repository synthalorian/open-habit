# open_habit

<p align="center">
  <img src="https://img.shields.io/badge/Rust-2024-orange?style=for-the-badge&logo=rust" alt="Rust">
  <img src="https://img.shields.io/badge/Flutter-3.0-blue?style=for-the-badge&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/License-Apache_2.0-green?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/badge/Status-MVP-red?style=for-the-badge" alt="Status">
</p>

> **Retro-synthwave habit tracker with gamification. Level up your life.**

---

## The Problem

Habit apps are either boring (Todoist clone) or gimmicky (Duolingo for habits). There's no habit tracker that actually makes you *want* to show up.

## The Solution

**open_habit** is a habit tracker powered by a Rust gamification engine. XP, streaks, achievements, procedural challenges, and a neon-soaked UI that makes you actually excited to check off your habits.

```
┌───────────────────────────────────────────────────┐
│             open_habit architecture                │
│                                                    │
│  ┌──────────────┐      ┌──────────────────┐       │
│  │  Flutter UI   │◄────►│  Rust Backend    │       │
│  │  (Neon       │  IPC │  Gamification    │       │
│  │   dashboard, │      │  Engine          │       │
│  │   avatar     │      │  Rules engine    │       │
│  │   animations)│      │  Progress system │       │
│  └──────────────┘      └──────────────────┘       │
│                                                    │
│  ┌──────────────────────────────────────────┐      │
│  │  Gamification Engine                      │      │
│  │  XP • Streaks • Achievements • Levels     │      │
│  └──────────────────────────────────────────┘      │
│  ┌──────────────────────────────────────────┐      │
│  │  Procedural Engine                        │      │
│  │  Daily challenges • Random events         │      │
│  │  • "Do 10 pushups at midnight"            │      │
│  └──────────────────────────────────────────┘      │
│  ┌──────────────────────────────────────────┐      │
│  │  Habit Stacking Engine                    │      │
│  │  Rule-based recommendations               │      │
│  │  "You already track sleep → try wind-down"│      │
│  └──────────────────────────────────────────┘      │
└───────────────────────────────────────────────────┘
```

## Features

### MVP (Current)
- ✅ Rust gamification engine (XP, streaks, achievements, levels)
- ✅ Flutter UI with synthwave neon aesthetic
- ✅ Procedural daily challenges
- ✅ Habit stacking recommendations (Rust rules engine)
- ✅ Local-first data storage
- ✅ Neon animated dashboard

### Roadmap
- 🔜 AI-powered habit suggestions
- 🔜 Group challenges (P2P via open_grid!)
- 🔜 Wearable notifications (via open_health!)
- 🔜 Leaderboards (opt-in, anonymous, hashed)
- 🔜 "The Grid" — persistent world that evolves with your real habits
- 🔜 Cross-app stat sharing (health + habits = combined avatar)

## Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| **Rust Backend** | Tokio, `serde`, `rusqlite` | Async, safe, embedded DB |
| **Flutter Frontend** | Riverpod, `fl_chart`, `go_router` | Clean state, smooth UI |
| **Gamification** | Custom Rust rules engine | Deterministic, fast |
| **Database** | SQLite + AES-GCM | Encrypted, embedded |
| **Procedural** | Rust PRNG + seeded events | Reproducible, fun |

## Getting Started

### Prerequisites
- Rust 1.75+
- Flutter 3.0+
- macOS 13+ / Android API 26+ / Linux

### Build

```bash
# Clone the repo
git clone https://github.com/synth/open_habit.git
cd open_habit

# Build the Rust backend
cd rust
cargo build --release

# Build the Flutter app
cd ../flutter
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## Architecture

### Rust Backend (`rust/`)

```
rust/
├── Cargo.toml
├── src/
│   ├── lib.rs              # Library root
│   ├── gamification/       # Gamification engine
│   │   ├── mod.rs
│   │   ├── xp.rs           # XP calculation & leveling
│   │   ├── streaks.rs      # Streak tracking & bonuses
│   │   ├── achievements.rs # Achievement system
│   │   └── levels.rs       # Level thresholds & rewards
│   ├── procedural/         # Procedural challenges
│   │   ├── mod.rs
│   │   ├── generator.rs    # Challenge generation
│   │   ├── events.rs       # Random events
│   │   └── rng.rs          # Seeded PRNG
│   ├── rules/              # Habit stacking rules engine
│   │   ├── mod.rs
│   │   ├── engine.rs       # Rule evaluation
│   │   └── definitions.rs  # Built-in rules
│   ├── db/                 # Database layer
│   │   ├── mod.rs
│   │   ├── schema.rs       # Habit schema
│   │   └── queries.rs      # Typed queries
│   └── server/             # Local IPC server
│       ├── mod.rs
│       └── handler.rs
```

### Flutter Frontend (`flutter/`)

```
flutter/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart              # App shell & routing
│   ├── themes/               # Synthwave neon themes
│   ├── screens/              # Dashboard, habits, challenges, avatar
│   ├── widgets/              # Neon cards, XP bar, streak flames
│   ├── providers/            # Riverpod state
│   ├── services/             # IPC bridge to Rust
│   └── utils/                # Helpers
└── test/
    ├── unit/
    ├── integration/
    └── widgets/
```

## Development

### Running Tests

```bash
# Rust tests
cd rust && cargo test

# Flutter tests
cd flutter && flutter test
```

### Code Style

- **Rust:** `cargo fmt` + `cargo clippy -- -D warnings`
- **Flutter:** `dart format .` + `flutter analyze`

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

## Acknowledgments

Built with love by **synth** 🎹🦞 — [synthclaw](https://github.com/synth)

Part of **The Neon Stack** — three open-source apps, one ecosystem.

---

*Your habits shape your world. Make them legendary.*
