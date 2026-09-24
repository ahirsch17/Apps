# Between product requirements

Last updated: September 2026

Campus participation app: one place to see what is happening at VT and join without schedule matching or class data.

## Problem

Campus life is scattered across email, Instagram, GroupMe, posters, and portals. Showing up alone feels socially risky. Free-time and class-overlap tools go stale after the first couple of weeks, and they depend on protected academic data that is hard to get approved.

## Solution

Make events easy to find and low-pressure to track. Official events, clubs, sports, student pop-ups, and local happenings share one feed. Interest is private by default.

The university is the primary customer. Students are users. Without institutional seeding (major events and club onboarding before move-in), the feed dies.

## Principles

1. Engagement over academics. No course data, SIS, or free-time matching.
2. Low embarrassment. Private interest by default; soft cues like "1 spot left" instead of newcomer labels.
3. Value for tapping. "Keep me posted" unlocks updates and alerts, not a public commitment.
4. Unified feed with clear category labels.
5. Fast, mobile-native UX.
6. Institution-ready analytics (for example QR check-in) without making students feel watched.

## Deprecated

| Removed | Why |
|---------|-----|
| Course ingestion / CRN lookup | Protected data; weak long-term value |
| Schedule / free-block overlap | Stale after week ~2 |
| Class-friend discovery via course hashes | Academic infrastructure, not engagement |
| Public Interested / Going lists | Lowers tap rates |

Legacy schedule code may still exist in the tree. Treat it as dead product surface; do not extend it.

## North star

Weekly event engagements per active user (keep-me-posted taps, open-spot claims, check-ins, attributed attendance).

## Target tabs

| Tab | Job |
|-----|-----|
| For You | Personalized + trending + happening soon |
| Discover | Categories and search |
| Post | Club events or moderated student pop-ups |
| My Week | Private tracked events and reminders |
| Friends | Lightweight social graph (opt-in), not chat-as-product |

### Event categories

1. Official university events
2. Clubs and student orgs
3. Sports and athletics (including IM / Rec)
4. Campus services
5. Student pop-ups (moderated)
6. Community and local businesses (separated from official)

### Copy rules

- Prefer **Keep me posted** / **Follow updates**. Avoid public **Going**.
- Show counts by default; names only with explicit opt-in.
- Soft cues: open spots, rides, drop-in language.
- No guilt copy, newcomer badges, or schedule exposure.

## Differentiator features

| Feature | Student value | Admin value |
|---------|---------------|-------------|
| Private interest + turnout signals | Social safety | Engagement analytics |
| Student pop-ups + moderation | Informal layer stays alive | Campus vitality with safety |
| Open spots | Join with cover | Higher turnout |
| Rideboard | Off-campus without awkward asks | Trip participation |
| Local business category | Trivia, specials, live music | Town-gown life (separated) |
| QR check-in | Fast entry | Attendance metrics |

## Auth and profiles

1. Enter `@vt.edu` email
2. Verification code
3. Password + minimal profile (name, year, optional bio)

No academic data. Event visibility is opt-in.

## MVP status

| Capability | Status |
|------------|--------|
| VT email auth (demo code flow) | Partial |
| Unified event feed + categories | Partial |
| Event detail + private keep-me-posted | In progress / rebrand |
| Interests onboarding | Shipped (retarget to engagement) |
| Open spots | Not built (P0) |
| Rideboard | Not built (P0) |
| Student pop-up create + moderation | Not built (P0) |
| Local business category | Not built (P1) |
| QR check-in + admin analytics | Not built (P1) |
| Friend graph | Shipped (keep lightweight) |
| Course / schedule / free-time stack | Deprecated |

## Privacy

- No SIS, rosters, or course schedules
- Interest and attendance anonymous by default
- Location only if event-tied; never always-on tracking
- Student pop-ups need moderation and a report path

## Near-term out of scope

- Class schedules, CRN tools, free-time overlap
- Public follower graphs
- Always-on precise GPS
- Replacing Banner or other systems of record

## Related docs

- [Data model](DATA_MODEL.md)
- [Server architecture](SERVER_ARCHITECTURE.md)
- [Testing](TESTING.md)
