# Between — VT Pitch Deck (10 slides)

**Audience:** Student Engagement, Rec Sports, IT Security, Hokies Wellness  
**Ask:** One-semester pilot · 500–1,000 students · SSO + FERPA agreement (Handshake-level)  
**Duration:** 12 minutes + Q&A

---

## Slide 1 — Title

**Between**  
*Find your people between classes.*

Virginia Tech pilot · [Your names] · [Date]

---

## Slide 2 — The problem (issue)

Students are told to **get involved** — but the system works against them:

- **Information is scattered** — Gobbler Connect, Instagram, GroupMe, department emails. Nothing is on the phone when you're actually free.
- **Web-first tools** — Checking Gobbler Connect between classes isn't convenient. Many students don't use social media.
- **Freshman reality** — Dorm life helps you make friends, but not **get back into your hobbies** (volleyball, soccer). Out-of-state students lose continuity.
- **Sophomore+ isolation** — Off-campus housing → stay home. Hard to coordinate free time with friends. Participation drops.
- **Resume padding** — Students join clubs on Gobbler Connect for the line on the resume, never attend, never enjoy it.

> "I lost volleyball even though I made friends in the dorm." — Alex

**Research-backed barriers:** don't know about events · intimidated · burnout · fear of overcommitment · no early hobby connections · homework feels higher-value than a pickup game.

**Holistic cost:** mental health, grades, community morale, Hokie spirit.

---

## Slide 3 — The insight

**Participation fails at the last mile** — not because students don't care, but because:
1. They don't know **who else is going** (social proof)
2. They don't have **someone to go with** (accountability)
3. They don't see events **when they're actually free** (schedule + phone)

**Two numbers change behavior:**
- **How many people are interested**
- **Who else is in the same boat** (partner OR "don't know anyone" — privacy-safe)

---

## Slide 4 — The resolution (what Between does)

1. **Free-time matches** — When are you and friends both free? Human copy, not minute math.
2. **Class connections** — Hashed course IDs match classmates **without the server seeing course titles**.
3. **Campus events** — School-specific feed; recurring pickup soccer vs IM volleyball with different matching types.
4. **Activity modes** — Hungry, Study, Gym — implementation intentions, auto-expire.

*Not a feed. Not LinkedIn. One screen: who can I see right now?*

---

## Slide 5 — Live demo (2 min)

1. **Sign in with Virginia Tech SSO** (demo email)
2. **Consent screen** — FERPA, hashed courses explained
3. Home: "Free with John 'til 11" · 11 friends
4. **Saturday Night Pickup Soccer** — 31 interested · 8 don't know anyone
5. Opt in as newcomer → see others who opted in (mutual only)
6. **IM Volleyball** — 48 interested · 9 need a partner
7. Security: encrypted blob → device decrypt → hash upload → match counts

---

## Slide 6 — Privacy & trust (for IT / Legal)

| Commitment | How |
|------------|-----|
| School isolation | VT data never mixes with other schools |
| **Course hashing** | Device hashes CRNs; server stores hashes only |
| **No grades** | Not collected, not requested |
| Schedule control | Student chooses share level |
| Partner/newcomer privacy | Mutual opt-in only |
| Encryption | TLS + AES-256-GCM blobs; decrypt on device |
| SSO | VT credentials via OIDC |
| FERPA | **Institutional agreement** — same bar as Handshake |

**Why we need course data:** Handshake doesn't use it. We do — for classmate overlap. **Hashing is how we earn that trust.**

---

## Slide 7 — Why VT should care

- **Involvement** — IM, Rec Sports, clubs see real attendance lift
- **Wellness** — Fights isolation; especially off-campus sophomores+
- **Out-of-state retention** — Helps students rebuild hobby communities
- **Complements Gobbler Connect** — Discovery + accountability, not replacement
- **Low-lift pilot** — CS + Rec Sports cohort, one semester, measurable

---

## Slide 8 — Pilot plan

| Week | Milestone |
|------|-----------|
| 1–2 | FERPA agreement draft + SSO sandbox |
| 3–4 | TestFlight · 100 students |
| 5–8 | Rec Sports events (volleyball, pickup soccer) |
| 9–12 | Attendance lift + loneliness survey |

**Metrics:** WAU · mode usage · event interest → opt-in conversion · post-event survey

---

## Slide 9 — Team

- Built by VT students who lived this problem
- Working iOS app + `/v1` API with realistic campus data
- Multi-tenant architecture ready for production Postgres
- Open to security audit before wide rollout

---

## Slide 10 — The ask

1. **FERPA / data-use agreement** — Handshake precedent, with course hashing addendum
2. **SSO test environment** (OIDC)
3. **Rec Sports + Student Engagement** intro for event seeding
4. **Pilot endorsement** — 500–1,000 students, one semester

**Contact:** [email] · TestFlight · Repo for security review

---

## Appendix — Q&A prep

**Q: Another social app?**  
A: No feed. Two home actions: events + friends. Answers one question.

**Q: Why course data if Handshake doesn't need it?**  
A: Handshake matches jobs. We match **classmates and free time**. Hashes protect course identity.

**Q: Harassment?**  
A: Mutual opt-in. First name only. Report/block. No stranger DMs in v1.

**Q: Gobbler Connect?**  
A: We drive **attendance**, not club registration. Complementary.

**Q: Cost?**  
A: Pilot ~$50–200/mo cloud. Scale with adoption.
