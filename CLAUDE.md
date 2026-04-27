# CLAUDE.md

## Project

Bumper is an iOS walking app for wandering toward a place without staring at a route. It uses MapKit walking routes internally to create a loose corridor, then gives haptic correction only when the user drifts meaningfully away or starts making bad progress. The route is never exposed as turn-by-turn navigation.

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
- `RouteService` — MapKit walking directions wrapper. Requests alternate walking routes and returns route geometry plus ETA/distance metadata.
- `RouteCorridor` / `CorridorNavigationEngine` — Projects the user onto the route corridor, tracks progress, classifies confidence and drift, and emits `CorrectionInstruction`.
- `DestinationSearchService` — Location-aware MapKit search/completer service with stale-result suppression through `DestinationSearchViewModel`.
- `HapticPatternFactory` / `HapticService` — Pocket-first duration-rhythm haptic patterns with Core Haptics playback and UIKit fallback.
- `LiveActivityManager` — ActivityKit lifecycle for Lock Screen + Dynamic Island. Local updates only (no push).

**Navigation flow:** `HomeView` (search) -> `WanderDialSheet` (time + looseness + calibration) -> `NavigationView` (corridor guidance) -> `ArrivalView` (stats)

**The brain:** `NavigationViewModel` orchestrates services only. It owns the 0.5s loop, route loading/rerouting, journey sampling, Live Activity updates, location-mode tuning, arrival transition, and haptic cooldown. Corridor decisions live in `CorridorNavigationEngine`, not in the view model.

**Design system:** `Theme.swift` is the single source for colors, typography (all Quicksand via `Theme.quicksand(size:weight:)`), spacing tokens, animation presets, and orb visual constants. `TemperatureZone` owns visual temperature colors and animation tuning. Haptic timing lives in `HapticPatternFactory`. `Interactions.swift` provides `.pressable()`, `.rowPressable()`, and `.staggeredEntrance()` modifiers.

**Shared code between targets:** `NavigationActivityAttributes` lives in `bumpers/Shared/` and is added to both the main app and widget extension targets. Zone is passed as a raw string to stay Codable.

## Navigation Logic

```
route = MapKit walking route(s)
corridor = route geometry + NavigationMode width
projection = nearest route point + route progress
instruction = corridor distance + progress trend + confidence + heading/course
```

Primary mode is route-aware corridor guidance. Crow-flies bearing is fallback only when MapKit route lookup fails or confidence is too poor for corridor guidance.

The sign convention is:

```
deviation = normalize(targetBearing - currentHeading)
positive deviation = correct right
negative deviation = correct left
```

`CorrectionDirection.from(deviation:)` is the source of truth for sign mapping.

| Mode | Label | Baseline Corridor |
|------|-------|-------------------|
| `direct` | Keep me close | 35m |
| `roomToWander` | Give me space | 75m |
| `scenic` | Let me drift | 125m |

Confidence rules:
- Horizontal accuracy worse than 50m suppresses directional haptics.
- If heading is unavailable and walking speed is below 0.7 m/s, wait for course instead of guessing.
- Arrival requires staying inside the dynamic arrival radius for 3 seconds.

Haptic language:
- On track is silent by default.
- Correct right: short pulse, gap, long pulse.
- Correct left: long pulse, gap, short pulse.
- Strong corrections repeat the signature.
- Wrong way is long rumble plus directional signature.

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Foreground-only (no background mode) | Haptics require foreground. Screen stays on via `isIdleTimerDisabled`. |
| Route-aware soft corridor | Preserves wandering while avoiding stupid crow-flies nudges through buildings and street-grid constraints. |
| Crow-flies fallback | Honest degradation when MapKit routing fails. UI shows "Using simple direction guidance." |
| Pocket-first haptics | Duration rhythm survives clothing better than subtle intensity ramps. |
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
- Prefer item-driven sheets (`.sheet(item:)`) when a selected model drives presentation.
- Cancel stale async tasks before starting replacement MapKit searches or route estimates.
- Use Swift Testing (`#expect`, `#require`) for new tests.

## Simulator Limitations

- Haptics don't work — must test on real device
- Compass heading doesn't work — use GPS course (requires simulated movement) or mock
- Location can be simulated via Xcode: Features -> Location -> Custom Location

**Debug overlay:** Triple-tap on the navigation screen to show lat/lon, heading, bearing, deviation, zone, distance, corridor/simple mode, confidence, and navigation mode.

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
