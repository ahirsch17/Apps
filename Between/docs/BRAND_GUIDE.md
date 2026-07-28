# Brand Guide — Between

Honest assessment for college students (18–24) and the VT pilot audience.

---

## Is "Between" the best name?

**Verdict: Yes — keep it.** Score **8.5/10** for this product.

| Criterion | Between | Typical alternatives |
|-----------|---------|----------------------|
| Describes the job | ✅ Literal — free time *between* classes | "CampusConnect" — generic social |
| Memorable & short | ✅ One word, easy to say | "GobblerGap" — doesn't scale past VT |
| Multi-school ready | ✅ Not VT-specific | "HokieHours" — locked to one school |
| Not dating-coded | ✅ With campus tagline, clear | "Meetup" — crowded trademark space |
| App Store clarity | ⚠️ Common word — needs subtitle | |

**Recommended App Store subtitle:**  
*"Find friends & events between classes"*

**Why not rebrand:** The name *is* the insight. Students don't need another "social network" — they need something that names the awkward hour between lectures. Alternatives we evaluated (FreeBlock, Gap, Passing, Hallway) are either too technical, too vague, or already taken.

The **Be | tween** split in the wordmark reinforces the meaning without a rebrand.

---

## Color scheme — what psychology says

College students respond to apps that feel **inviting daily**, not **institutional mandatory**.

| Approach | Student feeling | Admin feeling |
|----------|-----------------|---------------|
| Full VT maroon on every button | "Another school portal" | "Official, trusted" |
| Neon / gradient startup | "Fun but sketchy for my schedule" | "Not FERPA-serious" |
| **Warm neutral + maroon identity + coral actions** | "My app — feels modern" | "Professional enough for pilot" |

### Our split palette

| Token | Hex | Role | Psychology |
|-------|-----|------|------------|
| `accent` (product maroon) | `#8B2A4A` | Wordmark, headers, icons | Warmth + identity; softer than banner maroon |
| `accentAction` (coral) | `#E85D47` | Primary buttons, badges | Action & energy; outperforms dark maroon for taps among 18–24 |
| `vtMaroon` / `vtOrange` | `#861F41` / `#CF4420` | SSO screen, "VT pilot" badge only | Official co-brand when talking to the university |
| Background | `#FAF9F7` warm off-white | Canvas | Calm, not clinical white |
| `free` green | — | "Available now" | Positive availability — never alarm red |

**Key rule:** VT official colors appear on **login / SSO / pilot badge** — not on every CTA. Daily use feels like *your* tool; pitch moments feel like *VT's* partner.

---

## Logo / mark

**Verdict:** The vector **BetweenMark** (two bars, one gap) is stronger than a missing PNG asset.

| Element | Purpose |
|---------|---------|
| **BetweenMark** | Symbol — the gap between two blocks = time between classes |
| **BetweenWordmark** | Be (maroon) + tween (coral) |
| **BetweenBrandLockup** | Mark + wordmark on welcome |
| **VTPilotBadge** | Official VT co-brand without repainting the whole app |

**Avoid:** Gradients, glow, emoji logos, busy crests. Gen Z trusts **flat, native, iOS-native** visuals (see BeReal, Duolingo, Apple Health — confident simplicity).

The old `BrandLogo.png` was not in the repo; the SwiftUI mark fixes that and scales to any size.

---

## What we changed (implementation)

1. **Coral primary buttons** — students tap actions; maroon stays for brand
2. **Warmer background** — less "hospital white"
3. **BetweenMark** — vector logo, no broken image
4. **VT colors scoped** — SSO + pilot badge only
5. **Toolbar** — compact mark, not cluttered wordmark

---

## When to revisit the name

Only if:
- App Store discovery fails after launch (add subtitle first)
- VT asks for co-branded name ("Between @ VT" is enough for pilot)
- Expansion beyond campus schedule into unrelated verticals

Until then, invest in **behavior and trust**, not a rebrand.

---

## Quick reference

```
Daily app:     maroon identity + coral actions + warm gray surfaces
VT moments:    vtMaroon + vtOrange badge on SSO / consent
Logo:          BetweenMark + wordmark lockup
Tagline:       "Find your people between classes"
```
