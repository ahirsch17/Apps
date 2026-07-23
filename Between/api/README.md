# Between API (Postgres / VT)

Node + Express backend carried over from the earlier SamePath prototype. Handles VT import, activation codes, CRN storage, and friend match lists.

The Swift app’s production contract lives in `Between/Services/BetweenAPIClient.swift` (`/v1/...`). This server is the database layer to evolve or wrap behind those routes.

## Run locally

```bash
npm install
export DATABASE_URL="postgresql://..."
npm start
```

## Deploy

```bash
vercel --prod
```

Set `DATABASE_URL` in your host environment.

## Key routes

| Route | Purpose |
|-------|---------|
| `POST /vt-import` | VT pushes student + CRNs |
| `POST /vt-activate` | User activates with email + code |
| `POST /login` | Sign in |
| `GET /users/:vtEmail/friends` | Friend schedules |

See `../docs/VT_INTEGRATION_GUIDE.md` for the full VT onboarding flow.
