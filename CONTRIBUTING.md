# Contributing to open_habit

First off, thank you for considering contributing! 🎹🦞

This project follows the Apache 2.0 license. All contributions must comply with the same terms.

## Code of Conduct

- Be respectful and constructive
- No harassment, spam, or low-effort contributions
- We're building something legendary together

## Getting Started

### Prerequisites
- Rust 1.75+ (stable toolchain)
- Flutter 3.24+ (stable channel)
- Android Studio or Xcode (for mobile builds)
- SQLite 3 (for local development)

### Development Setup
```bash
# Clone and enter
git clone https://github.com/synth/open_habit.git
cd open_habit

# Build the Rust backend
cd rust
cargo build --release

# Build the Flutter frontend
cd ../flutter
flutter pub get
flutter build apk --debug  # or ios --debug
```

## Development Workflow

### Rust Code
```bash
# Format
cargo fmt --all

# Lint (must pass with no warnings)
cargo clippy --all-targets --all-features -- -D warnings

# Test
cargo test

# Benchmarks (requires criterion)
cargo bench
```

### Flutter Code
```bash
# Format
dart format .

# Analyze (must pass with no issues)
flutter analyze

# Test
flutter test
```

## Architecture Guidelines

### Rust Backend
- Use `thiserror` for error types
- Use `tracing` for logging (not `println!`)
- Encrypt all sensitive data with `ring` + AES-GCM
- Write tests for all business logic
- Keep public API stable via `pub(crate)` visibility

### Flutter Frontend
- Use Riverpod for state management
- Keep widgets small and focused
- Write widget tests for complex components
- Use the synthwave neon theme consistently
- Never hardcode colors — use theme constants

## Commit Style

```
<type>(<scope>): <subject>

<description>

<footer>
```

Types:
- `feat` — new feature
- `fix` — bug fix
- `refactor` — code restructuring
- `docs` — documentation changes
- `test` — test additions/modifications
- `ci` — CI/CD changes
- `chore` — build/tooling changes

Example:
```
feat(health): add CSV import from Oura device

Add support for Oura Ring CSV export format.
Includes sleep stages, heart rate, and resting heart rate.
```

## Pull Request Process

1. Fork the repo and create your branch from `dev`
2. Make your changes (with tests)
3. Run `cargo fmt`, `cargo clippy`, `dart format`, and `flutter analyze`
4. Ensure all CI checks pass
5. Submit the PR targeting the `dev` branch
6. Wait for review (usually within 48 hours)

## Reporting Issues

- Use the bug report template for bugs
- Use the feature request template for features
- Include reproducible steps for bugs
- Include environment info (OS, app version)

## Security

If you find a security vulnerability, please **do not** open an issue. Instead, email synth directly or open a private security advisory on GitHub.

---

*Thank you for helping build the future of privacy. The grid needs you.* 🎹🦞
