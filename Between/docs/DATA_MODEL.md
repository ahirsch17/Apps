# Data Model — Multi-Tenant Schools

Every table is scoped by `school_id`. No cross-school queries. This is the contract VT (and future schools) need before sharing course data.

---

## Entity hierarchy

```
schools
├── students          (friends, requests, presence, interests live here)
├── sections          (course catalog per school — CRN import)
├── enrollments       (student ↔ section, stored as hashes in production)
├── interests         (volleyball, soccer, study — school-specific tags)
├── campus_events     (Rec Sports, clubs, pickup games — per school)
├── event_participation
└── connection_profiles  (partner OR newcomer — mutual opt-in)
```

---

## `schools`

| Column | Type | Notes |
|--------|------|-------|
| id | text PK | e.g. `vt` |
| name | text | Virginia Tech |
| email_domain | text | `vt.edu` |
| timezone | text | `America/New_York` |
| hash_salt_version | int | Rotate without re-enrolling all students |

---

## `students` (per school)

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | Internal only |
| school_id | FK | Required on every query |
| email | text | From SSO; unique per school |
| name, year, major | text | From SSO or profile |
| privacy_json | jsonb | Schedule share level, class visibility |
| interest_ids | text[] | Onboarding picks |
| sso_sub | text | IdP subject — never exposed to other students |

**Relationships (all same school):**
- `friendships` — undirected, status `accepted`
- `friend_requests` — directed, status `pending` | `accepted` | `declined`
- `presence` — mode, activity, location, expires_at

---

## `sections` (per school)

| Column | Type | Notes |
|--------|------|-------|
| id | text PK | Section CRN or internal ID |
| school_id | FK | |
| canonical_course_id | text | Stable ID for hashing (e.g. `CSE-1002`) |
| course_code | text | Display: `CS 2114` |
| course_name | text | Display only — **never sent to server in production** |
| meeting_days, times, location | | Schedule blocks for overlap engine |

**We do not store grades.** Ever.

---

## `enrollments` (privacy-critical)

**Production shape:**

| Column | Type | Notes |
|--------|------|-------|
| student_id | FK | |
| course_hash | text | `SHA256(school_id + canonical_course_id)` computed **on device** |
| section_hash | text | Optional finer grain |

Server receives **hashes only** from the client after SSO. Server groups students where `course_hash` matches. Server cannot reverse hashes to course titles without the school's salt + catalog (which stays in a separate encrypted blob delivered post-consent).

**Demo / seed:** Plain `enrollments` with section IDs for local development. Same overlap logic, different wire format.

---

## `campus_events` (per school)

| Column | Type | Notes |
|--------|------|-------|
| id | uuid | |
| school_id | FK | |
| interest_id | FK | Links to school interests |
| title, description, location | text | |
| starts_at, ends_at | timestamptz | |
| is_recurring | bool | |
| recurrence_label | text | "Every Saturday night" |
| matching_kind | enum | `partner` \| `newcomer` \| `none` |
| promoted_interested_count | int | Demo credibility (optional) |
| promoted_seeking_count | int | Demo credibility (optional) |

### Matching kinds

| Kind | Example event | Seeking label | Privacy |
|------|---------------|---------------|---------|
| `partner` | IM Volleyball | "need a partner" | Mutual opt-in to see seeker profiles |
| `newcomer` | Saturday pickup soccer | "don't know anyone" | Same rule — nobody knows you're "new" until you opt in |
| `none` | Study session | — | Interest count only |

---

## `event_participation`

| event_id | student_id | kind |
|----------|------------|------|
| | | `interested` |
| | | `lookingForPartner` (used for both partner + newcomer flows) |

---

## `connection_profiles` (partner / newcomer)

| Column | Notes |
|--------|-------|
| event_id, student_id | Composite key |
| display_name | First name only |
| year | |
| looking_note | One line |
| experience_note | Skill / comfort level |
| social_handle_enc | Encrypted optional |

Returned to client as **encrypted blob**; decrypted on device with session key.

---

## Query rules (enforced in middleware)

1. `JWT.school_id` must match resource `school_id`
2. Events list: `WHERE school_id = $jwt.school_id`
3. Classmate match: `WHERE course_hash IN ($client_hashes) AND school_id = $jwt.school_id`
4. Connection profiles: only if viewer has `lookingForPartner` on same event

---

## Handshake comparison

| | Handshake | Between |
|---|-----------|---------|
| Course data | No | Yes — **hashed only** |
| Grades | No | No |
| FERPA agreement | Yes | Yes — required for pilot |
| Social layer | Career | Campus life + free time |
| School isolation | Per employer | Per `school_id` |

Course data is higher value than email. Hashing + school agreement is the only path to classmate matching at scale.
