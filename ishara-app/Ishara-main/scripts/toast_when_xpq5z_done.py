"""Watches for the xpq5z TFLite asset. Shows:

  1. A toast (with sound) every 30 minutes while training is still running.
  2. When the file appears: an audible toast PLUS a modal Tk dialog that
     blocks until the user clicks OK. Only after OK does the watcher exit.

Run:
    py -3.12 scripts/toast_when_xpq5z_done.py
"""

from __future__ import annotations

import time
import tkinter as tk
from pathlib import Path
from tkinter import messagebox

from winotify import Notification, audio

REPO_ROOT = Path(__file__).resolve().parents[1]
TARGET = REPO_ROOT / "assets" / "models" / "sign_yolo_xpq5z.tflite"
LABELS = REPO_ROOT / "assets" / "models" / "sign_labels_xpq5z.txt"
APP_ID = "Ishara Training"

POLL_SECONDS = 30
HEARTBEAT_EVERY_MINUTES = 30


def toast(title: str, body: str, sound=audio.Default) -> None:
    n = Notification(app_id=APP_ID, title=title, msg=body, duration="long")
    n.set_audio(sound, loop=False)
    n.show()


def show_blocking_done_dialog(size_mb: float, label_count: int, elapsed_min: int) -> None:
    """Pops a centred Tk dialog and blocks until OK is clicked."""
    root = tk.Tk()
    root.withdraw()
    root.attributes("-topmost", True)
    # Beep so it's audible alongside the toast.
    try:
        root.bell()
    except Exception:
        pass
    messagebox.showinfo(
        title="✅ xpq5z training complete",
        message=(
            f"Bundled: assets/models/sign_yolo_xpq5z.tflite\n"
            f"Size: {size_mb:.1f} MB\n"
            f"Classes: {label_count}\n"
            f"Wait time: {elapsed_min} min\n\n"
            f"Run `flutter pub get && flutter run` to pick up the new model.\n\n"
            f"Click OK to dismiss this watcher."
        ),
    )
    root.destroy()


def main() -> None:
    started = time.time()
    last_heartbeat = started
    toast("Watcher armed", f"Will alert when {TARGET.name} appears.")
    while True:
        if TARGET.is_file():
            size_mb = TARGET.stat().st_size / 1024 / 1024
            label_count = (
                len([
                    ln
                    for ln in LABELS.read_text(encoding="utf-8").splitlines()
                    if ln.strip()
                ])
                if LABELS.is_file()
                else 0
            )
            elapsed_min = int((time.time() - started) / 60)
            # 1) Toast with audible alarm.
            toast(
                "✅ xpq5z training complete",
                f"{TARGET.name} ({size_mb:.1f} MB, {label_count} classes) is bundled.",
                sound=audio.LoopingAlarm,
            )
            # 2) Blocking dialog — exits only after OK.
            show_blocking_done_dialog(size_mb, label_count, elapsed_min)
            return
        now = time.time()
        if now - last_heartbeat >= HEARTBEAT_EVERY_MINUTES * 60:
            elapsed_min = int((now - started) / 60)
            toast(
                "⏳ Still training",
                f"xpq5z YOLO running for {elapsed_min} min. "
                f"Next ping in {HEARTBEAT_EVERY_MINUTES} min or on completion.",
                sound=audio.Reminder,
            )
            last_heartbeat = now
        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    main()
