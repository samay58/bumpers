# Bumper — Implementation Plan

*Last updated: 2026-01-01*

---

## Overview

This document tracks implementation progress. Check boxes indicate completion.

**Current Phase:** Phase 3 (Destination Entry)
**Overall Progress:** Phase 1-2 complete, Phase 3-5 pending

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
  - [x] `playOnTrackPulse()` — Single tap
  - [x] `playVeerWarning()` — Double tap
  - [x] `playOffCourseAlert()` — Triple tap
  - [x] `playWrongWayBuzz()` — Continuous buzz
  - [x] `playArrival()` — Celebration pattern
  - [x] `playForZone(_:)` — Zone-based dispatch

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

## Phase 3: Destination Entry ⏳ PENDING

**Goal:** Search for places, select destination, set time constraint.

### HomeView.swift

- [ ] "Where are you headed?" header
- [ ] Search bar with MapKit integration
- [ ] Recent destinations list (SwiftData query)
- [ ] Search results list
- [ ] Destination selection → WanderDial

### SearchBar.swift

- [ ] Text field styling
- [ ] MKLocalSearch integration
- [ ] Debounced search
- [ ] Loading state
- [ ] Error handling

### WanderDial.swift

- [ ] Horizontal slider
- [ ] "No rush" default
- [ ] Wander budget display
- [ ] Arrival time calculation
- [ ] Long-press for time picker

### Navigation Flow

- [ ] HomeView → WanderDial sheet → NavigationView
- [ ] Pass selected destination
- [ ] Save to recent destinations

---

## Phase 4: Arrival & Polish ⏳ PENDING

**Goal:** Complete the loop with arrival celebration.

### ArrivalView.swift

- [ ] "You made it" message
- [ ] Total walk time display
- [ ] Total distance display
- [ ] Celebratory animation
- [ ] Save destination option
- [ ] Dismiss button

### Edge Cases

- [ ] No location permission → explanation + settings link
- [ ] No heading available → GPS course + "Keep walking" prompt
- [ ] Poor GPS accuracy → indicator + widened thresholds
- [ ] Time constraint impossible → warning message

### Battery Optimization

- [ ] Reduce heading frequency when stable/on-track
- [ ] Increase distance filter when far from destination
- [ ] Stop updates immediately on arrival

### Debug Improvements

- [ ] Heading calibration status
- [ ] GPS accuracy indicator
- [ ] Battery impact estimate

---

## Phase 5: Final Polish ⏳ PENDING

**Goal:** Production-ready quality.

### Visual Polish

- [ ] Launch screen
- [ ] App icon
- [ ] Smooth view transitions
- [ ] Accessibility labels

### Testing

- [ ] Walk test in Roma Norte → 180º Shop
- [ ] Walk test with time constraint
- [ ] Test in low-GPS areas
- [ ] Test with poor compass calibration

### Documentation

- [ ] Update SPEC if design changed
- [ ] Final BUILD-LOG entry
- [ ] Archive any abandoned ideas

---

## Files Checklist

| File | Status | Phase |
|------|--------|-------|
| `BumpersApp.swift` | ✅ Done | 1 |
| `Theme.swift` | ✅ Done | 1 |
| `NavigationCalculator.swift` | ✅ Done | 1 |
| `LocationService.swift` | ✅ Done | 1 |
| `HapticService.swift` | ✅ Done | 1 |
| `TemperatureZone.swift` | ✅ Done | 1 |
| `Destination.swift` | ✅ Done | 1 |
| `NavigationViewModel.swift` | ✅ Done | 1 |
| `NavigationView.swift` | ✅ Done | 1 |
| `OrbView.swift` | ✅ Done | 2 |
| `Animations.swift` | ✅ Done | 2 |
| `HomeView.swift` | ⏳ Pending | 3 |
| `SearchBar.swift` | ⏳ Pending | 3 |
| `WanderDial.swift` | ⏳ Pending | 3 |
| `ArrivalView.swift` | ⏳ Pending | 4 |
| `DebugOverlay.swift` | ⏳ Pending | 4 |
