# Between

Between helps college students find shared free time and class overlap with people they already know — privacy-first, no campus-wide feed.

**Stack:** SwiftUI · pluggable backend (local seed demo → deployed API)

## Run in Xcode

1. Open `Between.xcodeproj` on your Mac.
2. Select the **Between** scheme → Run on Simulator or iPhone.
3. Sign in as **Alex Hirsch (`alex.hirsch@vt.edu`)**.

Works offline in demo mode (bundled seed data).

## Architecture (swap backend in one place)

```
Views  →  AppViewModel  →  BetweenBackendServicing (protocol)
                                    ↑
                    ┌───────────────┴───────────────┐
            LocalBackendService          RemoteBackendService
            (seed_data.json)             (HTTPS /v1/…)
                    ↑                           ↑
            BackendServiceFactory ← BackendConfiguration.mode
```

| File | Role |
|------|------|
| `BetweenBackendServicing.swift` | API contract — UI never imports local vs remote |
| `BackendConfiguration.swift` | **Change `mode` here to go production** |
| `BackendServiceFactory.swift` | Wires the active backend |
| `LocalBackendService.swift` | Demo: in-process store + `seed_data.json` |
| `RemoteBackendService.swift` | Production: `BetweenAPIClient` + REST routes |
| `DashboardBuilder.swift` | Domain logic (mirrors what the server should return) |
| `ScheduleEngine.swift` | Overlap / timeline math (client-side for demo) |

### Going live

1. Deploy an API implementing routes in `BetweenAPIClient.swift` (`/v1/auth/login`, `/v1/me/dashboard`, etc.).
2. In `BackendConfiguration.swift`:

```swift
static var mode: BackendMode = .remote(baseURL: URL(string: "https://your-api.com")!)
```

3. Release build already defaults to remote — point the URL at your deployment.

No ViewModel or View changes required.

## Demo data

Regenerate curated seed data (25 students, John + Rachel with designed overlaps):

```bash
python Scripts/generate_seed_data.py
```

**Demo cast**

| Person | Role |
|--------|------|
| Alex Hirsch | You — login account |
| John Martinez | Close friend, same section CS 2114, Wed lunch overlap |
| Rachel Chen | Close friend, different section CS 3214, partial overlap |
| Others | Suggestions, classmates, pending requests |

Contact-style suggestions show **“In your contacts”** (simulated via `suggestedVia: "contacts"` until Contacts API is wired).

## Demo flow (Sunday)

1. **I'm returning** → `alex.hirsch@vt.edu` / `demo123`
2. **Today** — main screen: schedule, free-time overlap bars, shared-free-time hero
3. **Bell** — friend requests · **People icon** — network, star friends, add suggestions
4. **Search** — course/CRN lookup · **People on class row** — friends in that section

New users: **I'm new** → any seed email + code `482910`.

## Repo layout

| Path | Purpose |
|------|---------|
| `Between/` | SwiftUI iOS app |
| `api/` | Postgres + VT import server (from earlier prototype) |
| `docs/VT_INTEGRATION_GUIDE.md` | VT onboarding flow for production |
| `Scripts/` | Seed data generator |

**Note:** SamePath was the earlier React Native prototype for the same product. It is consolidated here — Between is the only app.

## Related

- Product requirements: [`BetweenPRD`](https://github.com/ahirsch17/BetweenPRD) (private)
- Repo: [`Apps`](https://github.com/ahirsch17/Apps) → `Between/`
