# Bumper - Agent Instructions

## Current Project State

Bumper is an iOS 17+ SwiftUI walking app for wandering toward a destination without staring at turn-by-turn directions. It uses MapKit walking routes internally to create a loose corridor, then gives pocket-first haptic corrections only when the user drifts meaningfully away, starts making bad progress, or needs urgent guidance.

As of 2026-04-30, the Phase 6 route-aware V2 prototype is implemented. The live work is validation, not broad new feature work:

- `bumper-dva.5` - Device walk testing and V2 validation
- `bumper-dva.7` - Clarify and validate rotation/orb behavior on physical device
- `bumper-dva.2` - Live Activity device validation

Treat `docs/PLAN.md` as the progress ledger, `docs/SPEC.md` as the product contract, `CLAUDE.md` as the architecture guide, and `docs/BUILD-LOG.md` as the decision history.

## Start Here

```bash
bd prime
bd ready
git status --short --branch
```

Before changing code or docs:

1. Read `docs/PLAN.md` for current phase and remaining gates.
2. Read `CLAUDE.md` for architecture, build commands, and Swift rules.
3. Read `docs/BUILD-LOG.md` when touching behavior with history.
4. Read `docs/WALK-TESTS.md` before navigation, haptic, Live Activity, or device-validation work.
5. Use beads for task tracking. Create or claim an issue before implementation work.

## Issue Tracking

This project uses `bd` (beads). `bd prime` is the up-to-date workflow context; keep `AGENTS.md` lean and let beads provide dynamic details.

Useful commands:

```bash
bd ready
bd show <id>
bd create --title "Title" --type task --priority 2
bd update <id> --status in_progress
bd close <id> --reason "Done"
bd sync
```

Do not use blocking editor flows such as `bd edit`.

## Architecture Rules

Follow the existing layers:

```text
Services -> Models -> ViewModels -> Views
```

- Views talk to ViewModels, not directly to Services.
- `NavigationViewModel` orchestrates route loading, rerouting, haptic cooldown, journey sampling, arrival, and Live Activity updates.
- Corridor decisions belong in `CorridorNavigationEngine` and related model/service types.
- `Theme.swift` is the design-system source for colors, typography, spacing, animation, and orb constants.
- `HapticPatternFactory` owns haptic timing and pattern vocabulary.
- `NavigationActivityAttributes` must stay target-safe and Codable for ActivityKit.
- Never directly edit `.pbxproj`; use Xcode/XcodeBuildMCP-style project operations when target membership changes.

## Product Contracts To Preserve

- No blue route line or turn-by-turn UI during active navigation.
- Route-aware corridor guidance is primary; crow-flies bearing is fallback only.
- If MapKit routing is unavailable, the UI labels simple guidance honestly.
- In-lane/on-track is mostly silent. Silence is success, not a bug.
- The orb is correction-driven in V2. Stationary rotation may not move it while the user remains `In lane`.
- Positive deviation means correct right; negative deviation means correct left.
- Low-confidence location or heading suppresses directional haptics.
- Arrival requires location dwell near destination, not heading correctness.
- If front-pocket haptics fail real walks, consider the Apple Watch/wearable pivot instead of polishing iPhone-only UX.

## Build And Test

Preferred simulator gate:

```bash
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' -skip-testing:bumpersUITests test -quiet
```

If `iPhone 17` is unavailable:

```bash
xcrun simctl list devices available
```

Use a concrete installed simulator. UI tests can hang; only run them intentionally.

Simulator validation is not product validation. Haptics, compass behavior, pocket legibility, and Live Activity behavior need real-device testing. Use `docs/WALK-TESTS.md` for the V2 field-test matrix.

## Documentation Discipline

When changing behavior:

- Update `docs/PLAN.md` if progress, status, or checkboxes changed.
- Update `docs/BUILD-LOG.md` with the decision, rationale, and verification.
- Update `docs/SPEC.md` only when the product contract changes.
- File follow-up beads for real remaining work instead of burying it in prose.

When only refreshing agent/process docs, keep product docs unchanged unless the product state itself changed.

## Session Close

Work is not complete until the relevant changes are committed and pushed. Before saying done:

1. Run `git status --short --branch`.
2. Close or update the relevant bead issue.
3. Stage only files that belong to your work; do not sweep unrelated untracked artifacts into the commit.
4. Run the appropriate build/test gate, or clearly record why it was not applicable.
5. Run `bd sync`.
6. Commit.
7. Run `bd sync` again if beads changed.
8. `git push`.
9. Confirm `git status --short --branch` is clean or only contains pre-existing unrelated local files.

## Key Files

| File | Purpose |
| --- | --- |
| `CLAUDE.md` | Architecture, build/test commands, Swift rules |
| `docs/SPEC.md` | Product and behavior specification |
| `docs/PLAN.md` | Current implementation phase and checklist |
| `docs/WALK-TESTS.md` | V2 simulator and real-device validation protocol |
| `docs/BUILD-LOG.md` | Session history, rationale, learnings |
| `docs/ROADMAP.md` | Future ideas and pivots |
