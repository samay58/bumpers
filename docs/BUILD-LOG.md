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
3. `xcodebuild test` can hang in this environment; running unit and UI suites separately is reliable (documented in `CLAUDE.md`).

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

## Session 4: Destination Entry (Phase 3)

**Date:** 2026-01-02
**Duration:** ~45 min
**Phase:** 3 (Destination Entry) → Complete

### What We Built

Created the destination entry flow with two new views:

**Files Created (2):**
```
bumpers/Features/Home/
├── HomeView.swift          # Main entry screen with search
└── WanderDialSheet.swift   # Time constraint selector
```

**Files Modified (2):**
- `BumpersApp.swift` — Changed entry point from NavigationView to HomeView
- `docs/PLAN.md` — Marked Phase 3 complete

### Key Features Implemented

**HomeView.swift:**
- "Where are you headed?" header
- MapKit search with MKLocalSearch integration
- Recent destinations list (SwiftData query, sorted by lastUsed)
- Search results with place icons and addresses
- Clear search button
- Selection triggers WanderDialSheet

**WanderDialSheet.swift:**
- Custom gesture-based horizontal slider
- "No rush" default (60 min position = no time constraint)
- Walk time estimate from current location
- Wander budget display with dynamic text
- Color-interpolated thumb (hot → warm gradient)
- NavigationStack integration to NavigationView
- Sheet presentation with drag indicator

### Key Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Search inline vs separate | Inline in HomeView | Simpler, less file overhead, search is single-use component |
| Wander dial as slider | Custom DragGesture | SwiftUI Slider lacks styling flexibility for dark UI |
| No rush threshold | 60 minutes | Generous upper bound, clear "take your time" message |
| Time constraint as nil | nil arrivalTime = no constraint | Clean API, ViewModel already handles nil case |

### Learnings

1. **Color interpolation requires UIColor bridge** — SwiftUI Color doesn't expose RGB components directly. Used UIColor.getRed() for interpolation.
2. **Sheet presentation in NavigationStack** — NavigationDestination inside sheet works seamlessly.
3. **MKLocalSearch is synchronous-feeling** — No debounce needed for typical typing speeds.

### Navigation Flow (Complete)

```
HomeView
  ├── Search → SearchResults → WanderDialSheet (sheet)
  └── Recents → WanderDialSheet (sheet)
                    ↓
              NavigationView (navigationDestination)
                    ↓
              Arrival (inline overlay) → dismiss()
```

### What's Next

Phase 5: Final Polish
- Launch screen
- App icon
- Accessibility labels

---

## Session 4 (continued): Arrival & Polish (Phase 4)

**Date:** 2026-01-02
**Duration:** ~30 min
**Phase:** 4 (Arrival & Polish) → In Progress

### What We Built

**Files Created (2):**
```
bumpers/Features/
├── Arrival/
│   └── ArrivalView.swift       # Quiet celebration screen
└── Shared/
    └── PermissionView.swift    # Location permission handler
```

**Files Modified (2):**
- `NavigationView.swift` — Added permission check, GPS accuracy, heading UX
- `NavigationViewModel.swift` — Simplified arrival handling

### Key Features Implemented

**ArrivalView.swift:**
- "You're here" message (quiet, not cheesy)
- Walk duration and distance stats
- Staggered entrance animations
- Warm glowing orb
- Done button → dismisses to HomeView

**PermissionView.swift:**
- Explains why location is needed
- "Allow Location Access" button (notDetermined)
- "Open Settings" button (denied)

**NavigationView Improvements:**
- GPS accuracy indicator (shows ±Xm when accuracy >30m)
- Animated heading calibration indicator
- Context-aware hint (compass vs GPS course)
- PermissionView integration

### Key Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Arrival tone | "You're here" not "You made it!" | Quiet celebration feels more elegant |
| GPS threshold | Show indicator at >30m | Below 30m is acceptable for walking |
| Permission flow | Inline in NavigationView | User sees it when they need it, not preemptively |

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
| Search integration | Inline in HomeView, not separate component | 4 |
| Wander dial | Custom gesture slider, not SwiftUI Slider | 4 |
| Time constraint | nil arrivalTime = "no rush" | 4 |
| Arrival tone | "You're here" (quiet, elegant) | 4 |
| GPS accuracy threshold | Show indicator at >30m | 4 |
| Permission flow | Inline in NavigationView | 4 |
| Battery modes | precise/balanced/efficient based on zone + distance | 5 |
| Tight schedule threshold | <5 min wander time triggers warning | 5 |

---

## Session 5: Final Polish (Phase 4-5)

**Date:** 2026-01-02
**Duration:** ~40 min
**Phase:** 4 (Complete) → 5 (In Progress)

### What We Built

**Battery Optimization (LocationService):**
- Added `UpdateMode` enum with three modes: precise, balanced, efficient
- `setMode(_:)` method dynamically adjusts distance and heading filters
- NavigationViewModel calls `updateLocationMode()` every 0.5s based on:
  - Zone (hot/warm = can use efficient mode)
  - Distance (<200m = use precise, >500m on-track = use efficient)

**Time Constraint Warning (WanderDialSheet):**
- Added `isTightSchedule` computed property (wander < 5 min)
- Shows orange "You'll need to walk directly" when tight

**Accessibility (NavigationView, ArrivalView):**
- Orb: dynamic label ("Hot. Turn right" etc.) + hint
- Distance, GPS accuracy, wander budget all labeled
- Journey stats in ArrivalView combine for VoiceOver

**Launch Screen:**
- Created `LaunchScreen.storyboard` with Theme.background color (#0A0A0A)

### Key Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Battery mode thresholds | <200m precise, >500m+on-track efficient | Balance UX and battery |
| Tight schedule | <5 min wander | Below this, user should walk directly |
| Accessibility grouping | Combine related stats | Cleaner VoiceOver experience |

### Learnings

1. **Dynamic CLLocationManager filters** — Can change `distanceFilter` and `headingFilter` at runtime; no restart needed.
2. **Accessibility element children** — Use `.accessibilityElement(children: .combine)` to group related UI elements for VoiceOver.

---

## Session 6: Code Review & Critical Fixes

**Date:** 2026-01-02
**Duration:** ~20 min
**Phase:** 5 (Final Polish) — Code Quality

### What We Built

Ran a comprehensive code review agent on the entire codebase and fixed all 4 critical issues identified.

### Critical Issues Fixed

| Issue | File | Fix |
|-------|------|-----|
| Timer RunLoop mode | NavigationViewModel.swift | Added timer to `.common` RunLoop mode so it continues during UI scrolling |
| Missing deinit cleanup | NavigationViewModel.swift | Added `deinit` to re-enable idle timer and invalidate haptic timer |
| Race condition in handlers | HapticService.swift | Wrapped `stoppedHandler` and `resetHandler` callbacks in `DispatchQueue.main.async` |
| Strong capture in closure | HapticService.swift | Changed `self` to `[weak self]` in `asyncAfter` fallback haptic |

### Code Changes

**NavigationViewModel.swift:**
```swift
// Timer fix: Add to .common mode
private func startHapticTimer() {
    let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
        self?.updateNavigation()
    }
    RunLoop.current.add(timer, forMode: .common)
    hapticTimer = timer
}

// Cleanup: Added deinit
deinit {
    UIApplication.shared.isIdleTimerDisabled = false
    hapticTimer?.invalidate()
}
```

**HapticService.swift:**
```swift
// Race condition fix: Dispatch to main queue
engine?.stoppedHandler = { [weak self] reason in
    DispatchQueue.main.async {
        self?.isEngineRunning = false
    }
}

// Strong capture fix: Use weak self
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
    self?.impactMedium.impactOccurred()
}
```

### Learnings

1. **Timer RunLoop modes** — `.default` mode pauses during UI interaction (scrolling). Use `.common` for timers that must run continuously.
2. **CHHapticEngine callbacks** — `stoppedHandler` and `resetHandler` are called on arbitrary threads; always dispatch UI/state changes to main queue.
3. **Capture semantics** — Even short-lived closures like `asyncAfter` should use `[weak self]` to prevent potential retain cycles.

### Code Review Summary

The code reviewer agent analyzed 16 source files and identified:
- 4 Critical issues (all fixed)
- 9 Improvements (documented for future)
- 6 Suggestions (nice-to-haves)

### What's Next

- Walk testing in Roma Norte
- Consider implementing suggested improvements from code review

---

## Session 7: App Icon

**Date:** 2026-01-02
**Duration:** ~5 min
**Phase:** 5 (Final Polish) — Visual

### What We Built

Added the app icon to the project. The icon features the signature "orb" design — a warm orange/amber center radiating through blue/purple rings on a dark background, perfectly matching the app's hot-cold navigation metaphor.

### Source File Analysis

Examined `~/Downloads/bumpers-app-icon-raw-needs-editing.png`:

| Property | Value | Assessment |
|----------|-------|------------|
| Dimensions | 1024x1024 | Exact iOS requirement |
| Format | PNG, RGB | Correct (no alpha required) |
| Alpha | None | Correct for app icons |
| Pre-baked corners | Yes (iOS-style squircle) | Acceptable — iOS mask overlays anyway |

### Files Changed

**Added:**
- `bumpers/Assets.xcassets/AppIcon.appiconset/AppIcon.png` (1.1MB)

**Modified:**
- `bumpers/Assets.xcassets/AppIcon.appiconset/Contents.json` — Added filename reference for regular and dark mode slots

### Configuration

The asset catalog uses iOS 18's modern single-icon format with appearance variants:
- **Regular**: `AppIcon.png` (used for light mode)
- **Dark**: `AppIcon.png` (same icon works well due to dark design)
- **Tinted**: Empty (system applies tint automatically)

### Verification

- Build succeeded with no asset warnings
- `actool` processed assets without errors

### Learnings

1. **iOS app icon masks** — iOS applies its own superellipse mask; pre-baked rounded corners in source files are acceptable as long as the image fills the full 1024x1024 canvas.
2. **Modern asset catalogs** — iOS 18+ uses a single 1024x1024 image with appearance variants; Xcode generates all required sizes automatically.

---

## Session 9: Typography — Quicksand

**Date:** 2026-01-02
**Duration:** ~20 min
**Phase:** 5 (Final Polish) — Visual

### What We Built

Replaced system fonts with Quicksand — a rounded geometric sans-serif that gives the app a warm, friendly feel matching the "hot/cold" navigation metaphor.

### Why Quicksand

| Property | Benefit |
|----------|---------|
| Rounded terminals | Matches the orb's soft glow aesthetic |
| Geometric forms | Clean, modern, crisp |
| Light weights available | Maintains the minimal, elegant feel |
| Variable font | Single file, all weights (300-700) |
| Open source | SIL Open Font License |

### Files Added/Changed

**Added:**
- `bumpers/Fonts/Quicksand-Variable.ttf` (125KB)
- `Info.plist` (at project root) — UIAppFonts registration

**Modified:**
- `bumpers.xcodeproj/project.pbxproj` — INFOPLIST_FILE reference
- `bumpers/Design/Theme.swift` — Custom font helper + updated typography

### Typography Scale (Updated)

```swift
titleFont    = Quicksand 22pt Light
headlineFont = Quicksand 18pt Regular
bodyFont     = Quicksand 16pt Medium
captionFont  = Quicksand 14pt Regular
debugFont    = SF Mono 11pt Medium (unchanged)
```

### Implementation Details

1. **Variable font approach** — Single `Quicksand[wght].ttf` file supports all weights (300-700). iOS applies weight via `.weight()` modifier.

2. **Info.plist placement** — Must be at project root, NOT inside the auto-synced `bumpers/` folder, to avoid duplicate resource conflict.

3. **Font registration** — `UIAppFonts` array in Info.plist with filename (not font name).

4. **Font name in code** — Use `"Quicksand"` (the PostScript name), not the filename.

### Learnings

1. **Google Fonts repo structure changed** — No longer has static TTF files; only variable fonts. Use `Quicksand[wght].ttf` URL-encoded as `Quicksand%5Bwght%5D.ttf`.

2. **FileSystemSynchronizedRootGroup gotcha** — Info.plist inside a synced folder gets copied as a resource AND processed as Info.plist, causing duplicate output error.

3. **Variable fonts in SwiftUI** — Use `Font.custom("FontName", size:).weight(.light)` — the weight modifier works with variable fonts.

### Verification

```bash
# Font in bundle
ls bumpers.app/Quicksand-Variable.ttf  # ✓ exists

# Info.plist configured
plutil bumpers.app/Info.plist | grep UIAppFonts  # ✓ array with font
```

### Sources

- [Google Fonts - Quicksand](https://fonts.google.com/specimen/Quicksand)
- [Google Fonts GitHub](https://github.com/google/fonts/tree/main/ofl/quicksand)

---

## Session 8: Visual Polish & Performance

**Date:** 2026-01-02
**Duration:** ~90 min
**Phase:** 5 (Final Polish) — UX Quality

### What We Built

Complete visual and performance overhaul of the orb, transforming it from "functional" to "premium." Also updated test destination for tomorrow's Temazcal trip.

### Changes Summary

**Test Destination:**
- Changed from 180º Shop (Roma Norte) to Starbucks Condesa (Alfonso Reyes 218)
- Coordinates: `19.4074986, -99.1738171`
- Temazcal pickup point for tomorrow

**iOS Compatibility:**
- Lowered deployment target from 26.2 → 17.0
- Now works on user's iPhone (iOS 26.1)

**Visual Polish (Rauno Freiberg-inspired):**
- Multi-layer shadow system (ambient + glow)
- Zone-responsive gradient falloff (steeper for cold zones)
- Highlight reflection (3D glass effect)
- Enhanced directional shift (X + Y movement)

**Performance Optimization:**
- Animation timing halved (0.6s → 0.3s, 2.0s → 1.2s)
- Snappier springs (0.5s → 0.25s response, 0.8 → 0.7 damping)
- Unified OrbScaleModifier (combines pulse + bump)
- Reduced shadows (3 → 2 layers, smaller radii)
- Added `.drawingGroup()` for GPU-backed rendering

### Files Modified

| File | Changes |
|------|---------|
| `Models/Destination.swift` | New test destination (Starbucks Condesa) |
| `Design/Theme.swift` | +OrbShadow system, +OrbGradient constants, +snappySpring, faster timings |
| `Design/Animations.swift` | +OrbScaleModifier (unified), snappier springs |
| `Models/TemperatureZone.swift` | +isUrgent, +pulseScale, +bumpSpring, +gradientFalloff |
| `Features/Navigation/OrbView.swift` | Layered shadows, highlight, .drawingGroup() |
| `docs/TEST-GUIDE.md` | Updated destination |
| `CLAUDE.md` | Updated destination reference |

### Key Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Shadow count | 2 layers (was 3) | Performance; 3 large blurs caused frame drops |
| Animation response | 0.25s (was 0.5s) | Immediate feedback feels premium |
| Unified scale modifier | Combined pulse + bump | Prevents animation conflicts |
| `.drawingGroup()` | GPU-backed rendering | Smooth 60fps during transitions |
| Pulse duration | 1.2s (was 2.0s) | Faster breathing feels more alive |

### Learnings

1. **Multiple `.animation()` modifiers conflict** — When zone and directionShift change simultaneously, two animation contexts fight. Unified modifier solves this.

2. **Shadow blur radius impacts performance** — Each shadow with radius N requires O(N²) GPU work. Reducing from 60+24+12 to 40+16 cut compositing cost by ~60%.

3. **`.drawingGroup()` is essential for gradient animations** — Renders to Metal texture, prevents CPU-GPU sync stalls during color transitions.

4. **Spring damping below 0.7 feels snappy** — 0.8 damping is "floaty," 0.6-0.7 is "immediate." Use lower damping for UI feedback.

5. **Zone-responsive animation parameters** — Freezing zone uses snappier spring (0.15s, 0.55 damping) vs hot zone (0.35s, 0.75 damping). Urgency should feel urgent.

### Performance Before/After

```
METRIC                  BEFORE          AFTER
─────────────────────────────────────────────────
Gradient transition     0.6s easeInOut  0.3s easeOut
Pulse cycle             2.0s            1.2s
Spring response         0.5s            0.25s
Shadow layers           3               2
Shadow blur total       96px            56px
Animation conflicts     Yes (2 modifiers) No (unified)
GPU optimization        None            .drawingGroup()
```

### What's Next

- [ ] Walk test to Starbucks Condesa (Temazcal pickup)
- [ ] Tune haptic timing based on real-world feel
- [ ] Consider asymmetric pulse (slow expand, quick contract)
- [ ] Add subtle opacity flash on bump

---

## Session 10: Journey Trail

**Date:** 2026-01-02
**Duration:** ~25 min
**Phase:** 5 (Final Polish) — Feature

### What We Built

Added journey visualization on arrival: a minimal dark map showing your actual walking path colored by temperature zone, plus a "wander factor" showing how much you explored vs. direct route.

### Why This Feature

| Problem | Solution |
|---------|----------|
| Arrival shows flat stats | Show the actual path walked |
| Journey "story" is lost | Trail colored by zone tells the story |
| No replay value | Wander factor gamifies exploration |

### Files Added

| File | Purpose |
|------|---------|
| `Models/JourneyPoint.swift` | Single sampled point (coordinate, timestamp, zone) |
| `Models/Journey.swift` | Container with computed properties (wanderFactor, segmentsByZone) |
| `Features/Arrival/JourneyMapView.swift` | MapKit visualization with colored polylines |

### Files Modified

| File | Changes |
|------|---------|
| `NavigationViewModel.swift` | Added journey sampling (every 10m or zone change) |
| `ArrivalView.swift` | Added map + wander factor stat |
| `NavigationView.swift` | Pass journey to ArrivalView |

### Sampling Strategy

Points sampled when ANY condition is met:
- First point (journey start)
- Moved 10+ meters from last sample
- Zone changed (captures turning points)
- 30 seconds elapsed (fallback for stationary periods)

### Map Design

- Dark map style (matches app theme)
- Colored polylines per zone (uses existing `TemperatureZone.colors.inner`)
- Dashed white line for crow-flies comparison
- Small dots for start/end points
- Non-interactive (pure visualization)
- Auto-fits to journey bounds with 40% padding

### Wander Factor

- Formula: `actualDistance / directDistance`
- Only shown if > 1.05 (meaningfully more than direct)
- Displayed as "1.4×" (you walked 1.4x the direct route)
- Framed positively: higher = more exploration

### Edge Cases

- Short walks (< 3 points): Map hidden, just show stats
- Direct walks (< 1.05×): Wander factor hidden
- GPS drift: 10m threshold prevents jitter sampling

---

## Session 11: Premium UX Overhaul (Lumy-Inspired)

**Date:** 2026-01-02
**Duration:** ~60 min
**Phase:** 5 (Final Polish) — Micro-Interactions

### What We Built

Researched Lumy app (sun/moon tracker) and implemented premium micro-interactions across the app.

**Research Findings:**
- Lumy uses data-rich minimalism, VFX-grade polish, haptic-visual sync
- Every interaction feels intentional and connected to metaphor
- "Window to outside world" design philosophy

**Files Created (1):**
- `Design/Interactions.swift` — Reusable interaction modifiers

**Files Modified (4):**
- `HomeView.swift` — Added `.rowPressable()` + staggered search animations
- `WanderDialSheet.swift` — Added haptic ticks + hero transition (growing orb)
- `ArrivalView.swift` — Added `.pressable()` + haptic crescendo trigger
- `CLAUDE.md` — Documented micro-interaction patterns

### Key Features Implemented

**Interaction Modifiers:**
```swift
.pressable()           // Scale 0.96 + selection haptic on press
.rowPressable()        // Warm background highlight + haptic
.staggeredEntrance()   // Fade-in with index-based delay
```

**WanderDial Haptic Ticks:**
- Selection haptic every 5-minute slider increment
- Tracked via `lastTickValue` state

**Hero Transition (Start → Navigation):**
- Start button morphs into growing orb
- RadialGradient scales from 0.3 → 3.5
- Other UI elements fade out during transition

**Arrival Haptic Crescendo:**
- HapticService already had `playArrival()` with 4-stage intensity
- Now triggered via `hapticService.playArrival()` on ArrivalView appear

### Learnings

1. **State-based hero transitions** — When `matchedGeometryEffect` is impractical (sheet → navigation), use state-driven scaling + opacity.

2. **Haptic tick tracking** — Track `lastTickValue` separately to fire haptics only on threshold crossing.

3. **Staggered animations** — `delay(Double(index) * 0.05)` creates premium cascading effect.

---

## Session 12: App Icon (Fire/Wave Design)

**Date:** 2026-01-02
**Duration:** ~10 min
**Phase:** 5 (Final Polish) — Visual

### What We Built

Replaced placeholder app icon with ChatGPT-generated fire/wave yin-yang design — perfect metaphor for "hot or cold" navigation.

### Image Processing

| Step | Action |
|------|--------|
| Source | `~/Downloads/ChatGPT Image Jan 2, 2026...png` (1024x1024) |
| Issue | Black background padding around icon |
| Fix | `magick -fuzz 5% -trim` to extract content (876x862) |
| Resize | Scaled to fill 1024x1024 canvas |
| Background | Extended with orange (#E07830) matching border |
| Output | `AppIcon.png` in asset catalog |

### Files Modified

- `bumpers/Assets.xcassets/AppIcon.appiconset/AppIcon.png` — New icon

### Design Alignment

| Element | Icon | App |
|---------|------|-----|
| Fire | Orange/red swirls | Hot zone gradient |
| Waves | Blue/white swirls | Cold zone gradient |
| Yin-yang | Duality balance | Hot ↔ Cold navigation |

---

## Session 13: Live Activity Widget (Lock Screen + Dynamic Island)

**Date:** 2026-01-02
**Duration:** ~45 min
**Phase:** 5 (Final Polish) — Feature

### What We Built

Real-time navigation status on Lock Screen and Dynamic Island (iPhone 14 Pro+).

**Why Live Activity (not Home Screen Widget):**
- Designed for ongoing activities (navigation, delivery)
- Updates every 0.5-2s (not limited like widgets)
- iOS 16.1+ (Bumpers targets 17.0)
- Appears without unlocking phone

### Architecture

```
Main App                          Widget Extension
───────────────────────────────   ─────────────────────────────
LiveActivityManager.swift         BumpersWidgetBundle.swift
  ├─ startNavigation()            NavigationLiveActivity.swift
  ├─ updateNavigation()             ├─ Lock Screen view
  └─ endNavigation()                ├─ Dynamic Island compact
                                    ├─ Dynamic Island expanded
NavigationActivityAttributes.swift  └─ Dynamic Island minimal
(shared between both targets)
```

### Files Created (5)

| File | Target | Purpose |
|------|--------|---------|
| `bumpers/Shared/NavigationActivityAttributes.swift` | Both | Activity data model |
| `bumpers/Services/LiveActivityManager.swift` | Main | Start/update/end lifecycle |
| `BumpersWidget/BumpersWidgetBundle.swift` | Widget | Entry point |
| `BumpersWidget/NavigationLiveActivity.swift` | Widget | Lock Screen + Dynamic Island |
| `BumpersWidget/NavigationActivityAttributes.swift` | Widget | Copy for widget target |

### Files Modified (3)

| File | Changes |
|------|---------|
| `NavigationViewModel.swift` | Added `liveActivityManager`, triggers on start/update/arrival |
| `Info.plist` | Added `NSSupportsLiveActivities = true` |
| `CLAUDE.md` | Updated architecture + Live Activity section |

### Key Implementation Details

**Data Model:**
```swift
struct NavigationActivityAttributes: ActivityAttributes {
    let destinationName: String

    struct ContentState: Codable, Hashable {
        let zone: String        // "hot", "warm", etc.
        let distanceMeters: Double
    }
}
```

**ViewModel Integration:**
```swift
// On navigation start
liveActivityManager.startNavigation(destinationName: destination.name, zone: zone, distance: distance)

// Every 0.5s update
liveActivityManager.updateNavigation(zone: zone, distance: distance)

// On arrival
liveActivityManager.endNavigation(showFinalState: true)
```

**Lock Screen Layout:**
```
┌────────────────────────────────────────┐
│  ●  On Track              245m away   │
│  ↓ Starbucks Condesa                  │
└────────────────────────────────────────┘
```

**Dynamic Island Compact:**
```
     [ ● ]─────────────[ 245m ]
```

### Key Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Foreground-only | No background location | Keeps current design; shows stale state when backgrounded |
| Minimal display | Zone + distance only | Glanceable; no cognitive load |
| No App Groups | Direct Activity.update() | Main app controls updates; widget doesn't need independent data |
| Zone colors | Match Theme.swift palette | Visual consistency |

### Learnings

1. **Live Activities can't access location** — Widget extensions are sandboxed. Main app must share data via Activity.update() or App Groups.

2. **Widget extension is separate target** — Requires Xcode: File → New → Target → Widget Extension. Check "Include Live Activity."

3. **Shared models** — `ActivityAttributes` must be identical in both targets. Copy file or use shared framework.

4. **Activity lifecycle** — 8-hour max on Dynamic Island, 12-hour on Lock Screen. `endNavigation()` with `dismissalPolicy: .after(5s)` shows final state briefly.

5. **No animations** — Live Activity updates are discrete snapshots, not continuous animations.

### Testing Notes

- **Simulator:** Limited support (Lock Screen only, no Dynamic Island)
- **Device:** Full testing requires iPhone 14 Pro+ for Dynamic Island
- **Stale state:** Background app → Activity shows last-known state

---

## Session 14: Widget Debug & Visual Polish

**Date:** 2026-01-02
**Duration:** ~30 min
**Phase:** 5 (Final Polish) — Bug Fix + Enhancement

### Issue

Widget extension failing with:
```
Failed to get descriptors for extensionBundleID (samayd.bumpers.BumpersWidget)
```

### Root Cause

Widget extension's **Sources build phase was empty** — Swift files existed in `/BumpersWidget/` but weren't added to Xcode's compile sources. SpringBoard couldn't discover the extension without compiled code.

### Fixes Applied

**1. Xcode Configuration (Manual)**
- Added 3 Swift files to BumpersWidgetExtension → Build Phases → Compile Sources
- Fixed deployment target: iOS 26.2 → iOS 17.0 (matching main app)
- Added `NSSupportsLiveActivities = true` to widget Info.plist

**2. Aura-Like Gradients (NavigationLiveActivity.swift)**
- Lock Screen: Radial gradient glow emanating from zone indicator
- Zone indicator: Blur glow behind it (0.4 opacity, 14px blur)
- Dynamic Island expanded: Zone indicator has 52px glow cloud
- Typography bumped to `.semibold` / `.bold`

**3. Bolder Navigation Typography (NavigationView.swift)**
- Destination: `17pt .light` → `18pt .medium` + 85% opacity
- Distance: `52pt .ultraLight` → `48pt .regular`

### Files Modified

| File | Changes |
|------|---------|
| `BumpersWidget/NavigationLiveActivity.swift` | Radial gradients, blur glows, bolder fonts |
| `BumpersWidget/Info.plist` | Added `NSSupportsLiveActivities` |
| `bumpers/Features/Navigation/NavigationView.swift` | Bolder typography |
| Xcode project | Fixed widget compile sources |

### Status

⚠️ **Widget needs device testing** — Compile sources now configured, builds succeed. Lock Screen + Dynamic Island visual polish applied. Needs real-device verification.

### What's Next

- Device test Live Activity (especially Dynamic Island on iPhone 14 Pro+)
- Verify distance syncs correctly between NavigationView and Live Activity
- Continue with Phase 5 testing checklist

---

## Session 15: Route-Aware Corridor + Pocket Haptics

**Date:** 2026-04-27
**Duration:** ~1 focused build cycle
**Phase:** 6 (Route-Aware V2) — Implementation complete, validation pending

### What We Built

Pivoted Bumper from a pure crow-flies compass into a route-aware soft corridor prototype.

**Files Created:**
- `RouteService.swift` — MapKit walking routes with alternate route support
- `WalkingRoute.swift` — Route geometry, nearest projection, progress, and corridor width
- `CorridorNavigationEngine.swift` — In-lane, drifting, off-course, wrong-way, low-confidence, arrived, and fallback states
- `DestinationSearchService.swift` / `DestinationSearchViewModel.swift` — Debounced location-aware search with stale result suppression
- `HapticProfile.swift` / `HapticPatternFactory.swift` / `HapticCalibrationService.swift` — Pocket-first haptic vocabulary and calibration
- `HapticCalibrationView.swift` — First-run haptic teach/test flow
- `NavigationMode.swift`, `CorridorState.swift`, `SearchModels.swift`
- `DestinationRows.swift`, `NavigationModePicker.swift`
- `docs/WALK-TESTS.md`
- `docs/assets/github-cover.png`
- V2 unit test files for navigation, haptics, search, and ETA states

**Files Modified:**
- `NavigationViewModel.swift` now orchestrates route loading, corridor instructions, haptic cooldowns, Live Activity updates, and rerouting. Corridor decisions live in `CorridorNavigationEngine`.
- `HomeView.swift` no longer owns raw MapKit search logic and now renders/resolves MapKit suggestions through `DestinationSearchViewModel`.
- `WanderDialSheet.swift` now uses shared location, route ETA, navigation modes, and calibration.
- `HapticService.swift` now plays patterns generated by `HapticPatternFactory`.
- `ArrivalView.swift` no longer double-plays arrival haptics.
- `Assets.xcassets/AppIcon.appiconset/AppIcon.png` now uses the updated 1024px transparent icon.
- `README.md`, `CLAUDE.md`, `HAPTICS.md`, `docs/SPEC.md`, `docs/PLAN.md`, `docs/ROADMAP.md`, and `AGENTS.md` now describe V2.

### Key Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Navigation brain | Route-aware corridor primary, crow-flies fallback only | Keeps wandering while avoiding bad geometry-only nudges |
| Sign convention | `targetBearing - currentHeading`; positive means correct right | Aligns navigation math, accessibility, orb shift, and haptics |
| Haptic language | Short-long = right, long-short = left | Duration order should survive pockets better than intensity ramps |
| On-track feedback | Silence by default | Silence becomes success; avoids haptic nagging |
| ETA | MapKit walking ETA first, rough straight-line fallback only when labeled | Removes the fake 15-minute estimate |
| Search | Dedicated service/view model with debounce, cancellation, and region hints | Keeps HomeView small and prevents stale result flashes |
| Low confidence | Suppress directional haptics | Better to be quiet than confidently wrong |
| Arrival | Debounced by location only, not heading | A stationary user at the destination should still arrive |

### Verification

- Added tests for correction sign, route projection, corridor states, wrong-way detection, arrival debounce, stale search suppression, ETA labels, and haptic pattern shape.
- Direct Swift typecheck passed for app Swift files after the V2 changes.
- `xcodebuild` is currently blocked by the local Xcode platform install: the iOS 26.4.1 simulator/platform download is still in progress, and the available runtime build does not match the 26.4 SDK asset catalog tool.
- Real-device walk tests remain required before treating V2 as product-validated.

### Learnings

1. The route corridor belongs in pure model/service code, not inside `NavigationViewModel`. The view model should orchestrate services and state, not become the navigation engine.
2. Arrival should be based on location confidence and dwell time, not heading. Heading is needed for directional correction, not for detecting that the user is already there.
3. Pocket haptics need inspectable pattern descriptors. Unit tests can verify left/right duration order and profile intensity before any subjective device tuning.
4. Search needs cancellation and stale-result suppression as first-class behavior. Without it, MapKit can make the UI feel cheap even when the result data is good.
5. The V1 field guide was useful history but became dangerous as active documentation. V2 now has a separate walk-test protocol with kill/pivot criteria.

### What's Next

1. Finish the local iOS 26.4.1 simulator download, then run the Xcode build and unit tests on a concrete simulator.
2. Run the V2 walk-test matrix in `docs/WALK-TESTS.md`.
3. If front-pocket haptics fail the kill gate, pivot toward Apple Watch or wearable-first haptics.

---

## Session 16: Onboarding Reliability + Navigation Legibility

**Date:** 2026-04-27
**Duration:** ~1 focused cleanup pass
**Phase:** 6 (Route-Aware V2) — Device UX hardening

### Issue

Real-device feedback exposed two core product problems:

- The first-run haptic calibration felt flaky and low-trust. The intro `Start` action could appear to do nothing, and the whole flow read like a nested prototype rather than a coherent onboarding step.
- The navigation orb could look dead while the system was actually working, because V2 intentionally keeps the orb calm while the user is still inside the route corridor.

### Root Cause

The calibration flow was presented as a nested `.sheet` from `WanderDialSheet`, while the parent sheet continued updating location and ETA state underneath it. That made the calibration UI feel transient and weakly owned. The flow logic also lived inside the view's local `@State`, so there was no testable state machine for step progression.

Separately, the navigation screen relied on the orb alone to communicate state. In corridor mode, `inLane` correctly returns no correction, but the UI did not make that calm state explicit enough.

### Fixes Applied

**1. Extracted calibration flow state**
- Added `HapticCalibrationFlow.swift` as a deterministic state machine for intro → right cue → left cue → completion.
- Added `HapticCalibrationFlowTests.swift` covering start, replay, progression, and completion profile selection.

**2. Rebuilt first-run calibration inside WanderDial**
- Removed the nested calibration `.sheet`.
- `WanderDialSheet` now has an explicit staged flow: undecided → calibration → planning.
- Profile completion and skip both transition back into the main wander setup cleanly without reopening.

**3. Reworked calibration UI**
- `HapticCalibrationView` is now driven by the extracted flow model instead of managing its own private onboarding state.
- Added clearer progress language, more explicit cue copy, cleaner button labeling, and a more intentional visual hierarchy.

**4. Made calm navigation states legible**
- Added a subtle navigation status chip to `NavigationView` so `In lane`, `GPS uncertain`, `Simple direction guidance`, and correction states are visible without opening debug.
- Added a small label helper on `CorrectionDirection` for clean user-facing copy.

**5. Cleaned up new warnings**
- Removed the actor-isolated default-initializer warnings added around `NavigationViewModel` dependency defaults by moving service construction into the `@MainActor` initializer body.

### Verification

- `xcodebuild -scheme bumpers -destination id=1EE1C676-F263-4002-A04A-4DB9907DC54D -derivedDataPath /tmp/bumpers-dd -only-testing:bumpersTests test` passed.
- New `HapticCalibrationFlowTests` passed alongside the existing V2 navigation, search/ETA, and haptic tests.
- `docs/WALK-TESTS.md` now explicitly documents that in corridor mode, stationary rotation may leave the orb visually calm while status remains `In lane`.

---

## Index of Decisions (Updated)

| Topic | Decision | Session |
|-------|----------|---------|
| V2 navigation brain | Route-aware soft corridor, crow-flies fallback only | 15 |
| V2 haptic language | Short-long corrects right, long-short corrects left | 15 |
| V2 search architecture | Dedicated debounced service/view model with cancellation | 15 |
| ETA display | MapKit direct ETA first; rough fallback must be labeled | 15 |
| Low-confidence behavior | Suppress directional haptics | 15 |
| Arrival detection | Dynamic radius with 3s dwell; heading not required | 15 |
| Widget typography | Semibold/bold weights | 14 |
| Widget aura effects | Radial gradients + blur glows | 14 |
| Live Activity | Lock Screen + Dynamic Island, foreground-only | 13 |
| App icon | Fire/wave yin-yang design | 12 |
| Micro-interactions | Pressable modifiers, haptic ticks, hero transition | 11 |
| Journey Trail | Colored path map + wander factor on arrival | 10 |
| Test destination | Starbucks Condesa (was 180º Shop) | 8 |
| iOS deployment target | 17.0 (was 26.2) | 8 |
| Shadow layers | 2 (ambient + glow) | 8 |
| Animation response | 0.25s snappy spring | 8 |
| Unified animation | OrbScaleModifier | 8 |
| GPU rendering | .drawingGroup() | 8 |
| Zone count | 5 (hot → freezing) | 1 |
| Haptic fallback | UIImpactFeedbackGenerator | 1 |
| Course correction reward | 3s pause | 1 |
| Battery modes | precise/balanced/efficient | 5 |
