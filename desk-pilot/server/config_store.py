"""Persistent DeskPilot server config (pairing PIN, tokens, MAC)."""

from __future__ import annotations

import json
import random
import secrets
import uuid
from pathlib import Path

CONFIG_DIR = Path.home() / "AppData" / "Local" / "DeskPilot"
CONFIG_PATH = CONFIG_DIR / "config.json"


def get_mac_address() -> str:
    node = uuid.getnode()
    return ":".join(f"{(node >> shift) & 0xFF:02X}" for shift in range(40, -1, -8))


def _default_config() -> dict:
    return {
        "pair_pin": f"{random.randint(0, 999999):06d}",
        "session_tokens": {},
        "mac_address": get_mac_address(),
    }


def load_config() -> dict:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    if CONFIG_PATH.exists():
        try:
            data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                data.setdefault("pair_pin", f"{random.randint(0, 999999):06d}")
                data.setdefault("session_tokens", {})
                data.setdefault("mac_address", get_mac_address())
                return data
        except (json.JSONDecodeError, OSError):
            pass
    data = _default_config()
    save_config(data)
    return data


def save_config(data: dict) -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    CONFIG_PATH.write_text(json.dumps(data, indent=2), encoding="utf-8")


def new_pair_pin() -> str:
    data = load_config()
    data["pair_pin"] = f"{random.randint(0, 999999):06d}"
    save_config(data)
    return data["pair_pin"]
