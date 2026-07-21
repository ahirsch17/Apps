# DeskPilot

Control your Windows PC from your iPhone — trackpad, keyboard, volume, media, and shortcuts over local Wi‑Fi.

## Quick start

### 1. Set up the PC server (one time)

```bat
cd server
install-autostart.bat
```

This installs dependencies, registers a **background task** (starts at Windows login — no terminal to keep open), and writes connection info to:

`%LOCALAPPDATA%\DeskPilot\server.log`

For manual testing only, you can still run `start.bat`.

Allow Python through Windows Firewall on **private networks** when prompted.

### 2. Install the iPhone app (Mac + Xcode)

1. Pull this repo onto your Mac (`mobile apps/desk-pilot`)
2. Open `mobile apps/desk-pilot/ios/DeskPilot.xcodeproj` in Xcode
3. Select your Apple ID under **Signing & Capabilities** (Team)
4. Connect your iPhone and select it as the run destination
5. Press **Run** (⌘R)
6. On first install: iPhone → **Settings → General → VPN & Device Management** → trust your developer cert

### 3. Pair

1. Open DeskPilot on your iPhone
2. Go to **Settings**
3. Enter your PC's IP (e.g. `192.168.1.42`) and the PIN from the server terminal
4. Tap **Pair with PC**
5. Switch to **Trackpad** and control your PC

Phone and PC must be on the **same Wi‑Fi network**.

---

## App tabs

| Tab | What it does |
|-----|----------------|
| **Trackpad** | Move cursor, left/right click, scroll mode, sensitivity slider |
| **Keyboard** | Type text, modifiers, arrows, function keys |
| **Media** | Volume up/down/mute, play/pause, skip |
| **Power** | **Wake PC** (no server needed), sleep / restart / shutdown |
| **Shortcuts** | Show desktop, Alt+Tab, lock, copy/paste, etc. |
| **Settings** | IP, pairing, sensitivity tuning |

---

## Power: what works when

| Action | PC state | Needs server? |
|--------|----------|---------------|
| **Wake PC** | Asleep or off | No — uses Wake-on-LAN from your phone |
| **Sleep / Restart / Shutdown** | On | Yes — server must be running (auto-start handles this) |
| **Trackpad, keyboard, etc.** | On | Yes |

**Wake-on-LAN** requires one-time setup: enable it in BIOS and your network adapter's Power Management settings. The app fills in your PC's MAC address automatically when you pair.

**Tip:** Sleep the PC instead of full shutdown — wake is faster and more reliable from your phone.

---

## Project structure

```
mobile apps/
├── desk-pilot/
│   ├── PLAN.md           Full design doc
│   ├── README.md         This file
│   ├── ios/              SwiftUI iPhone app (open in Xcode)
│   └── server/           Python WebSocket server for Windows
├── SamePath/             Separate repo (Expo app)
├── Stoke/
├── Encrypted/
└── ...
```

See [PLAN.md](PLAN.md) for architecture, protocol, and roadmap.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Can't connect | Same Wi‑Fi? Server running? Correct IP? |
| Pairing fails | PIN changes each server restart — use the latest one |
| Firewall block | Allow Python on port 8765 (private network) |
| Xcode signing error | Set your Team in Signing & Capabilities |
| Cursor doesn't move | Re-pair in Settings; check server terminal for errors |

---

## Requirements

- **PC:** Windows 10+, Python 3.10+
- **Phone:** iOS 17+, iPhone
- **Mac:** Xcode 15+ (to build/install the app)
