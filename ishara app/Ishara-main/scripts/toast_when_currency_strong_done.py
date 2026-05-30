"""Watches for the retrained currency_egp.tflite asset to be rewritten
with a *fresh* hash (we know the current file's MD5; the new training
will overwrite it). Shows a Windows toast + blocking dialog on success.

Run:
    py -3.12 scripts/toast_when_currency_strong_done.py
"""

from __future__ import annotations

import hashlib
import time
import tkinter as tk
from pathlib import Path
from tkinter import messagebox

from winotify import Notification, audio

REPO_ROOT = Path(__file__).resolve().parents[1]
TARGET = REPO_ROOT / "assets" / "models" / "currency_egp.tflite"
APP_ID = "Ishara Training"

POLL_SECONDS = 60
HEARTBEAT_EVERY_MINUTES = 60

def md5(path: Path) -> str:
    h = hashlib.md5()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def toast(title: str, body: str, sound=audio.Default) -> None:
    n = Notification(app_id=APP_ID, title=title, msg=body, duration="long")
    n.set_audio(sound, loop=False)
    n.show()


def show_blocking_dialog(size_mb: float, elapsed_min: int) -> None:
    root = tk.Tk()
    root.withdraw()
    root.attributes("-topmost", True)
    try:
        root.bell()
    except Exception:
        pass
    messagebox.showinfo(
        title="✅ Currency retrain complete",
        message=(
            f"Bundled: assets/models/currency_egp.tflite\n"
            f"Size: {size_mb:.1f} MB\n"
            f"Wait time: {elapsed_min} min\n\n"
            f"Run `flutter pub get && flutter run` to pick up the new model.\n\n"
            f"Click OK to dismiss this watcher."
        ),
    )
    root.destroy()


def main() -> None:
    started = time.time()
    last_heartbeat = started
    baseline = md5(TARGET) if TARGET.is_file() else ""
    toast("Watcher armed", f"Will alert when {TARGET.name} hash changes.")
    while True:
        if TARGET.is_file():
            current = md5(TARGET)
            if current and current != baseline:
                size_mb = TARGET.stat().st_size / 1024 / 1024
                elapsed_min = int((time.time() - started) / 60)
                toast(
                    "✅ Currency retrain complete",
                    f"{TARGET.name} ({size_mb:.1f} MB) is bundled.",
                    sound=audio.LoopingAlarm,
                )
                show_blocking_dialog(size_mb, elapsed_min)
                return
        now = time.time()
        if now - last_heartbeat >= HEARTBEAT_EVERY_MINUTES * 60:
            elapsed_min = int((now - started) / 60)
            toast(
                "⏳ Currency still training",
                f"Running {elapsed_min} min. Next ping in {HEARTBEAT_EVERY_MINUTES} min.",
                sound=audio.Reminder,
            )
            last_heartbeat = now
        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    main()
