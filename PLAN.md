# open_habit — Development Plan

> **Retro-synthwave habit tracker with gamification. Level up your life.**

---

## Vision

A habit tracker powered by a Rust gamification engine. XP, streaks, achievements, procedural challenges, and a neon-soaked UI that makes you actually excited to check off your habits.

---

## Tech Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **Rust Backend** | `tokio`, `rusqlite`, `rand`, `serde` | Async, safe, embedded DB, deterministic PRNG |
| **Flutter Frontend** | Riverpod, `fl_chart`, `go_router` | Clean state, smooth UI |
| **Gamification** | Custom Rust rules engine | Deterministic, fast, testable |
| **Procedural** | Seeded PRNG + event definitions | Reproducible, fun |
| **Database** | SQLite + AES-GCM (`ring`) | Encrypted, embedded |
| **IPC** | Unix domain socket (Linux/macOS), named pipe (Windows) | Zero-copy, no network exposure |

---

## Architecture

```
┌───────────────────────────────────────────────────┐
│           open_habit architecture                   │
│                                                      │
│  ┌──────────────┐      ┌──────────────────┐         │
│  │  Flutter UI   │◄────►│  Rust Backend    │         │
│  │  (Neon       │  IPC │  Gamification    │         │
│  │   dashboard,  │      │  Rules engine    │         │
│  │   avatar     │      │  Progress system │         │
│  │   animations)│      │  DB (AES-GCM)    │         │
│  └──────────────┘      └──────────────────┘         │
│                                                      │
│  ┌──────────────────────────────────────────┐        │
│  │  Gamification Engine                       │        │
│  │  XP • Streaks • Achievements • Levels      │        │
│  └──────────────────────────────────────────┘        │
│  ┌──────────────────────────────────────────┐        │
│  │  Procedural Engine                         │        │
│  │  Daily challenges • Random events          │        │
│  │  • "Do 10 pushups at midnight"             │        │
│  └──────────────────────────────────────────┘        │
│  ┌──────────────────────────────────────────┐        │
│  │  Habit Stacking Engine                     │        │
│  │  Rule-based recommendations                │        │
│  │  "You already track sleep → try wind-down" │        │
│  └──────────────────────────────────────────┘        │
└───────────────────────────────────────────────────┘
```

---

## Development Phases

### Phase 1 — Core Gamification Engine [DONE ✅]

**Status: COMPLETE** — All 32 tests pass across shared, gamification, db, and cli crates.

**Post-completion fixes (2026-05-14):**
- Fixed `ChallengeEngine::active_challenges()`: was calling recursive non-existent method; now correctly filters `self.challenges.iter()` by `ChallengeStatus::Active`.
- Added `GamificationEngine::active_challenges()` delegator to expose active challenges for persistence.
- Added `POST /challenges/{id}/progress` server endpoint + DB `SaveChallenges` command to persist challenge state after progression.

---

### Phase 2 — Procedural Challenge Engine

**Goal:** Generate daily/weekly challenges, random events, and quests.

#### 2.1 Challenge Definitions

- [ ] Define challenge types in `rust/src/procedural/generator.rs`:
  - **Physical** — "Do 20 pushups", "Run 5K"
  - **Mental** — "Read 30 pages", "Learn a new word"
  - **Social** — "Call a friend", "Compliment someone"
  - **Creative** — "Write 500 words", "Sketch something"
  - **Health** — "Drink 2L water", "No sugar today"
  - **Weird** — "Stand on one leg for 5 minutes", "Eat something new"
- [ ] Each challenge has: difficulty, XP reward, category, requirements
- [ ] Write definition tests

#### 2.2 Seeded PRNG

- [ ] Implement seeded PRNG in `rust/src/procedural/rng.rs`
- [ ] Seed from date + user_id (reproducible daily challenges)
- [ ] Use `rand_pcg` for cryptographically unpredictable but deterministic
- [ ] Write PRNG tests (same seed → same sequence)

#### 2.3 Challenge Generator

- [ ] Generate daily challenge pool (5 challenges, pick 1)
- [ ] Weekly challenges: bigger XP rewards, harder requirements
- [ ] Quest chains: multi-part challenges over days/weeks
- [ ] Filter by user preferences (skip disliked categories)
- [ ] Write generator tests

#### 2.4 Random Events

- [ ] Implement random event system in `rust/src/procedural/events.rs`
- [ ] Event triggers: time-based, streak-based, XP milestone-based
- [ ] Event types:
  - **Bonus XP** — Double XP for next 24 hours
  - **Challenge Rush** — Complete 3 challenges in a row
  - **Mystery Box** — Random achievement unlock
  - **Grid Storm** — All streaks frozen for 24 hours (brutal!)
- [ ] Event notifications
- [ ] Write event tests

#### 2.5 Challenge UI

- [ ] Display today's challenge in Flutter
- [ ] Mark challenge complete (log + XP)
- [ ] View challenge history
- [ ] Weekly quest overview
- [ ] Event notification toast
- [ ] Write Flutter widget tests

**Deliverable:** Rust engine generates reproducible daily challenges. Flutter UI displays and tracks them.

---

### Phase 3 — Habit Stacking & Recommendations

**Goal:** Rule-based habit stacking engine that recommends complementary habits.

#### 3.1 Habit Categories & Tags

- [ ] Define categories: Health, Fitness, Learning, Social, Creative, Productivity, Spirituality, Finance
- [ ] Define tags: morning, evening, quick, deep, social, solo
- [ ] Auto-categorize new habits based on name/description (simple keyword matching)
- [ ] Write categorization tests

#### 3.2 Stacking Rules Engine

- [ ] Define rules in `rust/src/rules/definitions.rs`:
  - "Habit A → Try Habit B" (co-occurrence)
  - "Habit A completed → Suggest Habit B" (temporal)
  - "Habit A streak > 7 → Unlock Habit B" (prerequisite)
  - "Habit A missed 3 days → Recommend Habit C" (recovery)
- [ ] Evaluate rules on every log event in `rust/src/rules/engine.rs`
- [ ] Rule priority: temporal > prerequisite > recovery > co-occurrence
- [ ] Write rule evaluation tests

#### 3.3 Recommendation Engine

- [ ] Build recommendation service in `rust/src/rules/`
- [ ] Score habits by relevance (category, tags, timing)
- [ ] Balance exploration vs. exploitation (try new habits occasionally)
- [ ] Filter: don't recommend habits already created
- [ ] Write recommendation tests

#### 3.4 Habit Stacking UI

- [ ] "Recommended Habits" section in Flutter dashboard
- [ ] Swipe-to-add (add recommended habit)
- [ ] Dismiss recommendation (don't show again)
- [ ] Show why recommended ("You've been streaking sleep → try wind-down")
- [ ] Write Flutter widget tests

**Deliverable:** Habit stacking engine recommends relevant habits. UI surfaces recommendations.

---

### Phase 4 — Flutter Frontend

**Goal:** Synthwave-themed UI with animated dashboard, habit tracking, and gamification visuals.

#### 4.1 App Shell & Routing

- [ ] Flutter project scaffold
- [ ] Riverpod state management
- [ ] `go_router` setup (dashboard, habits, challenges, stats tabs)
- [ ] Synthwave neon theme (dark mode, gradient accents)

#### 4.2 IPC Bridge

- [ ] Unix socket client in Flutter (`dart:io` `Socket`)
- [ ] Serialize/deserialize messages to/from Rust
- [ ] Error handling (connection lost, timeout)
- [ ] Background service (keep Rust process alive)

#### 4.3 Dashboard Screen

- [ ] XP bar at top (animated fill on level-up)
- [ ] Streak flames for active streaks
- [ ] Today's habits checklist
- [ ] Today's challenge card
- [ ] "Habit Stacking" suggestions section
- [ ] Pull-to-refresh

#### 4.4 Habits Screen

- [ ] Habit list grouped by category
- [ ] Habit cards: name, streak count, XP earned, difficulty badge
- [ ] Tap to log completion (modal with quality stars + notes)
- [ ] Edit habit (inline edit)
- [ ] Swipe to delete (with confirmation)
- [ ] Category filter tabs

#### 4.5 Challenges Screen

- [ ] Today's challenge (big card with XP reward)
- [ ] Complete challenge (log + XP animation)
- [ ] Challenge history (completed/active/upcoming)
- [ ] Weekly quests overview
- [ ] Event notifications (toast)

#### 4.6 Stats Screen

- [ ] Overview: total XP, level, streak count, achievements
- [ ] XP timeline (bar chart)
- [ ] Streak heat map (like GitHub contributions)
- [ ] Habit completion rate per category
- [ ] Achievement gallery (locked/unlocked)
- [ ] Level progress (XP bar)

#### 4.7 Avatar & Progression

- [ ] Avatar that evolves with level (unlock new visual elements)
- [ ] Level-up celebration animation (Lottie)
- [ ] Badge display (earned achievements)
- [ ] Trophy case

#### 4.8 Settings Screen

- [ ] Habit preferences (categories to skip)
- [ ] Notification settings
- [ ] Data export (encrypted backup)
- [ ] About / feedback

#### 4.9 Polish

- [ ] Lottie animations for loading states
- [ ] Haptic feedback on habit completion
- [ ] XP gain animations (confetti, numbers flying)
- [ ] Streak fire animations
- [ ] Offline-first (all state local)
- [ ] Accessibility (semantic labels, contrast)

**Deliverable:** `flutter build apk --release` produces a working Android APK.

---

### Phase 5 — Cross-App Integration

**Goal:** Integrate with open_health and open_grid for richer ecosystem features.

#### 5.1 Health → Habit Correlation

- [ ] Query open_health for sleep data, HRV, activity levels
- [ ] Correlate: "You sleep better on days you exercise"
- [ ] Suggest habits based on health data: "Your HRV is low → try meditation"
- [ ] Write integration tests (mock health data)

#### 5.2 Grid → Habit Notifications

- [ ] Use open_grid for P2P habit reminders (opt-in)
- [ ] Share challenge invitations with friends
- [ ] Anonymous leaderboards (hashed usernames)
- [ ] Write integration tests (mock grid data)

#### 5.3 Wearable Notifications

- [ ] Integrate with open_health for heart rate alerts
- [ ] Send habit reminders based on health patterns
- [ ] Write integration tests

**Deliverable:** open_habit pulls health data and sends notifications via open_grid.

---

### Phase 6 — Hardening & Release

#### 6.1 Performance

- [ ] Benchmark: habit log time (100 habits)
- [ ] Benchmark: XP calculation (1000 achievements)
- [ ] Optimize: reduce Flutter IPC latency
- [ ] Memory profiling: ensure no leaks

#### 6.2 Security

- [ ] Verify encryption at rest (dump SQLite, confirm unreadable)
- [ ] Key rotation flow
- [ ] Secure deletion (overwrite keys on uninstall)
- [ ] Write security tests

#### 6.3 CI/CD

- [ ] GitHub Actions: Rust fmt, clippy, test (PR)
- [ ] GitHub Actions: Flutter analyze, test (PR)
- [ ] GitHub Actions: Cross-platform release (Android APK, iOS IPA, Linux AppImage, macOS DMG)
- [ ] Release artifacts attached to GitHub releases

#### 6.4 Documentation

- [ ] Update README with screenshots
- [ ] Developer guide (gamification rules engine)
- [ ] Integration guide (open_health, open_grid)
- [ ] Security model doc

#### 6.5 Publishing

- [ ] Publish Android APK to GitHub Releases
- [ ] Submit to F-Diff (if applicable)
- [ ] Submit to Amazon Appstore
- [ ] Write blog post / HN / r/productivity

**Deliverable:** v1.0 release on GitHub with binaries for Android, iOS, Linux, macOS.

---

## Dependencies Between Projects

| Feature | Depends on |
|---------|-----------|
| Health → Habit correlation | open_health (health data engine) |
| P2P challenge invitations | open_grid (mesh networking) |
| Wearable notifications | open_grid (BLE) + open_health (health data) |

These are future integrations. Phase 1–4 are fully self-contained.

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Habit log time | < 1 second |
| XP calculation (1000 achievements) | < 100ms |
| Streak detection accuracy | 100% |
| Challenge generation reproducibility | 100% (same seed → same result) |
| Crash-free sessions | > 99% |

---

## Open Questions

1. **Avatar evolution** — Should avatars be visual (images) or abstract (stats, badges)?
2. **Streak restoration cost** — Fixed (100 XP) or scaling (based on streak length)?
3. **Secret achievements** — How many? What triggers them? (Easter egg: "The Grid" achievement for using all 3 apps)
4. **Cross-app data** — How does open_habit access open_health data without coupling?
5. **Leaderboards** — Anonymous, hashed usernames? Opt-in? How to prevent cheating?
6. **Gamification fatigue** — How to prevent XP grind from feeling like work?

---

*Your habits shape your world. Make them legendary.*
