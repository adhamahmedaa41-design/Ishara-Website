"""One-shot: export runs/detect/ewaste_v1/weights/best.pt to TFLite,
copy to assets/models/yolo_ewaste.tflite, write yolo_ewaste_labels.txt."""

import os, sys, shutil, hashlib
from pathlib import Path

os.environ["PYTHONIOENCODING"] = "utf-8"
try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = Path(__file__).resolve().parents[1]
BEST = ROOT / "runs" / "detect" / "ewaste_v1" / "weights" / "best.pt"
DATA_YAML = ROOT / "data" / "e_waste" / "data.yaml"
ASSETS = ROOT / "assets" / "models"
TARGET_TFLITE = ASSETS / "yolo_ewaste.tflite"
TARGET_LABELS = ASSETS / "yolo_ewaste_labels.txt"


def write_labels():
    text = DATA_YAML.read_text(encoding="utf-8")
    names, in_names = [], False
    for raw in text.splitlines():
        s = raw.strip()
        if s.startswith("names:"):
            in_names = True
            continue
        if in_names:
            if s.startswith("- "):
                names.append(s[2:].strip().strip('"').strip("'"))
            elif s and not s.startswith("#") and not raw.startswith(" "):
                break
    TARGET_LABELS.write_text("\n".join(names) + "\n", encoding="utf-8")
    print(f"[labels] wrote {len(names)} -> {TARGET_LABELS}")


def export():
    print(f"[export] loading {BEST}")
    from ultralytics import YOLO
    model = YOLO(str(BEST))
    print("[export] exporting to TFLite (imgsz=416)…")
    model.export(format="tflite", imgsz=416, int8=False, nms=False)
    cands = sorted(BEST.parent.glob("**/*float32.tflite")) or sorted(BEST.parent.glob("**/*.tflite"))
    cands = [c for c in cands if c.is_file()]
    if not cands:
        raise SystemExit("no .tflite produced")
    src = cands[0]
    print(f"[export] using {src} ({src.stat().st_size/1024/1024:.2f} MB)")
    ASSETS.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, TARGET_TFLITE)
    h = hashlib.md5(TARGET_TFLITE.read_bytes()).hexdigest()
    print(f"[export] copied -> {TARGET_TFLITE} md5={h}")


if __name__ == "__main__":
    write_labels()
    export()
    print("[done]")
