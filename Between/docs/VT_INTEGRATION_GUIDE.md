# VT Integration Guide — Between

How Virginia Tech schedule data flows into Between for production sign-up.

## Flow

### 1. VT website → your database

```
VT Scheduling Website
    ↓ (sends user data)
Your API (Between/api)
    ↓ (stores in database)
PostgreSQL (e.g. Neon)
```

VT sends data when students register for classes:

```json
{
  "vtEmail": "alex.hirsch@vt.edu",
  "name": "Alex Hirsch",
  "crns": ["83534", "83484", "87290", "83339"]
}
```

### 2. Generate activation code and email

The API creates a user with a unique 6-digit activation code and emails it to the `@vt.edu` address.

### 3. User activates in the app

1. Download Between
2. Enter VT email
3. Enter activation code
4. Set a password
5. Account activated

## API endpoints (legacy Postgres server)

The Express server in `Between/api/` implements:

- `POST /vt-import` — VT pushes schedule + match list
- `POST /vt-activate` — user activates with code
- `POST /login` — returning users
- `GET /users/:vtEmail/friends` — friend schedules for overlap

See `Between/Between/Services/BetweenAPIClient.swift` for the **target** REST shape the Swift app expects when you wire production (`/v1/auth/login`, `/v1/me/dashboard`, etc.). The Postgres API is the starting point; adapt routes or add a thin `/v1` gateway.

## Deployment

```bash
cd Between/api
npm install
# Set DATABASE_URL, deploy to Vercel or run locally
npm run dev
```

Then set `BackendConfiguration.mode` to `.remote(baseURL:)` in the iOS app.

## Benefits

- No hardcoded demo data in production
- Secure per-user activation codes
- VT schedule sync on registration
- Scales to full campus population
