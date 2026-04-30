# Bumper V2 Field Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Bumper V2 Field Mode so real-device walks can quickly prove whether iPhone pocket haptics are strong, legible, and trustworthy enough.

**Architecture:** Add a small Field Mode model layer that owns validation defaults, orb signal derivation, and diagnostics text. Keep route decisions in `CorridorNavigationEngine`, orchestration in `NavigationViewModel`, setup in `WanderDialSheet`, rendering in `NavigationView` and `OrbView`, and haptic pattern construction in `HapticPatternFactory`.

**Tech Stack:** SwiftUI, Swift Testing, CoreLocation, MapKit route corridor logic, Core Haptics, ActivityKit remains unchanged.

---

## File Structure

- Create `bumpers/Models/FieldMode.swift`
  - Owns Field Mode defaults, `FieldOrbSignal`, and diagnostic text. This keeps validation behavior testable without bloating `NavigationViewModel`.
- Create `bumpersTests/FieldModeTests.swift`
  - Tests orb liveliness and diagnostics without requiring simulator UI.
- Modify `bumpers/Models/HapticProfile.swift`
  - Adds `fieldMax` plus profile-specific cooldown and duration tuning.
- Modify `bumpers/Services/HapticPatternFactory.swift`
  - Applies `fieldMax` intensity, duration, and cooldown scaling.
- Modify `bumpers/Features/Calibration/HapticCalibrationFlow.swift`
  - Adds preflight haptic cue mapping and upgrades calibration cue severity for Field Mode.
- Modify `bumpersTests/HapticPatternFactoryTests.swift`
  - Covers stronger Field Max energy, longer continuous pulses, and shorter cooldown.
- Modify `bumpersTests/HapticCalibrationFlowTests.swift`
  - Covers strong calibration cues and preflight left/right/max buzz mapping.
- Modify `bumpers/Features/Home/WanderDialSheet.swift`
  - Makes Field Mode the validation default, bypasses walkthrough calibration, adds preflight test controls, and starts navigation with Field Mode enabled.
- Modify `bumpers/Features/Navigation/NavigationViewModel.swift`
  - Accepts Field Mode flag, passes sensitivity into the corridor engine, tracks last haptic metadata, exposes field diagnostics and orb signal.
- Modify `bumpers/Services/CorridorNavigationEngine.swift`
  - Adds optional Field Mode sensitivity that tightens the corridor without changing product mode defaults.
- Modify `bumpersTests/V2NavigationTests.swift`
  - Covers earlier Field Mode drift while preserving low-confidence suppression.
- Modify `bumpers/Features/Navigation/NavigationView.swift`
  - Displays Field Mode diagnostics and uses the Field Mode orb signal.
- Modify `bumpers/Features/Navigation/OrbView.swift`
  - Renders an alive visual signal separate from correction-only hotspot movement.
- Modify `docs/PLAN.md`, `docs/WALK-TESTS.md`, and `docs/BUILD-LOG.md`
  - Records Field Mode behavior, validation commands, and real-device kill criteria.

---

### Task 1: Field Mode Model And Orb Signal

**Files:**
- Create: `bumpers/Models/FieldMode.swift`
- Create: `bumpersTests/FieldModeTests.swift`

- [ ] **Step 1: Write failing tests for Field Mode orb signal and diagnostics**

Create `bumpersTests/FieldModeTests.swift`:

```swift
import Testing
@testable import bumpers

struct FieldModeTests {

    @Test func inLaneFieldModeKeepsOrbAliveWithoutDirectionalCorrection() {
        let instruction = CorrectionInstruction(
            state: .inLane,
            correctionDirection: nil,
            severity: .gentle,
            urgency: 0,
            hapticPattern: .none,
            visualTemperature: .hot,
            confidence: 0.82,
            usesSimpleGuidance: false
        )

        let signal = FieldOrbSignal.make(
            instruction: instruction,
            deviation: 45,
            fieldModeEnabled: true
        )

        #expect(signal.shift > 0)
        #expect(signal.shift <= 0.18)
        #expect(signal.isAlive)
        #expect(!signal.isDirectionalCorrection)
    }

    @Test func correctionDirectionWinsOverAliveBias() {
        let instruction = CorrectionInstruction(
            state: .offCourse(direction: .left, severity: .strong),
            correctionDirection: .left,
            severity: .strong,
            urgency: 0.9,
            hapticPattern: .correctLeft(severity: .strong),
            visualTemperature: .cold,
            confidence: 0.8,
            usesSimpleGuidance: false
        )

        let signal = FieldOrbSignal.make(
            instruction: instruction,
            deviation: 20,
            fieldModeEnabled: true
        )

        #expect(signal.shift < -0.85)
        #expect(signal.isAlive)
        #expect(signal.isDirectionalCorrection)
    }

    @Test func productModeKeepsInLaneOrbStill() {
        let instruction = CorrectionInstruction(
            state: .inLane,
            correctionDirection: nil,
            severity: .gentle,
            urgency: 0,
            hapticPattern: .none,
            visualTemperature: .hot,
            confidence: 0.8,
            usesSimpleGuidance: false
        )

        let signal = FieldOrbSignal.make(
            instruction: instruction,
            deviation: 90,
            fieldModeEnabled: false
        )

        #expect(signal.shift == 0)
        #expect(!signal.isAlive)
        #expect(!signal.isDirectionalCorrection)
    }

    @Test func diagnosticsMentionStateProfileAndHapticAge() {
        let instruction = CorrectionInstruction(
            state: .drifting(direction: .right, severity: .medium),
            correctionDirection: .right,
            severity: .medium,
            urgency: 0.5,
            hapticPattern: .correctRight(severity: .medium),
            visualTemperature: .cool,
            confidence: 0.74,
            usesSimpleGuidance: false
        )

        let diagnostics = FieldModeDiagnostics.text(
            instruction: instruction,
            hapticProfile: .fieldMax,
            lastHapticAge: 3.2,
            cooldown: 1.4,
            headingAvailable: true
        )

        #expect(diagnostics.contains("Drifting right"))
        #expect(diagnostics.contains("Field Max"))
        #expect(diagnostics.contains("buzz 3s ago"))
        #expect(diagnostics.contains("cooldown 1.4s"))
    }
}
```

- [ ] **Step 2: Run the new tests to verify they fail**

Run:

```bash
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:bumpersTests/FieldModeTests test -quiet
```

Expected: FAIL with errors that `FieldOrbSignal`, `FieldModeDiagnostics`, and `HapticProfile.fieldMax` cannot be found.

- [ ] **Step 3: Add the Field Mode model**

Create `bumpers/Models/FieldMode.swift`:

```swift
import Foundation

struct FieldModeSettings: Equatable {
    let isEnabled: Bool
    let hapticProfile: HapticProfile

    static let validationDefault = FieldModeSettings(
        isEnabled: true,
        hapticProfile: .fieldMax
    )

    static let productDefault = FieldModeSettings(
        isEnabled: false,
        hapticProfile: .pocketNormal
    )
}

struct FieldOrbSignal: Equatable {
    let shift: Double
    let isAlive: Bool
    let isDirectionalCorrection: Bool

    static func make(
        instruction: CorrectionInstruction,
        deviation: Double,
        fieldModeEnabled: Bool
    ) -> FieldOrbSignal {
        if let direction = instruction.correctionDirection {
            let magnitude = max(0.2, min(1, instruction.urgency))
            return FieldOrbSignal(
                shift: direction == .right ? magnitude : -magnitude,
                isAlive: true,
                isDirectionalCorrection: true
            )
        }

        guard fieldModeEnabled else {
            return FieldOrbSignal(shift: 0, isAlive: false, isDirectionalCorrection: false)
        }

        switch instruction.state {
        case .inLane:
            let liveBias = max(-0.18, min(0.18, deviation / 360))
            return FieldOrbSignal(shift: liveBias, isAlive: true, isDirectionalCorrection: false)
        case .simpleGuidance:
            let liveBias = max(-0.35, min(0.35, deviation / 240))
            return FieldOrbSignal(shift: liveBias, isAlive: true, isDirectionalCorrection: false)
        case .acquiringLocation, .lowConfidence:
            return FieldOrbSignal(shift: 0, isAlive: true, isDirectionalCorrection: false)
        case .arrived:
            return FieldOrbSignal(shift: 0, isAlive: true, isDirectionalCorrection: false)
        case .drifting, .offCourse, .wrongWay:
            return FieldOrbSignal(shift: 0, isAlive: true, isDirectionalCorrection: false)
        }
    }
}

enum FieldModeDiagnostics {
    static func text(
        instruction: CorrectionInstruction,
        hapticProfile: HapticProfile,
        lastHapticAge: TimeInterval?,
        cooldown: TimeInterval,
        headingAvailable: Bool
    ) -> String {
        let state = stateLabel(for: instruction, headingAvailable: headingAvailable)
        let buzz = buzzLabel(lastHapticAge)
        let cooldownText = cooldown > 0 ? "cooldown \(String(format: "%.1f", cooldown))s" : "no cooldown"
        return "\(state) - \(hapticProfile.displayName) - \(buzz) - \(cooldownText)"
    }

    private static func stateLabel(
        for instruction: CorrectionInstruction,
        headingAvailable: Bool
    ) -> String {
        switch instruction.state {
        case .acquiringLocation:
            return "Finding location"
        case .lowConfidence(.poorLocationAccuracy):
            return "GPS uncertain"
        case .lowConfidence(.headingUnavailable):
            return headingAvailable ? "Calibrating direction" : "Need walking direction"
        case .lowConfidence(.locationUnavailable):
            return "Location unavailable"
        case .inLane:
            return "In lane"
        case .drifting(let direction, _):
            return "Drifting \(direction.label)"
        case .offCourse(let direction, _):
            return "Off course \(direction.label)"
        case .wrongWay:
            return "Wrong way"
        case .arrived:
            return "Arrived"
        case .simpleGuidance:
            return "Simple guidance"
        }
    }

    private static func buzzLabel(_ lastHapticAge: TimeInterval?) -> String {
        guard let lastHapticAge else {
            return "no buzz yet"
        }
        return "buzz \(Int(lastHapticAge.rounded()))s ago"
    }
}
```

- [ ] **Step 4: Temporarily add `fieldMax` to `HapticProfile` so Task 1 compiles**

In `bumpers/Models/HapticProfile.swift`, add `case fieldMax` before `case pocketMax`, then update `displayName`:

```swift
case .fieldMax: return "Field Max"
```

Update `energyScale` with a temporary value:

```swift
case .fieldMax: return 1.18
```

Update `allowsOnTrackNod` so Field Max allows alive nudges:

```swift
self != .quiet
```

- [ ] **Step 5: Run Field Mode tests**

Run:

```bash
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:bumpersTests/FieldModeTests test -quiet
```

Expected: PASS. Existing Swift 6 warning debt in other tests may still appear if Xcode compiles the full test target.

- [ ] **Step 6: Commit Task 1**

```bash
git add bumpers/Models/FieldMode.swift bumpers/Models/HapticProfile.swift bumpersTests/FieldModeTests.swift
git commit -m "feat: add field mode signal model"
```

---

### Task 2: Field Max Haptic Strength And Cadence

**Files:**
- Modify: `bumpers/Models/HapticProfile.swift`
- Modify: `bumpers/Services/HapticPatternFactory.swift`
- Modify: `bumpersTests/HapticPatternFactoryTests.swift`

- [ ] **Step 1: Add failing haptic strength tests**

Append these tests inside `HapticPatternFactoryTests`:

```swift
@Test func fieldMaxUsesStrongerContinuousEnergyThanPocketMax() throws {
    let factory = HapticPatternFactory()
    let field = factory.makePattern(.correctLeft(severity: .medium), profile: .fieldMax)
    let max = factory.makePattern(.correctLeft(severity: .medium), profile: .pocketMax)

    let fieldContinuous = try #require(field.events.first { $0.type == .continuous })
    let maxContinuous = try #require(max.events.first { $0.type == .continuous })

    #expect(fieldContinuous.intensity > maxContinuous.intensity)
    #expect(fieldContinuous.duration > maxContinuous.duration)
    #expect(field.cooldown < max.cooldown)
}

@Test func fieldMaxWrongWayHasLongPocketLegibleRumble() throws {
    let factory = HapticPatternFactory()
    let pattern = factory.makePattern(.wrongWay(direction: .right), profile: .fieldMax)
    let rumble = try #require(pattern.events.first)

    #expect(rumble.type == .continuous)
    #expect(rumble.intensity == 1)
    #expect(rumble.duration >= 0.55)
    #expect(pattern.cooldown <= 0.9)
}
```

- [ ] **Step 2: Run haptic tests to verify they fail**

Run:

```bash
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:bumpersTests/HapticPatternFactoryTests test -quiet
```

Expected: FAIL because Field Max does not yet apply duration or cooldown scaling.

- [ ] **Step 3: Complete `HapticProfile` tuning properties**

In `bumpers/Models/HapticProfile.swift`, update the enum so it has these cases:

```swift
enum HapticProfile: String, CaseIterable, Codable, Identifiable {
    case fieldMax
    case pocketMax
    case pocketNormal
    case handheld
    case quiet
```

Update `displayName`:

```swift
var displayName: String {
    switch self {
    case .fieldMax: return "Field Max"
    case .pocketMax: return "Pocket Max"
    case .pocketNormal: return "Pocket Normal"
    case .handheld: return "Handheld"
    case .quiet: return "Quiet"
    }
}
```

Update `energyScale`:

```swift
var energyScale: Float {
    switch self {
    case .fieldMax: return 1.18
    case .pocketMax: return 1.0
    case .pocketNormal: return 0.78
    case .handheld: return 0.62
    case .quiet: return 0.42
    }
}
```

Add these properties below `energyScale`:

```swift
var cooldownScale: Double {
    switch self {
    case .fieldMax: return 0.62
    case .pocketMax: return 0.82
    case .pocketNormal, .handheld, .quiet: return 1.0
    }
}

var continuousDurationScale: Double {
    switch self {
    case .fieldMax: return 1.28
    case .pocketMax: return 1.08
    case .pocketNormal, .handheld, .quiet: return 1.0
    }
}

var wrongWayRumbleDuration: TimeInterval {
    switch self {
    case .fieldMax: return 0.58
    case .pocketMax: return 0.50
    case .pocketNormal, .handheld, .quiet: return 0.45
    }
}
```

- [ ] **Step 4: Apply profile scaling in `HapticPatternFactory`**

In `HapticPatternFactory.makePattern`, update wrong-way rumble to use profile duration:

```swift
continuous(
    at: 0,
    duration: profile.wrongWayRumbleDuration,
    intensity: 1.0 * profile.energyScale,
    sharpness: 0.10
)
```

In `directional(direction:severity:profile:kind:)`, replace the final return with:

```swift
return HapticPattern(kind: kind, events: events, cooldown: cooldown * profile.cooldownScale)
```

In the `.wrongWay` case, replace `cooldown: 1.2` with:

```swift
cooldown: 1.2 * profile.cooldownScale
```

In `signature(direction:severity:profile:start:)`, add:

```swift
let longDuration = params.longDuration * profile.continuousDurationScale
```

Use `longDuration` for both continuous events:

```swift
continuous(at: start + 0.12, duration: longDuration, intensity: params.longIntensity * scale, sharpness: params.longSharpness)
```

and:

```swift
continuous(at: start, duration: longDuration, intensity: params.longIntensity * scale, sharpness: params.longSharpness)
```

- [ ] **Step 5: Run haptic tests**

Run:

```bash
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:bumpersTests/HapticPatternFactoryTests test -quiet
```

Expected: PASS.

- [ ] **Step 6: Commit Task 2**

```bash
git add bumpers/Models/HapticProfile.swift bumpers/Services/HapticPatternFactory.swift bumpersTests/HapticPatternFactoryTests.swift
git commit -m "feat: strengthen field mode haptics"
```

---

### Task 3: Preflight Cue Mapping And Strong Calibration Defaults

**Files:**
- Modify: `bumpers/Features/Calibration/HapticCalibrationFlow.swift`
- Modify: `bumpersTests/HapticCalibrationFlowTests.swift`

- [ ] **Step 1: Add failing calibration and preflight tests**

In `HapticCalibrationFlowTests`, update the existing medium expectations to strong:

```swift
#expect(transition == .play(.correctRight(severity: .strong)))
#expect(transition == .play(.correctLeft(severity: .strong)))
#expect(flow.replay() == .play(.correctRight(severity: .strong)))
#expect(flow.replay() == .play(.correctLeft(severity: .strong)))
```

Append this test:

```swift
@Test func preflightCueMappingUsesFieldStrengthPatterns() {
    #expect(HapticCalibrationFlow.preflightPattern(for: .right) == .correctRight(severity: .strong))
    #expect(HapticCalibrationFlow.preflightPattern(for: .left) == .correctLeft(severity: .strong))
    #expect(HapticCalibrationFlow.preflightPattern(for: .maxBuzz) == .wrongWay(direction: nil))
}
```

- [ ] **Step 2: Run calibration tests to verify they fail**

Run:

```bash
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:bumpersTests/HapticCalibrationFlowTests test -quiet
```

Expected: FAIL because calibration still emits `.medium`, and `PreflightHapticCue` does not exist.

- [ ] **Step 3: Add preflight cue enum and strong mappings**

At the top of `HapticCalibrationFlow.swift`, below `import Foundation`, add:

```swift
enum PreflightHapticCue: Equatable {
    case right
    case left
    case maxBuzz
}
```

Inside `HapticCalibrationFlow`, add:

```swift
static func preflightPattern(for cue: PreflightHapticCue) -> HapticPatternKind {
    switch cue {
    case .right:
        return .correctRight(severity: .strong)
    case .left:
        return .correctLeft(severity: .strong)
    case .maxBuzz:
        return .wrongWay(direction: nil)
    }
}
```

Update `start()`:

```swift
mutating func start() -> Transition {
    step = .right
    return .play(.correctRight(severity: .strong))
}
```

Update `replay()`:

```swift
mutating func replay() -> Transition? {
    switch step {
    case .intro:
        return nil
    case .right:
        return .play(.correctRight(severity: .strong))
    case .left:
        return .play(.correctLeft(severity: .strong))
    }
}
```

Update the `.right` branch in `record(_:)`:

```swift
case .right:
    rightResult = result
    step = .left
    return .play(.correctLeft(severity: .strong))
```

- [ ] **Step 4: Run calibration tests**

Run:

```bash
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:bumpersTests/HapticCalibrationFlowTests test -quiet
```

Expected: PASS.

- [ ] **Step 5: Commit Task 3**

```bash
git add bumpers/Features/Calibration/HapticCalibrationFlow.swift bumpersTests/HapticCalibrationFlowTests.swift
git commit -m "feat: add field preflight haptic cues"
```

---

### Task 4: Field Mode Preflight In WanderDial

**Files:**
- Modify: `bumpers/Features/Home/WanderDialSheet.swift`

- [ ] **Step 1: Change Field Mode defaults**

In `WanderDialSheet`, replace:

```swift
@AppStorage("hapticProfile") private var hapticProfileRawValue = HapticProfile.pocketNormal.rawValue
```

with:

```swift
@AppStorage("hapticProfile") private var hapticProfileRawValue = FieldModeSettings.validationDefault.hapticProfile.rawValue
@AppStorage("fieldModeEnabled") private var fieldModeEnabled = FieldModeSettings.validationDefault.isEnabled
```

- [ ] **Step 2: Make setup default to planning while Field Mode is enabled**

Replace `initializeStageIfNeeded()` with:

```swift
private func initializeStageIfNeeded() {
    guard !hasInitializedStage else { return }
    hasInitializedStage = true
    sheetStage = fieldModeEnabled || hasSeenHapticCalibration ? .planning : .calibration
    calibrationHapticService.prepare()
}
```

- [ ] **Step 3: Add preflight haptic controls**

In `planningStage`, insert this block after `NavigationModePicker(...)` and before `wanderDial`:

```swift
preflightHapticPanel
    .padding(.horizontal, Theme.Spacing.xxl)
    .padding(.bottom, Theme.Spacing.xl)
    .opacity(isTransitioning ? 0 : 1)
```

Add this view below `walkTimeEstimate`:

```swift
private var preflightHapticPanel: some View {
    VStack(spacing: Theme.Spacing.md) {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Field haptics")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)

                Text(hapticProfile.displayName)
                    .font(Theme.labelFont)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            Button("Too weak") {
                hapticProfileRawValue = HapticProfile.fieldMax.rawValue
                playPreflightCue(.maxBuzz)
            }
            .font(Theme.labelFont)
            .foregroundStyle(Theme.warm.inner)
        }

        HStack(spacing: Theme.Spacing.sm) {
            preflightButton("Test left", cue: .left)
            preflightButton("Test right", cue: .right)
            preflightButton("Max buzz", cue: .maxBuzz)
        }
    }
    .padding(Theme.Spacing.md)
    .background(Theme.surfaceSubtle)
    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    .overlay(
        RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
            .stroke(Theme.borderSubtle, lineWidth: 1)
    )
}

private func preflightButton(_ title: String, cue: PreflightHapticCue) -> some View {
    Button(title) {
        playPreflightCue(cue)
    }
    .font(Theme.labelFont)
    .foregroundStyle(Theme.textSecondary)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .background(Theme.surfaceElevated)
    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
}
```

Add this helper below `runCalibrationTransition(_:)`:

```swift
private func playPreflightCue(_ cue: PreflightHapticCue) {
    calibrationHapticService.prepare()
    calibrationHapticService.play(
        HapticCalibrationFlow.preflightPattern(for: cue),
        profile: hapticProfile
    )
}
```

- [ ] **Step 4: Pass Field Mode into navigation**

Update `createViewModel()`:

```swift
private func createViewModel() -> NavigationViewModel {
    NavigationViewModel(
        destination: destination,
        arrivalTime: arrivalTime,
        mode: selectedMode,
        locationService: locationService,
        hapticProfile: hapticProfile,
        fieldModeEnabled: fieldModeEnabled
    )
}
```

This will fail to compile until Task 5 adds the `NavigationViewModel` initializer parameter.

- [ ] **Step 5: Commit Task 4 after Task 5 compiles**

Do not commit Task 4 separately if the project does not compile after Step 4. Commit it together with Task 5:

```bash
git add bumpers/Features/Home/WanderDialSheet.swift
git commit -m "feat: add field mode preflight controls"
```

---

### Task 5: Field Mode Sensitivity, Haptic Metadata, And ViewModel Signals

**Files:**
- Modify: `bumpers/Services/CorridorNavigationEngine.swift`
- Modify: `bumpers/Features/Navigation/NavigationViewModel.swift`
- Modify: `bumpersTests/V2NavigationTests.swift`

- [ ] **Step 1: Add failing Field Mode sensitivity test**

Append this test to `V2NavigationTests`:

```swift
@Test func fieldModeTightensCorridorForEarlierDrift() {
    let start = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    let end = CLLocationCoordinate2D(latitude: 0, longitude: 0.01)
    let corridor = RouteCorridor(routes: [makeRoute(start, end)], mode: .direct, destination: end)
    let normalEngine = CorridorNavigationEngine()
    let fieldEngine = CorridorNavigationEngine()

    let location = makeLocation(latitude: 0.00026, longitude: 0.005, accuracy: 8, speed: 1.2)

    let normal = normalEngine.instruction(
        for: CorridorNavigationInput(
            currentLocation: location,
            currentHeading: 90,
            destination: end,
            corridor: corridor,
            mode: .direct,
            arrivalTime: nil,
            now: Date(timeIntervalSince1970: 100)
        )
    )

    let field = fieldEngine.instruction(
        for: CorridorNavigationInput(
            currentLocation: location,
            currentHeading: 90,
            destination: end,
            corridor: corridor,
            mode: .direct,
            arrivalTime: nil,
            now: Date(timeIntervalSince1970: 100),
            fieldModeEnabled: true
        )
    )

    #expect(normal.state == .inLane)
    if case .drifting = field.state {
        #expect(field.hapticPattern != .none)
    } else {
        Issue.record("Expected field mode drift, got \(field.state)")
    }
}
```

- [ ] **Step 2: Run navigation tests to verify the new test fails**

Run:

```bash
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:bumpersTests/V2NavigationTests test -quiet
```

Expected: FAIL because `fieldModeEnabled` is not part of `CorridorNavigationInput`.

- [ ] **Step 3: Add Field Mode input to the corridor engine**

In `CorridorNavigationInput`, add:

```swift
let fieldModeEnabled: Bool

init(
    currentLocation: CLLocation?,
    currentHeading: Double?,
    destination: CLLocationCoordinate2D,
    corridor: RouteCorridor?,
    mode: NavigationMode,
    arrivalTime: Date?,
    now: Date,
    fieldModeEnabled: Bool = false
) {
    self.currentLocation = currentLocation
    self.currentHeading = currentHeading
    self.destination = destination
    self.corridor = corridor
    self.mode = mode
    self.arrivalTime = arrivalTime
    self.now = now
    self.fieldModeEnabled = fieldModeEnabled
}
```

After computing `width`, add:

```swift
let effectiveWidth = input.fieldModeEnabled ? width * 0.72 : width
```

Replace later uses of `width` in the in-lane and `ratio` calculations with `effectiveWidth`:

```swift
if projection.distanceFromCorridorCenter <= effectiveWidth,
   trend.distanceDelta <= 15 || trend.progressDelta >= -0.01 {
```

and:

```swift
let ratio = projection.distanceFromCorridorCenter / max(effectiveWidth, 1)
```

- [ ] **Step 4: Add Field Mode state to `NavigationViewModel`**

In `NavigationViewModel`, add properties near `hapticProfile`:

```swift
var fieldModeEnabled: Bool
var lastHapticFiredAt: Date?
var currentHapticCooldown: TimeInterval = 0
```

Add computed properties:

```swift
var orbSignal: FieldOrbSignal {
    FieldOrbSignal.make(
        instruction: currentInstruction,
        deviation: deviation,
        fieldModeEnabled: fieldModeEnabled
    )
}

var lastHapticAge: TimeInterval? {
    guard let lastHapticFiredAt else { return nil }
    return Date().timeIntervalSince(lastHapticFiredAt)
}

var fieldDiagnosticsText: String {
    FieldModeDiagnostics.text(
        instruction: currentInstruction,
        hapticProfile: hapticProfile,
        lastHapticAge: lastHapticAge,
        cooldown: currentHapticCooldown,
        headingAvailable: hasHeading
    )
}
```

Update the initializer signature:

```swift
hapticProfile: HapticProfile = .pocketNormal,
fieldModeEnabled: Bool = false
```

Inside the initializer body:

```swift
self.fieldModeEnabled = fieldModeEnabled
```

In `startNavigation()`, reset:

```swift
lastHapticFiredAt = nil
currentHapticCooldown = 0
```

When creating `CorridorNavigationInput`, pass:

```swift
fieldModeEnabled: fieldModeEnabled
```

In `fireHapticsIfNeeded()`, after creating `pattern`, set:

```swift
currentHapticCooldown = pattern.cooldown
```

After `hapticService.play(kind, profile: hapticProfile)`, set:

```swift
lastHapticFiredAt = now
```

- [ ] **Step 5: Run navigation tests**

Run:

```bash
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:bumpersTests/V2NavigationTests test -quiet
```

Expected: PASS.

- [ ] **Step 6: Run a build to catch Task 4 and Task 5 integration**

Run:

```bash
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 7: Commit Task 4 and Task 5 together if Task 4 was not committed**

```bash
git add bumpers/Features/Home/WanderDialSheet.swift bumpers/Features/Navigation/NavigationViewModel.swift bumpers/Services/CorridorNavigationEngine.swift bumpersTests/V2NavigationTests.swift
git commit -m "feat: wire field mode into navigation"
```

---

### Task 6: Navigation UI And Orb Liveliness

**Files:**
- Modify: `bumpers/Features/Navigation/NavigationView.swift`
- Modify: `bumpers/Features/Navigation/OrbView.swift`

- [ ] **Step 1: Update `OrbView` inputs**

In `OrbView`, replace:

```swift
let directionShift: Double
let bumpTrigger: Int
```

with:

```swift
let signal: FieldOrbSignal
let bumpTrigger: Int
```

Replace uses of `directionShift` with `signal.shift`.

In the body, after the highlight circle, add:

```swift
if signal.isAlive && !signal.isDirectionalCorrection {
    Circle()
        .stroke(zone.colors.inner.opacity(0.18), lineWidth: 2)
        .scaleEffect(1.08)
        .blur(radius: 1)
}
```

Update animations:

```swift
.animation(Theme.snappySpring, value: signal.shift)
```

- [ ] **Step 2: Update previews**

Replace preview calls with:

```swift
OrbView(
    zone: .hot,
    signal: FieldOrbSignal(shift: 0, isAlive: true, isDirectionalCorrection: false),
    bumpTrigger: 0
)
```

For shifted previews, use:

```swift
FieldOrbSignal(shift: 0.5, isAlive: true, isDirectionalCorrection: true)
```

- [ ] **Step 3: Use Field Mode signal in `NavigationView`**

In `orbCore`, replace:

```swift
directionShift: viewModel.directionShift,
```

with:

```swift
signal: viewModel.orbSignal,
```

In `statusChip`, replace:

```swift
Text(viewModel.statusText)
```

with:

```swift
Text(viewModel.fieldModeEnabled ? viewModel.fieldDiagnosticsText : viewModel.statusText)
```

In `debugOverlay`, after the `Shift` line, add:

```swift
Text("Orb Signal: \(viewModel.orbSignal.shift, specifier: "%.2f")")
Text("Profile: \(viewModel.hapticProfile.displayName)")
Text("Last Buzz: \(viewModel.lastHapticAge.map { String(format: "%.1fs", $0) } ?? "--")")
Text("Cooldown: \(viewModel.currentHapticCooldown, specifier: "%.1f")s")
Text("Field Mode: \(viewModel.fieldModeEnabled ? "on" : "off")")
```

- [ ] **Step 4: Run build**

Run:

```bash
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit Task 6**

```bash
git add bumpers/Features/Navigation/NavigationView.swift bumpers/Features/Navigation/OrbView.swift
git commit -m "feat: show field mode navigation diagnostics"
```

---

### Task 7: Documentation And Validation Protocol

**Files:**
- Modify: `docs/PLAN.md`
- Modify: `docs/WALK-TESTS.md`
- Modify: `docs/BUILD-LOG.md`

- [ ] **Step 1: Update `docs/PLAN.md`**

Under Phase 6, add a Field Mode subsection:

```markdown
### Field Mode Validation

- [x] Add Field Max haptic profile for real-pocket validation
- [x] Add one-screen haptic preflight with left, right, and max buzz
- [x] Make Field Mode the default validation posture
- [x] Make in-lane navigation visibly alive without constant buzzing
- [x] Add Field Mode diagnostics for route state, profile, last buzz, and cooldown
- [ ] Real-device Field Mode walk test passes pocket viability gate
```

- [ ] **Step 2: Update `docs/WALK-TESTS.md`**

In Preflight, replace the current calibration bullets with:

```markdown
- Use Field Mode unless intentionally comparing against Product Mode.
- Keep haptic profile on `Field Max` for the first validation walk.
- Before starting, tap `Test left`, `Test right`, and `Max buzz` with the phone in the real carrying pocket.
- If either direction is unclear, tap `Too weak`, replay `Max buzz`, and record the phone placement as a failure if it still cannot be felt.
- Start walking only after left and right are distinguishable.
```

Add this Field Mode pass criterion under Kill / Pivot Gate:

```markdown
- In Field Mode, the user can tell within 60 seconds whether route, heading, and haptics are live.
```

- [ ] **Step 3: Append `docs/BUILD-LOG.md` session**

Add a new session before the Index of Decisions:

```markdown
---

## Session 18: Field Mode Validation Rig

**Date:** 2026-04-30
**Duration:** Implementation pass
**Phase:** 6 (Route-Aware V2) - Field validation

### What Changed

Implemented Field Mode as the default validation posture for Bumper V2. The pass makes haptics stronger, setup faster, and active navigation visibly diagnostic so real walks can answer whether iPhone pocket haptics are viable.

### Key Updates

- Added `fieldMax` as the strongest haptic profile.
- Added preflight controls for left, right, max buzz, and too-weak replay.
- Added Field Mode corridor sensitivity so drift appears earlier during validation.
- Added Field Mode orb signal and diagnostics for state, profile, last buzz, and cooldown.
- Kept low-confidence behavior conservative: no fake directional haptics.

### Verification

- `xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' build` passed.
- `xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' -skip-testing:bumpersUITests test -quiet` passed.
- Real-device Field Mode walk testing remains the product gate.
```

- [ ] **Step 4: Run docs grep for stale Field Mode claims**

Run:

```bash
rg -n "pocketNormal|Play first cue|calibration|Field Mode|Field Max" docs README.md AGENTS.md
```

Expected: Any remaining `pocketNormal` default or walkthrough-first language is intentional history, not active instructions.

- [ ] **Step 5: Commit Task 7**

```bash
git add docs/PLAN.md docs/WALK-TESTS.md docs/BUILD-LOG.md
git commit -m "docs: document field mode validation"
```

---

### Task 8: Full Verification And Final Sync

**Files:**
- Verify all changed files
- No new source files beyond those listed above unless the implementation found a compile-time need

- [ ] **Step 1: Run full build**

Run:

```bash
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 2: Run unit tests without UI tests**

Run:

```bash
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' -skip-testing:bumpersUITests test -quiet
```

Expected: All unit tests pass. Existing Swift 6 warning debt around main-actor-isolated `Equatable` checks may still appear unless fixed separately.

- [ ] **Step 3: Inspect git diff**

Run:

```bash
git status --short --branch
git diff --stat
```

Expected: Only Field Mode implementation, tests, and docs are changed. Pre-existing untracked local artifacts such as `.specstory/`, `assets/`, `icon-build/`, `bumpers-readme-kami.pdf`, `.beads/last-touched`, and `bumpers.xcodeproj/xcshareddata/` remain unstaged unless the user explicitly asks to handle them.

- [ ] **Step 4: Sync beads**

Run:

```bash
bd sync
bd sync --status
```

Expected: `Pending changes: none`.

- [ ] **Step 5: Commit any final verification or bead export changes**

If `bd sync` modifies `.beads/issues.jsonl`, commit it:

```bash
git add .beads/issues.jsonl
git commit -m "chore: sync field mode bead state"
```

Expected: Either a commit is created for bead state or git reports no staged changes.

- [ ] **Step 6: Push**

Run:

```bash
git push
git status --short --branch
```

Expected: branch is up to date with `origin/main`, with only the known pre-existing untracked local artifacts remaining.

---

## Self-Review Notes

Spec coverage:

- Stronger default haptics are covered by Tasks 2 and 4.
- Shorter cooldowns and earlier correction feedback are covered by Tasks 2 and 5.
- One-screen preflight is covered by Task 4.
- Live route, heading, correction, profile, last haptic, and cooldown instrumentation is covered by Tasks 1, 5, and 6.
- Orb liveliness across states is covered by Tasks 1 and 6.
- Updated tests and docs are covered by Tasks 1, 2, 3, 5, 7, and 8.
- Pocket-viability kill criteria are covered by Task 7.

Rollback:

- Field Mode defaults can be disabled by setting `fieldModeEnabled` false and defaulting `hapticProfileRawValue` back to `pocketNormal`.
- No user data migration is introduced.

Risk:

- Field Max may still be physically insufficient through clothing. If the device walk fails after this plan, stop iPhone-only polish and spec the wearable pivot.
