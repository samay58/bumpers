# Bumper

![Bumper cover](docs/assets/github-cover.png)

An iOS app that guides you toward your destination using haptic feedback instead of turn-by-turn directions.

## Why this exists

Every navigation app works the same way. A blue line, a voice, and the expectation that you'll follow. You stare at the screen, make the turns, arrive efficiently, and learn nothing about where you actually are.

This is fine when you're driving somewhere unfamiliar. It fails when you're walking through a city you want to know. The more you lean on the blue line, the less you build a mental map of the place. GPS navigation optimized for efficiency and accidentally eroded spatial awareness.

Bumper tries something different. Pick where you're going, choose how much room you want to wander, put your phone in your pocket, walk. The app uses walking routes internally to create a loose corridor, but it never asks you to follow a blue line. Haptics stay quiet when you are inside the lane and become unmistakable when you drift out of it.

No prescribed route. No map on screen. You figure out the obstacles, pick the interesting streets, stop when something catches your eye. The app nudges you back when you wander too far, like bowling bumpers keeping the ball in the lane.

A simple way to stay on track while still letting you wander.

## How it works

You pick a destination and optionally set when you need to arrive. The app asks MapKit for walking routes, turns them into an invisible corridor, and compares your location, heading/course, progress trend, and location confidence against that corridor. If routing is unavailable, it falls back to simple bearing guidance and labels that state honestly.

| State | You're... | Feels like |
|-------|-----------|------------|
| In lane | Making useful progress | Silence by default |
| Drifting | Outside the soft corridor | Directional pocket correction |
| Off course | Meaningfully out of lane | Repeated directional correction |
| Wrong way | Losing progress | Rumble, then correction |
| Low confidence | GPS/heading is not trustworthy | Neutral warning, no fake direction |

The direction language is pocket-first: short-long means correct right, long-short means correct left. The orb's hot center shifts toward the correction direction when haptics fire. When you remain within the dynamic arrival radius for three seconds, you've arrived.

## Stack

- iOS 17+, SwiftUI, no external dependencies
- Core Haptics for directional haptic patterns
- MapKit for destination search, walking routes, and ETA
- ActivityKit for Lock Screen and Dynamic Island
- SwiftData for recent destinations

## Build

```bash
open bumpers.xcodeproj
# Or from command line:
xcodebuild -scheme bumpers -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Haptics and compass heading require a real device. The simulator handles UI and location with simulated coordinates.

## Docs

- [`docs/SPEC.md`](docs/SPEC.md) - Product specification
- [`docs/PLAN.md`](docs/PLAN.md) - Implementation phases and progress
- [`docs/ROADMAP.md`](docs/ROADMAP.md) - Future directions
- [`docs/BUILD-LOG.md`](docs/BUILD-LOG.md) - Session history and decisions
- [`docs/WALK-TESTS.md`](docs/WALK-TESTS.md) - V2 field test protocol
- [`HAPTICS.md`](HAPTICS.md) - Haptic pattern design and tuning guide
