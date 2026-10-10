# Stoke

Weekly heart-rate goal for building a cardio base. Stoke reads heart rate from Apple Health (usually an Apple Watch), turns minutes in each effort zone into points, and gives you one ring to close per week. Built for people starting from low activity.

## How it works

| Piece | Behavior |
|-------|----------|
| Points | Per-minute points from heart-rate zones: ~1 pt/min easy aerobic, ~2 pt/min tempo, ~1 pt/min brisk. Zones use heart-rate reserve (Karvonen) when Apple Health has a resting heart rate, otherwise % of max. |
| Weeks | Sunday to Saturday. The first week is prorated through Saturday. |
| Goal | Set at onboarding from age, activity level, and up to 14 days of Health history. Rises 2–8% after a met week, recalibrates after a blowout, and eases 8% after two missed weeks in a row. You can also set it by hand in Settings. |
| Pace | A second ring shows where you'd be on an even pace through the week, plus a one-line status ("About 6 pts to match today's pace"). |
| Today | Points so far plus minutes by zone ("12 min easy · 8 min tempo"). |
| Recap | When a week closes, Home shows last week's result and next week's goal for a few days. |
| Rewards | Week streak, badge tiles for met weeks, milestones. |
| Family | Compare percent of goal (not raw points) and share a weekly snapshot image. |
| Reminders | At most one gentle notification a day, 9am–8pm, only when you're behind pace. Asked for at the end of onboarding. |

## Reliability

- Points are cached per day, so Home still shows numbers if Health is briefly unreadable.
- Weeks are only closed when Health can be read (not while the phone is locked during a background update). If a day can't be read and has no cached value, closing waits up to 3 days before archiving with what it has.
- Health background delivery refreshes the week when new heart-rate samples arrive.

## Install

Requires an iPhone with Apple Health (iOS 17+). Heart-rate data normally comes from an Apple Watch.

```bash
cd Stoke && xcodegen generate   # optional, the .xcodeproj is checked in
```

Open `Stoke.xcodeproj`, set your signing team (HealthKit capability + background delivery are in `Stoke.entitlements`), run on a device.

Wellness app only, not medical advice. Heart-rate zones are estimates.
