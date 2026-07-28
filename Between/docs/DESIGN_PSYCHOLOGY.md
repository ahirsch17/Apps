# Design Psychology — Between

Research-backed patterns for encouraging involvement without overwhelming students.

---

## Why students don't participate (research synthesis)

| Barrier | What students say | Between response |
|---------|-------------------|-------------------|
| **Don't know about it** | Events buried in Gobbler Connect, Instagram stories, GroupMe | One feed: campus events matched to *your* interests |
| **Intimidation** | "I won't know anyone" | Newcomer matching — mutual opt-in, counts before names |
| **Burnout / overcommitment** | "I'm already overwhelmed" | Modes with auto-expire; no guilt copy |
| **No early connections** | Freshman dorm friends ≠ hobby friends | Interest onboarding + class hash matching |
| **Homework > social** | Career fairs feel "productive" | Show free windows *between* classes — low time cost |
| **Resume padding** | Join clubs on Gobbler Connect, never attend | Social proof counts + accountability partner |

**Lifecycle pain (your story):**
- **Freshman in dorms:** Less "make friends" than **get back into hobbies** (volleyball, soccer). Out-of-state students lose continuity.
- **Sophomore+ off campus:** Easy to stay home. Coordinating free time with friends is friction. Participation and networking drop → mental health, grades, community morale.

Between is not another social feed. It answers: **"Who can I see right now, and what can I actually go do?"**

---

## 1. Social proof (reduce "nobody's going")

**Problem:** Ambiguity kills attendance. Students assume low turnout.

**Pattern:** Show **aggregate counts first**, identities second.
- "48 Hokies interested" before any names
- "9 looking for a partner" OR "8 new to this" depending on event type

**Research:** Cialdini's social proof; campus event studies show +15–30% RSVP when peer counts visible.

**UI:** Large number + short label. No charts. One tap to "I'm interested."

---

## 2. Mutual opt-in for vulnerability

**Partner events (IM volleyball):** "Need a partner" — profiles unlock only when you post too.

**Newcomer events (Saturday pickup soccer):** "Don't know anyone" — **nobody knows you're that person** unless another newcomer opts in. Same double opt-in, different label.

**Research:** Privacy calculus (Altman); reciprocal disclosure builds trust without exposure.

---

## 3. Implementation intentions (modes)

**Pattern:** Mode = intention + duration. "Hungry · next hour" not "I'm free."

Quiet mode = 2h default. Respects introverts.

---

## 4. Reduce cognitive load (menu structure)

**Problem:** Overwhelming menus → close app → stay in dorm.

**Home top bar (2 actions + brand):**
| Position | Action | Why |
|----------|--------|-----|
| Left | Campus events | Discovery — "what can I do?" |
| Center | Between wordmark | Identity anchor, not clutter |
| Right | Friends | People — requests, search, course lookup |

Secondary actions (course search, notifications) live **inside Friends** — not on home.

**Rules:**
- Max **3 primary actions** on home scroll: see friends, pick mode, browse events
- One hero card answers the main question
- No minute math, no sync timestamps on home

**Research:** Hick's Law; mobile attention ~8s to value.

---

## 5. Identity & belonging (interests)

Interests on onboarding (pick 2–3). Home surfaces one matching event: "Because you picked volleyball."

**Research:** Self-congruity — people attend what matches self-image.

---

## 6. Color, logo & name

**Name:** Keep **Between** — see `BRAND_GUIDE.md` for full analysis.

**Direction:** Campus-trusted for admins, warm and modern for students — not startup-neon, not full VT maroon on every button.

| Token | Value | Use |
|-------|-------|-----|
| Product maroon | `#8B2A4A` | Wordmark "Be", icons, headers |
| Action coral | `#E85D47` | Primary buttons, badges — energy without admin-portal feel |
| VT maroon/orange | `#861F41` / `#CF4420` | SSO + "Virginia Tech pilot" badge **only** |
| Background | Warm off-white `#FAF9F7` | Calm canvas |
| Free | Soft green | Availability |

**Mark:** `BetweenMark` — two bars with a gap (time between classes). Vector, no PNG.

**Wordmark:** `Be` (maroon) + `tween` (coral).

**Avoid:** Full school colors on every surface (feels like Banner/HokieSPA), neon gradients, gamification badges.

**Modern = confident restraint.** Students open this between classes — it should feel like a helpful friend, not a university form.

---

## 7. Encouragement copy

| Context | ❌ Don't | ✅ Do |
|---------|----------|-------|
| Overlap | "550 min free" | "Free with John 'til 11" |
| Event | "0 attendees" | "48 interested · 8 new to this" |
| Partner | "List of seekers" | "9 need a partner · join to see" |
| Newcomer | "Lonely people" | "Don't know anyone? Opt in to meet others" |
| Empty | "No data" | "Your friends' schedules sync here after class" |

---

## 8. Credibility with the school

1. **VT SSO** — real students only
2. **FERPA consent** — plain English, one screen
3. **Hashed course IDs** — server never sees CRNs or course titles from device
4. **No grades** — ever
5. **School data isolation** — VT never mixes with other tenants

Pitch demo flow: SSO → consent → encrypted blob → client hash → classmate counts by hash → event with mutual opt-in.

---

## 9. vs Handshake / Gobbler Connect

| Tool | Strength | Gap Between fills |
|------|----------|-------------------|
| Gobbler Connect | Official clubs | Resume joins, not attendance; no free-time coordination |
| Handshake | Career + FERPA trust | No course overlap, no "between classes" social layer |
| Instagram / GroupMe | Event discovery | No schedule awareness, no privacy-safe matching |
| Between | Free time + hashed classes + events | Needs school FERPA agreement (like Handshake) |

We need course data to match classmates — **hashing is the only way schools say yes.**
