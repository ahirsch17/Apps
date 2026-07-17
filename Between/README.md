# Between iOS Prototype

SwiftUI iOS prototype for the `Between` PRD.

## Run in Xcode

1. Open `Between.xcodeproj`.
2. Select the `Between` scheme.
3. Choose an iOS Simulator device.
4. Press Run.

## Regenerate project

This project is generated with XcodeGen from `project.yml`.

```bash
xcodegen generate
```

## Local pipeline architecture

- `LocalBackendService` simulates API endpoints for login, dashboard fetch, refresh, friend requests, and request acceptance.
- `connectPresenceStream()` simulates websocket-style real-time updates.
- `seed_data.json` is bundled app data generated from script output.
- `AppViewModel` is the app-side orchestrator and can be swapped to a network backend later.

## Seed data generation

Generate fake university data:

```bash
python3 Scripts/generate_seed_data.py
```

The script generates:

- 1 university (`vt`) with `@vt.edu` users.
- 20 canonical classes with multiple sections (including weekend sections for testability).
- 70 students, enrollments, friendships, pending friend requests, presence updates, and plans.

## Current app testing flow

- Login as any seeded account from the picker (for example `alex.hirsch@vt.edu`).
- Review nearby friends and class connections (same section vs different section).
- Accept incoming friend requests and send new requests from suggested users.
- Pull refresh from class panel to simulate app-start/manual sync behavior.
