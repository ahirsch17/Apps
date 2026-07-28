# Server Architecture — Between

Local demo today, production-ready shape for VT deployment.

---

## Tenancy model

```
┌─────────────────────────────────────────┐
│              API Gateway (/v1)           │
│         JWT + school_id in claims        │
└─────────────────┬───────────────────────┘
                  │
     ┌────────────┼────────────┐
     ▼            ▼            ▼
  school:vt   school:uva   school:…
     │            │            │
  students    students     students
  sections    sections     sections
  events      events       events
```

**Rule:** Every query scoped by `school_id`. No cross-school joins. Enforced in middleware + DB RLS.

---

## API surface (matches iOS `BetweenBackendServicing`)

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/v1/auth/login` | Email/password or SSO token exchange |
| POST | `/v1/auth/activate` | VT activation code |
| GET | `/v1/me/dashboard` | Friends, schedule, today plan, events summary |
| GET | `/v1/events` | Events for my interests + school |
| POST | `/v1/events/:id/interested` | Mark interested |
| POST | `/v1/events/:id/partner` | Post partner-seeking profile |
| GET | `/v1/events/:id/partners` | **Only if caller also seeking** |
| PATCH | `/v1/me/presence` | Mode + activity + expiry |
| PATCH | `/v1/me/interests` | Update interest IDs |
| POST | `/v1/friends/request` | Friend request |
| GET | `/v1/sections/search` | Course lookup |

---

## Database schema (Postgres)

```sql
schools (id, name, email_domain, timezone)
students (id, school_id, email, name, year, major, privacy_json, interests[])
sections (id, school_id, course_code, …)
enrollments (student_id, section_id)
friendships (student_a, student_b, status)
friend_requests (…)
presence (student_id, mode, activity, location, expires_at)
events (id, school_id, interest_tag, title, description, starts_at, location)
event_interest (event_id, student_id, kind)  -- 'interested' | 'partner'
partner_profiles (event_id, student_id, year, note, experience, social_handle_enc)
```

---

## Privacy & encryption

### In transit
- TLS 1.3 everywhere

### At rest
- Postgres TDE or cloud provider encryption
- `partner_profiles.social_handle` encrypted field-level (AES-256-GCM)
- Canvas API keys: encrypted, per-student, never returned in API responses

### Client-side demo (pitch)
1. Server returns `partner_profiles` blob encrypted with user's session key
2. iOS `CryptoKit` decrypts locally
3. UI shows "Decrypted on your device" badge in demo mode

### Partner visibility rule (server-enforced)
```sql
-- Return partner profiles only if:
SELECT * FROM partner_profiles pp
WHERE pp.event_id = $1
AND EXISTS (
  SELECT 1 FROM event_interest ei
  WHERE ei.event_id = $1
  AND ei.student_id = $current_user
  AND ei.kind = 'partner'
)
```

---

## SSO (VT pilot)

1. VT IdP (Azure AD / Shibboleth) → OIDC
2. App receives `email`, `sub`, optional `name`
3. Match or create student row with `school_id = vt`
4. Consent screen: schedule sharing, class visibility, FERPA notice

---

## Canvas integration (optional)

- Student pastes API token in Settings (encrypted storage)
- Background job: `GET /api/v1/courses` → map to canonical sections
- Merge with VT CRN import (dedupe by course code)
- **Never** store Canvas token in plaintext logs

---

## Local demo backend (current)

`LocalBackendService` actor:
- Loads `seed_data.json`
- Mutates in memory (friends, presence, event interest)
- Same method signatures as production
- Swap via `BackendConfiguration.mode`

---

## Deployment target

| Layer | Suggestion |
|-------|------------|
| API | Fly.io / Railway / AWS ECS |
| DB | Neon Postgres (RLS) |
| Secrets | AWS Secrets Manager / Doppler |
| iOS | TestFlight → App Store (VT enterprise optional) |
