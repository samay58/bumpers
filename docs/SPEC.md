# Bumper — Specification

*Version 2.0 — 2026-04-27*

---

## The Problem

GPS navigation has made us mindless route-followers. We stare at blue lines, miss our surroundings, and never develop intuitive spatial awareness of the places we live and visit.

## The Solution

Bumper guides you toward your destination using haptic feedback and a minimal visual interface, without exposing turn-by-turn directions. Internally it uses walking routes to create a loose corridor. You can wander, explore, and choose interesting streets, but the app bumps you back when you leave the useful envelope or start making bad progress.

## Core Metaphor

Think of bowling bumpers: you can bounce around within the lane, but you'll still make it to the pins. The app creates an invisible corridor to your destination and uses warmth (visual + haptic) to keep you roughly on track.

---

## User Flow

### 1. Launch → Set Destination
- App opens to a clean destination entry screen
- Search field at top (uses MapKit suggestions and search)
- Recent destinations below (stored locally, last 10)
- User taps a suggestion, result, exact address, or POI

### 2. Set Time Constraint (Optional)
- After destination selected: "When do you need to arrive?"
- Options:
  - "No rush" (default) — route-aware corridor guidance, no time pressure
  - Time picker — user sets arrival deadline
- If time set: app calculates walking time and shows "wander budget"
  - Example: "25 min to destination • You have ~40 min of wander time"

### 3. Active Navigation
- Transitions to the navigation screen (the core experience)
- Screen is minimal: dark background, central gradient orb, minimal text
- User puts phone in pocket; haptics guide them
- Screen serves as glanceable confirmation when they do look

### 4. Arrival
- When inside the dynamic arrival radius for ~3 seconds: celebratory haptic + visual
- "You made it" with total walk time / distance
- Option to save destination or just dismiss

---

## Navigation Logic

### V2 Route-Aware Corridor

Primary guidance uses MapKit walking routes internally:

```
walking routes -> route corridor -> nearest projection -> progress trend -> correction instruction
```

The route is never shown as a blue line during active navigation. The user sees a calm instrument, not turn-by-turn instructions.

User-facing looseness modes:

| Mode | Label | Baseline Corridor |
|------|-------|-------------------|
| Direct | Keep me close | 35m |
| Room to wander | Give me space | 75m |
| Scenic | Let me drift | 125m |

The corridor tightens near arrival and can tighten when the user has a tight arrival time. If the user is making progress without time pressure, it can widen slightly.

Engine states:

| State | Behavior |
|-------|----------|
| Acquiring location | No directional haptics |
| Low confidence | Neutral warning only |
| In lane | Silence by default |
| Drifting | Directional correction |
| Off course | Stronger directional correction |
| Wrong way | Rumble plus directional correction |
| Arrived | Single arrival crescendo |

### Fallback Calculation

If MapKit returns no walking route, Bumper falls back to simple direction guidance and shows "Using simple direction guidance."

### Core Calculation
```
bearing_to_destination = calculate_bearing(current_location, destination)
user_heading = device_heading (from compass/motion)
deviation = normalize_angle(bearing_to_destination - user_heading)
```

- `deviation` of 0° = walking directly toward destination
- `deviation` of ±180° = walking directly away
- Positive deviation = correct right
- Negative deviation = correct left

### Fallback Zones (Deviation Thresholds)

These zones are used for simple bearing fallback and visual temperature. Primary V2 haptics come from corridor state and `HapticPatternFactory`.

| Zone | Deviation | State | Haptic | Visual |
|------|-----------|-------|--------|--------|
| On Track | 0° - 20° | Hot | Silent by default | Warm red/orange orb |
| Slight Veer | 20° - 45° | Warm | Directional correction if stable | Orange orb |
| Veering | 45° - 90° | Cool | Medium correction | Yellow-green orb |
| Off Course | 90° - 135° | Cold | Strong correction | Blue-green orb |
| Wrong Way | 135° - 180° | Freezing | Rumble + direction | Blue/purple orb |

### Haptic Directionality
Use duration-rhythm patterns for pocket legibility. Correct right is short-long. Correct left is long-short. Strong corrections repeat the signature. Wrong way adds a long rumble before the directional signature.

### Time-Aware Mode
When user sets an arrival time:

```
remaining_time = arrival_time - current_time
min_travel_time = estimate_walking_time(current_location, destination)
buffer = remaining_time - min_travel_time
```

- **Free Wander** (buffer > 10 min): Relaxed haptics, wide tolerance
- **Gentle Guide** (buffer 5-10 min): Normal haptics, standard thresholds
- **Active Guide** (buffer 2-5 min): Frequent haptics, tighter thresholds
- **Urgent** (buffer < 2 min): Continuous guidance, narrow tolerance

### Obstacle Handling
Bumper does not give street names or turn-by-turn instructions. It does use route geometry internally so it does not nag the user toward impossible crow-flies paths through buildings, parks, highways, or blocked streets.

---

## Visual Design

### Design Philosophy
Inspired by Rauno Freiberg's work: minimal, typography-focused, fluid animations, dark aesthetic, deliberate use of color.

### Navigation Screen Layout
```
┌─────────────────────────────────┐
│                                 │
│         Destination Name        │  ← Quicksand, medium/light, 17pt
│                                 │
│                                 │
│                                 │
│           ┌───────┐             │
│          │         │            │
│          │  ORB    │            │  ← Large gradient circle, ~200pt diameter
│          │         │            │
│           └───────┘             │
│                                 │
│                                 │
│            0.4 mi               │  ← Quicksand, large, quiet
│                                 │
│       ~20 min wander time       │  ← Quicksand, 13pt, reduced opacity
│                                 │
└─────────────────────────────────┘
```

### The Orb
The central visual element. A radial gradient that shifts based on "temperature":

- **Hot (on track):** Deep red center → orange → dark edges
- **Warm:** Orange center → yellow → dark edges
- **Cool:** Yellow-green center → teal → dark edges
- **Cold:** Cyan center → blue → dark edges
- **Freezing:** Blue center → purple → dark edges

The orb should feel alive:
- Subtle pulsing animation (scale 1.0 → 1.02 → 1.0, ~2s loop)
- Gradient shifts should animate smoothly (0.5s transition)
- When haptic fires, orb does a subtle "bump" animation

### Orb Directionality
The orb has an inner "hot spot" that shifts toward the direction you should turn:
- Centered when on track
- Shifts 10-30% left/right based on correction direction
- Feels like a compass needle or marble rolling in a bowl

### Color Palette
```swift
// Background
let background = Color(hex: "0A0A0A") // Near-black

// Temperature gradient stops (for orb)
let freezing = [Color(hex: "667EEA"), Color(hex: "764BA2")]  // Blue-purple
let cold = [Color(hex: "06B6D4"), Color(hex: "3B82F6")]       // Cyan-blue
let cool = [Color(hex: "84CC16"), Color(hex: "22D3D1")]       // Green-teal
let warm = [Color(hex: "F59E0B"), Color(hex: "EF4444")]       // Orange-red
let hot = [Color(hex: "EF4444"), Color(hex: "DC2626")]        // Red

// Text
let textPrimary = Color.white
let textSecondary = Color.white.opacity(0.6)
let textTertiary = Color.white.opacity(0.4)
```

### Typography
- Use bundled Quicksand via `Theme.quicksand(size:weight:)`
- Destination name: 17-20pt, medium/light depending on surface
- Distance: large, quiet, glanceable
- Secondary info: 13pt, reduced opacity

### Animations
- All transitions: spring animation with response ~0.5s, dampingFraction ~0.8
- Orb gradient shifts: ease-in-out, 0.5s
- Screen transitions: matched geometry where possible, otherwise fade + scale

---

## Haptic Design

### Core Haptics Framework
Use `CHHapticEngine` for rich, custom haptics (not just `UIImpactFeedbackGenerator`).

### Haptic Patterns

**In lane:**
- Silent by default
- Optional faint nod for calibration/testing profiles

**Correct right:**
- Short transient, gap, longer continuous pulse

**Correct left:**
- Longer continuous pulse, gap, short transient

**Strong correction:**
- Repeat the directional signature twice

**Wrong way:**
- Long rumble, gap, directional signature

**Arrival Celebration:**
- Rising intensity taps: 0.3 -> 0.5 -> 0.7 -> 0.9
- Final soft continuous buzz

### Haptic Timing
- Don't spam haptics—they lose meaning
- Minimum interval comes from `HapticPatternFactory`
- Low-confidence states suppress directional haptics

---

## Technical Requirements

### Minimum Deployment Target
iOS 17.0 — For `@Observable`, modern SwiftUI navigation, all Core Haptics features.

### Info.plist Keys
```
NSLocationWhenInUseUsageDescription = "Bumper uses your location to guide you toward your destination."
```

### Frameworks
- SwiftUI
- SwiftData
- CoreLocation
- CoreHaptics
- MapKit (search and internal walking routes)

### No External Dependencies
Pure Apple frameworks. No CocoaPods, SPM packages, or third-party libraries.

---

## Test Destination

**180º Shop** — Colima 180, Roma Norte, CDMX
- Coordinates: `19.4184425, -99.1762134`
- Used for walk-testing during development

---

## Definition of Done (V2 Prototype)

The app is ready for personal use when:

1. **Core flow works:** Can search, select looseness, calibrate, navigate, arrive
2. **Pocket haptics work:** Strong correction is noticeable in a front pants pocket while walking
3. **Direction is learnable:** Left vs right is clear within one calibration session
4. **Corridor feels right:** A 15-minute city walk has rare false nudges and rising trust
5. **Search and ETA feel native:** Nearby POIs, exact addresses, and rough fallback labels behave honestly
6. **Platform gate is passed:** If pocket haptics fail, pivot to Apple Watch/wearable-first instead of polishing iPhone-only UX
