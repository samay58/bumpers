# Bumper V2 Walk Tests

*Route-aware corridor + pocket-first haptics validation protocol.*

---

## Purpose

V2 only matters if it feels like this:

> I forgot I was using it, but I never got meaningfully lost.

These tests validate the two hard risks:

1. The iPhone haptics are noticeable in a front pants pocket while walking.
2. The route-aware corridor feels like safe meandering, not a compass nagging through buildings.

Do not treat simulator success as product success. Simulator testing proves UI flow and state handling. Real walks prove the product.

---

## Preflight

Before each real walk:

- Build the current branch onto a real iPhone.
- Enable location permission.
- Run haptic calibration with the phone in the exact place you plan to carry it.
- Start with `pocketNormal`; switch to `pocketMax` if either side is unclear.
- Confirm the selected navigation mode:
  - Direct: keep me close
  - Room to wander: give me space
  - Scenic: let me drift

Record:

| Field | Value |
|-------|-------|
| Date/time | |
| Route | |
| Phone placement | front pocket / jacket pocket / loose pants / handheld |
| Haptic profile | pocketNormal / pocketMax / handheld / quiet |
| Navigation mode | direct / roomToWander / scenic |
| Weather / street noise | |
| Battery before / after | |

---

## Simulator Validation

Run this before device work after the iOS simulator runtime is installed:

```bash
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' -skip-testing:bumpersUITests test
```

If `iPhone 17` is not available, list devices and choose a concrete installed simulator:

```bash
xcrun simctl list devices available
```

Simulator pass criteria:

- App launches to destination search.
- Search results use nearby context when simulated location is available.
- Wander sheet never shows a fake 15-minute estimate.
- Mode picker works.
- Calibration flow can be completed or skipped.
- Navigation screen shows mode, confidence/debug state, and simple-guidance fallback when routing fails.
- Unit tests pass.

---

## Test 1: Short Direct Route

**Goal:** Confirm baseline route loading, ETA, arrival debounce, and quiet in-lane behavior.

Steps:

1. Pick a destination 5-10 minutes away.
2. Choose `Direct`.
3. Put phone in front pants pocket.
4. Walk the obvious pedestrian route.
5. Do not look at the screen unless something feels wrong.

Expected:

- Search result and ETA feel native-quality.
- In-lane state is mostly silent.
- No repeated false corrections while walking a plausible route.
- Arrival triggers only after staying near the destination for a few seconds.

Log:

| Question | Answer |
|----------|--------|
| Could you feel strong corrections in pocket? | |
| Any false nudges? | |
| Arrival too early / right / too late? | |
| Trust score 1-5 | |

---

## Test 2: Parallel-Street Meander

**Goal:** Prove the corridor allows exploration without nagging.

Steps:

1. Pick a destination 10-15 minutes away.
2. Choose `Room to wander`.
3. Walk one reasonable parallel street instead of the shortest path.
4. Keep making broad progress toward the destination.

Expected:

- The app does not punish a plausible parallel street.
- Corrections begin only when the detour becomes meaningfully unhelpful.
- The visual state stays calm unless you leave the corridor.

Log:

| Question | Answer |
|----------|--------|
| Did it feel like safe meandering? | |
| Did it ever nag through buildings or private blocks? | |
| Which correction, if any, felt unjustified? | |
| Trust score 1-5 | |

---

## Test 3: Intentional Wrong Way

**Goal:** Validate wrong-way detection and the urgent pocket pattern.

Steps:

1. Start any active navigation.
2. Walk away from the destination for at least 30 seconds.
3. Keep the phone in pocket.

Expected:

- Wrong-way state does not trigger instantly.
- After sustained bad progress, a long rumble plays before the directional signature.
- Direction remains legible after the rumble.

Log:

| Question | Answer |
|----------|--------|
| Seconds until wrong-way felt obvious | |
| Could you identify left/right after the rumble? | |
| Too weak / right / too aggressive? | |
| Trust score 1-5 | |

---

## Test 4: Pocket Placement

**Goal:** Decide whether iPhone-only pocket haptics survive real carrying conditions.

Run the same 5-minute route four times or in four segments:

| Placement | Expected Result |
|-----------|-----------------|
| Front jeans pocket | Strong corrections are obvious |
| Jacket pocket | May be weaker; note reliability |
| Loose pants pocket | May blur direction; note reliability |
| Handheld | Should be clearly legible |

Pass criteria:

- Front pocket: strong corrections are reliably noticed.
- Front pocket: left vs right is identifiable within one calibration session.
- Jacket/loose-pocket failures are acceptable only if the app copy and default profile stay honest.

---

## Test 5: Search and ETA

**Goal:** Verify the app feels native before navigation starts.

Queries:

- Exact address: `220 Withers St`
- Nearby POI: `Devoción`
- Park: `McCarren Park`
- Ambiguous/local: `main Williamsburg`

Expected:

- Results prefer nearby plausible places.
- Rows show name, address, and distance when location is available.
- Tapping a result resolves to the right coordinate.
- Walk time shows `Finding your location...`, `Estimating walk...`, `Direct walk: ~N min`, `Rough estimate: ~N min`, or `Unable to estimate yet`.
- It never shows a fake default estimate.

---

## Test 6: Tight Arrival Time

**Goal:** Validate dynamic corridor tightening under time pressure.

Steps:

1. Pick a 10-minute destination.
2. Set arrival time to 11-12 minutes from now.
3. Choose `Room to wander`.
4. Try a small detour.

Expected:

- Wander budget copy says to leave now or gives a very small budget.
- Corridor tightens enough to discourage meaningful detours.
- The app still avoids turn-by-turn instructions.

---

## Test 7: Low Confidence

**Goal:** Confirm the app degrades honestly when location or heading is unreliable.

Good locations:

- Tall buildings.
- Under scaffolding.
- Indoors near the entrance before stepping outside.

Expected:

- If horizontal accuracy is worse than 50m, no directional haptics fire.
- If heading/course is unavailable while stationary, no fake left/right correction fires.
- The UI exposes uncertainty without becoming noisy.

---

## Kill / Pivot Gate

Continue iPhone-only V2 only if these are true after real walks:

- In a front pocket, strong correction haptics are reliably noticeable while walking.
- Left vs right is identifiable within one calibration session.
- On a 15-minute city walk, false nudges are rare enough that trust increases over time.
- Search and ETA feel native-quality.
- The app feels calmer and more useful than opening Apple Maps for exploratory walking.

If the haptic criteria fail because the phone is not perceptible enough through clothing, pivot to Apple Watch or wearable-first haptics instead of polishing iPhone-only navigation.
