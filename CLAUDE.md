# Bumper — Claude Code Instructions

*Last updated: 2026-01-01*

---

## Project Overview

**Bumper** is a "hot or cold" navigation iOS app that guides users toward destinations using haptic feedback and a minimal visual interface — without prescribing specific routes.

**Core Philosophy:** GPS navigation has made us mindless route-followers. Bumper builds spatial awareness by giving you a destination and a feeling (haptic "temperature"), not turn-by-turn directions. You're free to wander; the app "bumps" you back on track when you veer too far.

**Metaphor:** Bowling bumpers — you can bounce around within the lane, but you'll still reach your destination.

---

## Quick Reference

```bash
# Build
cd ~/bumpers
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' build

# Open in Xcode
open ~/bumpers/bumpers.xcodeproj

# Issue tracking
bd ready              # Find available work
bd show <id>          # View issue details
bd sync               # Sync with git

# Documentation
cat docs/PLAN.md      # Current implementation status
cat docs/ROADMAP.md   # Future ideas
cat docs/BUILD-LOG.md # Session history
```

---

## Architecture Overview

```
bumpers/
├── BumpersApp.swift              # App entry point
├── Design/
│   └── Theme.swift               # Colors, fonts, constants
├── Features/
│   ├── Home/                     # (Planned) Destination entry
│   ├── Navigation/
│   │   ├── NavigationView.swift      # Main navigation screen
│   │   ├── NavigationViewModel.swift # Navigation brain
│   │   └── OrbView.swift             # (Planned) Animated gradient orb
│   └── Arrival/                  # (Planned) Celebration screen
├── Models/
│   ├── Destination.swift         # SwiftData model
│   └── TemperatureZone.swift     # Zone enum with thresholds
└── Services/
    ├── HapticService.swift       # Core Haptics patterns
    ├── LocationService.swift     # CoreLocation wrapper
    └── NavigationCalculator.swift # Bearing/deviation math
```

### Layer Responsibilities

| Layer | Purpose | Key Classes |
|-------|---------|-------------|
| **Services** | Pure logic, no UI, reusable | `LocationService`, `HapticService`, `NavigationCalculator` |
| **Models** | Data structures, persistence | `Destination`, `TemperatureZone` |
| **Features** | UI + view models, screen-specific | `NavigationView`, `NavigationViewModel` |
| **Design** | Shared visual constants | `Theme` |

---

## Key Design Decisions

These decisions were made deliberately. Before changing them, understand the rationale.

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Foreground-only** | No background mode | Haptics require foreground. Screen stays on (idle timer disabled). Simpler than fighting iOS background limits. |
| **Crow-flies bearing** | No route following | Core philosophy: user navigates obstacles themselves. Builds spatial awareness. |
| **Temperature zones** | 5 zones (hot → freezing) | Simple mental model. Easy to understand haptic patterns. |
| **Haptic timing** | Zone-based intervals | Hot = 5s, Freezing = 0.5s. More frequent = more urgent. |
| **Screen-on navigation** | `isIdleTimerDisabled = true` | Phone in pocket, screen faces thigh. Haptics work. |
| **SwiftData** | For recent destinations | Already in the template. Simple for structured data. |
| **iOS 17+ only** | For `@Observable` | Modern SwiftUI patterns. No legacy support needed. |

---

## Navigation Math

The core algorithm (in `NavigationCalculator.swift`):

```
1. bearing_to_destination = calculate_bearing(current_location, destination)
2. deviation = normalize_angle(user_heading - bearing_to_destination)
3. zone = TemperatureZone.from(absoluteDeviation: abs(deviation))
4. Play haptic for zone at zone.hapticInterval
```

**Deviation interpretation:**
- `deviation = 0°` → walking directly toward destination
- `deviation = ±180°` → walking directly away
- `deviation > 0` → need to turn right
- `deviation < 0` → need to turn left

---

## Temperature Zones

| Zone | Deviation | Haptic Interval | Haptic Pattern |
|------|-----------|-----------------|----------------|
| Hot | 0° - 20° | 5s | Single gentle tap |
| Warm | 20° - 45° | 3s | Double tap |
| Cool | 45° - 90° | 2s | Triple tap |
| Cold | 90° - 135° | 1.5s | Triple tap (urgent) |
| Freezing | 135° - 180° | 0.5s | Continuous buzz |

---

## Common Tasks

### Add a new haptic pattern

1. Open `Services/HapticService.swift`
2. Add a new method following the existing pattern:
   ```swift
   func playMyNewPattern() {
       let events = [
           CHHapticEvent(eventType: .hapticTransient, ...)
       ]
       playPattern(events: events)
   }
   ```
3. Add fallback using `UIImpactFeedbackGenerator` for older devices

### Change zone thresholds

1. Open `Models/TemperatureZone.swift`
2. Modify `maxDeviation` for each case
3. Update `TemperatureZone.from(absoluteDeviation:)` if needed

### Add a new destination source

1. Create a view in `Features/Home/`
2. Use MapKit's `MKLocalSearch` for search
3. Create `Destination` model and save to SwiftData

### Modify the orb appearance

1. Open `Features/Navigation/OrbView.swift`
2. Colors are in `Theme.swift` → `TemperatureZone.colors`
3. Animation constants in `Theme.swift` → `orbPulseScale`, `orbPulseDuration`

---

## Testing

### Simulator Limitations
- **Haptics don't work** — must test on real device
- **Heading/compass doesn't work** — use GPS course (requires movement) or mock
- **Location can be simulated** — Features → Location → Custom Location

### Real Device Checklist
- [ ] Location permission prompt works
- [ ] Haptics fire correctly per zone
- [ ] Heading updates smoothly outdoors
- [ ] Arrival detection at ~50m
- [ ] Screen stays on during navigation

### Debug Overlay
**Triple-tap anywhere** on the navigation screen to show:
- Current lat/lon
- Heading (degrees)
- Bearing to destination (degrees)
- Deviation (degrees)
- Current zone
- Distance remaining

---

## Test Destination

**180º Shop** — Colima 180, Roma Norte, CDMX
Coordinates: `19.4184425, -99.1762134`

Hardcoded in `Destination.testDestination` for walk-testing.

---

## Code Style

- **SwiftUI-first** — No UIKit unless necessary
- **@Observable** — Use iOS 17+ observation, not ObservableObject
- **MARK comments** — Organize code sections
- **Light typography** — SF Pro Light/Ultralight weights
- **Minimal color palette** — Dark background, temperature gradients only

---

## Files to Read First

When onboarding to this codebase:

1. `docs/SPEC.md` — Full specification
2. `docs/PLAN.md` — Current implementation status
3. `Services/NavigationCalculator.swift` — Core math
4. `Models/TemperatureZone.swift` — Zone definitions
5. `Features/Navigation/NavigationViewModel.swift` — Navigation brain

---

## Links

- **Plan:** `docs/PLAN.md`
- **Spec:** `docs/SPEC.md`
- **Roadmap:** `docs/ROADMAP.md`
- **Build Log:** `docs/BUILD-LOG.md`
- **Issues:** `bd ready`
