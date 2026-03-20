# Bumper — Field Test Guide

```
                                    N
                                    │
                              ╭─────┼─────╮
                            ╱       │       ╲
                          ╱    You  │         ╲
                    W ───●    are   ●───────── E
                          ╲   here  │         ╱
                            ╲       │       ╱
                              ╰─────┼─────╯
                                    │
                                    S

              "GPS made us route-followers. Bumper makes us explorers."
```

---

## Pre-Flight

**Status:** Ready for field testing.

All systems go. The app is built, the critical bugs are squashed, and 180º Shop awaits.

```
┌─────────────────────────────────────────────────────────────┐
│  ✓ Phase 1: Foundation      ✓ Phase 4: Arrival & Polish    │
│  ✓ Phase 2: The Orb         ◐ Phase 5: Final Polish        │
│  ✓ Phase 3: Destination     ✓ Critical fixes applied       │
└─────────────────────────────────────────────────────────────┘
```

---

## Deploy to Your iPhone

```bash
# Open the project
open ~/bumpers/bumpers.xcodeproj
```

Then in Xcode:

```
┌────────────────────────────────────────────────────────────────────┐
│  bumpers  │  iPhone 17  ▼  │                          │ ▶ Run     │
├───────────┴─────────────────┴──────────────────────────┴───────────┤
│                                                                    │
│   1. Connect your iPhone (cable or same WiFi)                      │
│   2. Click the device dropdown → select your phone                 │
│   3. Hit ▶ (or Cmd+R)                                              │
│   4. Wait for build... then it launches on device                  │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

**First time?** Your phone may show "Untrusted Developer":
```
Settings → General → VPN & Device Management → [Your Apple ID] → Trust
```

---

## Your Destination

```
                    ┌─────────────────────────────────────┐
                    │                                     │
                    │    S T A R B U C K S   C O N D E S A│
                    │                                     │
                    │   Alfonso Reyes 218, Hipódromo      │
                    │         Condesa, CDMX               │
                    │                                     │
                    │       📍 19.4075, -99.1738          │
                    │                                     │
                    └─────────────────────────────────────┘

                      Your Temazcal pickup point tomorrow.
                    The coffee before the cleansing ritual.
                        Navigate here, then let go of
                            everything else.
```

This destination is hardcoded for v1. Launch the app, pick any search result or recent, and you'll navigate here.

---

## The Walk

### How It Works

You walk. The app feels.

```
        ┌─────────────────────────────────────────────────────────┐
        │                                                         │
        │   Your heading                      Destination         │
        │        │                                 │              │
        │        ▼                                 ▼              │
        │                                                         │
        │        ◉ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ▶ ★              │
        │       you        bearing = 45°      180º Shop          │
        │                                                         │
        │   If you're facing 45° (northeast), you're on track.   │
        │   If you're facing 180° (south), you're WAY off.       │
        │                                                         │
        └─────────────────────────────────────────────────────────┘

                    deviation = your_heading - bearing

                           Negative = turn left
                           Positive = turn right
                           Zero = perfect
```

### The Temperature Zones

The app translates deviation into feeling:

```
    DEVIATION        ZONE         HAPTIC              FEELING
    ─────────────────────────────────────────────────────────────

      0° - 20°       HOT          ∙                   "You're on track"
                                  Single gentle tap
                                  every 5 seconds

     20° - 45°       WARM         ∙ ∙                 "Slight veer"
                                  Double tap
                                  every 3 seconds

     45° - 90°       COOL         ∙ ∙ ∙               "Getting off course"
                                  Triple tap
                                  every 2 seconds

     90° - 135°      COLD         ∙ ∙ ∙               "Wrong direction"
                                  Urgent triple tap
                                  every 1.5 seconds

    135° - 180°      FREEZING     ≋≋≋≋≋               "Turn around!"
                                  Continuous buzz
                                  every 0.5 seconds

    ─────────────────────────────────────────────────────────────
```

### The Orb

The orb lives at the center of your screen. It breathes with you.

```
                         ╭─────────────────╮
                        ╱   ╭───────────╮   ╲
                       │   ╱  ░░░▓▓▓░░░  ╲   │
                       │  │  ░▓▓█████▓▓░  │  │
                       │  │  ▓███████████▓  │  │
          HOT →        │  │  ▓███████████▓  │  │        ← FREEZING
       (red/orange)    │  │  ░▓▓█████▓▓░  │  │         (blue/purple)
                       │   ╲  ░░░▓▓▓░░░  ╱   │
                        ╲   ╰───────────╯   ╱
                         ╰─────────────────╯

                    The hot center shifts toward where
                    you need to turn. Left shift = turn left.
```

---

## Test Scenarios

### Test 1: The Straight Shot

```
        YOU                                         DESTINATION
         │                                               │
         ▼                                               ▼
         ◉ ═══════════════════════════════════════════▶ ★

         Walk directly toward Starbucks Condesa.

         Expected: Gentle single taps every 5 seconds.
                   Orb glows warm red/orange.
                   You feel... calm. Confident.
```

### Test 2: The Deliberate Detour

```
                                              ★ Starbucks
                                             ╱
                                           ╱
                                         ╱
                                       ╱
         ◉ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ▶ ?
        YOU

        Turn 90° from your target. Keep walking.

        Expected: Haptics intensify (triple taps).
                  Interval shortens (every 2s).
                  Orb shifts blue/cyan.
                  The app is saying "hey... wrong way"
```

### Test 3: The Wrong Way

```
                          ★ 180º Shop
                          │
                          │
                          │
                          │
                          │
                          ▼
                          ◉ YOU (walking away)
                          │
                          │
                          ▼

        Turn your back completely on the destination.

        Expected: Continuous buzz every 0.5 seconds.
                  Orb goes cold purple/blue.
                  Unmistakable "you're freezing" signal.
```

### Test 4: The Course Correction

```
                                    ★
                                   ╱│
                                 ╱  │
        ◉ ─ ─ ─ ▶ ╳ ─ ─ ─ ─ ╱    │
        │         wrong    correction
        │         way      ↑
        YOU               You fix it

        Go wrong, then correct yourself.

        Expected: When you correct course, haptics PAUSE
                  for 3 seconds. This is the "reward" —
                  the app saying "good, you got it."
```

### Test 5: The Arrival

```
                              ╭───────────╮
                             ╱   50m      ╲
                            │   radius     │
                            │      ★       │
                            │   180º Shop  │
                             ╲             ╱
                              ╰─────◉─────╯
                                   YOU

        Get within ~50 meters of the destination.

        Expected: Celebration haptic (rising taps + buzz)
                  "You're here" screen appears
                  Journey stats: time walked, distance
                  The quiet satisfaction of arrival
```

---

## The Debug Overlay

**Triple-tap anywhere** during navigation.

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   DEBUG                                              [dismiss]  │
│   ───────────────────────────────────────────────────────────   │
│                                                                 │
│   Location     19.4201, -99.1758                                │
│   Heading      47.3°                                            │
│   Bearing      52.1°                                            │
│   Deviation    -4.8° (turn slightly left)                       │
│   Zone         HOT                                              │
│   Distance     312m                                             │
│   Accuracy     ±8m                                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

                Use this when something feels off.
                The numbers don't lie.
```

---

## What to Watch For

### Good Signs

```
    ✓  Haptics feel intuitive — you "know" when you're off without looking
    ✓  Zone transitions are smooth, not jarring
    ✓  The 3-second reward pause feels like positive feedback
    ✓  Arrival triggers at a reasonable distance (not too early, not too late)
    ✓  You actually want to wander, not beeline
```

### Potential Issues

```
    SYMPTOM                          LIKELY CAUSE              WHERE TO FIX
    ─────────────────────────────────────────────────────────────────────────

    Haptics too frequent            Zone thresholds too       TemperatureZone.swift
                                    tight                     → maxDeviation values

    Haptics too rare                Intervals too long        TemperatureZone.swift
                                                              → hapticInterval

    Heading jumps around            Compass needs             Consider smoothing
                                    calibration               in LocationService

    Arrival triggers too far        Radius too big            NavigationCalculator
                                                              → hasArrived (50m)

    Arrival triggers too close      Radius too small          Same as above

    Battery drains fast             Location updates          Check updateLocationMode()
                                    too aggressive            thresholds

    Orb doesn't shift direction     directionShift math       NavigationViewModel
                                    may be off                → directionShift
```

---

## The Philosophy

```
                    ┌─────────────────────────────────────┐
                    │                                     │
                    │   "The journey is the destination   │
                    │    — but you still need to get      │
                    │    to the coffee shop."             │
                    │                                     │
                    └─────────────────────────────────────┘
```

Bumper isn't about efficiency. It's about awareness.

You're not following a blue line. You're feeling your way through a city.
You can take the long way. The scenic way. The way past that mural you've
always wanted to photograph.

The app just... bumps you back when you wander too far.

Like bowling bumpers. You'll get there. Eventually. Your way.

---

## After the Walk

Note what worked and what didn't:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   HAPTIC TIMING                                                 │
│   [ ] Too frequent   [ ] Just right   [ ] Too rare              │
│                                                                 │
│   ZONE THRESHOLDS                                               │
│   [ ] Too sensitive  [ ] Just right   [ ] Too loose             │
│                                                                 │
│   ARRIVAL RADIUS                                                │
│   [ ] Too early      [ ] Just right   [ ] Too late              │
│                                                                 │
│   HEADING STABILITY                                             │
│   [ ] Jittery        [ ] Stable       [ ] N/A (used GPS course) │
│                                                                 │
│   OVERALL FEELING                                               │
│   [ ] Stressed       [ ] Guided       [ ] Free                  │
│                                                                 │
│   NOTES:                                                        │
│   _____________________________________________________________│
│   _____________________________________________________________│
│   _____________________________________________________________│
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Quick Reference Card

Print this. Fold it. Put it in your pocket.

```
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   B U M P E R   Q U I C K   R E F                                ║
║                                                                   ║
║   ─────────────────────────────────────────────────────────────   ║
║                                                                   ║
║   DESTINATION     Starbucks, Alfonso Reyes 218, Condesa           ║
║                   19.4075, -99.1738                               ║
║                                                                   ║
║   ─────────────────────────────────────────────────────────────   ║
║                                                                   ║
║   ∙           HOT       On track         5s interval              ║
║   ∙ ∙         WARM      Slight veer      3s interval              ║
║   ∙ ∙ ∙       COOL      Off course       2s interval              ║
║   ∙ ∙ ∙       COLD      Wrong way        1.5s interval            ║
║   ≋≋≋≋≋       FREEZING  Turn around      0.5s interval            ║
║                                                                   ║
║   ─────────────────────────────────────────────────────────────   ║
║                                                                   ║
║   TRIPLE-TAP  →  Debug overlay                                    ║
║   ARRIVAL     →  ~50m from destination                            ║
║   REWARD      →  3s pause after correcting course                 ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
```

---

*Now go get lost. On purpose.*

```
                                    🚶
                                   ╱
                                 ╱
                               ╱
                             ╱
                           ★
```
