# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned
- Encrypted SQLite database
- Random events (bonus XP, challenge rush, mystery boxes)
- Weekly quests and challenge history
- Achievement push notifications
- Habit stacking recommendations engine
- Cross-device sync
- iOS support

## [0.6.0] - 2025-05-21

### Added
- One-Click GO!! — instant habit completion from dashboard
- 50 challenge presets (expanded from 22)
- Neon pulse animation on XP gain
- Stat XP multiplier x2 for faster progression
- XP Test button in settings (dev helper)

### Changed
- Stat XP persistence overhaul — stats now properly save and load
- Compact stat bar layout on dashboard
- Challenge card polish with progress indicators

### Fixed
- Stat XP not persisting across app restarts
- Various UI overflow issues on smaller screens

## [0.5.0] - 2025-05-16

### Added
- 28 new challenge presets (total 22 → 50)
- One-click challenge progress from dashboard
- Bad habit relapse penalty (-50% streak XP)
- XP Test button for dev debugging

### Fixed
- Stat XP persistence — custom stats now save correctly
- Per-habit streak tracking accuracy

## [0.4.1] - 2025-05-14

### Added
- 4 home screen widgets (Quick Toggle, XP Summary, Stat Snapshot, Challenges)
- App icon and branding assets

### Fixed
- AppBar text clipping on high-DPI devices
- Dialog overflow on stat customization screen

## [0.4.0] - 2025-05-13

### Added
- RPG Stat XP system — 7 core stats level up independently
- Per-habit streak tracking
- XP timeline chart on stats screen
- Achievement progress indicators
- Spirit stat with 🙏 icon

### Changed
- Clean UI overhaul — removed preset clutter
- Dashboard layout optimized for stat display

## [0.2.0] - 2025-05-12

### Added
- RPG Stats system (Strength, Intelligence, Vitality, Agility, Wisdom, Charisma, Luck)
- Bad habit (quit) tracking with reverse streaks
- Habit Library — 80+ pre-made healthy habits
- Synthwave icon system with 130+ emoji choices
- Custom stat creation (name, icon, color, category mapping)

## [0.1.0] - 2025-05-11

### Added
- Core habit tracking (CRUD, completion, XP)
- Streaks and achievements engine
- Procedural daily challenges
- 3 themes: Synthwave '84, Dark, Light
- Rust backend with SQLite persistence
- Flutter frontend with Riverpod state management
- Android APK release

---

*Built with retro soul and modern precision. 🎹🦈*
