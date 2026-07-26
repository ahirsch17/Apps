"""Launch installed Windows Store / Start Menu apps by name."""

from __future__ import annotations

import json
import subprocess
from typing import Callable

LogFn = Callable[[str], None]


def launch_app(app_name: str, log: LogFn = print) -> bool:
    cleaned = app_name.strip()
    if not cleaned:
        return False

    ps = (
        "$name = "
        + json.dumps(cleaned)
        + "; "
        "$app = Get-StartApps | Where-Object { $_.Name -eq $name } | Select-Object -First 1; "
        "if (-not $app) { "
        "$app = Get-StartApps | Where-Object { $_.Name -like ('*' + $name + '*') } | Select-Object -First 1 "
        "}; "
        "if ($app) { Start-Process ('shell:AppsFolder\\' + $app.AppID); exit 0 } "
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
            log(f"Launched {cleaned}")
            return True
        log(f"Could not find app: {cleaned}")
        return False
    except Exception as exc:
        log(f"Launch failed for {cleaned}: {exc}")
        return False
