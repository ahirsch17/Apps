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
  interests   interests    interests
```

**Rule:** Every query scoped by `school_id`. No cross-school joins. Enforced in middleware + DB RLS.

See `DATA_MODEL.md` for full schema.

---

## SSO + token + encrypted blob flow

```
┌──────────┐     OIDC      ┌──────────┐
│ VT IdP   │ ────────────► │ Between  │
└──────────┘               │   API    │
                           └────┬─────┘
                                │ JWT (sub, email, school_id)
                                │ + encrypted schedule blob
                                ▼
                           ┌──────────┐
                           │  iOS app │
                           └────┬─────┘
                                │ decrypt blob locally (CryptoKit)
                                │ hash canonical_course_ids on device
                                │ POST /v1/me/course-hashes { hashes[] }
                                ▼
                           ┌──────────┐
                           │   API    │  returns { hash, classmateCount }
                           └──────────┘  — never raw course titles from client
```

### Step by step

1. **SSO login** — VT IdP returns OIDC token; API exchanges for Between JWT
2. **Consent** — FERPA screen; record `consent_at`
3. **Encrypted blob** — Server sends schedule/enrollment payload encrypted to session key (AES-256-GCM demo in `/v1/auth/sso`)
4. **Client decrypt** — Course sections live on device only
5. **Client hash** — `SHA256(school_id + canonical_course_id)` via `CourseHashService`
6. **Client upload hashes** — `POST /v1/me/course-hashes` with hash array only
7. **Server match** — Group students by hash within same `school_id`; return counts (friends layer adds identity)

**Server never receives:** raw CRNs, course titles, grades, Canvas tokens in logs.

---

## Course data protection (why schools care)

| Data | Sensitivity | Between handling |
|------|-------------|------------------|
| Email | Medium | SSO only |
| Schedule blocks | High (FERPA) | Encrypted blob, student-controlled share |
| Course identity | **Highest** | Hashed on device; server stores hash only |
| Grades | N/A | **Not collected** |
| Partner/newcomer notes | Medium | Encrypted field; mutual opt-in visibility |

This is the Handshake-level bar: institutional agreement + technical minimization.

---

## API surface

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/v1/auth/sso` | VT OIDC exchange + encrypted claims |
| POST | `/v1/me/consent` | FERPA / privacy consent |
| POST | `/v1/me/course-hashes` | Upload hashed enrollments; get match counts |
| GET | `/v1/me/events` | School events + matching kind |
| POST | `/v1/events/:id/partner` | Partner OR newcomer opt-in |
| GET | `/v1/events/:id/partners` | Only if caller also opted in |

Full list in `api/README.md`.

---

## Event matching kinds (server-enforced)

```javascript
matching_kind: 'partner' | 'newcomer' | 'none'
```

- `partner` — IM volleyball, doubles sports
- `newcomer` — Pickup soccer, open mic — "don't know anyone" copy
- `none` — Study groups — interest count only

Visibility rule identical for partner and newcomer:

```sql
-- Return profiles only if viewer opted in on same event
EXISTS (
  SELECT 1 FROM event_participation
  WHERE event_id = $1 AND student_id = $current_user
  AND kind = 'lookingForPartner'
)
```

---

## Database (Postgres production)

Per-school tables or single schema with `school_id` + RLS:

```sql
schools, students, sections, enrollments_hash, friendships,
friend_requests, presence, interests, campus_events,
event_participation, connection_profiles
```

`enrollments_hash(student_id, course_hash, school_id)` — no plaintext course names in this table.

---

## Local demo backend

`Between/api/v1/` — seed-backed, in-memory mutations, same JWT + route shapes as production.

iOS `LocalBackendService` — bundled `seed_data.json`, plain enrollments for overlap demo.

Swap via `BackendConfiguration.mode`.

---

## Deployment

| Layer | Suggestion |
|-------|------------|
| API | Fly.io / Railway |
| DB | Neon Postgres + RLS |
| Secrets | Doppler / AWS Secrets Manager |
| IdP | VT Azure AD / Shibboleth OIDC |
