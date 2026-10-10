# NFL DraftKings Edge Finder

Model fair prices for NFL spreads, totals, and player props, then compare them to **DraftKings** lines (via [The Odds API](https://the-odds-api.com/)) and surface **+EV** singles and correlated same-game parlays.

This is a research / decision-support tool — not betting advice. Edges are small and noisy; never chase “locks.”

## Setup

```bash
cd /Users/alexhirsch/Projects/Apps/nfl-edge
/opt/homebrew/bin/python3.12 -m venv .venv
source .venv/bin/activate
pip install -e .
cp .env.example .env
# optional: set ODDS_API_KEY for live DraftKings odds
```

Without an Odds API key, `edges` falls back to **nflverse schedule lines** (spread/total/ML on the schedule file) so you can still run the full pipeline offline.

## Web UI

Clean localhost board focused on **multi-leg parlays in a solid payout band** (fair odds about **+250 to +900** — good payout, not lotto chalk-killers).

```bash
cd /Users/alexhirsch/Projects/Apps/nfl-edge
source .venv/bin/activate
nfl-edge ui
# opens http://127.0.0.1:8501
```

- NFL / MLB toggle
- Parlay cards with 2–4 legs, copy-ticket button
- Singles rail + game list
- Same-game (SGP) and cross-game tickets ranked for the payout window

## MLB module

```bash
nfl-edge mlb --days 2
```

Weighted factors (see `research/mlb/factor_weights.json`):

| Factor | Weight | Role |
| --- | --- | --- |
| Starting pitcher | 0.28 | Biggest single-game lever (ERA/WHIP/K-BB) |
| Offense form | 0.14 | Rolling RPG + OPS |
| Platoon matchup | 0.12 | Lineup vs SP handedness |
| Bullpen | 0.12 | Team ERA proxy for late innings |
| Park factor | 0.10 | Coors ↑ / pitchers' parks ↓ |
| Weather | 0.08 | Temp + wind out/in (totals) |
| Home field | 0.06 | ~0.12 runs |
| Similar pitcher history | 0.06 | Offense vs similar ERA-band SPs |
| Rest / travel | 0.04 | Placeholder / light |

## Weekly NFL workflow

```bash
# 1) Cache historical data (regular season only; no preseason)
nfl-edge ingest --start 2006

# 2) Refit factor weights from ~20y of history (HFA, weather, momentum)
nfl-edge research

# 3) Project this week's games (+ optional in-season backtest)
nfl-edge predict --week 3
nfl-edge predict --week 3 --backtest
nfl-edge backtest --season 2025 --start 2022

# 4) Compare to market
nfl-edge edges --week 3
nfl-edge edges --week 3 --props   # live DK player props (needs ODDS_API_KEY)

# 5) Correlated SGP ideas from edged bets
nfl-edge parlays --week 3
```

Outputs land in `output/`:

| File | Contents |
| --- | --- |
| `week_{season}_{week}_predictions.csv` | Spread/total/win% + team pass/rush yards |
| `week_{season}_{week}_props.csv` | Player pass/rush yard projections |
| `week_{season}_{week}_edges.csv` | Model vs market EV |
| `week_{season}_{week}_parlays.json` | 2–3 leg correlated SGP ideas |

## Research snapshot (refit anytime)

`nfl-edge research` writes [`research/factor_weights.json`](research/factor_weights.json). Latest fit on REG seasons 2006+:

- **HFA (mean home margin):** ~2.4 pre-2016 → ~1.9 (2016–19) → ~0.1 in 2020 → ~2.0 since 2021
- **Weather:** ~−2.9 total points per 10 mph wind; dome games ~+1.8 vs calm outdoor
- **Momentum:** last-3 margin correlates ~0.17–0.20 with next margin; form weight slightly higher mid/late season
- **Preseason:** excluded (`game_type == REG` only)

Reference backtest (simple rating model, 2025 REG): ~60% winner accuracy, ~10.5 MAE on margin — useful as a baseline, not a finished sharp book.

## What the model uses

| Factor | Source | Notes |
| --- | --- | --- |
| Team offense/defense | Rolling points for/against | Prior-to-game ratings (no leakage) |
| Home field | Era-split mean home margin | From `factor_weights.json` |
| Weather | `temp` / `wind` / `roof` | Wind strongest; high wind → lower totals & pass yards |
| Momentum | Last-3 margin EMA | Phase-weighted |
| Injuries | Injuries × depth charts | QB1 >> depth-chart backups; inactive depth ignored |
| Props | Rolling player yards × team pass/rush projection | Pass/rush yards first |

## Deep matchups (beyond the board)

On top of ratings / HFA / weather / injuries, each game gets:

1. **Style vector** — rolling pass/rush EPA, pass rate, sack pressure
2. **Similar-opponent history** — past games vs opponents with a similar style to this week’s foe
3. **Key-playmaker continuity** — those historical results are down-weighted if today’s QB1/WR1/RB1/CB1 (etc.) weren’t the same people
4. **Player mismatches** — pass EPA vs opposing pass rush, WR1 vs CB1, hot WR1 usage

See `output/week_*_deep_matchups.csv` for per-game notes (`sim_note`, `mm_note`) and continuity %.

## Market priority (payout-oriented)

1. Player props (softer retail lines; needs Odds API)
2. Totals (especially weather unders)
3. Spreads / ML (higher EV bar — sharper market)
4. SGPs only from correlated legs (Under + rush Over, Over + pass Over, total + side, etc.)

## Tuning loop

After each week:

1. Diff `output/week_*_edges.csv` vs results — which markets were overconfident?
2. Re-run `nfl-edge research` after major regime shifts
3. Tighten/loosen `edge_thresholds` in `factor_weights.json`
4. Prefer props + weather totals early; trust main lines less until ratings stabilize (weeks 1–4 are noisy)

## Layout

```
nfl-edge/
  src/nfl_edge/
    ingest/     # nflverse + Odds API + schedule-line fallback
    features/   # ratings, weather, injuries, matchups
    models/     # game + player props
    edge/       # EV + parlays
    cli.py
  research/     # factor studies → factor_weights.json
  data/         # cache (gitignored)
  output/
```

## Data sources

- **nflverse** via `nflreadpy` (CC-BY)
- **The Odds API** — DraftKings bookmaker key `draftkings`
