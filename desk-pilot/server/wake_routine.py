"""Unlock Windows after wake."""

from __future__ import annotations

import time
from typing import Callable

from pynput.keyboard import Controller as KeyboardController, Key

keyboard = KeyboardController()
LogFn = Callable[[str], None]


def _log(message: str, log: LogFn = print) -> None:
    log(message)


def is_sign_in_screen() -> bool:
    try:
        import uiautomation as auto

        fg = auto.GetForegroundControl()
        if fg is None:
            return True

        class_name = (fg.ClassName or "").lower()
        if any(token in class_name for token in ("logon", "lock", "credential")):
            return True

        for control, _ in fg.Walk(maxDepth=5):
            name = (control.Name or "").lower()
            control_type = control.ControlTypeName
            if control_type in {"EditControl", "PaneControl"} and any(
                token in name for token in ("pin", "password", "sign in")
            ):
                return True
            if name == "sign in options":
                return True
        return False
    except Exception:
        return False


def select_user_profile(user_name: str, log: LogFn = print) -> bool:
    if not user_name.strip():
        return False

    try:
        import uiautomation as auto

        root = auto.GetRootControl()
        target = user_name.strip().lower()
        for control, _ in root.Walk(maxDepth=8):
            name = (control.Name or "").strip()
            if not name:
                continue
            if target not in name.lower():
                continue
            if control.ControlTypeName in {
                "ListItemControl",
                "ButtonControl",
                "HyperlinkControl",
            }:
                _log(f"Selecting profile: {name}", log)
                control.Click()
                time.sleep(0.8)
                return True
        return False
    except Exception as exc:
        _log(f"Could not select profile: {exc}", log)
        return False


def type_pin(pin: str, log: LogFn = print) -> None:
    cleaned = "".join(ch for ch in pin if ch.isdigit())
    if not cleaned:
        return

    _log("Entering Windows PIN…", log)
    time.sleep(0.4)
    for digit in cleaned:
        keyboard.type(digit)
        time.sleep(0.12)
    keyboard.press(Key.enter)
    keyboard.release(Key.enter)


def run_wake_routine(*, windows_user: str, windows_pin: str, log: LogFn = print) -> None:
    _log("Wake routine started", log)
    time.sleep(4)

    if is_sign_in_screen():
        select_user_profile(windows_user, log=log)
        time.sleep(0.6)
        type_pin(windows_pin, log=log)
        time.sleep(10)
    else:
        _log("Already signed in — skipping PIN entry", log)

    _log("Wake routine finished", log)


def run_login_watch(
    *,
    windows_user: str,
    windows_pin: str,
    log: LogFn = print,
    timeout_seconds: int = 180,
) -> None:
    """Poll for the Windows sign-in screen after cold boot (used by scheduled task)."""
    _log("Login watch started", log)
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        if is_sign_in_screen():
            run_wake_routine(windows_user=windows_user, windows_pin=windows_pin, log=log)
            return
        time.sleep(3)
    _log("Login watch timed out", log)


if __name__ == "__main__":
    import sys
    from config_store import CONFIG_DIR, load_config

    config = load_config()
    user = str(config.get("windows_user", ""))
    pin = str(config.get("windows_pin", ""))

    def log(message: str) -> None:
        print(message)
        try:
            CONFIG_DIR.mkdir(parents=True, exist_ok=True)
            with (CONFIG_DIR / "server.log").open("a", encoding="utf-8") as handle:
                handle.write(message + "\n")
        except OSError:
            pass

    if "--login-watch" in sys.argv:
        run_login_watch(windows_user=user, windows_pin=pin, log=log)
    else:
        run_wake_routine(windows_user=user, windows_pin=pin, log=log)
