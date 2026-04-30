# Bumper — Implementation Plan

*Last updated: 2026-04-30*

---

## Overview

This document tracks implementation progress. Check boxes indicate completion.

**Current Phase:** Phase 6 (Route-Aware V2 validation)
**Overall Progress:** Phase 1-5 complete, Phase 6 implementation complete; simulator and device validation pending

---

## Phase 1: Foundation ✅ COMPLETE

**Goal:** Build the three core services that power everything.

### Services Layer

- [x] **NavigationCalculator.swift**
  - [x] `bearing(from:to:)` — Haversine formula
  - [x] `normalizeAngle(_:)` — Range -180 to 180
  - [x] `deviation(currentHeading:targetBearing:)` — Signed deviation
  - [x] `estimatedWalkingTime(meters:)` — 5 km/h assumption
  - [x] `distance(from:to:)` — CLLocation wrapper
  - [x] `hasArrived(current:destination:)` — 50m radius check
  - [x] `wanderBudget(...)` — Time constraint calculation

- [x] **LocationService.swift**
  - [x] `@Observable` class
  - [x] Location permission request
  - [x] Location updates (5m distance filter)
  - [x] Heading updates (5° filter)
  - [x] GPS course fallback for heading
  - [x] Authorization status tracking
  - [x] Error handling

- [x] **HapticService.swift**
  - [x] Core Haptics engine setup
  - [x] Engine lifecycle (restart on foreground)
  - [x] Fallback to UIImpactFeedbackGenerator
  - [x] Pattern playback from `HapticPatternFactory`
  - [x] Profile-aware playback (`fieldMax`, `pocketMax`, `pocketNormal`, `handheld`, `quiet`)
  - [x] Arrival pattern playback

### Models Layer

- [x] **TemperatureZone.swift**
  - [x] Enum with 5 cases (hot → freezing)
  - [x] `maxDeviation` thresholds
  - [x] `from(absoluteDeviation:)` factory
  - [x] `hapticInterval` per zone
  - [x] `colors` (inner, outer) per zone
  - [x] Display helpers (displayName, emoji)

- [x] **Destination.swift**
  - [x] SwiftData `@Model` class
  - [x] Properties: name, address, latitude, longitude, lastUsed
  - [x] `coordinate` computed property
  - [x] `testDestination` static (180º Shop)

### Design Layer

- [x] **Theme.swift**
  - [x] Background color
  - [x] Temperature gradient tuples
  - [x] Text colors (primary, secondary, tertiary)
  - [x] Typography (title, headline, body, caption, debug)
  - [x] Layout constants (orbSize, orbPulseScale)
  - [x] Animation presets
  - [x] Color hex extension

### Minimal Navigation

- [x] **NavigationViewModel.swift**
  - [x] Destination and arrivalTime inputs
  - [x] Location/heading from LocationService
  - [x] Computed: distance, bearing, deviation, zone
  - [x] `directionShift` for orb (-1 to 1)
  - [x] Haptic timer and zone-based firing
  - [x] "Reward" pause after course correction
  - [x] Arrival detection
  - [x] Start/stop navigation lifecycle
  - [x] Screen-on during navigation

- [x] **NavigationView.swift**
  - [x] Dark background
  - [x] Destination name display
  - [x] Zone indicator (emoji + text)
  - [x] Distance display (formatted)
  - [x] Wander budget display (if set)
  - [x] No-heading warning
  - [x] Debug overlay (triple-tap)
  - [x] Arrival overlay
  - [x] Start/stop on appear/disappear

### Configuration

- [x] **BumpersApp.swift**
  - [x] SwiftData ModelContainer setup
  - [x] Launch to NavigationView with test destination

- [x] **Info.plist** (via build settings)
  - [x] NSLocationWhenInUseUsageDescription

### Verification

- [x] Build compiles successfully

---

## Phase 2: The Orb ✅ COMPLETE

**Goal:** Beautiful, animated orb that shows temperature + direction.

### OrbView.swift

- [x] **Gradient rendering**
  - [x] Radial gradient from zone colors
  - [x] Hot center → dark edges
  - [x] Center offset based on `directionShift`

- [x] **Animations**
  - [x] Pulse animation (scale 1.0 → 1.02, 2s loop)
  - [x] Gradient color transition (0.5s ease)
  - [x] "Bump" animation on haptic fire

- [x] **Integration**
  - [x] Replace emoji/text zone indicator
  - [x] Pass zone and directionShift from ViewModel

### Animations.swift

- [x] Custom spring configurations
- [x] Pulse modifier
- [x] Bump modifier

### Navigation View Updates

- [x] Integrate OrbView
- [x] Smooth zone transitions
- [x] Orb bump triggers on haptic

---

## Phase 3: Destination Entry ✅ COMPLETE

**Goal:** Search for places, select destination, set time constraint.

### HomeView.swift

- [x] "Where are you headed?" header
- [x] Search bar with MapKit integration
- [x] Recent destinations list (SwiftData query)
- [x] Search results list
- [x] Destination selection → WanderDial

### SearchBar.swift (Integrated into HomeView)

- [x] Text field styling
- [x] MKLocalSearch integration
- [x] Debounced search (onChange triggers)
- [x] Loading state (via searchResults)
- [x] Clear button

### WanderDialSheet.swift

- [x] Horizontal slider (custom gesture-based)
- [x] "No rush" default (60+ min = no constraint)
- [x] Wander budget display
- [x] Arrival time calculation
- [x] Walk time estimate
- [x] Color-interpolated thumb

### Navigation Flow

- [x] HomeView → WanderDialSheet (sheet) → NavigationView
- [x] Pass selected destination
- [x] Save to recent destinations (via markAsUsed)

---

## Phase 4: Arrival & Polish ✅ COMPLETE

**Goal:** Complete the loop with arrival celebration.

### ArrivalView.swift

- [x] "You're here" message (elegant, quiet celebration)
- [x] Total walk time display
- [x] Total distance display
- [x] Entrance animation (staggered fade-in)
- [x] Save destination option (destinations saved on selection in HomeView)
- [x] Dismiss button → returns to HomeView

### Edge Cases

- [x] No location permission → PermissionView with explanation + Settings link
- [x] No heading available → Animated indicator + context-aware hint
- [x] Poor GPS accuracy → Inline ±Xm indicator (shows when >30m)
- [x] Time constraint tight → "You'll need to walk directly" warning

### Battery Optimization

- [x] Dynamic update modes (precise/balanced/efficient)
- [x] Reduce heading frequency when stable/on-track (efficient mode)
- [x] Increase distance filter when far from destination (efficient mode)
- [x] Stop haptic timer on arrival (stats preserved for ArrivalView)

### Debug Improvements

- [x] Heading calibration status (shown in noHeadingWarning)
- [x] GPS accuracy indicator (inline with distance)
- [x] Update mode visible in debug overlay (via locationService.currentMode)

---

## Phase 5: Final Polish ⏳ IN PROGRESS

**Goal:** Production-ready quality.

### Visual Polish

- [x] Launch screen (dark background, matches Theme.background)
- [x] App icon (fire/wave yin-yang design)
- [x] Custom typography (Quicksand — warm, rounded geometric sans-serif)
- [x] Smooth view transitions (staggered animations in ArrivalView)
- [x] Accessibility labels (NavigationView, ArrivalView)
- [x] Journey Trail on arrival (colored path map + wander factor)

### Micro-Interactions (Lumy-Inspired)

- [x] `Interactions.swift` — Pressable, rowPressable, staggeredEntrance modifiers
- [x] Button press feedback (scale + haptic) on all buttons
- [x] WanderDial haptic ticks (every 5-minute increment)
- [x] Search result staggered entrance animation
- [x] Hero transition (WanderDial → Navigation — growing orb)
- [x] Arrival haptic crescendo trigger

### Live Activity (Lock Screen + Dynamic Island)

- [x] `NavigationActivityAttributes.swift` — Shared data model
- [x] `LiveActivityManager.swift` — Start/update/end lifecycle
- [x] `BumpersWidgetExtension` target — Created in Xcode
- [x] `NavigationLiveActivity.swift` — Lock Screen + Dynamic Island views
- [x] Integration with NavigationViewModel
- [x] Build succeeds for both targets
- [x] Aura-like gradients (radial glow, blur effects) — Session 14
- [x] Bolder typography (semibold/bold weights) — Session 14
- [x] Widget compile sources fixed — Session 14
- [ ] ⚠️ **Device testing required** — Verify Live Activity appears on real device

### Testing

- [ ] Walk test to Starbucks Condesa (Alfonso Reyes 218)
- [ ] Walk test with time constraint
- [ ] Test in low-GPS areas
- [ ] Test with poor compass calibration
- [ ] Test Live Activity on device (Dynamic Island on iPhone 14 Pro+)
- [ ] Verify distance syncs between NavigationView and Live Activity

### Documentation

- [x] Update CLAUDE.md with Live Activity architecture
- [x] BUILD-LOG entries for sessions 11-14
- [ ] Archive any abandoned ideas

---

## Phase 6: Route-Aware V2 ⏳ IN PROGRESS

**Goal:** Prove the real product: wander toward a place without following a route.

### Core Pivot

- [x] Fix left/right sign convention so positive deviation means correct right
- [x] Keep crow-flies guidance as fallback only
- [x] Add user-facing looseness modes: Direct, Room to wander, Scenic
- [x] Use MapKit walking routes internally without showing a blue route line
- [x] Add route-aware corridor projection and progress tracking
- [x] Add low-confidence states that suppress directional haptics
- [x] Add wrong-way detection from sustained bad progress
- [x] Add reroute cooldown instead of constant rerouting

### Search and ETA

- [x] Refactor search into `DestinationSearchService` and `DestinationSearchViewModel`
- [x] Debounce query input and suppress stale results
- [x] Use current location as MapKit search region when available
- [x] Cancel prior MapKit searches before starting new ones
- [x] Render MapKit suggestions and resolve tapped suggestions through the search view model
- [x] Store iOS 18+ `MKMapItem.Identifier` raw value when available
- [x] Replace fake 15-minute estimate with explicit finding/estimating/direct/rough/unavailable states
- [x] Use MapKit walking ETA first, straight-line ETA only as labeled rough fallback

### Pocket-First Haptics

- [x] Add `HapticProfile` with fieldMax, pocketMax, pocketNormal, handheld, quiet
- [x] Add inspectable `HapticPatternFactory`
- [x] Replace intensity-ramp direction language with duration rhythm
- [x] Add skippable first-run haptic calibration
- [x] Remove double arrival haptic playback
- [x] Keep on-track mostly silent

### Field Mode Validation

- [x] Add Field Max haptic profile for real-pocket validation
- [x] Add one-screen haptic preflight with left, right, and max buzz
- [x] Make Field Mode the default validation posture
- [x] Make in-lane navigation visibly alive without constant buzzing
- [x] Add Field Mode diagnostics for route state, profile, last buzz, and cooldown
- [ ] Real-device Field Mode walk test passes pocket viability gate

### Visual Refresh

- [x] Calm the active navigation glow
- [x] Show mode and simple-guidance fallback
- [x] Preserve debug triple tap with confidence and route mode
- [x] Update README/agent/docs language from crow-flies V1 to route-aware V2
- [x] Add V2 walk-test protocol in `docs/WALK-TESTS.md`
- [x] Install updated app icon into `Assets.xcassets`
- [x] Add README cover image
- [ ] Device walk-test the new corridor and pocket haptics

### Verification

- [x] Add unit tests for sign convention, route projection, corridor states, stale search suppression, ETA labels, and haptic pattern shape
- [x] Direct Swift typecheck passes for app Swift files
- [x] Fold simulator-install dependency into validation plan
- [x] Xcode build passes after local iOS simulator/runtime install finishes
- [x] Unit tests pass on concrete simulator
- [ ] Real-device walk tests pass the V2 gate

---

## Files Checklist

| File | Status | Phase |
|------|--------|-------|
| `BumpersApp.swift` | ✅ Done | 1 |
| `Theme.swift` | ✅ Done | 1 |
| `NavigationCalculator.swift` | ✅ Done | 1 |
| `LocationService.swift` | ✅ Done | 1 |
| `HapticService.swift` | ✅ Done | 1 |
| `RouteService.swift` | ✅ Implemented | 6 |
| `CorridorNavigationEngine.swift` | ✅ Implemented | 6 |
| `DestinationSearchService.swift` | ✅ Implemented | 6 |
| `HapticPatternFactory.swift` | ✅ Implemented | 6 |
| `HapticCalibrationService.swift` | ✅ Implemented | 6 |
| `TemperatureZone.swift` | ✅ Done | 1 |
| `Destination.swift` | ✅ Done | 1 |
| `NavigationMode.swift` | ✅ Implemented | 6 |
| `WalkingRoute.swift` | ✅ Implemented | 6 |
| `CorridorState.swift` | ✅ Implemented | 6 |
| `HapticProfile.swift` | ✅ Implemented | 6 |
| `SearchModels.swift` | ✅ Implemented | 6 |
| `NavigationViewModel.swift` | ✅ Done | 1 |
| `NavigationView.swift` | ✅ Done | 1 |
| `OrbView.swift` | ✅ Done | 2 |
| `Animations.swift` | ✅ Done | 2 |
| `HomeView.swift` | ✅ Done | 3 |
| `WanderDialSheet.swift` | ✅ Done | 3 |
| `DestinationSearchViewModel.swift` | ✅ Implemented | 6 |
| `HapticCalibrationView.swift` | ✅ Implemented | 6 |
| `NavigationModePicker.swift` | ✅ Implemented | 6 |
| `DestinationRows.swift` | ✅ Implemented | 6 |
| `ArrivalView.swift` | ✅ Done | 4 |
| `PermissionView.swift` | ✅ Done | 4 |
| `LaunchScreen.storyboard` | ✅ Done | 5 |
| `Interactions.swift` | ✅ Done | 5 |
| `LiveActivityManager.swift` | ✅ Done | 5 |
| `NavigationActivityAttributes.swift` | ✅ Done | 5 |
| `BumpersWidget/*` | ✅ Done | 5 |
