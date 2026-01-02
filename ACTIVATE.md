# Bumper — Activation Prompt

*Copy this entire prompt to activate a new AI session on this project.*

---

## ACTIVATION PROMPT

```
I'm working on Bumper, an iOS navigation app at ~/bumpers. Before doing anything, orient yourself:

1. **Read the project instructions:**
   cat ~/bumpers/CLAUDE.md

2. **Check current implementation status:**
   cat ~/bumpers/docs/PLAN.md

3. **Review recent session history:**
   cat ~/bumpers/docs/BUILD-LOG.md

4. **Check for tracked issues:**
   cd ~/bumpers && bd ready

5. **Verify build still works:**
   cd ~/bumpers && xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -10

After orienting, tell me:
- What phase are we in?
- What's the next task according to PLAN.md?
- Any open issues from `bd ready`?
- Does the build pass?

Then we can proceed with work. Remember:
- Update docs/PLAN.md as you complete tasks
- Add session notes to docs/BUILD-LOG.md when done
- Follow the architecture in CLAUDE.md
- Commit work before ending: git add . && git commit -m "description"
```

---

## QUICK ACTIVATION (Shorter Version)

```
Working on ~/bumpers (Bumper iOS app). Orient first:

cat ~/bumpers/CLAUDE.md && cat ~/bumpers/docs/PLAN.md | head -60

Then tell me: What phase? What's next? Build passing?

Track progress in docs/PLAN.md. Log sessions in docs/BUILD-LOG.md.
```

---

## RESUME FROM BEADS

```
Resume work on ~/bumpers:

cd ~/bumpers && bd ready && bd prime

Read CLAUDE.md for architecture, docs/PLAN.md for status.
Pick up the next unchecked item or open issue.
```

---

## CONTEXT REFRESH (Mid-Session)

If you lose context during a long session:

```
I've lost context on Bumper. Quick refresh:

1. What is this project? (cat ~/bumpers/CLAUDE.md | head -30)
2. Current status? (cat ~/bumpers/docs/PLAN.md | grep -A 5 "IN PROGRESS")
3. What was I working on? (git diff --stat)

Summarize and continue.
```

---

## HANDOFF PROMPT (End of Session)

Before ending a session, use this to ensure proper handoff:

```
Session ending. Complete handoff checklist:

1. What did we build this session?
2. Update docs/PLAN.md with completed items
3. Add session entry to docs/BUILD-LOG.md
4. Commit all changes: git add . && git commit -m "Session summary"
5. Any open issues to track? bd create "title" --type task
6. What should the next session start with?

Execute steps 2-5, then summarize for handoff.
```

---

## PROJECT QUICK FACTS

- **Location:** `~/bumpers`
- **Type:** iOS app (SwiftUI, Swift 5, iOS 17+)
- **Build:** `xcodebuild -scheme bumpers build`
- **Open in Xcode:** `open ~/bumpers/bumpers.xcodeproj`
- **Issue tracking:** `bd ready` / `bd create` / `bd close`

**Key files:**
- `CLAUDE.md` — Architecture, decisions, how-to
- `docs/PLAN.md` — Implementation checklist
- `docs/SPEC.md` — Full specification
- `docs/BUILD-LOG.md` — Session history

**Test destination:** 180º Shop, Colima 180, Roma Norte, CDMX

---

## DISCIPLINE REMINDERS

Include these in your system prompt or initial message:

```
RULES FOR THIS PROJECT:
- Read before write (understand existing code before modifying)
- Update docs/PLAN.md after completing tasks
- Log decisions and learnings in docs/BUILD-LOG.md
- Follow architecture in CLAUDE.md (Services → Models → ViewModels → Views)
- Verify build passes before committing
- Commit at logical checkpoints, not just at end
- If adding a new feature, check docs/ROADMAP.md first
- If removing something, document why in BUILD-LOG.md
```

---

## TROUBLESHOOTING PROMPTS

**Build failing?**
```
Build is failing. Debug:
cd ~/bumpers && xcodebuild -scheme bumpers build 2>&1 | grep -A 5 "error:"
```

**Lost track of what's done?**
```
Show me git log and current diff:
cd ~/bumpers && git log --oneline -10 && git diff --stat
```

**Need to understand a file?**
```
Explain this file's purpose and how it fits the architecture:
cat ~/bumpers/bumpers/[path/to/file.swift]
Cross-reference with CLAUDE.md architecture section.
```

---

## EXAMPLE: FULL COLD START

Here's what a complete cold start looks like:

```
User: I want to continue working on Bumper

AI: Let me orient myself on the Bumper project.

[Reads CLAUDE.md]
[Reads docs/PLAN.md]
[Runs bd ready]
[Verifies build]

Here's the current state:
- **Phase:** 2 (The Orb) - IN PROGRESS
- **Completed:** Phase 1 (Foundation) - all services, models, minimal navigation view
- **Next task:** Create OrbView.swift with gradient rendering
- **Open issues:** bumper-dva (epic for v1 build)
- **Build status:** ✅ Passing

Ready to implement the orb. Should I start with the gradient rendering?
```

---

*This file lives at ~/bumpers/ACTIVATE.md for easy reference.*
