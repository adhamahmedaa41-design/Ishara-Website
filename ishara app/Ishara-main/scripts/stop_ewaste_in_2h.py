"""Wait 2 hours, gracefully stop the e-waste YOLO training, export the
best checkpoint to TFLite at assets/models/yolo_ewaste.tflite, and write
the matching labels file. Pops a Windows toast + dialog when done."""

import os, sys, time, shutil, hashlib, subprocess
import tkinter as tk
from pathlib import Path
from tkinter import messagebox

# stdout/err -> utf-8 so emojis don't crash on Windows
os.environ["PYTHONIOENCODING"] = "utf-8"
try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = Path(__file__).resolve().parents[1]
RUN_DIR = ROOT / "runs" / "detect" / "ewaste_v1"
WEIGHTS_DIR = RUN_DIR / "weights"
DATA_YAML = ROOT / "data" / "e_waste" / "data.yaml"
ASSETS = ROOT / "assets" / "models"
TARGET_TFLITE = ASSETS / "yolo_ewaste.tflite"
TARGET_LABELS = ASSETS / "yolo_ewaste_labels.txt"
WAIT_SECONDS = 2 * 3600  # 2 hours

try:
    from winotify import Notification, audio
    HAVE_TOAST = True
except Exception:
    HAVE_TOAST = False


def toast(title, body):
    if not HAVE_TOAST:
        print(f"[toast] {title}: {body}")
        return
    n = Notification(app_id="Ishara Training", title=title, msg=body, duration="long")
    try:
        n.set_audio(audio.LoopingAlarm, loop=False)
    except Exception:
        pass
    n.show()


def dialog(title, body):
    root = tk.Tk()
    root.withdraw()
    root.attributes("-topmost", True)
    try:
        root.bell()
    except Exception:
        pass
    messagebox.showinfo(title=title, message=body)
    root.destroy()


def find_train_pid():
    """Find the python.exe PID actively writing to runs/detect/ewaste_v1."""
    try:
        out = subprocess.check_output(
            ["wmic", "process", "where", "name='python.exe'", "get", "ProcessId,CommandLine", "/FORMAT:CSV"],
            stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace",
        )
    except Exception as e:
        print(f"[pid] wmic failed: {e}")
        return None
    pids = []
    for line in out.splitlines():
        line = line.strip()
        if not line or line.lower().startswith("node"):
            continue
        # Heuristic: any python.exe whose command line mentions yolo/ultralytics/train
        low = line.lower()
        if ("ultralytics" in low) or ("yolo" in low) or ("train" in low) or ("ewaste" in low):
            for part in reversed(line.split(",")):
                part = part.strip()
                if part.isdigit():
                    pids.append(int(part))
                    break
    return pids[0] if pids else None


def kill_pid(pid):
    print(f"[kill] terminating PID {pid}")
    try:
        subprocess.run(["taskkill", "/PID", str(pid), "/T", "/F"], check=False)
    except Exception as e:
        print(f"[kill] taskkill failed: {e}")


def write_labels():
    """Parse data/e_waste/data.yaml and write yolo_ewaste_labels.txt."""
    if not DATA_YAML.is_file():
        print(f"[labels] missing {DATA_YAML}")
        return False
    text = DATA_YAML.read_text(encoding="utf-8")
    names = []
    in_names = False
    for raw in text.splitlines():
        line = raw.rstrip()
        s = line.strip()
        if s.startswith("names:"):
            in_names = True
            continue
        if in_names:
            if s.startswith("- "):
                val = s[2:].strip().strip('"').strip("'")
                names.append(val)
            elif s and not s.startswith("#") and not line.startswith(" "):
                break
    if not names:
        print("[labels] could not parse names")
        return False
    TARGET_LABELS.write_text("\n".join(names) + "\n", encoding="utf-8")
    print(f"[labels] wrote {len(names)} -> {TARGET_LABELS}")
    return True


def export_tflite():
    best = WEIGHTS_DIR / "best.pt"
    if not best.is_file():
        best = WEIGHTS_DIR / "last.pt"
    if not best.is_file():
        print(f"[export] no checkpoint in {WEIGHTS_DIR}")
        return False
    print(f"[export] loading {best}")
    from ultralytics import YOLO
    model = YOLO(str(best))
    out_dir = best.parent
    # Ultralytics exports a folder with several files; we want the _float32.tflite
    print("[export] exporting to TFLite (imgsz=416)…")
    model.export(format="tflite", imgsz=416, int8=False, nms=False)
    # Find produced .tflite under the same parent
    candidates = sorted(best.parent.glob("**/*float32.tflite")) + sorted(best.parent.glob("**/*.tflite"))
    candidates = [c for c in candidates if c.is_file()]
    if not candidates:
        print("[export] no .tflite found after export")
        return False
    src = candidates[0]
    print(f"[export] using {src} ({src.stat().st_size/1024/1024:.1f} MB)")
    ASSETS.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, TARGET_TFLITE)
    h = hashlib.md5(TARGET_TFLITE.read_bytes()).hexdigest()
    print(f"[export] copied -> {TARGET_TFLITE} md5={h}")
    return True


def main():
    print(f"[start] sleeping {WAIT_SECONDS/3600:.1f}h, then will stop+export e-waste training")
    started = time.time()
    while time.time() - started < WAIT_SECONDS:
        time.sleep(60)
    print("[wake] 2h elapsed — stopping training")
    pid = find_train_pid()
    if pid:
        kill_pid(pid)
        # Give Ultralytics a moment to release file locks
        time.sleep(8)
    else:
        print("[kill] no training PID found — proceeding to export anyway")

    ok_labels = write_labels()
    try:
        ok_export = export_tflite()
    except Exception as e:
        ok_export = False
        print(f"[export] FAILED: {e}")

    if ok_export and ok_labels:
        body = (
            f"yolo_ewaste.tflite + labels bundled.\n"
            f"{TARGET_TFLITE.stat().st_size/1024/1024:.1f} MB\n\n"
            f"flutter clean && flutter pub get && flutter run to load it."
        )
        toast("✅ E-waste model bundled", body)
        dialog("E-waste model bundled", body)
    else:
        msg = (
            f"export={'OK' if ok_export else 'FAIL'}, labels={'OK' if ok_labels else 'FAIL'}\n"
            f"Check {RUN_DIR}"
        )
        toast("⚠️ E-waste finish partial", msg)
        dialog("E-waste finish partial", msg)


if __name__ == "__main__":
    main()
