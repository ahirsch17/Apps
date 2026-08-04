#!/usr/bin/env python3
"""Start DeskPilot server in the background if port 8765 is not listening."""

from __future__ import annotations

import socket
import subprocess
import sys
from pathlib import Path

PORT = 8765
SERVER_DIR = Path(__file__).resolve().parent


def port_is_open() -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(0.75)
        return sock.connect_ex(("127.0.0.1", PORT)) == 0


def pythonw_executable() -> str:
    exe = Path(sys.executable)
    candidate = exe.with_name("pythonw.exe")
    if candidate.is_file():
        return str(candidate)
    return str(exe)


def main() -> None:
    if port_is_open():
        return

    creationflags = 0
    if sys.platform == "win32":
        creationflags = subprocess.CREATE_NO_WINDOW  # type: ignore[attr-defined]

    subprocess.Popen(
        [pythonw_executable(), str(SERVER_DIR / "server.py")],
        cwd=str(SERVER_DIR),
        creationflags=creationflags,
    )


if __name__ == "__main__":
    main()
