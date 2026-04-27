# Bumper — Roadmap

*Future ideas, enhancements, and directions. Not committed—just possibilities.*

---

## v1.0 — Minimum Viable Bumper

**Status:** Complete

Core features:
- Destination search and recent places
- Haptic navigation with simple guidance fallback
- Temperature orb visualization
- Arrival detection
- Live Activity

See `PLAN.md` for detailed progress.

---

## v1.1 — Complete Flow

**Status:** Complete

- [x] Destination search (MapKit)
- [x] Recent destinations (SwiftData)
- [x] Wander dial (time constraint)
- [x] Full arrival screen

---

## v1.2 — Polish & Refinement

**Status:** Mostly Complete, Device Testing Pending

- [x] Pocket-first haptic pattern redesign
- [x] Accessibility improvements for active navigation
- [x] Battery optimization
- [x] Heading calibration prompts
- [ ] Device walk-test tuning

---

## v2.0 — Route Awareness

**Status:** Prototype Implemented, Validation Pending

The pure crow-flies approach is philosophically correct but may frustrate users in complex urban environments.

### Implemented Approach

**Corridor Mode**
- Use MapKit walking directions to create a "path band"
- User can wander within the band
- Haptics only fire when leaving the corridor
- Preserves exploration while avoiding dead-ends

The route stays internal. The app shows a quiet navigation instrument, never a blue line.

### Still Exploratory

**Option B: Obstacle Hints**
- Detect when user is heading toward water, highways, or restricted areas
- Gentle "not that way" nudge before they hit the obstacle
- Still no prescribed route

**Option C: Learning Mode**
- Remember paths user has taken before
- Suggest familiar routes when heading to known destinations
- "You usually go this way" subtle guidance

### Trade-offs

| Approach | Preserves Philosophy | Complexity | Battery |
|----------|---------------------|------------|---------|
| Corridor | Mostly | Medium | Higher |
| Obstacle Hints | Yes | High | Higher |
| Learning | Somewhat | High | Medium |

**Current thinking:** V2 only continues if real walks prove the corridor feels calmer and more trustworthy than the crow-flies prototype.

---

## v3.0 — Multi-Platform

**Status:** Distant Future

### Apple Watch App

The ideal Bumper experience:
- Phone stays in pocket
- Watch handles haptics directly
- Better battery (Watch optimized for this)
- True directional haptics (Taptic Engine)

**Technical notes:**
- WatchConnectivity for destination transfer
- Watch can run independently for short walks
- Complication showing distance/zone

### CarPlay Integration

- Audio cues instead of haptics
- "Getting warmer... getting colder..."
- Useful for passengers navigating driver

---

## Ideas Backlog

These are unfiltered ideas. May or may not pursue.

### Features

- **Surprise Me mode** — App picks a destination (coffee shop, park) based on available time
- **Photo Hunt** — Navigate to take a photo at a specific location
- **Walking Buddy** — Two phones, navigate toward each other
- **Historical walks** — Map of past wanderings, replay old routes
- **Soundscapes** — Ambient audio that changes with zone (experimental)
- **Widget** — Glanceable info for frequent destinations
- **Shortcuts integration** — "Start walking to work"

### Design Explorations

- **Alternative orb styles** — Particle effects, fluid simulation, simple ring
- **Light mode** — For outdoor visibility
- **Minimal mode** — Just haptics, blank screen
- **Artistic mode** — Generative art based on walk pattern

### Experimental

- **Offline mode** — Download map tiles, work without data
- **Social layer** — Share destinations, see friends' walks
- **Gamification** — Badges for exploration, wander streaks
- **AR overlay** — Point camera, see destination direction (gimmicky?)

---

## Anti-Features

Things we've explicitly decided NOT to do:

| Anti-Feature | Reason |
|--------------|--------|
| Turn-by-turn directions | Core philosophy violation |
| Street names | Builds dependence, not awareness |
| ETA countdown | Anxiety-inducing |
| Speed tracking | Not a fitness app |
| Social sharing | Privacy concerns, scope creep |
| Advertising | Ruins the aesthetic |

---

## Simplification Opportunities

If the app becomes too complex, consider removing:

- **Time constraints** — If users rarely use the wander dial
- **SwiftData** — If recent destinations aren't valued
- **Multiple zones** — Could simplify to 3 (hot/medium/cold)
- **Arrival screen** — Just vibrate and stop

The goal is always: **minimal, elegant, functional**.

---

## Technical Debt

Known issues to address eventually:

- [ ] Heading smoothing algorithm (currently raw values)
- [ ] Haptic engine restart is aggressive
- [ ] No graceful degradation for iOS < 17
- [ ] Debug overlay is crude
- [x] Unit tests for navigation math, corridor projection, haptics, search stale-result suppression, and ETA labels
- [ ] Full Xcode test run pending installed simulator/runtime

---

## Metrics to Track

If/when we add analytics:

- Time to destination vs. estimated time
- Number of haptic events per walk
- Walk completion rate
- Most used time constraints
- Repeat destination usage

**Privacy note:** All analytics would be local/opt-in. No tracking.
