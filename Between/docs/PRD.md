# Between — Product Requirements (canonical)

**Last updated:** August 2026  

This file is the single PRD pointer inside the app repo. Narrative and fundraising story live in [`Between/Between/docs/PITCH_DECK.md`](../Between/docs/PITCH_DECK.md) and [`docs/VT_PITCH_DECK.md`](VT_PITCH_DECK.md). Execution checklist: [`docs/PRODUCT_MASTER_PLAN.md`](PRODUCT_MASTER_PLAN.md). Technical shape: [`DATA_MODEL.md`](DATA_MODEL.md), [`SERVER_ARCHITECTURE.md`](SERVER_ARCHITECTURE.md).

The old standalone repo `ahirsch17/BetweenPRD` (LaTeX, July 2026) is **retired** — it described an earlier UI (heatmap / neon / three-tab prototype) that we replaced with the current minimal overlap-first home.

---

## One-line

**Schedule-native campus app:** see when friends are free between classes, discover class overlap, and opt into campus events — privacy-first, no public feed.

## Product principles

1. **Schedule-centered** — enrollments and free blocks drive the experience.
2. **Privacy-first** — share overlap and free/busy by friend; minimization by default.
3. **Low friction** — one screen answers “who can I see now?”; deeper flows are optional.
4. **Real-time relevance** — “now” and “later today” beat all-day density.

## North star

**Weekly coordinated meetups per active user (WCM/AU)** — accepted/joined in-person coordination that happened in the intended time window, per weekly active user.

### Pilot KPIs (first 90 days — targets from legacy PRD, still useful for VT pilot)

| Metric | Target |
|--------|--------|
| Activation (verify + schedule + ≥2 connections) | ≥ 45% |
| WAU/MAU | ≥ 0.45 |
| Time to first meaningful overlap / plan | median < 24h after onboarding |
| D30 retention (activated) | ≥ 25% |
| Weekly class-connection views (WAU) | ≥ 40% |

Adjust with the institution during MOU; measure with server analytics when deployed.

## MVP scope (current build vs planned)

| Capability | Status in repo |
|------------|----------------|
| Free-time overlap with friends | Shipped (local seed + `/v1` API) |
| Class same-course / different-section matches | Shipped (`ClassConnection`, course lookup) |
| Friend graph (requests, accept, suggestions) | Shipped |
| Contact-based suggestions | Shipped (matcher + simulated contacts fixture) |
| Activity modes + “available to hang” | Shipped |
| Campus events + interests onboarding | Shipped |
| Partner / newcomer event matching | Shipped (mutual opt-in gate) |
| Course hash upload (privacy-preserving discovery) | Shipped (client hash, server match) |
| VT SSO + consent | Demo (domain check + consent UI; real OIDC planned) |
| SIS schedule import | Planned (manual/seed today) |
| Push notifications (smart, capped) | Planned |
| Join / Maybe / Pass on shared **activities** | Partial (plans in model; not full UI loop) |

## User stories (still valid)

- As a student, I want my schedule represented once so the app knows when I am free.
- As a privacy-conscious user, I want to control overlap visibility per friend.
- As a student between classes, I want to see who is free now or later without a group chat.
- As a student in a large lecture, I want to know friends in my course or section.
- As a student, I want event interest and optional partner matching without exposing my whole schedule.

## Functional requirements (traceability)

| ID | Requirement | Notes |
|----|-------------|--------|
| FR-1 | Verified campus identity before social features | Demo: `@vt.edu` + roster; prod: OIDC |
| FR-2 | Schedule engine: free blocks, overlaps, class relationships | `ScheduleEngine`, `DashboardBuilder` |
| FR-2a | Enrollment freshness / last sync visible | Dashboard `syncTimestamp`; refresh in app |
| FR-3 | Matching respects privacy prefs | Per-friend share overlap; hash-based discovery |
| FR-4 | Activity / plan lifecycle | Backend `Plan`; UI lightweight |
| FR-5 | Targeted notifications | Not implemented |

## Privacy model (institution-facing)

- Schedule import only after explicit consent; revocation must be supported in production.
- Default: friends-only; overlap windows — not full catalog broadcast to strangers.
- Course discovery: prefer hashed canonical course IDs where possible.
- Align storage and subprocessors with school policy and FERPA guidance (see consent copy in app — keep aligned with actual deployment).

## Out of scope (MVP)

- Public feed, follower graphs, creator metrics.
- Always-on precise GPS.
- Full replacement for campus-wide event calendars.

---

For deck slides and VT-specific pitch, use **`Between/Between/docs/PITCH_DECK.md`**, not this file alone.
