# DeskPilot

Control your Windows PC from your iPhone — trackpad, keyboard, volume, media, and power over local Wi‑Fi. Mac full desktop: **[MAC_REMOTE.md](docs/MAC_REMOTE.md)**.

## PC setup — **once**, then phone only

```bat
cd server
install-all.bat
```

Approve **one** Administrator prompt (firewall + Remote Desktop for Mac). After that you should **not** run `start.bat`, firewall scripts, or terminal commands for daily use. See **[SECURITY_AND_AUTOSTART.md](docs/SECURITY_AND_AUTOSTART.md)** for what is automated vs what stays secure.

1. Pair **once** in the iPhone app (Settings → IP + PIN from `%LOCALAPPDATA%\DeskPilot\server.log`).
2. Use **Sleep** from the phone instead of shutdown when you want **Wake PC** to work later.
3. Set wake sign-in locally: `%LOCALAPPDATA%\DeskPilot\config.json` (`windows_user`, `windows_pin`) — see `server/config.example.json`.

---

## iPhone app (Mac + Xcode)

Open `ios/DeskPilot.xcodeproj`, set Signing, run on your iPhone. Same Wi‑Fi as the PC.

---

## Troubleshooting (should be rare)

| Problem | Fix |
|---------|-----|
| App never connects after reboot | Re-run **`install-all.bat` once** (registers autostart; path-with-spaces bug was fixed in `register-user-autostart.ps1`) |
| Wake works, no sign-in | Check local `config.json` PIN / display name |
| Mac RDP | [MAC_REMOTE.md](docs/MAC_REMOTE.md) |

`start.bat` and `restart-server.bat` are for **developers**, not daily use.

---

See [PLAN.md](PLAN.md) for protocol details.
