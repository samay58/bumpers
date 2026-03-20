# HAPTICS.md — Bumper Haptic Language

> This file defines the haptic vocabulary for Bumper. Claude Code reads it automatically.
> All haptic implementation goes through `Services/HapticService.swift` using Core Haptics.

---

## Design Philosophy

Bumper's haptics are a **language the user's body learns over time.** Three principles:

1. **On-track feels rewarding.** A slow, warm, satisfying click — like a watch crown settling into place. This is the "you're doing great" signal. It should feel good enough that the user subtly seeks it out.

2. **Off-track encodes direction.** Left and right deviation produce distinct haptic patterns so the user learns to correct without looking at the screen. The encoding is temporal: a **rising** sequence (soft → firm) means one direction; a **falling** sequence (firm → soft) means the other.

3. **Intensity scales with urgency, not annoyance.** Further off-track means stronger and more frequent, but never a crude continuous buzz. Even the most urgent signal is a patterned rhythm — uncomfortable enough to correct, never unpleasant enough to make the user turn off haptics.

---

## The Direction Encoding

This is the core innovation. Direction is encoded in **tap sequence order**, not sharpness or pitch.

### Rising Pattern → "Correct Right" (user has veered left, deviation < 0)

```
tap₁ (soft) → gap → tap₂ (firm)
```

The second tap is stronger than the first. Feels like momentum building rightward.
Perceptually: a "nudge" that lands on the strong beat at the end.

### Falling Pattern → "Correct Left" (user has veered right, deviation > 0)

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

## Zone × Direction Matrix

The full haptic space. Each cell describes what the user feels.

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

## Transition Smoothing

When the user crosses a zone boundary, don't abruptly switch patterns. Instead:

1. **Debounce zone changes** by 1.5 seconds. If the user bounces between zones (e.g., walking along the edge of Hot ↔ Warm), don't ping-pong the haptics. Stay in the current zone until the new zone has been stable for 1.5s.

2. **Blend at boundaries.** When transitioning from Hot → Warm, the first Warm pattern should play at 75% of its normal intensity. Second play is at full. This prevents a jarring jump from the gentle "nod" to the directional nudge.

3. **Direction hysteresis.** If deviation crosses 0° (Hot zone, switching from barely-left to barely-right), don't change the direction encoding. Only encode direction once outside the Hot zone. The Hot zone is always direction-agnostic — it's always the same rewarding click regardless of which side of center you are.

---

## Vocabulary for Describing Adjustments

When I test on device and ask for changes, use these mappings:

| I say... | Adjust... |
|----------|-----------|
| "too buzzy" / "feels cheap" | Increase sharpness by 0.10–0.15 (crisper transients feel more premium) |
| "too aggressive" / "too strong" | Decrease intensity by 0.10–0.15 |
| "can barely feel it" / "too subtle" | Increase intensity by 0.10–0.15 |
| "can't tell left from right" | Widen the intensity gap between the soft and firm taps in the rising/falling pattern |
| "too frequent" / "nagging" | Increase the interval by 0.5–1.0 seconds |
| "not urgent enough" | Decrease the interval, or add one more tap to the pattern |
| "the on-track click is too sharp" | Decrease sharpness toward 0.40 (warmer) |
| "the on-track click isn't satisfying enough" | Increase intensity slightly (+0.05) and/or increase the continuous tail duration |
| "the transition between zones is jarring" | Increase debounce time or add a third intermediate-intensity play |
| "I keep overshooting the correction" | The directional signal may be too intense — soften the Warm zone pattern |
| "feels robotic" | Add ±0.03 randomization to intensity values per-play |

---

## Implementation Notes for Claude Code

### Updating HapticService.swift

The existing `HapticService.swift` needs to be refactored to support this system. Key changes:

1. **Add direction as an input.** Every zone-based haptic method (except Hot) takes a `CorrectionDirection` parameter:
   ```swift
   enum CorrectionDirection {
       case left   // user should correct left (deviation > 0)
       case right  // user should correct right (deviation < 0)
   }
   ```

2. **Replace the current zone patterns** (single/double/triple tap + continuous buzz) with the directional patterns specified above.

3. **Add the "Nod" pattern** for the Hot zone (transient + continuous tail).

4. **Add the arrival crescendo** as a distinct method.

5. **Add zone transition debouncing** in `NavigationViewModel.swift`, not in `HapticService.swift`. The service plays what it's told; the view model decides when to change zones.

6. **Use Core Haptics for all patterns**, not UIKit generators. The directional asymmetry requires per-tap intensity control that UIKit generators can't provide. Keep UIKit generators only as a device-capability fallback.

### Updating NavigationViewModel.swift

1. Pass `CorrectionDirection` derived from the sign of `deviation` to the haptic service.
2. Implement the 1.5s zone debounce.
3. Implement the boundary intensity blending (first play in a new zone at 75%).
4. Hot zone is always direction-agnostic — ignore deviation sign when in Hot.

### Updating TemperatureZone.swift

The haptic intervals may differ from current values. Use these:

```swift
var hapticInterval: TimeInterval {
    switch self {
    case .hot: return 5.0
    case .warm: return 3.5
    case .cool: return 2.0
    case .cold: return 1.2
    case .freezing: return 0.7
    }
}
```

---

## Testing Protocol (Real Device Walk-Test)

Test each scenario on a real walk:

1. **On-track feel.** Walk straight toward destination. Does the "nod" feel satisfying? Is 5s the right interval — reassuring without nagging?

2. **Direction legibility.** Walk at ~45° off-course to the left, then to the right. Can you tell the difference between rising and falling patterns without looking at the screen? How many repetitions until it becomes automatic?

3. **Zone transitions.** Slowly sweep from on-track to 90° off. Does the escalation feel smooth? Are zone boundaries jarring?

4. **Freezing urgency.** Walk directly away from destination. Does the pattern feel urgent without being unpleasant? Can you still tell which direction to correct?

5. **Arrival payoff.** Walk to the destination and arrive. Does the crescendo feel like a reward? Does it feel like an ending?

Report findings using the adjustment vocabulary above (e.g., "the Warm nudge is too subtle, the Cold triple feels robotic").
