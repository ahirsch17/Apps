# Between API (v1)

Demo server that mirrors the iOS `LocalBackendService` contract.

## Quick start

```bash
cd Between/api
npm install
npm start
```

Server: `http://localhost:3000`. Routes live under `/v1`.

## Demo login

| Field | Value |
|-------|-------|
| Email | `alex.hirsch@vt.edu` |
| Password | `demo123` |
| Activation code | `482910` |

## Point the iOS app at this API

In `BackendConfiguration.swift` (DEBUG):

```swift
static var mode: BackendMode = .remote(baseURL: URL(string: "http://localhost:3000")!)
```

Use your Mac's LAN IP instead of `localhost` on a physical device.

## Main endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/health` | Health check |
| POST | `/v1/auth/login` | Email/password login |
| POST | `/v1/auth/sso` | Mock VT SSO |
| POST | `/v1/auth/activate` | New user activation |
| GET | `/v1/me/dashboard` | Dashboard payload |
| GET | `/v1/me/events` | Campus events |
| PATCH | `/v1/me/mode` | Activity mode |
| POST | `/v1/events/:id/partner` | Looking-for-partner flag |

## Environment

| Variable | Default | Purpose |
|----------|---------|---------|
| `BETWEEN_SEED_MODE` | `true` | Seed-backed v1 API |
| `JWT_SECRET` | demo secret | JWT signing (change in real deploys) |
| `DATABASE_URL` | unset | Optional Postgres for legacy routes |
