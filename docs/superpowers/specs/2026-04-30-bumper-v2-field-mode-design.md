# Bumper V2 Field Mode Design

## Purpose

Bumper V2 needs a validation rig before it needs more polish. The current route-aware prototype is too quiet to evaluate on a real walk. When the user is inside the corridor, the orb can stay visually calm, haptics stay silent, and the status reads as technically correct but emotionally dead. That makes a field test feel meaningless even if the engine is working.

Field Mode makes the app louder, clearer, and more diagnostic so one question can be answered quickly:

> Can an iPhone in a real pocket reliably tell the walker left, right, wrong way, and keep going?

This mode is allowed to be less elegant than the eventual product. It exists to prove or disprove iPhone pocket viability.

## Scope

Build a validation-first version of the existing V2 flow.

In scope:

- Stronger default haptic profile for field testing.
- Shorter haptic cooldowns and earlier correction feedback in Field Mode.
- One-screen setup preflight with left, right, and max haptic tests.
- Faster path from destination selection to walking.
- Navigation screen instrumentation that proves location, heading, route state, correction, and haptics are live.
- Orb behavior that shows live state during in-lane walking, drifting, off-course, wrong-way, and low-confidence states.
- Updated tests and docs for Field Mode behavior and pocket-viability criteria.

Out of scope:

- Apple Watch or wearable implementation.
- New routing engine.
- Turn-by-turn instructions.
- Blue route line in the normal navigation experience.
- Broad Home, Search, or Arrival redesign.
- Final-product minimalism. Field Mode can be explicit and diagnostic.

## Current Failure

The current code is internally coherent but poor for field validation.

`CorridorNavigationEngine` returns `.inLane` with no correction direction, no haptic, urgency `0`, and visual temperature `.hot` when the user is inside the route corridor and not losing progress. `NavigationViewModel.directionShift` depends on `currentInstruction.correctionDirection`, so it returns `0` in that state. `OrbView` only shifts from that value. The result is a hot, calm orb that may look inert.

That is philosophically consistent with "silence is success," but it leaves the tester unable to tell whether the route, heading, haptics, and orb are working.

The setup flow has a similar trust problem. It asks the user to complete a calibration sequence before the product has earned confidence. The copy is earnest, but the interaction feels slow. A field test should feel like arming an instrument, not answering a tutorial.

The haptic defaults are also too restrained for the current stage. `pocketNormal` scales energy to `0.78`, while calibration uses medium correction patterns. That is a reasonable product default only after hardware viability is proven. It is too polite for a kill-gate test.

## Recommended Approach

Make Field Mode the default validation posture for now. The app should start from stronger haptics, visible liveliness, and fast preflight. Later, the final product can keep what works and calm the rest down.

Minimal tuning alone is not enough. Simply increasing intensities would still leave the tester guessing whether silence means success or failure. A compass-like orb alone would misrepresent corridor guidance. The right move is a combined field instrument: stronger haptics plus truthful visual diagnostics.

This plan assumes Core Haptics can become meaningfully more legible through pattern shape, stronger default profile, shorter cooldowns, and better setup. If that assumption fails on real walks, the next decision is a wearable-first pivot, not more iPhone UI polish.

## User Experience

After choosing a destination, the user sees a compact preflight screen:

- Destination and selected navigation mode.
- Haptic profile set to Field Max by default.
- Buttons for "Test right," "Test left," and "Max buzz."
- A clear "Start walking" action.
- A secondary "Too weak" action that switches or keeps Field Max and immediately replays a stronger cue.

The preflight should take seconds. It replaces the current walkthrough-style calibration as the main path. The detailed explanation can be kept behind secondary copy or removed during Field Mode.

During navigation, the screen should visibly prove that the system is alive:

- Status chip includes route state and key diagnostics, for example `In lane · heading OK` or `Drifting right · last buzz 3s ago`.
- Orb always shows a live signal. In-lane can use a subtle breathing, route-confidence shimmer, or destination-bearing bias. Drifting and off-course use stronger hotspot movement. Wrong-way uses an obvious cold/urgent state. Low confidence shows uncertainty.
- Debug overlay remains available and should expose heading, bearing, deviation, corridor distance if available, route mode, correction direction, shift, haptic profile, last haptic age, and current cooldown.

Normal product mode can later hide or soften these details. Field Mode should not.

## Haptic Behavior

Add or repurpose a strongest validation profile named `fieldMax`.

Field Max behavior:

- Energy at the maximum useful Core Haptics level.
- Stronger continuous pulses with longer duration where needed for pocket perception.
- Shorter cooldowns than current product profiles.
- Calibration and preflight use strong or urgent patterns, not medium.
- Direction language remains duration-based: short-long means right, long-short means left.
- Wrong-way remains a rumble followed by directional signature.

In-lane behavior should stay mostly silent. Field Mode may add a rare "tracking alive" cue only if needed, with a long interval and low semantic weight. It must not train the user to expect constant buzzing.

Drifting should be more sensitive in Field Mode. The threshold can be tightened in the engine or applied as a Field Mode modifier around corridor width, severity, and cooldown. The implementation should keep the route-aware product contract intact: no fake correction when confidence is low.

## Visual Behavior

The orb should become an instrument in Field Mode.

Required states:

- In lane: warm/hot, visibly alive, no correction direction unless the engine emits one.
- Drifting: warm/cool, clear hotspot movement toward the correction direction.
- Off course: cold, stronger hotspot movement and bump on haptic fire.
- Wrong way: freezing, urgent visual state.
- Low confidence: muted or unstable visual treatment that reads as uncertainty, not direction.
- Simple guidance: explicitly labeled and more bearing-reactive because corridor routing is unavailable.

The orb should not become a false map or turn-by-turn display. It can show bearing/correction energy, confidence, and last haptic state, but it must not imply a route line.

## Architecture

Use existing boundaries.

```text
WanderDialSheet / Preflight
  -> selects profile and validation mode
  -> runs manual haptic tests
  -> creates NavigationViewModel

CorridorNavigationEngine
  -> emits correction state, confidence, severity, urgency

NavigationViewModel
  -> derives Field Mode haptic cadence, last haptic metadata, orb signal

NavigationView / OrbView
  -> render diagnostics and live visual signal

HapticPatternFactory / HapticService
  -> generate and play stronger pocket patterns
```

Prefer small extensions to current types over a new service unless the implementation becomes tangled. Field Mode can be represented as a validation flag or navigation configuration passed from setup into the view model. If a new model is introduced, it should be a small value type that owns profile, sensitivity, cooldown scale, and diagnostic display behavior.

No data migration is required. Persisting the selected haptic profile through `@AppStorage` is acceptable. If Field Mode becomes a separate setting, default it on during validation.

## Implementation Surface

Expected files:

- `bumpers/Models/HapticProfile.swift`
- `bumpers/Services/HapticPatternFactory.swift`
- `bumpers/Features/Calibration/HapticCalibrationFlow.swift`
- `bumpers/Features/Calibration/HapticCalibrationView.swift`
- `bumpers/Features/Home/WanderDialSheet.swift`
- `bumpers/Features/Navigation/NavigationViewModel.swift`
- `bumpers/Features/Navigation/NavigationView.swift`
- `bumpers/Features/Navigation/OrbView.swift`
- `bumpers/Services/CorridorNavigationEngine.swift`
- `bumpersTests/HapticPatternFactoryTests.swift`
- `bumpersTests/HapticCalibrationFlowTests.swift`
- `bumpersTests/V2NavigationTests.swift`
- `docs/PLAN.md`
- `docs/BUILD-LOG.md`
- `docs/WALK-TESTS.md`

This is more than eight files because the failure crosses setup, haptics, navigation feedback, tests, and documentation. Keep edits focused on Field Mode.

## Testing

Automated checks:

- Field Max exists and is stronger than current pocket profiles.
- Directional duration order still matches right and left semantics.
- Field Mode cooldowns are shorter than normal product cooldowns.
- Preflight actions play right, left, and max buzz patterns.
- In-lane Field Mode produces a live visual signal without directional haptics.
- Drifting and off-course states create clear direction shift and haptic metadata.
- Low-confidence states still suppress directional haptics.
- Existing V2 navigation tests continue to pass.

Manual simulator checks:

- Destination selection opens preflight quickly.
- Preflight can test right, left, and max buzz without navigating.
- Start walking transitions cleanly into navigation.
- Navigation shows route state, profile, last haptic, and confidence diagnostics.
- Orb visibly changes across forced or simulated states.

Manual device checks:

- Front pocket can feel right, left, and max buzz before walking.
- During a short walk, Field Max corrections are noticeable.
- Left versus right is learnable within one preflight session.
- In-lane state looks alive but does not buzz constantly.
- Drift and wrong-way states fire sooner and more clearly than the current build.

## Kill Criteria

After Field Mode is implemented, continue iPhone-only Bumper only if these are true on real walks:

- Front-pocket strong corrections are reliably noticeable while walking.
- Left and right are identifiable within one preflight session.
- Wrong-way rumble is unmistakable without looking at the screen.
- The user can tell within 60 seconds whether the app is tracking live state.
- The app feels more useful than opening Apple Maps for exploratory walking.

If these fail with Field Max, document the failure and spec the Apple Watch or wearable-first pivot.

## Rollback

Field Mode can be made non-default or removed without touching user data. The routing engine, destination search, recent destinations, and arrival records do not depend on it. The safest rollback is:

- Default back to `pocketNormal`.
- Hide field diagnostics.
- Keep any haptic pattern improvements that tested well.
- Keep the faster preflight only if it improves setup without reducing trust.
