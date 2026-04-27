# Bumper — Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

---

## Project Context

**Bumper** is an iOS navigation app that uses haptic feedback instead of turn-by-turn directions. The core philosophy is helping a user wander toward a destination without staring at a route.

**Current Status:** Phase 6 Route-Aware V2 prototype is implemented and awaiting simulator/device validation. See `docs/PLAN.md` for details.

---

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

---

## Before Making Changes

1. **Read `docs/PLAN.md`** to understand what's built and what's next
2. **Read `docs/SPEC.md`** for the full specification
3. **Check `CLAUDE.md`** for architecture and design decisions
4. **Run `bd ready`** to see if there are existing issues related to your work

---

## Making Changes

### Adding Features

1. Check if it's in `docs/PLAN.md` — if so, mark it in_progress
2. Follow the existing architecture (Services → Models → Features)
3. Update `docs/PLAN.md` when complete
4. Add to `docs/BUILD-LOG.md` with learnings

### Modifying Existing Code

1. Understand *why* the current code exists (check `docs/BUILD-LOG.md`)
2. If changing a design decision, document the change and rationale
3. Run the build to verify: `xcodebuild -scheme bumpers build`

### Subtracting/Removing Features

1. Document what's being removed and why in `docs/BUILD-LOG.md`
2. Update `docs/PLAN.md` to reflect the change
3. If removing for simplification, note what it replaced

---

## Code Style

- **SwiftUI views** — Struct-based, use `@State` and `@Observable`
- **Services** — Classes, handle lifecycle, can be shared
- **Models** — Structs or SwiftData `@Model` classes
- **File naming** — Match the main type (e.g., `HapticService.swift` contains `HapticService`)

---

## Testing Requirements

**Before marking work complete:**

1. Build passes: `xcodebuild -scheme bumpers build`
2. No new warnings (strive for)
3. If touching navigation logic, walk-test on device if possible

---

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **Update docs** — Reflect changes in `docs/PLAN.md` and `docs/BUILD-LOG.md`
2. **File issues for remaining work** — Create issues for anything that needs follow-up
3. **Run quality gates** — `xcodebuild -scheme bumpers build`
4. **Update issue status** — Close finished work, update in-progress items
5. **PUSH TO REMOTE** — This is MANDATORY:
   ```bash
   git add .
   git commit -m "Description of changes"
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
6. **Verify** — All changes committed AND pushed
7. **Hand off** — Update `docs/BUILD-LOG.md` with session summary

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing — that leaves work stranded locally
- NEVER say "ready to push when you are" — YOU must push
- If push fails, resolve and retry until it succeeds

---

## Key Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Project-specific Claude instructions |
| `docs/SPEC.md` | Full specification |
| `docs/PLAN.md` | Implementation phases with checkboxes |
| `docs/ROADMAP.md` | Future ideas and enhancements |
| `docs/BUILD-LOG.md` | Session history and learnings |

---

## Architecture at a Glance

```
Services (pure logic)
    ↓
Models (data structures)
    ↓
ViewModels (business logic + state)
    ↓
Views (UI)
```

Don't skip layers. A view should talk to its ViewModel, not directly to a Service.
