# DeskPilot — Phone Remote for Your PC

Control your Windows PC from your iPhone over local Wi‑Fi: trackpad, keyboard, volume, media, and shortcuts — without cramming everything onto one screen.

**Stack:** SwiftUI iOS app + Python WebSocket server on Windows  
**Install path:** Pull repo on Mac → open `ios/DeskPilot.xcodeproj` in Xcode → run on your iPhone

---

## Why this shape

| Choice | Reason |
|--------|--------|
| **SwiftUI (native iOS)** | You asked for Xcode install — no Flutter/React Native bridge |
| **Tab navigation** | Phone screens need one primary task per tab |
| **WebSocket over LAN** | Low latency for pointer movement; works on home Wi‑Fi |
| **Python server on Windows** | Easy to run on your PC; controls mouse, keys, volume via OS APIs |
| **PIN pairing** | Stops random devices on your network from taking over |

---

## Architecture

```
┌─────────────────┐         WebSocket (JSON)         ┌──────────────────────┐
│  iPhone app     │  ◄──────────────────────────────► │  Windows server      │
│  (SwiftUI)      │         same Wi‑Fi / LAN          │  (Python)            │
│                 │                                   │                      │
│  • Trackpad     │  mouse_move, mouse_click, scroll  │  pynput → cursor     │
│  • Keyboard     │  key, text, shortcut            │  pynput → keyboard   │
│  • Media        │  volume, media                   │  Win32 media keys    │
│  • Shortcuts    │  shortcut                        │  Win+D, Alt+Tab…     │
│  • Settings     │  pair, ping                      │  auth + status       │
└─────────────────┘                                   └──────────────────────┘
```

### Message protocol (JSON)

| Type | Payload | PC action |
|------|---------|-----------|
| `pair` | `{ pin, deviceName }` | Validate PIN, return token |
| `mouse_move` | `{ dx, dy }` | Move cursor (scaled by sensitivity) |
| `mouse_click` | `{ button, action }` | left/right/middle down/up/click |
| `scroll` | `{ dx, dy }` | Vertical/horizontal scroll |
| `key` | `{ key, modifiers[] }` | Single key + Ctrl/Alt/Shift/Win |
| `text` | `{ content }` | Type string |
| `volume` | `{ action, steps? }` | up / down / mute / set |
| `media` | `{ action }` | play_pause / next / prev |
| `shortcut` | `{ name }` | Named preset (see below) |
| `ping` | — | Returns `{ type: pong }` |

---

## App screens (TabView — one job per tab)

### Tab 1 — Trackpad (home)

Primary screen. Most-used controls live here.

```
┌─────────────────────────────┐
│  ● Connected · DESKTOP-PC   │  ← status pill
├─────────────────────────────┤
│                             │
│                             │
│      TRACKPAD SURFACE       │  ← drag = move cursor
│      (large touch area)     │     two-finger = scroll
│                             │
│                             │
├─────────────────────────────┤
│  Sensitivity  ────●────     │  ← inline slider (saved)
├─────────────────────────────┤
│ [L Click] [R Click] [Scroll]│  ← mode + click buttons
└─────────────────────────────┘
```

- **Single finger drag:** move mouse (sensitivity multiplier applied on phone before send)
- **Two-finger drag:** scroll (when Scroll mode off — always available as gesture)
- **Tap:** left click (optional toggle in Settings)
- **Bottom buttons:** explicit left/right click; Scroll mode locks surface to scroll-only
- **Haptics:** light tap on click actions

### Tab 2 — Keyboard

Split into sections — never one giant grid.

**Section A — Type & send**
- Multiline text field + “Send to PC” button (types full string)

**Section B — Modifiers** (sticky toggles)
- Ctrl · Alt · Shift · Win

**Section C — Essentials** (horizontal scroll row)
- Esc · Tab · Enter · Backspace · Delete · Space

**Section D — Arrows**
- D-pad layout (↑ ↓ ← →)

**Section E — Function keys** (collapsible)
- F1–F12 in a 4×3 grid, hidden until expanded

### Tab 3 — Media

Big, thumb-friendly controls.

```
┌─────────────────────────────┐
│                             │
│         ┌─────┐             │
│         │ 🔊  │  Volume     │
│         └─────┘             │
│    [ − ]  ═══════●══  [ + ] │
│         [ Mute ]            │
├─────────────────────────────┤
│   ⏮      ⏯      ⏭          │
│   Prev   Play    Next       │
└─────────────────────────────┘
```

- Volume step buttons + draggable slider (sends repeated up/down or future `set`)
- Mute toggle
- Media transport keys (system-wide)

### Tab 4 — Shortcuts

Quick actions as large tiles (2 columns).

| Shortcut | Windows action |
|----------|----------------|
| Show Desktop | Win+D |
| Switch App | Alt+Tab |
| Task View | Win+Tab |
| Lock | Win+L |
| Screenshot | Win+Shift+S |
| Copy / Paste | Ctrl+C / Ctrl+V |
| Undo | Ctrl+Z |
| Select All | Ctrl+A |
| Close Window | Alt+F4 |
| Minimize | Win+Down |

### Tab 5 — Settings

Connection + tuning — not mixed into control tabs.

- **Server host** (IP or `.local` hostname)
- **Port** (default 8765)
- **Pair** — enter 6-digit PIN shown in server terminal
- **Trackpad sensitivity** (0.25× – 3×)
- **Scroll sensitivity**
- **Tap to click** toggle
- **Invert scroll** toggle
- **Haptic feedback** toggle
- **Connection test** button
- **Forget device** (clears saved token)

---

## Visual design

- **Dark-first** UI (`#0D0F14` background) — comfortable at night, matches “remote” vibe
- **Accent:** soft blue `#4DA3FF` for active states
- **Cards:** rounded 16pt, subtle `#1A1D26` elevation
- **Typography:** SF Pro system fonts; large hit targets (min 44pt)
- **Status:** green/amber/red connection pill at top of each tab via shared `ConnectionBanner`

---

## Windows server

Location: `server/`

**Run once:**
```bash
cd server
pip install -r requirements.txt
python server.py
```

**What it does:**
1. Prints local IP + random 6-digit PIN to terminal
2. Listens on `0.0.0.0:8765`
3. Requires `pair` with correct PIN → returns session token
4. All later messages require `Authorization: Bearer <token>` header (WebSocket subprotocol or first auth message)

**Dependencies:**
- `websockets` — async WebSocket server
- `pynput` — mouse + keyboard control

**Optional later:** system tray icon, auto-start on login, firewall rule helper script

---

## Mac / iPhone setup (Xcode)

1. Clone/pull `mobile apps/desk-pilot` onto your Mac
2. Open `mobile apps/desk-pilot/ios/DeskPilot.xcodeproj` in Xcode
3. Select your **Apple ID** team under Signing & Capabilities
4. Connect iPhone → select it as run destination
5. Build & Run (first time: trust developer on iPhone in Settings → General → VPN & Device Management)
6. On Windows PC: start `server/server.py`, note IP + PIN
7. In app **Settings** tab: enter host, tap **Pair**, enter PIN
8. Switch to **Trackpad** tab and control your PC

**Info.plist keys already included:**
- `NSLocalNetworkUsageDescription` — required for LAN WebSocket on iOS 14+

---

## Security notes

- LAN-only by default (no cloud relay)
- PIN rotates each server restart
- Token stored in iOS Keychain
- Do not port-forward 8765 to the internet without TLS + stronger auth

---

## Roadmap (v2 ideas)

- [ ] Bonjour / mDNS auto-discovery of PC on network
- [ ] Brightness control (DDC/WM APIs)
- [ ] Custom shortcut editor
- [ ] Wake-on-LAN from app
- [ ] macOS server variant
- [ ] System tray + Windows service installer

---

## Repo layout

```
mobile apps/
├── PLAN.md              ← this file (inside desk-pilot/)
├── README.md
├── ios/
│   ├── DeskPilot.xcodeproj
│   └── DeskPilot/
└── server/
```
