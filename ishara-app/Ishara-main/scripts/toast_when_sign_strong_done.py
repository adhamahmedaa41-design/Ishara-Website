"""Toast + dismiss-dialog watcher for the sign-yolo Arabic-10 strong
retrain. Detects the hash change on assets/models/sign_yolo.tflite.
"""

from __future__ import annotations

import hashlib
import time
import tkinter as tk
from pathlib import Path
from tkinter import messagebox

from winotify import Notification, audio

REPO_ROOT = Path(__file__).resolve().parents[1]
TARGET = REPO_ROOT / "assets" / "models" / "sign_yolo.tflite"
APP_ID = "Ishara Training"
POLL_SECONDS = 60
HEARTBEAT_EVERY_MINUTES = 60


def md5(p: Path) -> str:
    h = hashlib.md5()
    with p.open("rb") as fh:
        for c in iter(lambda: fh.read(65536), b""):
            h.update(c)
    return h.hexdigest()


def toast(title, body, sound=audio.Default):
    n = Notification(app_id=APP_ID, title=title, msg=body, duration="long")
    n.set_audio(sound, loop=False)
    n.show()


def show_dialog(size_mb, elapsed_min):
    root = tk.Tk()
    root.withdraw()
    root.attributes("-topmost", True)
    try:
        root.bell()
    except Exception:
        pass
    messagebox.showinfo(
        title="✅ Sign retrain complete",
        message=(
            f"Bundled: assets/models/sign_yolo.tflite\n"
            f"Size: {size_mb:.1f} MB\n"
            f"Wait time: {elapsed_min} min\n\n"
            f"Run `flutter pub get && flutter run`.\n\n"
            f"Click OK to dismiss this watcher."
        ),
    )
    root.destroy()


def main():
    started = time.time()
    last_hb = started
    baseline = md5(TARGET) if TARGET.is_file() else ""
    toast("Watcher armed", "Will alert when sign_yolo.tflite hash changes.")
    while True:
        if TARGET.is_file():
            cur = md5(TARGET)
            if cur and cur != baseline:
                size_mb = TARGET.stat().st_size / 1024 / 1024
                elapsed_min = int((time.time() - started) / 60)
                toast(
                    "✅ Sign retrain complete",
                    f"{TARGET.name} ({size_mb:.1f} MB) bundled.",
                    sound=audio.LoopingAlarm,
                )
                show_dialog(size_mb, elapsed_min)
                return
        now = time.time()
        if now - last_hb >= HEARTBEAT_EVERY_MINUTES * 60:
            mins = int((now - started) / 60)
            toast(
                "⏳ Sign still training",
                f"Running {mins} min. Next ping in {HEARTBEAT_EVERY_MINUTES} min.",
                sound=audio.Reminder,
            )
            last_hb = now
        time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    main()
