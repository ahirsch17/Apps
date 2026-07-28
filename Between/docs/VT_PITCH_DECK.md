# Between — VT Pitch Deck (10 slides)

**Audience:** Student Engagement, Rec Sports, IT Security, Hokie Wellness  
**Ask:** One-semester pilot · 500–1,000 students · SSO + privacy review  
**Duration:** 12 minutes + Q&A

---

## Slide 1 — Title

**Between**  
*Find your people between classes.*

Virginia Tech pilot proposal · [Your names] · [Date]

---

## Slide 2 — The problem

- Students have **structured class time** but **unstructured free time**
- Social media spreads events; it doesn't **match you with a partner**
- Showing up alone to IM volleyball or a club meeting is **high friction**
- Result: students stay in their room even when they'd rather be active

> "I picked volleyball as an interest but forgot about it. I assumed nobody I know was going."

---

## Slide 3 — The insight

**Two numbers change behavior:**
1. **How many people are interested** (social proof)
2. **Who else needs a partner** (mutual opt-in, privacy-safe)

Between shows counts first. Partner details unlock only when **you're also looking**.

---

## Slide 4 — What Between does (3 things)

1. **Free-time matches** — When are you and friends both free? (no minute math — human times)
2. **Class connections** — Who's in your section vs another section?
3. **Activity modes + events** — Hungry, Study, Gym · campus events with partner matching

*Optional:* Canvas schedule sync · VT SSO · encrypted partner profiles

---

## Slide 5 — Live demo flow (2 min)

1. Sign in with VT email (demo: alex.hirsch@vt.edu)
2. Home: "Free with John 'til 11" · 11 friends connected
3. Tap **Hungry** mode → friends also hungry surface
4. Events: **IM Volleyball · 48 interested · 9 looking for partner**
5. Tap "Looking for partner" → unlock anonymized profiles (year, note)
6. Security slide: encrypted in transit · SSO · FERPA-aligned consent

---

## Slide 6 — Privacy & trust (for IT / Legal)

| Commitment | How |
|------------|-----|
| School isolation | VT data never mixes with other schools |
| Schedule control | Student chooses share level; per-friend overrides |
| Partner privacy | No identity leak without mutual opt-in |
| Encryption | TLS + field-level encryption for sensitive fields |
| SSO | VT credentials; no password reuse |
| FERPA | Schedule = education record; minimal retention policy |

---

## Slide 7 — Why VT should care

- **Student involvement** — More IM, club, and pickup attendance
- **Wellness** — Reduces isolation; encourages in-person connection
- **Complements Canvas** — Schedule in, social layer on top
- **Low lift pilot** — Seed cohort (CS + Rec Sports), measure in one semester

---

## Slide 8 — Pilot plan

| Week | Milestone |
|------|-----------|
| 1–2 | SSO sandbox + privacy review |
| 3–4 | TestFlight to 100 students |
| 5–8 | Rec Sports events live (volleyball, soccer) |
| 9–12 | Measure attendance lift + survey |

**Success metrics:** WAU, mode usage, event interest → partner conversion, post-event survey

---

## Slide 9 — Team & credibility

- Built by VT students who feel this problem
- Working iOS demo with realistic campus data
- Architecture ready for production API + Postgres
- Open to security audit before wide rollout

---

## Slide 10 — The ask

**We request:**
1. Intro to Student Engagement + Rec Sports for event seeding
2. SSO test environment (OIDC)
3. One-semester pilot endorsement to 500–1,000 students

**Contact:** [email] · Demo: TestFlight link · Repo available for security review

---

## Appendix — Anticipated questions

**Q: Another social app?**  
A: No feed. One screen answers "who can I see right now?" Counts, not scroll.

**Q: Harassment via partner profiles?**  
A: Mutual opt-in only. Report block. No DMs to strangers in v1.

**Q: Canvas?**  
A: Optional token sync. VT CRN import is primary for pilot.

**Q: Cost?**  
A: Pilot on modest cloud (~$50–200/mo). Scale with adoption.
