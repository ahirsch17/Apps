# Between API — V1 Seed Mode

Dynamic demo server that mirrors the iOS `LocalBackendService` contract.

## Quick start

```bash
cd Between/api
npm install
npm start
```

Server runs on **http://localhost:3000**. V1 routes are mounted at `/v1`.

## Demo login

| Field | Value |
|-------|-------|
| Email | `alex.hirsch@vt.edu` |
| Password | `demo123` |
| Activation code | `482910` |

## Switch iOS to remote

In `BackendConfiguration.swift` (DEBUG):

```swift
static var mode: BackendMode = .remote(baseURL: URL(string: "http://localhost:3000")!)
```

Use your Mac's LAN IP instead of `localhost` when running on a physical device.

## Key endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/health` | Health check |
| POST | `/v1/auth/login` | Email/password login |
| POST | `/v1/auth/sso` | Mock VT SSO |
| POST | `/v1/auth/activate` | New user activation |
| GET | `/v1/me/dashboard` | Full dashboard |
| GET | `/v1/me/events` | Campus events + interests |
| PATCH | `/v1/me/mode` | Set activity mode |
| POST | `/v1/events/:id/partner` | Mark looking for partner |

## Environment

| Variable | Default | Purpose |
|----------|---------|---------|
| `BETWEEN_SEED_MODE` | `true` | Set `false` to disable v1 seed API |
| `JWT_SECRET` | demo secret | JWT signing |
| `DATABASE_URL` | — | Optional Postgres for legacy routes |

Legacy Postgres routes in `index.js` only activate when `DATABASE_URL` is set.
