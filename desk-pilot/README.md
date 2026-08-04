# DeskPilot

Control your Windows PC from your iPhone — trackpad, keyboard, volume, media, and power over local Wi‑Fi. Use **[Mac remote desktop setup](docs/MAC_REMOTE.md)** for full RDP from a MacBook.

## Quick start (PC, one time)

```bat
cd server
install-all.bat
```

This will:

- Install Python dependencies
- Register **scheduled tasks** (server at login, after sleep, wake/sign-in helpers)
- Start the server immediately
- Prompt for **Administrator** once to allow firewall (8765) and **Remote Desktop** for Mac

Connection details append to `%LOCALAPPDATA%\DeskPilot\server.log`.

Set wake/sign-in credentials locally (not in git):

`%LOCALAPPDATA%\DeskPilot\config.json` — see `server/config.example.json`.

For manual testing only: `start.bat`. To reload code: `restart-server.bat`.

---

## iPhone app (Mac + Xcode)

1. Pull this repo onto your Mac (`mobile apps/desk-pilot`)
2. Open `ios/DeskPilot.xcodeproj` in Xcode
3. Set your Team under **Signing & Capabilities**
4. Run on your iPhone (⌘R)
5. **Settings** → PC IP + PIN → **Pair with PC**

Phone and PC must be on the **same Wi‑Fi** (or same Tailscale network if you extend routing later).

---

## MacBook → full desktop

See **[docs/MAC_REMOTE.md](docs/MAC_REMOTE.md)** (Microsoft Remote Desktop + optional Tailscale).

---

## App tabs

| Tab | What it does |
|-----|----------------|
| **Trackpad** | Move cursor, click, scroll |
| **Keyboard** | Type text, modifiers, arrows |
| **Media** | Volume, play/pause, skip, launch apps |
| **Power** | Wake PC, sleep, lock, shutdown |
| **Settings** | IP, pairing, sensitivity |

---

## Power: what works when

| Action | PC state | Needs server? |
|--------|----------|---------------|
| **Wake PC** | Asleep | No for magic packet; yes for auto sign-in after wake |
| **Sleep / Lock / Shutdown** | On | Yes (auto-start handles this) |
| **Trackpad, keyboard, etc.** | On | Yes |

**Tip:** Prefer **Sleep** over shutdown. Run `enable-wol.bat` once if wake from off/sleep is unreliable.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Must run `start.bat` every login | Run `install-all.bat` again |
| Can't connect | Same Wi‑Fi? Check `server.log` for IP; firewall rule from install-all |
| Wake works but no sign-in | Set `windows_user` + `windows_pin` in local `config.json` |
| Pairing fails | Use PIN from latest `server.log` |
| Mac RDP fails | See [MAC_REMOTE.md](docs/MAC_REMOTE.md) |

---

## Requirements

- **PC:** Windows 10/11 Pro (for Mac RDP host), Python 3.10+
- **Phone:** iOS 17+
- **Mac:** Xcode 15+ (iPhone build); Microsoft Remote Desktop (desktop access)

See [PLAN.md](PLAN.md) for architecture and protocol.
