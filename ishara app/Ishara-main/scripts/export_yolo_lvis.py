"""Export a fine-grained YOLO to TFLite for the Flutter Vision page.

Ultralytics no longer publishes a YOLOv8-LVIS checkpoint in their public
asset releases. The next-best option (and what this script uses by
default) is **YOLOv8n-OIv7**, trained on Open Images V7 → 601 fine-grained
classes (Pear, Apple, Croissant, Espresso machine, Snowboard, …) versus
COCO's 80. Roughly the same speed and footprint as a COCO model, but
naming is much closer to "the actual thing".

If a real LVIS checkpoint becomes available, just pass it via
`--weights yolov8n-lvis.pt` and the rest of the pipeline still applies.

Usage:

    pip install ultralytics onnx onnx2tf onnxslim onnxruntime tensorflow
    python scripts/export_yolo_lvis.py            # int8 OIv7 by default
    python scripts/export_yolo_lvis.py --imgsz 640 --no-int8

The script:
  1. Lets Ultralytics resolve + download the chosen checkpoint
     (`YOLO('<name>.pt')` reads from Ultralytics' assets CDN).
  2. `model.export(format='tflite', int8=…, nms=True, data='<auto>.yaml')`.
  3. Copies the artefact to `assets/models/yolov8n_lvis.tflite` (we keep
     the legacy filename so the Flutter detector picks it up without
     code changes) and writes `assets/models/lvis_labels.txt`.
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

# Picked in order — first one that resolves wins. The real LVIS asset
# would obviously be best; OIv7 is a strong, available stand-in.
DEFAULT_WEIGHT_CANDIDATES = ["yolov8n-lvis.pt", "yolov8n-oiv7.pt"]

# Maps a checkpoint name to the dataset YAML Ultralytics ships for the
# int8 calibrator. Without `data=…`, int8 export raises.
DATA_FOR_WEIGHTS = {
    "yolov8n-lvis.pt": "lvis.yaml",
    "yolov8n-oiv7.pt": "open-images-v7.yaml",
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--weights",
        default=None,
        help="Override checkpoint (defaults to yolov8n-lvis.pt → yolov8n-oiv7.pt fallback)",
    )
    parser.add_argument("--imgsz", type=int, default=640)
    parser.add_argument(
        "--no-int8",
        dest="int8",
        action="store_false",
        help="Export float16 instead of int8",
    )
    parser.add_argument(
        "--out-dir",
        default=str(Path(__file__).resolve().parents[1] / "assets" / "models"),
    )
    parser.set_defaults(int8=True)
    args = parser.parse_args()

    try:
        from ultralytics import YOLO  # type: ignore
    except ImportError:
        print("Run: pip install ultralytics onnx onnx2tf tensorflow")
        return 1

    candidates = [args.weights] if args.weights else DEFAULT_WEIGHT_CANDIDATES

    model = None
    chosen = ""
    for cand in candidates:
        try:
            print(f"Resolving {cand} via Ultralytics …")
            model = YOLO(cand)
            chosen = cand
            break
        except Exception as exc:  # noqa: BLE001
            print(f"  failed: {exc}")
            continue

    if model is None:
        print("All checkpoint candidates failed. Pass --weights <path>.")
        return 1

    data = DATA_FOR_WEIGHTS.get(chosen, "open-images-v7.yaml")

    out_path = Path(model.export(
        format="tflite",
        imgsz=args.imgsz,
        int8=args.int8,
        half=not args.int8,
        nms=True,
        data=data,
    ))

    target_dir = Path(args.out_dir)
    target_dir.mkdir(parents=True, exist_ok=True)
    target_tflite = target_dir / "yolov8n_lvis.tflite"
    shutil.copy(out_path, target_tflite)
    size_mb = target_tflite.stat().st_size / 1024 / 1024
    print(f"Wrote {target_tflite} ({size_mb:.1f} MB)")

    # Persist the LVIS label set in index order — Ultralytics keeps them in
    # `model.names`, which is a {int: str} dict.
    names = model.names if isinstance(model.names, dict) else dict(enumerate(model.names))
    labels_path = target_dir / "lvis_labels.txt"
    with labels_path.open("w", encoding="utf-8") as fh:
        for i in range(len(names)):
            fh.write(f"{names[i]}\n")
    print(f"Wrote {labels_path} ({len(names)} classes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
