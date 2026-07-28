# Design Psychology — Between

Research-backed patterns for encouraging involvement without overwhelming students.

---

## 1. Social proof (reduce "nobody's going")

**Problem:** Ambiguity kills attendance. Students assume low turnout.

**Pattern:** Show **aggregate counts first**, identities second.
- "48 Hokies interested" before any names
- "9 looking for a partner" with lock icon until user opts in

**Research:** Cialdini's social proof; campus event studies show +15–30% RSVP when peer counts visible (Festinger, latent demand).

**UI:** Large number + short label. No charts. One tap to "I'm interested."

---

## 2. Mutual opt-in for vulnerability (partner seeking)

**Problem:** Showing "who's looking" without opt-in feels creepy; hiding everything feels empty.

**Pattern:** **Reciprocal visibility**
- Everyone sees counts
- Partner cards unlock only when you post your own "looking for partner" profile
- Profiles: first name, year, one-line note, optional IG — no email/phone

**Research:** Privacy calculus (Altman); dating-app "double opt-in" reduces harassment, increases trust.

---

## 3. Implementation intentions (modes)

**Problem:** "I'm free" is too vague. Students don't act.

**Pattern:** **Mode = intention + duration**
- "Hungry · next hour" sets expectation for friends AND self
- Quiet mode defaults 2h — respects introverts, reduces ping fatigue

**Research:** Gollwitzer implementation intentions ("If 12pm, then lunch with friend") improve follow-through.

**UI:** Horizontal mode chips on home. One tap. Auto-expire. Toast confirms.

---

## 4. Reduce cognitive load

**Problem:** Overwhelming menus → close app → stay in dorm.

**Rules:**
- Max **3 primary actions** on home: see friends, pick mode, browse events
- One hero card answers the main question
- No minute math, no sync timestamps, no settings gear on every row

**Research:** Hick's Law; mobile attention spans ~8s to value.

---

## 5. Identity & belonging (interests)

**Problem:** Picking "volleyball" once then forgetting.

**Pattern:**
- Interests on onboarding (required pick 2–3)
- Home surfaces **one event matching top interest** when relevant
- "Because you picked volleyball" subtitle

**Research:** Self-congruity — people attend what matches self-image.

---

## 6. Color & typography (VT pilot)

| Token | Value | Why |
|-------|-------|-----|
| Primary | Chicago Maroon `#861F41` | Campus trust, official adjacency |
| Accent | Burnt Orange `#CF4420` | Energy, CTAs |
| Free/success | Soft green | "Available" without alarm |
| Background | Off-white `#F7F7F8` | Calm, not clinical |
| Type | SF Pro system | Native, readable, accessible |

**Avoid:** Neon gradients, dashboard density, emoji avatars in production.

---

## 7. Encouragement copy (examples)

| Context | ❌ Don't | ✅ Do |
|---------|----------|-------|
| Overlap | "550 min free" | "Free with John 'til 11" |
| Event | "0 attendees" | "Be the first — or see 48 interested" |
| Partner | "List of seekers" | "9 looking for a partner · join to see" |
| Empty | "No data" | "Your friends' schedules sync here after class" |

---

## 8. Credibility with the school

Students trust the app when:
1. **VT email / SSO** — "real students only"
2. **Privacy policy in plain English** — one screen at signup
3. **FERPA alignment** — schedule data never sold, school can audit
4. **Encryption callout** — demo shows lock + "encrypted in transit"

Pitch demo should include: SSO login mock → encrypted payload → client decrypt → partner list gated.
