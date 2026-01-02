# Bumper — Build Log

*Historical record of what we built, decisions made, and learnings.*

---

## Session 1: Foundation

**Date:** 2026-01-01
**Duration:** ~2 hours
**Phase:** 1 (Foundation) → Complete

### What We Built

Created the entire Phase 1 foundation from a fresh Xcode project:

**Files Created (9):**
```
bumpers/
├── BumpersApp.swift
├── Design/Theme.swift
├── Features/Navigation/
│   ├── NavigationView.swift
│   └── NavigationViewModel.swift
├── Models/
│   ├── Destination.swift
│   └── TemperatureZone.swift
└── Services/
    ├── HapticService.swift
    ├── LocationService.swift
    └── NavigationCalculator.swift
```

**Files Removed (3):**
- `bumpersApp.swift` (template)
- `ContentView.swift` (template)
- `Item.swift` (template)

**Configuration:**
- Added `NSLocationWhenInUseUsageDescription` to build settings
- Set up SwiftData with Destination model
- Created folder structure (Features/, Services/, Models/, Design/)

### Key Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Start with services, not UI** | Built NavigationCalculator → LocationService → HapticService first | Services are the foundation. UI is just a shell around them. |
| **Hardcode test destination** | 180º Shop, Roma Norte | Enables immediate walk-testing without building destination entry UI. |
| **Use `@Observable`** | Not `ObservableObject` | iOS 17+ requirement already in spec. Modern pattern is cleaner. |
| **5 temperature zones** | Hot/Warm/Cool/Cold/Freezing | Balances granularity with simplicity. More zones = harder to distinguish haptics. |
| **Zone-based haptic timing** | 5s → 3s → 2s → 1.5s → 0.5s | Faster = more urgent. Natural mental model. |
| **Course correction "reward"** | 3s pause after improving zone | Prevents haptic spam when user oscillates. Feels like positive feedback. |
| **GPS course fallback** | Use `location.course` when heading unavailable | Compass fails indoors. GPS course works while walking. |

### Learnings

1. **Xcode 15+ uses file system sync** — No need to manually add files to project. Just create them in the right folder.

2. **Info.plist keys via build settings** — Modern Xcode generates Info.plist. Add keys as `INFOPLIST_KEY_*` build settings.

3. **CoreLocation needs explicit import in views** — NavigationView needed `import CoreLocation` to access `CLLocation.coordinate` properties.

4. **CHHapticEngine lifecycle is fragile** — Engine stops when app backgrounds. Need restart logic. Fallback to UIImpactFeedbackGenerator is essential.

5. **Deviation sign matters** — Positive = turn right, negative = turn left. This enables future directional orb shifting.

### Test Destination Verification

Verified 180º Shop coordinates via multiple sources:
- Google Maps: 19.4184425, -99.1762134
- Address: Colima 180, Roma Norte, Cuauhtémoc, 06700 CDMX
- Business: Concept store / clothing manufacturer

### What's Next

Phase 2: The Orb
- Replace emoji zone indicator with animated gradient orb
- Implement directional shift based on deviation sign
- Add pulse and bump animations

### Open Questions

1. **Haptic tuning** — Are the intensity/sharpness values right? Need real-world testing.
2. **Arrival radius** — 50m feels generous. Should it be 30m?
3. **Heading smoothing** — Raw heading values may be jittery. Consider rolling average.

---

## Session 2: Documentation Infrastructure

**Date:** 2026-01-01
**Duration:** ~30 min
**Phase:** Meta (docs setup)

### What We Built

Created comprehensive documentation system:

**Files Created (6):**
- `CLAUDE.md` — Project-specific Claude instructions
- `AGENTS.md` — Agent workflow instructions (expanded from beads template)
- `docs/SPEC.md` — Full specification
- `docs/PLAN.md` — Implementation phases with checkboxes
- `docs/ROADMAP.md` — Future ideas and directions
- `docs/BUILD-LOG.md` — This file

### Why We Did This

Before building the orb, we paused to establish:
- **Alignment** — What are we building and why?
- **Tracking** — What's done, what's next?
- **Knowledge preservation** — What did we learn?
- **Change management** — How to modify/upgrade/subtract effectively?

### Documentation Structure

```
bumpers/
├── CLAUDE.md        # Read first. Architecture, decisions, common tasks.
├── AGENTS.md        # How to work in this codebase. Landing the plane.
└── docs/
    ├── SPEC.md      # The full specification (source of truth)
    ├── PLAN.md      # Implementation progress (checkboxes)
    ├── ROADMAP.md   # Future ideas (not committed)
    └── BUILD-LOG.md # Session history (learnings)
```

### Key Insight

Documentation isn't overhead — it's **continuity insurance**. Next session (or next collaborator) can:
1. Read `CLAUDE.md` for quick orientation
2. Check `docs/PLAN.md` for what's done/next
3. Review `docs/BUILD-LOG.md` for context on past decisions

---

## Session 3: Orb + Tests

**Date:** 2026-01-01
**Duration:** ~60 min
**Phase:** 2 (The Orb) -> Complete

### What We Built

- Added `OrbView` with radial gradient, directional hotspot, and pulse/bump animation hooks
- Created `Animations.swift` with pulse and bump modifiers
- Wired orb into `NavigationView`, replacing the emoji zone indicator
- Added haptic bump trigger in `NavigationViewModel` and cached distance formatting
- Added unit tests for `NavigationCalculator` and `TemperatureZone`

### Key Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Orb bump trigger | Increment a simple `hapticPulseID` | Avoids tighter coupling between UI and haptic service |

### Learnings

1. Shared `MeasurementFormatter` instances reduce repeated allocations during view updates.
2. Swift Testing macros make it easy to validate navigation math deterministically.

### What's Next

Phase 3: Destination Entry (HomeView, SearchBar, WanderDial, navigation flow)

### Open Questions

1. Should the orb shadow/glow be tuned after real-device observation?

---

## Template: Future Sessions

Copy this template for new sessions:

```markdown
## Session N: [Title]

**Date:** YYYY-MM-DD
**Duration:** ~X hours
**Phase:** N ([Phase Name])

### What We Built

[List files created/modified]

### Key Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| | | |

### Learnings

1. [Learning]
2. [Learning]

### What's Next

[Next steps]

### Open Questions

1. [Question]
```

---

## Index of Decisions

Quick reference for why things are the way they are:

| Topic | Decision | Session |
|-------|----------|---------|
| Test destination | 180º Shop, Roma Norte | 1 |
| Zone count | 5 (hot → freezing) | 1 |
| Haptic fallback | UIImpactFeedbackGenerator | 1 |
| Course correction reward | 3s pause | 1 |
| Heading fallback | GPS course | 1 |
| Documentation structure | CLAUDE + AGENTS + docs/ | 2 |
