# Bumper — Specification

*Version 1.0 — 2026-01-01*

---

## The Problem

GPS navigation has made us mindless route-followers. We stare at blue lines, miss our surroundings, and never develop intuitive spatial awareness of the places we live and visit.

## The Solution

Bumper is a "hot or cold" navigation app that guides you toward your destination using haptic feedback and a minimal visual interface—without prescribing a specific route. You're free to wander, explore, and take whatever path feels interesting. The app gently "bumps" you back on track when you veer too far or run low on time.

## Core Metaphor

Think of bowling bumpers: you can bounce around within the lane, but you'll still make it to the pins. The app creates an invisible corridor to your destination and uses warmth (visual + haptic) to keep you roughly on track.

---

## User Flow

### 1. Launch → Set Destination
- App opens to a clean destination entry screen
- Search field at top (uses MapKit search)
- Recent destinations below (stored locally, last 10)
- User taps a result or searches for address

### 2. Set Time Constraint (Optional)
- After destination selected: "When do you need to arrive?"
- Options:
  - "No rush" (default) — pure directional guidance, no time pressure
  - Time picker — user sets arrival deadline
- If time set: app calculates walking time and shows "wander budget"
  - Example: "25 min to destination • You have ~40 min of wander time"

### 3. Active Navigation
- Transitions to the navigation screen (the core experience)
- Screen is minimal: dark background, central gradient orb, minimal text
- User puts phone in pocket; haptics guide them
- Screen serves as glanceable confirmation when they do look

### 4. Arrival
- When within ~50m of destination: celebratory haptic + visual
- "You made it" with total walk time / distance
- Option to save destination or just dismiss

---

## Navigation Logic

### Core Calculation
```
bearing_to_destination = calculate_bearing(current_location, destination)
user_heading = device_heading (from compass/motion)
deviation = normalize_angle(user_heading - bearing_to_destination)
```

- `deviation` of 0° = walking directly toward destination
- `deviation` of ±180° = walking directly away
- We care about deviation magnitude and sign (left vs right)

### Zones (Deviation Thresholds)

| Zone | Deviation | State | Haptic | Visual |
|------|-----------|-------|--------|--------|
| On Track | 0° - 20° | Hot | Gentle pulse every 5s | Warm red/orange orb |
| Slight Veer | 20° - 45° | Warm | Soft tap every 3s | Orange orb |
| Veering | 45° - 90° | Cool | Double tap every 2s | Yellow-green orb |
| Off Course | 90° - 135° | Cold | Triple tap every 1.5s | Blue-green orb |
| Wrong Way | 135° - 180° | Freezing | Continuous gentle buzz | Blue/purple orb |

### Haptic Directionality
Use haptic *patterns* to indicate urgency. For v1, simpler approach: intensity = how off course. True directional haptics are limited on iPhone.

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

### Obstacle Handling (v1 Approach)
We're NOT doing turn-by-turn routing. The "bumper" philosophy means:
- User figures out obstacles themselves
- If they hit a dead end, they naturally veer, and the app guides them back
- This is a feature, not a bug—it builds spatial awareness

For v1, pure crow-flies bearing is fine. User will learn to anticipate obstacles.

---

## Visual Design

### Design Philosophy
Inspired by Rauno Freiberg's work: minimal, typography-focused, fluid animations, dark aesthetic, deliberate use of color.

### Navigation Screen Layout
```
┌─────────────────────────────────┐
│                                 │
│         Destination Name        │  ← SF Pro Display, Light, 17pt, white
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
│            0.4 mi               │  ← SF Pro, Regular, 15pt, 60% white
│                                 │
│       ~20 min wander time       │  ← SF Pro, Light, 13pt, 40% white
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
- Use SF Pro throughout (system font)
- Destination name: SF Pro Display, Light or Ultralight, 17-20pt
- Distance: SF Pro, Regular, 15pt
- Secondary info: SF Pro, Light, 13pt

### Animations
- All transitions: spring animation with response ~0.5s, dampingFraction ~0.8
- Orb gradient shifts: ease-in-out, 0.5s
- Screen transitions: matched geometry where possible, otherwise fade + scale

---

## Haptic Design

### Core Haptics Framework
Use `CHHapticEngine` for rich, custom haptics (not just `UIImpactFeedbackGenerator`).

### Haptic Patterns

**On Track Pulse (every 5s when on track):**
- Gentle, reassuring single tap
- Intensity: 0.4, Sharpness: 0.3

**Veer Warning (when going off course):**
- Double tap, more noticeable
- Intensity: 0.6, Sharpness: 0.5
- Taps at 0s and 0.1s

**Off Course Alert:**
- Triple tap, urgent
- Taps at 0, 0.08, 0.16 seconds
- Intensity: 0.8, Sharpness: 0.7

**Wrong Way Buzz:**
- Continuous gentle vibration
- Intensity: 0.5, Sharpness: 0.3
- Duration: 0.5s

**Arrival Celebration:**
- Rising intensity taps: 0.3 → 0.5 → 0.7 → 1.0
- Final soft continuous buzz

### Haptic Timing
- Don't spam haptics—they lose meaning
- Minimum interval between haptic events: varies by zone
- When user corrects course, pause haptics for 3s as "reward"

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
- MapKit (for search only)

### No External Dependencies
Pure Apple frameworks. No CocoaPods, SPM packages, or third-party libraries.

---

## Test Destination

**180º Shop** — Colima 180, Roma Norte, CDMX
- Coordinates: `19.4184425, -99.1762134`
- Used for walk-testing during development

---

## Definition of Done (v1)

The app is ready for personal use when:

1. **Core flow works:** Can set destination, navigate with haptics, arrive
2. **Feels good:** Haptics are satisfying, not annoying; orb animation is smooth
3. **Reliable:** Doesn't crash, location updates consistently
4. **Minimal but complete:** No half-built features, everything present works fully
5. **Actually used:** Tested with real walks in CDMX
