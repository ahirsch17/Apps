# Database setup

## Modes

| Mode | Store |
|------|-------|
| Development | `LocalBackendService` + `seed_data.json` (no database) |
| Production target | Postgres / Azure SQL via `RemoteBackendService` |

## Local (current)

```swift
// BackendConfiguration.swift
static var mode: BackendMode = .local
```

Seed file: `Between/Resources/seed_data.json`

## Remote

1. Create an empty database and apply schema (`azure-sql-schema.sql` or equivalent Postgres DDL).
2. Deploy an API that implements the `/v1` routes used by `BetweenAPIClient`.
3. Point the app at it:

```swift
static var mode: BackendMode = .remote(
  baseURL: URL(string: "https://your-api.example.com")!
)
```

Use seed scripts only for testing. Delete fake rows before any real pilot.

## Files

| File | Use |
|------|-----|
| `azure-sql-schema.sql` | Tables / indexes |
| `seed-local-data.sql` | Dev fake data only |
| `seed-via-api.js` | Seed through the API |

See [DATA_MODEL.md](../docs/DATA_MODEL.md) for the entity sketch.
