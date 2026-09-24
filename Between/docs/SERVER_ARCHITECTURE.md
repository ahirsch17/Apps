# Server architecture

Local demo today, production-shaped API for a school deployment.

## Tenancy

```
API (/v1)
  JWT includes school_id
       |
  +----+----+
  |         |
 school:vt  school:...
```

Every query is scoped by `school_id`. No cross-school joins.

## Client backend switch

The iOS app talks only to `BetweenBackendServicing`.

- `LocalBackendService`: in-process store + `seed_data.json`
- `RemoteBackendService`: HTTPS client to `/v1`

Flip the mode in `BackendConfiguration.swift`.

## Auth (current demo)

1. `@vt.edu` email
2. Verification / activation code
3. Password + minimal profile

Production can swap the demo code flow for institutional SSO later without changing the UI contract.

## API surface (v1)

Core routes live under `/v1`:

- Auth: login, activate, mock SSO
- Me: dashboard, events, mode
- Events: detail, keep-me-posted, partner / open-spot style actions

See [api/README.md](../api/README.md) for the running list.

## Data stores

| Mode | Store |
|------|-------|
| Demo | JSON seed + in-memory mutations |
| Production target | Postgres (or Azure SQL) with school-scoped tables |

## Related

- [Data model](DATA_MODEL.md)
- [PRD](PRD.md)
- [Testing](TESTING.md)
