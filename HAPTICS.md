# HAPTICS.md — Bumper Haptic Language

> This file defines the haptic vocabulary for Bumper. Claude Code reads it automatically.
> Haptic vocabulary starts in `Services/HapticPatternFactory.swift`; `Services/HapticService.swift` only plays those descriptors through Core Haptics or UIKit fallback.

---

## Current V2 Pocket Language

V2 is pocket-first. The source of truth in code is `HapticPatternFactory`, which emits inspectable pattern descriptors before `HapticService` converts them to Core Haptics events.

The direction language is duration-rhythm based:

| State | Meaning | Pattern |
|-------|---------|---------|
| In lane | You are fine | Silence by default |
| Correct right | Move right soon | Short pulse, gap, long pulse |
| Correct left | Move left soon | Long pulse, gap, short pulse |
| Strong correction | Correct now | Repeat the directional signature twice |
| Wrong way | Turn around | Long rumble, gap, directional signature |
| Arrival | You are here | Crescendo, then warm tail |

Profiles:

| Profile | Use |
|---------|-----|
| `pocketMax` | Front-pocket walk tests where haptics are weak |
| `pocketNormal` | Default first-run profile |
| `handheld` | Lower energy for in-hand use |
| `quiet` | Minimal feedback |

The sign convention is shared across navigation, accessibility, and haptics:

```
deviation = normalize(targetBearing - currentHeading)
positive deviation = correct right
negative deviation = correct left
```

Older intensity-ramp zone notes below are historical reference only. Do not reintroduce rising/falling transient intensity as the primary V2 direction language.

---

## Design Philosophy

Bumper's haptics are a **language the user's body learns over time.** Three principles:

1. **Silence means success.** In-lane walking should usually produce nothing. Optional nods are for calibration and testing, not the default walk loop.

2. **Off-track encodes direction.** Left and right correction produce distinct haptic patterns so the user learns to correct without looking at the screen. The V2 encoding is temporal duration: short-long means correct right, long-short means correct left.

3. **Intensity scales with urgency, not annoyance.** Further off-track means stronger and more frequent, but never a crude continuous buzz. Even the most urgent signal is a patterned rhythm — uncomfortable enough to correct, never unpleasant enough to make the user turn off haptics.

---

## Historical V1 Direction Encoding

This section describes the older intensity-ramp language. It is kept for comparison, not as the current implementation target.

### Rising Pattern → "Correct Right" (historical)

```
tap₁ (soft) → gap → tap₂ (firm)
```

The second tap is stronger than the first. Feels like momentum building rightward.
Perceptually: a "nudge" that lands on the strong beat at the end.

### Falling Pattern → "Correct Left" (historical)

```
tap₁ (firm) → gap → tap₂ (soft)
```

The first tap is stronger. Feels like momentum pulling leftward.
Perceptually: a "nudge" that leads with the strong beat.

### Why This Works

- The two patterns use identical total energy (same annoyance budget).
- Temporal asymmetry is one of the most learnable haptic distinctions.
- After 2–3 walks, the correction direction becomes automatic — like knowing which way to steer without conscious thought.
- It works even at very low intensity for gentle corrections.

---

## Historical V1 Zone × Direction Matrix

This section is old V1 design context. It is not the V2 implementation target.

### Hot Zone (0°–20° deviation) — On Track

**No direction encoding.** The user is going the right way. Reward them.

| Parameter | Value | Why |
|-----------|-------|-----|
| Type | Transient + tiny continuous tail | Richer than a bare transient — feels "finished," like a latch closing |
| Intensity | 0.35 | Present but never demanding. A quiet nod. |
| Sharpness | 0.55 | Right in the middle — warm but with enough definition to feel intentional, not mushy |
| Tail | Continuous, intensity 0.15, sharpness 0.10, duration 0.08s | Almost subliminal warmth after the click. Adds "satisfaction" without adding "loudness" |
| Interval | 5 seconds | Slow enough to be a rhythm, not a nag |

**Implementation:**
```swift
// "The Nod" — on-track confirmation
events: [
    .at(0.0, .transient(intensity: 0.35, sharpness: 0.55)),
    .at(0.02, .continuous(intensity: 0.15, sharpness: 0.10, duration: 0.08)),
]
```

**What it feels like:** A single, clean, satisfying click with the faintest warm afterglow. Like the detent on a well-made dial.

---

### Warm Zone (20°–45° deviation) — Slightly Off

**Gentle directional nudge.** Two taps, asymmetric intensity.

| Parameter | Correct Right (veered left) | Correct Left (veered right) |
|-----------|---------------------------|---------------------------|
| Tap 1 intensity | 0.25 (soft) | 0.45 (firm) |
| Tap 2 intensity | 0.45 (firm) | 0.25 (soft) |
| Sharpness (both taps) | 0.65 | 0.65 |
| Gap between taps | 80ms | 80ms |
| Interval | 3.5 seconds | 3.5 seconds |

**Implementation (correct right):**
```swift
// Rising nudge — "go right"
events: [
    .at(0.0, .transient(intensity: 0.25, sharpness: 0.65)),
    .at(0.08, .transient(intensity: 0.45, sharpness: 0.65)),
]
```

**Implementation (correct left):**
```swift
// Falling nudge — "go left"
events: [
    .at(0.0, .transient(intensity: 0.45, sharpness: 0.65)),
    .at(0.08, .transient(intensity: 0.25, sharpness: 0.65)),
]
```

**What it feels like:** A polite two-tap, like someone lightly touching your arm to get your attention. You can feel which tap is stronger — that's the direction.

---

### Cool Zone (45°–90° deviation) — Moderately Off

**Firmer directional correction.** Same two-tap pattern, wider intensity gap, slightly crisper.

| Parameter | Correct Right | Correct Left |
|-----------|--------------|-------------|
| Tap 1 intensity | 0.25 | 0.60 |
| Tap 2 intensity | 0.60 | 0.25 |
| Sharpness (both taps) | 0.70 | 0.70 |
| Gap between taps | 70ms | 70ms |
| Interval | 2.0 seconds | 2.0 seconds |

**What it feels like:** A clearer version of the Warm nudge. The asymmetry between the two taps is obvious now — the "strong" tap is noticeably stronger than the "soft" one. Unmistakable direction.

---

### Cold Zone (90°–135° deviation) — Significantly Off

**Urgent directional correction.** Three taps, escalating or de-escalating.

| Parameter | Correct Right | Correct Left |
|-----------|--------------|-------------|
| Pattern | soft → medium → firm | firm → medium → soft |
| Intensities | 0.25, 0.50, 0.75 | 0.75, 0.50, 0.25 |
| Sharpness | 0.75 | 0.75 |
| Gaps | 60ms between each | 60ms between each |
| Interval | 1.2 seconds | 1.2 seconds |

**Implementation (correct right):**
```swift
// Rising triple — urgent "go right"
events: [
    .at(0.0, .transient(intensity: 0.25, sharpness: 0.75)),
    .at(0.06, .transient(intensity: 0.50, sharpness: 0.75)),
    .at(0.12, .transient(intensity: 0.75, sharpness: 0.75)),
]
```

**Implementation (correct left):**
```swift
// Falling triple — urgent "go left"
events: [
    .at(0.0, .transient(intensity: 0.75, sharpness: 0.75)),
    .at(0.06, .transient(intensity: 0.50, sharpness: 0.75)),
    .at(0.12, .transient(intensity: 0.25, sharpness: 0.75)),
]
```

**What it feels like:** A rapid three-beat that clearly ramps in one direction. Like someone drumming their fingers with increasing (or decreasing) urgency. You're going the wrong way and your body knows which way to turn.

---

### Freezing Zone (135°–180° deviation) — Going Backwards

**Strong directional warning.** Four rapid taps, pronounced escalation/de-escalation, with a subtle continuous undertone for urgency.

| Parameter | Correct Right | Correct Left |
|-----------|--------------|-------------|
| Pattern | 4-tap escalating + rumble | 4-tap de-escalating + rumble |
| Intensities | 0.20, 0.45, 0.65, 0.85 | 0.85, 0.65, 0.45, 0.20 |
| Sharpness (taps) | 0.80 | 0.80 |
| Gaps | 50ms between each | 50ms between each |
| Rumble | continuous, intensity 0.30, sharpness 0.05, starts at 0ms, duration 0.25s | Same |
| Interval | 0.7 seconds | 0.7 seconds |

**Implementation (correct right):**
```swift
// Escalating quad + rumble — "turn around, go right"
events: [
    .at(0.0, .continuous(intensity: 0.30, sharpness: 0.05, duration: 0.25)),
    .at(0.0, .transient(intensity: 0.20, sharpness: 0.80)),
    .at(0.05, .transient(intensity: 0.45, sharpness: 0.80)),
    .at(0.10, .transient(intensity: 0.65, sharpness: 0.80)),
    .at(0.15, .transient(intensity: 0.85, sharpness: 0.80)),
]
```

**What it feels like:** A rapid drumroll with clear direction, sitting on top of a low rumble. Urgent and insistent but not a crude buzz. It's a rhythm, not a punishment — the user's body reads the escalation direction instantly.

---

## Arrival Haptic

When the user reaches the destination (within arrival radius):

**A crescendo that blooms.** Four taps building in intensity, followed by a warm sustained pulse that fades out. The emotional arc is: anticipation → arrival → satisfaction.

```swift
// Arrival crescendo
events: [
    .at(0.0, .transient(intensity: 0.30, sharpness: 0.50)),
    .at(0.12, .transient(intensity: 0.50, sharpness: 0.55)),
    .at(0.24, .transient(intensity: 0.70, sharpness: 0.60)),
    .at(0.36, .transient(intensity: 0.90, sharpness: 0.70)),
    .at(0.45, .continuous(intensity: 0.60, sharpness: 0.15, duration: 0.6,
                          attackTime: 0.05, releaseTime: 0.4)),
]
```

**What it feels like:** Four quickening taps that build to a peak, then a warm wave that washes through your hand and fades. Like the feeling of stepping through your front door after a long walk.

---

## V2 Transition Smoothing

V2 smoothing happens at the corridor-state layer, not by directly debouncing angular zones.

1. **Suppress low-confidence direction.** If GPS accuracy or heading/course is poor, emit only neutral low-confidence feedback.

2. **Use haptic cooldowns.** `HapticPatternFactory` defines per-pattern cooldowns so corrections do not become a constant buzz.

3. **Let silence carry in-lane state.** Do not play repeated on-track pulses during normal navigation.

---

## Vocabulary for Describing Adjustments

When I test on device and ask for changes, use these mappings:

| I say... | Adjust... |
|----------|-----------|
| "too buzzy" / "feels cheap" | Increase sharpness by 0.10–0.15 (crisper transients feel more premium) |
| "too aggressive" / "too strong" | Decrease intensity by 0.10–0.15 |
| "can barely feel it" / "too subtle" | Increase intensity by 0.10–0.15 |
| "can't tell left from right" | Widen the duration gap or replay spacing between the short-long and long-short signatures |
| "too frequent" / "nagging" | Increase the interval by 0.5–1.0 seconds |
| "not urgent enough" | Decrease the interval, or add one more tap to the pattern |
| "I miss reassurance when in lane" | Consider an optional, rare `onTrackNod`; keep default navigation silent |
| "the transition between zones is jarring" | Increase engine state stability requirements or haptic cooldown |
| "I keep overshooting the correction" | The directional signal may be too frequent or too strong for gentle drift |
| "feels robotic" | Add ±0.03 randomization to intensity values per-play |

---

## Implementation Notes for Claude Code

### Current V2 Implementation

- `HapticPatternFactory` owns haptic vocabulary and returns `HapticPattern` descriptors.
- `HapticService` only prepares the engine, converts descriptors to `CHHapticEvent`, and falls back to UIKit generators.
- `NavigationViewModel` applies cooldowns from `HapticPatternFactory` before playback.
- `ArrivalView` does not play its own haptic. Arrival playback is owned by `NavigationViewModel`.

Do not add new haptic behavior directly to `HapticService`; add it to `HapticPatternFactory` first and cover it with tests.

---

## Testing Protocol (Real Device Walk-Test)

Test each scenario on a real walk:

1. **In-lane silence.** Walk a plausible route. Does silence feel like success, or does it create uncertainty?

2. **Direction legibility.** Walk at ~45° off-course to the left, then to the right. Can you tell the difference between short-long and long-short patterns without looking at the screen? How many repetitions until it becomes automatic?

3. **Corridor transitions.** Move from in-lane to drift to off-course. Does escalation feel smooth? Are state changes jarring?

4. **Wrong-way urgency.** Walk directly away from destination. Does the rumble plus directional signature feel urgent without being unpleasant? Can you still tell which direction to correct?

5. **Arrival payoff.** Walk to the destination and arrive. Does the crescendo feel like a reward? Does it feel like an ending?

Report findings using the adjustment vocabulary above (for example, "pocketMax right correction is clear, left correction blurs in loose pants").
