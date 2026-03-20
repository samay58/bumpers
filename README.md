# Bumper

An iOS app that guides you toward your destination using haptic feedback instead of turn-by-turn directions.

## Why this exists

Every navigation app works the same way. A blue line, a voice, and the expectation that you'll follow. You stare at the screen, make the turns, arrive efficiently, and learn nothing about where you actually are.

This is fine when you're driving somewhere unfamiliar. It fails when you're walking through a city you want to know. The more you lean on the blue line, the less you build a mental map of the place. GPS navigation optimized for efficiency and accidentally eroded spatial awareness.

Bumper tries something different. Pick where you're going, put your phone in your pocket, walk. Haptic pulses tell you if you're getting warmer or colder. A calm tap every few seconds when you're on track. Faster, stronger patterns when you veer off course. A persistent buzz when you're headed the wrong way entirely.

No prescribed route. No map on screen. You figure out the obstacles, pick the interesting streets, stop when something catches your eye. The app nudges you back when you wander too far, like bowling bumpers keeping the ball in the lane.

A simple way to stay on track while still letting you wander.

## How it works

You pick a destination and optionally set when you need to arrive. The app calculates a crow-flies bearing from your position and compares it to the direction you're walking. The angular difference maps to five temperature zones, each with its own haptic pattern and color on the central gradient orb.

| Zone | You're... | Feels like |
|------|-----------|------------|
| Hot | On track | Calm single tap every 5s |
| Warm | Slightly off | Gentle double tap every 3s |
| Cool | Veering | Triple tap every 2s |
| Cold | Way off | Urgent triple tap every 1.5s |
| Freezing | Going backwards | Persistent buzz every 0.5s |

The orb's hot center shifts toward the direction you need to correct. When you fix your course, haptics pause for three seconds as a reward. When you get within 50 meters, you've arrived.

## Stack

- iOS 17+, SwiftUI, no external dependencies
- Core Haptics for directional haptic patterns
- MapKit for destination search
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
- [`HAPTICS.md`](HAPTICS.md) - Haptic pattern design and tuning guide
