# HyroxPace

Apple Watch app that paces two athletes through a Hyrox race. One screen, one tap.

## Screen

| Position | Content |
|----------|---------|
| Top | Estimated finish time |
| Above center | Station name (Ski, Run 1K, ...) |
| Center | Progress or transition countdown |
| Bottom | Current athlete range, or next station preview |

## Interaction

- Tap once to start Run 1K pacing.
- Tap again to end the current station, run a short buffer, then start the next.
- No swipe, scroll, menu, crown, or secondary screens.

## Buffers

- 20s after runs
- 15s after stations
- No buffer before the opening run

## Behavior

- Pacing: `progress = elapsed * (target_work / target_duration)`
- Early tap stops pacing and starts the next buffer immediately
- If pacing finishes before you tap, the screen flashes red until the next tap
- Finish estimate updates on each station tap: `estimate += actual - planned`

## Default pace plan

- Runs: 8:30/mi (5:17 per 1K)
- Row: 4:30
- Wall balls: 4:00 (100 reps)
- Sled push: 2:50 / pull: 4:00
- Plan target: about 1:19:31 including buffers

## Install

```bash
cd HyroxPace && xcodegen generate
```

After generating, set `GENERATE_INFOPLIST_FILE = NO` in the pbxproj (xcodegen flips it to YES).

Open `HyroxPace.xcodeproj`, pick the `HyroxPace` scheme and your iPhone, run. The watch app is embedded in the iPhone app; install it from the iPhone Watch app under Available Apps. The `HyroxPaceWatch` scheme runs directly on a watch or watch simulator.

Requires iOS 17+ / watchOS 10+. The watch app runs independently once installed.
