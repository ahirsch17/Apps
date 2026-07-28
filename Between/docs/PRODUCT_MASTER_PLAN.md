# Between — Product Master Plan

> **Mission:** Help VT students find their people between classes — without doom-scrolling social media or showing up alone.

Three missions, one product. Build in this order.

---

## Mission 1 — App & Server (dynamic demo → real deployment)

### Phase 1A — Done / in progress
- [x] Free-time overlap with friends (schedule intersection)
- [x] Classmate discovery (same section vs other section)
- [x] Local seed backend (dynamic mutations, no hardcoded UI)
- [x] Student-facing Today home (no raw minutes)

### Phase 1B — Done
- [x] **Activity modes** — Quiet (2h default), Hungry, Study, Gym/Sports, Social
- [x] **Interests onboarding** — volleyball, soccer, etc. (persisted per student)
- [x] **Campus events** — interest counts + partner/newcomer matching with privacy gate
- [x] **Expanded seed** — IM volleyball (partner), Saturday pickup soccer (newcomer), study (none)
- [x] **Event matching kinds** — `partner` | `newcomer` | `none` per event

### Phase 1C — Demo server
- [x] `/v1` API matching `BetweenBackendServicing`
- [x] Multi-tenant schema documented: `schools → students, sections, events`
- [x] Course hash endpoint (`POST /v1/me/course-hashes`)
- [ ] Postgres with RLS (production)

### Phase 1D — Production path
- [x] VT SSO mock + consent flow in-app
- [x] Client-side course hashing (`CourseHashService`)
- [ ] Institutional FERPA agreement (Handshake-level)
- [ ] Full OIDC with VT IdP

---

## Mission 2 — Psychology & Design (simple, visual, encouraging)

### Core insight (your volleyball example)
Students skip events because:
1. **No social proof** — "probably nobody's going"
2. **No accountability partner** — easy to back out alone
3. **Interest fade** — picked volleyball once, never saw it again

### Design principles
| Principle | Implementation |
|-----------|----------------|
| **One answer per screen** | Home answers: "Who can I see right now?" |
| **Counts before identities** | "48 interested · 9 looking for a partner" |
| **Mutual opt-in for intimacy** | See partner seekers only if you're seeking too |
| **Gentle nudges, not guilt** | "3 friends free for lunch" not "You have 550 min" |
| **Campus-native feel** | VT maroon, clean type, no neon dashboard |

### Activity modes (default durations)
| Mode | Default | Matches with |
|------|---------|--------------|
| Quiet / alone | 2 hours | Nobody (hidden from hungry/social) |
| Hungry | 1 hour | Friends also in Hungry mode |
| Study | 2 hours | Friends in Study + same library |
| Gym / Sports | 1.5 hours | Friends in Gym + event partners |
| Social | 1 hour | Friends free + event interested |

### Name & logo direction
- **Between** — already strong: "the time between classes"
- Logo: minimal wordmark + optional clock/window mark
- Avoid: social-network clutter, gamification badges, minute counters

See `DESIGN_PSYCHOLOGY.md` for research-backed patterns.

---

## Mission 3 — VT Pitch & Campus Launch

### The ask
Pilot Between with **Student Engagement** or **Hokies Wellness** for one semester:
- 500–1,000 students in CS + Rec Sports cohort
- SSO + FERPA-aligned privacy review
- Success metrics: event attendance lift, self-reported loneliness, IM sign-ups

### Why VT wins
- Reduces isolation without another social feed
- Increases IM/club attendance with partner-matching
- Privacy-first: school can audit, students control visibility
- Complements Canvas (schedule) without replacing it

See `VT_PITCH_DECK.md` for slide-by-slide content.

---

## Data model (multi-tenant)

```
School (vt)
├── Students (friends, requests, interests, privacy)
├── Sections + Enrollments (from VT or Canvas)
├── Events (per interest: volleyball, soccer, …)
│   ├── interested[] (count public)
│   └── lookingForPartner[] (profiles private until mutual)
└── Presence (mode + expiry)
```

**Privacy rule:** Partner profiles visible only when viewer has `lookingForPartner` on same event.

---

## Success metrics (pilot)
- DAU / WAU among enrolled students
- Mode activations per week (Hungry, Gym, …)
- Event "interested" → "looking for partner" conversion
- Self-reported: "I went because I saw others were going" (in-app survey)

---

## What we are NOT building (v1)
- Public social feed
- DMs to strangers
- Unmasked partner lists without mutual opt-in
- Full Canvas replacement
