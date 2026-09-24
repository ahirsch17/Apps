# Between

iOS app for discovering campus events and deciding what to show up to, without schedule matching or class data.

Students see official events, clubs, IM sports, student pop-ups, and local happenings in one feed. Interest is private by default ("keep me posted") so joining feels low pressure.

**Stack:** SwiftUI, pluggable backend (bundled seed data for demo, or a deployed HTTP API)

## Run

1. Open `Between.xcodeproj` in Xcode.
2. Select the Between scheme and run on a simulator or iPhone.
3. Sign in with a `@vt.edu` demo email (for example `alex.hirsch@vt.edu`).

Demo mode works offline using bundled seed data.

## Architecture

```
Views  ->  AppViewModel  ->  BetweenBackendServicing
                                |
                 +--------------+--------------+
                 |                             |
         LocalBackendService          RemoteBackendService
         (seed_data.json)             (HTTPS /v1/...)
```

| File | Role |
|------|------|
| `BetweenBackendServicing.swift` | Backend contract used by the UI |
| `BackendConfiguration.swift` | Switch local vs remote here |
| `BackendServiceFactory.swift` | Wires the active backend |
| `LocalBackendService.swift` | In-process demo store |
| `RemoteBackendService.swift` | Production HTTP client |

To point a release build at a live API, set `BackendConfiguration.mode` to `.remote` with your base URL.

## Auth (demo)

- VT email only (`@vt.edu`)
- Activate with any seed email and code `482910`
- Profiles stay minimal: name, year, optional bio

Regenerate seed data:

```bash
python Scripts/generate_seed_data.py
```

## Layout

| Path | Purpose |
|------|---------|
| `Between/` | SwiftUI iOS app |
| `api/` | Node API and tests |
| `docs/PRD.md` | Product requirements |
| `docs/` | Architecture and data model notes |
| `Scripts/` | Seed generator and test helpers |

## Docs

- [Product requirements](docs/PRD.md)
- [Data model](docs/DATA_MODEL.md)
- [Server architecture](docs/SERVER_ARCHITECTURE.md)
- [API README](api/README.md)
