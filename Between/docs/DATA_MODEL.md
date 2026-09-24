# Data model

Multi-tenant schema sketch for Between. Every table is scoped by `school_id`.

## Current product focus

Events, interests, private keep-me-posted participation, and lightweight social graph.
Course sections and enrollments below are legacy / optional; the product no longer depends on schedule overlap.

## Entity hierarchy

```
schools
├── students
├── campus_events
├── event_participation
├── interests
├── friendships / friend_requests
├── sections            (legacy)
└── enrollments         (legacy)
```

## `schools`

| Column | Type | Notes |
|--------|------|-------|
| id | text PK | e.g. `vt` |
| name | text | Virginia Tech |
| email_domain | text | `vt.edu` |
| timezone | text | `America/New_York` |

## `students`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | Internal only |
| school_id | FK | Required on every query |
| email | text | From auth; unique per school |
| name, year | text | Profile fields |
| bio | text | Optional |
| interest_ids | text[] | Onboarding picks |
| privacy_json | jsonb | Visibility preferences |

## `campus_events`

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| school_id | FK | |
| title, description | text | |
| category | text | official, club, sports, services, pop-up, local |
| starts_at / ends_at | timestamptz | |
| location | text | |
| capacity / open_spots | int | Optional |
| created_by | uuid FK | Student or org account |

## `event_participation`

| Column | Type | Notes |
|--------|------|-------|
| event_id | FK | |
| student_id | FK | |
| status | text | `keep_me_posted`, claimed spot, etc. |
| show_name | bool | Default false |

## Interests and social

- `interests`: school-specific tags used in onboarding and For You ranking
- `friendships` / `friend_requests`: optional lightweight graph; not a chat product

## Legacy course tables

`sections` and `enrollments` remain documented for older code paths. Do not build new product features on them. See [PRD.md](PRD.md).
