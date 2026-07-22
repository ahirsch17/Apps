#!/usr/bin/env python3
"""DeskPilot Windows server — receives commands from the iPhone app over WebSocket."""

from __future__ import annotations

import asyncio
import json
import secrets
import socket
import subprocess
import sys
from typing import Any

import websockets
from config_store import CONFIG_DIR, load_config, save_config
from pynput.keyboard import Controller as KeyboardController, Key
from pynput.mouse import Button, Controller as MouseController
from text_focus import describe_focus_target, pc_text_field_is_focused
from wake_routine import run_login_watch, run_wake_routine

HOST = "0.0.0.0"
PORT = 8765

mouse = MouseController()
keyboard = KeyboardController()

CONFIG = load_config()
PAIR_PIN = str(CONFIG["pair_pin"])
SESSION_TOKENS: dict[str, str] = dict(CONFIG.get("session_tokens", {}))
MAC_ADDRESS = str(CONFIG.get("mac_address", ""))
AUTHED_CLIENTS: set[Any] = set()

KEY_MAP: dict[str, Any] = {
    "enter": Key.enter,
    "tab": Key.tab,
    "escape": Key.esc,
    "backspace": Key.backspace,
    "delete": Key.delete,
    "space": Key.space,
    "up": Key.up,
    "down": Key.down,
    "left": Key.left,
    "right": Key.right,
    "f1": Key.f1,
    "f2": Key.f2,
    "f3": Key.f3,
    "f4": Key.f4,
    "f5": Key.f5,
    "f6": Key.f6,
    "f7": Key.f7,
    "f8": Key.f8,
    "f9": Key.f9,
    "f10": Key.f10,
    "f11": Key.f11,
    "f12": Key.f12,
}

MODIFIER_MAP: dict[str, Key] = {
    "ctrl": Key.ctrl,
    "alt": Key.alt,
    "shift": Key.shift,
    "win": Key.cmd,
}

SHORTCUTS: dict[str, list[Any]] = {
    "show_desktop": [Key.cmd, "d"],
    "alt_tab": [Key.alt, Key.tab],
    "task_view": [Key.cmd, Key.tab],
    "lock": [Key.cmd, "l"],
    "screenshot": [Key.cmd, Key.shift, "s"],
    "copy": [Key.ctrl, "c"],
    "paste": [Key.ctrl, "v"],
    "undo": [Key.ctrl, "z"],
    "select_all": [Key.ctrl, "a"],
    "close_window": [Key.alt, Key.f4],
    "minimize": [Key.cmd, Key.down],
}

# Windows virtual-key codes for volume/media
VK_VOLUME_MUTE = 0xAD
VK_VOLUME_DOWN = 0xAE
VK_VOLUME_UP = 0xAF
VK_MEDIA_PLAY_PAUSE = 0xB3
VK_MEDIA_NEXT_TRACK = 0xB0
VK_MEDIA_PREV_TRACK = 0xB1


def local_ip() -> str:
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"


def hostname() -> str:
    return socket.gethostname()


def press_vk(vk_code: int) -> None:
    import ctypes

    ctypes.windll.user32.keybd_event(vk_code, 0, 0, 0)
    ctypes.windll.user32.keybd_event(vk_code, 0, 2, 0)


def volume_action(action: str, steps: int = 1) -> None:
    if action == "mute":
        press_vk(VK_VOLUME_MUTE)
        return

    vk = VK_VOLUME_UP if action == "up" else VK_VOLUME_DOWN
    count = max(1, min(steps, 50))
    for _ in range(count):
        press_vk(vk)


def media_action(action: str) -> None:
    mapping = {
        "play_pause": VK_MEDIA_PLAY_PAUSE,
        "next": VK_MEDIA_NEXT_TRACK,
        "prev": VK_MEDIA_PREV_TRACK,
    }
    if action in mapping:
        press_vk(mapping[action])


def power_action(action: str) -> None:
    if action == "sleep":
        subprocess.Popen(
            ["rundll32.exe", "powrprof.dll,SetSuspendState", "0,1,0"],
            creationflags=subprocess.CREATE_NO_WINDOW,
        )
        return

    flags = {
        "shutdown": ["/s", "/t", "5", "/c", "DeskPilot shutdown from phone"],
        "restart": ["/r", "/t", "5", "/c", "DeskPilot restart from phone"],
    }
    if action in flags:
        subprocess.Popen(["shutdown", *flags[action]], creationflags=subprocess.CREATE_NO_WINDOW)


def persist_tokens() -> None:
    CONFIG["session_tokens"] = SESSION_TOKENS
    CONFIG["pair_pin"] = PAIR_PIN
    save_config(CONFIG)


def resolve_key(key: str) -> Any:
    lower = key.lower()
    if lower in KEY_MAP:
        return KEY_MAP[lower]
    if len(key) == 1:
        return key
    return None


def press_combo(items: list[Any]) -> None:
    pressed_mods: list[Any] = []
    try:
        for item in items:
            resolved = resolve_key(item) if isinstance(item, str) else item
            if resolved in MODIFIER_MAP.values() or resolved in {
                Key.ctrl,
                Key.alt,
                Key.shift,
                Key.cmd,
            }:
                keyboard.press(resolved)
                pressed_mods.append(resolved)
            else:
                keyboard.press(resolved)
                keyboard.release(resolved)
    finally:
        for mod in reversed(pressed_mods):
            keyboard.release(mod)


def handle_key(key: str, modifiers: list[str]) -> None:
    mods = [MODIFIER_MAP[m.lower()] for m in modifiers if m.lower() in MODIFIER_MAP]
    resolved = resolve_key(key)
    if resolved is None:
        return

    for mod in mods:
        keyboard.press(mod)
    try:
        keyboard.press(resolved)
        keyboard.release(resolved)
    finally:
        for mod in reversed(mods):
            keyboard.release(mod)


def handle_mouse_click(button: str, action: str) -> None:
    btn = {
        "left": Button.left,
        "right": Button.right,
        "middle": Button.middle,
    }.get(button, Button.left)

    if action == "down":
        mouse.press(btn)
    elif action == "up":
        mouse.release(btn)
    else:
        mouse.click(btn)


async def send_json(websocket: websockets.WebSocketServerProtocol, payload: dict) -> None:
    await websocket.send(json.dumps(payload))


async def maybe_notify_text_focus(websocket: websockets.WebSocketServerProtocol) -> None:
    for delay in (0.2, 0.45, 0.75):
        await asyncio.sleep(delay)
        if pc_text_field_is_focused():
            log_line(f"Text focus detected ({describe_focus_target()})")
            await send_json(websocket, {"type": "focus_text"})
            return


def wake_settings() -> tuple[str, str, list[str]]:
    user = str(CONFIG.get("windows_user", "")).strip()
    pin = str(CONFIG.get("windows_pin", "")).strip()
    apps = CONFIG.get("launch_apps") or []
    if not isinstance(apps, list):
        apps = []
    cleaned_apps = [str(name).strip() for name in apps if str(name).strip()]
    return user, pin, cleaned_apps


async def handle_wake_routine(websocket: websockets.WebSocketServerProtocol) -> None:
    user, pin, apps = wake_settings()
    if not pin:
        await send_json(
            websocket,
            {"type": "wake_routine_status", "status": "error", "message": "No Windows PIN configured"},
        )
        return

    await send_json(websocket, {"type": "wake_routine_status", "status": "started"})

    def log(message: str) -> None:
        log_line(message)

    try:
        await asyncio.to_thread(
            run_wake_routine,
            windows_user=user,
            windows_pin=pin,
            launch_apps=apps,
            log=log,
        )
        await send_json(websocket, {"type": "wake_routine_status", "status": "done"})
    except Exception as exc:
        await send_json(
            websocket,
            {"type": "wake_routine_status", "status": "error", "message": str(exc)},
        )


async def handle_message(websocket: websockets.WebSocketServerProtocol, data: dict) -> None:
    msg_type = data.get("type")

    if msg_type == "pair":
        pin = str(data.get("pin", ""))
        if pin != PAIR_PIN:
            await send_json(websocket, {"type": "pair_fail", "message": "Invalid PIN"})
            return
        token = secrets.token_urlsafe(24)
        device = str(data.get("deviceName", "iPhone"))
        SESSION_TOKENS[token] = device
        persist_tokens()
        AUTHED_CLIENTS.add(websocket)
        await send_json(
            websocket,
            {
                "type": "pair_ok",
                "token": token,
                "hostname": hostname(),
                "mac_address": MAC_ADDRESS,
            },
        )
        print(f"✓ Paired device: {device}")
        return

    if msg_type == "auth":
        token = str(data.get("token", ""))
        if token not in SESSION_TOKENS:
            await send_json(websocket, {"type": "auth_fail", "message": "Invalid token"})
            return
        AUTHED_CLIENTS.add(websocket)
        await send_json(
            websocket,
            {"type": "auth_ok", "hostname": hostname(), "mac_address": MAC_ADDRESS},
        )
        return

    if websocket not in AUTHED_CLIENTS:
        await send_json(websocket, {"type": "error", "message": "Not authenticated"})
        return

    if msg_type == "ping":
        await send_json(websocket, {"type": "pong"})
        return

    if msg_type == "mouse_move":
        mouse.move(int(data.get("dx", 0)), int(data.get("dy", 0)))
        return

    if msg_type == "mouse_click":
        button = str(data.get("button", "left"))
        action = str(data.get("action", "click"))
        handle_mouse_click(button, action)
        if button == "left" and action in {"click", "down"}:
            asyncio.create_task(maybe_notify_text_focus(websocket))
        return

    if msg_type == "scroll":
        mouse.scroll(int(data.get("dx", 0)), int(data.get("dy", 0)))
        return

    if msg_type == "key":
        handle_key(str(data.get("key", "")), list(data.get("modifiers", [])))
        return

    if msg_type == "text":
        keyboard.type(str(data.get("content", "")))
        return

    if msg_type == "volume":
        volume_action(str(data.get("action", "up")), int(data.get("steps", 1)))
        return

    if msg_type == "media":
        media_action(str(data.get("action", "")))
        return

    if msg_type == "shortcut":
        name = str(data.get("name", ""))
        if name in SHORTCUTS:
            press_combo(SHORTCUTS[name])
        return

    if msg_type == "power":
        power_action(str(data.get("action", "")))
        return

    if msg_type == "wake_routine":
        asyncio.create_task(handle_wake_routine(websocket))
        return

    await send_json(websocket, {"type": "error", "message": f"Unknown command: {msg_type}"})


async def client_handler(websocket: websockets.WebSocketServerProtocol) -> None:
    try:
        async for message in websocket:
            try:
                data = json.loads(message)
            except json.JSONDecodeError:
                await send_json(websocket, {"type": "error", "message": "Invalid JSON"})
                continue
            await handle_message(websocket, data)
    finally:
        AUTHED_CLIENTS.discard(websocket)


def log_line(message: str) -> None:
    print(message)
    try:
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        log_path = CONFIG_DIR / "server.log"
        with log_path.open("a", encoding="utf-8") as handle:
            handle.write(message + "\n")
    except OSError:
        pass


def print_banner() -> None:
    ip = local_ip()
    lines = [
        "",
        "=" * 52,
        "  DeskPilot Server",
        "=" * 52,
        f"  PC name : {hostname()}",
        f"  Local IP: {ip}",
        f"  MAC     : {MAC_ADDRESS}  (for Wake-on-LAN in app)",
        f"  Port    : {PORT}",
        f"  PIN     : {PAIR_PIN}",
        "",
        "  Runs in background if installed via install-autostart.bat",
        "  Pair once in the iPhone app — token survives reboots.",
        "=" * 52,
        "",
    ]
    for line in lines:
        log_line(line)


async def main() -> None:
    print_banner()
    async with websockets.serve(client_handler, HOST, PORT, ping_interval=20, ping_timeout=20):
        await asyncio.Future()


if __name__ == "__main__":
    if sys.platform != "win32":
        print("This server is built for Windows. Mouse/keyboard hooks target win32 APIs.")
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nServer stopped.")
