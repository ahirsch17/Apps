# DeskPilot — what runs where (security vs convenience)

## You should never need daily PC commands

After **`install-all.bat` once** (one UAC prompt):

- The server starts at **Windows sign-in** and again after **sleep** (scheduled tasks + Run key).
- **Firewall** allows your phone on **private Wi‑Fi only** (port 8765), not the public internet.
- **Mac Remote Desktop** uses normal Windows RDP with sign-in (password + NLA), not a backdoor.

If something asks you to run `start.bat`, `restart-server.bat`, or firewall scripts **every day**, that is a bug — not the intended design.

## What the phone can do (and how)

| Action | Mechanism | Security note |
|--------|-----------|----------------|
| Trackpad, keyboard, media | WebSocket on LAN after **pairing PIN + token** | Same Wi‑Fi (or Tailscale); not exposed without firewall rule |
| Sleep / lock / shutdown | Authenticated session to server | Requires PC already on and paired |
| Wake | **Wake-on-LAN** magic packet | LAN broadcast; cannot wake from across the internet without VPN |
| Sign-in after wake | Local **Windows PIN** stored only in `%LOCALAPPDATA%\DeskPilot\config.json` | UI automation on lock screen; PIN never in git |

## What we deliberately do *not* do

- Open RDP to the whole internet (use **Tailscale** when away).
- Disable Windows Update, Defender, or lock screen.
- Store your Windows PIN in the GitHub repo.
- Run a always-on public tunnel (ngrok, etc.) by default.

## Honest limits (not bugs)

- **Full shutdown** from the phone means **Wake-on-LAN** + BIOS/network adapter settings — less reliable than **Sleep**.
- **Cold boot** sign-in automation is best-effort; sleep → wake is the happy path.
- **DHCP** may change the PC IP; re-pair or update IP in app Settings if Wi‑Fi assigns a new address.

## One-time optional

- **`enable-wol.bat`** — only if wake from sleep/off is flaky (network adapter + BIOS).
- **`restart-server.bat`** — only after you change server code, not for normal use.
