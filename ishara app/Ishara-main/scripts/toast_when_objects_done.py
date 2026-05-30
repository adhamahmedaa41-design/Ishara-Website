"""Watch for either currency_egp.tflite hash change or first
yolo_ewaste.tflite appearance; pop a Windows toast + dismiss dialog
when each lands. Exits after both fired (or after 5h timeout)."""

import hashlib, time, tkinter as tk
from pathlib import Path
from tkinter import messagebox
from winotify import Notification, audio

ROOT = Path(__file__).resolve().parents[1]
APP = "Ishara Training"
TARGETS = {
    "currency": ROOT / "assets" / "models" / "currency_egp.tflite",
    "ewaste":   ROOT / "assets" / "models" / "yolo_ewaste.tflite",
}

def md5(p): return hashlib.md5(p.read_bytes()).hexdigest() if p.is_file() else ""

def toast(title, body, sound=audio.LoopingAlarm):
    n = Notification(app_id=APP, title=title, msg=body, duration="long")
    n.set_audio(sound, loop=False)
    n.show()

def dialog(title, body):
    root = tk.Tk(); root.withdraw(); root.attributes("-topmost", True)
    try: root.bell()
    except: pass
    messagebox.showinfo(title=title, message=body)
    root.destroy()

def main():
    started = time.time()
    baseline = {k: md5(p) for k, p in TARGETS.items()}
    fired = set()
    toast("Object-pipeline watcher armed", "currency + e-waste TFLites", sound=audio.Default)
    while len(fired) < len(TARGETS) and (time.time() - started) < 5*3600:
        for k, p in TARGETS.items():
            if k in fired or not p.is_file():
                continue
            cur = md5(p)
            if cur and cur != baseline[k]:
                fired.add(k)
                size_mb = p.stat().st_size / 1024 / 1024
                mins = int((time.time() - started) / 60)
                toast(f"✅ {k} model bundled",
                      f"{p.name} {size_mb:.1f} MB after {mins} min")
                dialog(f"{k} model deployed",
                       f"{p.name}\n{size_mb:.1f} MB\nElapsed: {mins} min\n\n"
                       f"flutter pub get && flutter run to pick it up.")
        time.sleep(60)

if __name__ == "__main__":
    main()
