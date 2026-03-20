# CLAUDE.md

## Project

Bumper is a "hot or cold" iOS navigation app. Instead of turn-by-turn directions, it uses haptic feedback and a gradient orb to guide users toward their destination. Pick a place, pocket the phone, and haptic pulses tell you if you're getting warmer or colder. The name comes from bowling bumpers: you can bounce around, but you'll still get there.

- **iOS 17+**, SwiftUI-first, no external dependencies (pure Apple frameworks)
- **Bundle ID:** `samayd.bumpers`
- **Font:** Quicksand (variable TTF bundled in `bumpers/Fonts/`)
- **Targets:** `bumpers` (main app), `BumpersWidgetExtension` (Live Activity), `bumpersTests`, `bumpersUITests`

## Build & Test

```bash
# Build
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' build

# Unit tests (skip UI tests — they hang in CI)
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' \
  -skip-testing:bumpersUITests test -quiet

# UI tests only
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:bumpersUITests test -quiet

# Pre-grant location permission (avoids prompts blocking tests)
xcrun simctl privacy "iPhone 17" grant location samayd.bumpers
xcrun simctl privacy "iPhone 17" grant location-always samayd.bumpers

# Open in Xcode
open bumpers.xcodeproj
```

## Architecture

```
Services (pure logic, no UI)  ->  Models (data)  ->  ViewModels (state)  ->  Views (UI)
```

Don't skip layers. Views talk to ViewModels, not directly to Services.

**Services layer** — stateless calculators and system wrappers:
- `NavigationCalculator` — Haversine bearing, deviation, distance, arrival detection (50m radius), wander budget. All static methods.
- `LocationService` — `@Observable` CLLocationManager wrapper. Three update modes (precise/balanced/efficient) for battery optimization. Heading falls back from compass to GPS course.
- `HapticService` — Core Haptics engine with zone-based patterns and UIImpactFeedbackGenerator fallback.
- `LiveActivityManager` — ActivityKit lifecycle for Lock Screen + Dynamic Island. Local updates only (no push).

**Navigation flow:** `HomeView` (search) -> `WanderDialSheet` (time constraint) -> `NavigationView` (core experience) -> `ArrivalView` (celebration)

**The brain:** `NavigationViewModel` ties everything together. It owns the 0.5s timer that drives the update loop: track distance, sample journey points, update Live Activity, optimize location mode, check arrival, fire haptics. The "reward pause" (3s haptic silence after course correction) is intentional UX.

**Design system:** `Theme.swift` is the single source for colors, typography (all Quicksand via `Theme.quicksand(size:weight:)`), spacing tokens, animation presets, and orb visual constants. `TemperatureZone` owns its own colors, haptic intervals, pulse scales, and spring configs. `Interactions.swift` provides `.pressable()`, `.rowPressable()`, and `.staggeredEntrance()` modifiers.

**Shared code between targets:** `NavigationActivityAttributes` lives in `bumpers/Shared/` and is added to both the main app and widget extension targets. Zone is passed as a raw string to stay Codable.

## Navigation Math

```
bearing = haversine(current, destination)     // 0-360 degrees
deviation = normalize(heading - bearing)       // -180 to +180
zone = TemperatureZone.from(abs(deviation))   // hot/warm/cool/cold/freezing
```

Positive deviation = turn right. Negative = turn left. This is crow-flies bearing by design (no route following).

| Zone | Deviation | Haptic Interval | Pattern |
|------|-----------|-----------------|---------|
| Hot | 0-20 | 5s | Single gentle tap |
| Warm | 20-45 | 3s | Double tap |
| Cool | 45-90 | 2s | Triple tap |
| Cold | 90-135 | 1.5s | Triple tap (urgent) |
| Freezing | 135-180 | 0.5s | Continuous buzz |

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Foreground-only (no background mode) | Haptics require foreground. Screen stays on via `isIdleTimerDisabled`. |
| Crow-flies bearing, no routing | Core philosophy: user navigates obstacles, builds spatial awareness. |
| 5 temperature zones | Simple mental model maps cleanly to haptic patterns. |
| `@Observable` not `ObservableObject` | iOS 17+ only. Use `@State` to hold `@Observable` objects in views. |
| SwiftData for recent destinations | Simple structured persistence, ships with SwiftUI. |
| Live Activity uses raw strings for zone | `ContentState` must be `Codable`; avoids cross-target enum coupling. |

## Swift Rules

**Deprecated API — use modern equivalents:**
- `ObservableObject` + `@Published` -> `@Observable` macro
- `@StateObject` / `@ObservedObject` -> `@State` with `@Observable`
- `NavigationView` -> `NavigationStack`
- `.foregroundColor()` -> `.foregroundStyle()`
- `.onChange(of:)` single-param -> two-param `{ oldValue, newValue in }`
- implicit `.animation()` -> `.animation(_:value:)` with explicit value
- `AnyView` -> `@ViewBuilder` or conditional views

**Safety:**
- NEVER directly edit `.pbxproj`. Use Xcode or XcodeBuildMCP.
- View `body` max 100 lines. Extract subviews to avoid type-checker timeouts.
- No force-unwraps (`!`) in production code.
- `@MainActor` on ViewModels and any type driving UI state.
- Use Swift Testing (`#expect`, `#require`) for new tests.

## Simulator Limitations

- Haptics don't work — must test on real device
- Compass heading doesn't work — use GPS course (requires simulated movement) or mock
- Location can be simulated via Xcode: Features -> Location -> Custom Location

**Debug overlay:** Triple-tap on the navigation screen to show lat/lon, heading, bearing, deviation, zone, distance.

## Documentation

- `docs/PLAN.md` — Implementation phases with checkboxes (current status)
- `docs/SPEC.md` — Full product specification
- `docs/ROADMAP.md` — Future ideas
- `docs/BUILD-LOG.md` — Session history and learnings

## Issue Tracking

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress
bd close <id>
bd sync --flush-only  # End of session
```
