"""Launch installed Windows Store / Start Menu apps by name."""

from __future__ import annotations

import subprocess
from typing import Callable

LogFn = Callable[[str], None]


def launch_app(app_name: str, log: LogFn = print) -> bool:
    safe_name = app_name.replace('"', "")
    ps = (
        "$app = Get-StartApps | Where-Object { $_.Name -like '*"
        + safe_name
        + "*' } | Select-Object -First 1; "
        "if ($app) { Start-Process ('shell:AppsFolder\\' + $app.AppID) } "
        "else { exit 1 }"
    )
    try:
        result = subprocess.run(
            ["powershell", "-NoProfile", "-Command", ps],
            capture_output=True,
            text=True,
            timeout=20,
            creationflags=subprocess.CREATE_NO_WINDOW,
        )
        if result.returncode == 0:
            log(f"Launched {app_name}")
            return True
        log(f"Could not find app: {app_name}")
        return False
    except Exception as exc:
        log(f"Launch failed for {app_name}: {exc}")
        return False
