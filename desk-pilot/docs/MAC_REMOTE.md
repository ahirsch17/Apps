# Remote into this PC from your MacBook

DeskPilot handles **phone** control (trackpad, power, wake). Your Mac uses **Windows Remote Desktop (RDP)** for a full desktop session.

## Portable Mac, powerhouse PC (typical workflow)

Use the **MacBook** for what travels well: notes, meetings, light coding, browser, messaging. Use the **desktop PC** for heavy work (builds, GPU, large repos, Windows-only tools) by remoting in—you get the PC’s performance without moving the machine.

| Where you are | Mac | PC | Phone |
|---------------|-----|-----|--------|
| **At home** | RDP to `192.168.12.154` (or Tailscale IP) | On or sleeping | Optional: wake/sleep from couch |
| **Away (campus, travel)** | RDP to PC’s **Tailscale** `100.x.x.x` | Must be on or woken first | **Wake PC** + sign-in if it was sleeping |
| **PC off for the day** | Mac only | Off | Wake only works if WoL + sleep (not cold off) |

**Make it portable:** install **Tailscale** on both Mac and PC once. Save one RDP profile on the Mac using the PC’s Tailscale address—that same bookmark works on home Wi‑Fi and on cellular/hotel Wi‑Fi. No VPN config per network.

**Before you leave the house:** put the PC to **Sleep** (DeskPilot or physically), not full shutdown, so your phone can wake it when you need the beast from the Mac.

## One-time setup on the PC

From `desk-pilot/server` on this Windows machine:

```bat
install-all.bat
```

When prompted for administrator access, approve it. That registers DeskPilot background tasks, opens firewall port **8765** for the phone app, and **enables Remote Desktop** for your Mac.

Your Windows sign-in name and PIN for phone wake live only in:

`%LOCALAPPDATA%\DeskPilot\config.json`

Copy fields from `config.example.json` if you need a template. Never commit real PINs to git.

## On the MacBook

### Same home Wi‑Fi

1. Install **[Microsoft Remote Desktop](https://apps.apple.com/app/microsoft-remote-desktop/id1295203466)** from the App Store.
2. Add a PC:
   - **PC name:** this PC’s LAN IP (shown in `server.log` after setup, e.g. `192.168.12.154`)
   - **User account:** your Windows username (often `Alex` or your Microsoft email)
   - **Password:** your Windows password (RDP uses password; phone wake uses PIN via DeskPilot)
3. Connect.

### Away from home (recommended)

RDP over the public internet needs a VPN mesh:

1. Install **[Tailscale](https://tailscale.com/download)** on the PC and Mac; sign in to the same account.
2. On the Mac, note the PC’s **Tailscale IP** (100.x.x.x) in the Tailscale menu or admin console.
3. In Microsoft Remote Desktop, use that **100.x.x.x** address as the PC name.

No router port forwarding required.

## Phone vs Mac

| Goal | Tool |
|------|------|
| Wake, sleep, lock, trackpad from couch | **DeskPilot** (iPhone) |
| Full desktop, files, dev tools | **Microsoft Remote Desktop** (Mac) |

After **Sleep** from DeskPilot, tap **Wake PC** on the phone; scheduled tasks bring the server back and can enter your PIN. Use **Sleep** instead of shutdown for the most reliable flow.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Mac cannot connect on Wi‑Fi | Re-run `install-all.bat` and approve admin; confirm PC IP in `%LOCALAPPDATA%\DeskPilot\server.log` |
| Mac cannot connect on Tailscale | Both devices must show “Connected” in Tailscale; ping the PC’s 100.x address from Terminal |
| “Credentials did not work” for RDP | Use Windows **password**, not PIN; add `PCNAME\username` if needed |
| DeskPilot power buttons greyed out | Server not running — tasks should fix this after login; check port 8765 or run `restart-server.bat` once |
