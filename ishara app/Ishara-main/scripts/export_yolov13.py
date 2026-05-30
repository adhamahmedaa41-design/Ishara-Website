"""Export YOLOv13 (Ultralytics) to TFLite for the Flutter app.

Run once on a machine with Python 3.11 + the YOLOv13 source from
`G:\\Old Downloads\\Ishara\\Ishara\\ishara app\\ishara app\\yolov13-main\\yolov13-main`.

Usage:

    cd "G:/Old Downloads/Ishara/Ishara/ishara app/ishara app/yolov13-main/yolov13-main"
    pip install -r requirements.txt
    pip install tensorflow==2.15.0 onnx onnx2tf nvidia-pyindex sng4onnx
    python "../../Ishara-main/scripts/export_yolov13.py" \
        --weights yolov13n.pt \
        --imgsz 640 \
        --int8

The script:
  1. Downloads the official `yolov13n.pt` weights if missing
     (https://github.com/iMoonLab/yolov13/releases — see README).
  2. Loads the model via Ultralytics.
  3. Exports to TFLite (default float16, optional int8 with `--int8`).
  4. Copies the result to `<repo>/assets/models/yolov13n_float16.tflite`.

Output:
  - `assets/models/yolov13n_float16.tflite` (or `_int8.tflite`)
  - `assets/models/coco_labels.txt` (already shipped in repo)

Note: YOLOv13 uses the same Ultralytics export pipeline as YOLOv8/v10. The
generated TFLite is loadable directly via `tflite_flutter`.
"""

from __future__ import annotations

import argparse
import os
import shutil
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--weights", default="yolov13n.pt", help="Path or release name of YOLOv13 .pt weights")
    parser.add_argument("--imgsz", type=int, default=640, help="Square input size (320 / 480 / 640)")
    parser.add_argument("--int8", action="store_true", help="Quantise to int8 (smaller, slower-to-export)")
    parser.add_argument(
        "--out-dir",
        default=str(Path(__file__).resolve().parents[1] / "assets" / "models"),
        help="Where to drop the exported .tflite",
    )
    args = parser.parse_args()

    try:
        from ultralytics import YOLO  # type: ignore
    except ImportError:
        print("Run `pip install -r requirements.txt` from the YOLOv13 repo first.", file=sys.stderr)
        return 1

    model = YOLO(args.weights)

    # Ultralytics .export() handles ONNX → TFLite via onnx2tf when installed.
    export_kwargs = {
        "format": "tflite",
        "imgsz": args.imgsz,
        "int8": args.int8,
        "half": not args.int8,  # float16 unless int8
        "nms": True,             # bake NMS into the graph for fewer Dart-side ops
        "data": "coco.yaml",     # needed for int8 calibration
    }
    out_path = Path(model.export(**export_kwargs))

    target_dir = Path(args.out_dir)
    target_dir.mkdir(parents=True, exist_ok=True)
    suffix = "int8" if args.int8 else "float16"
    target = target_dir / f"yolov13n_{suffix}.tflite"
    shutil.copy(out_path, target)
    print(f"Wrote {target} ({target.stat().st_size / 1024 / 1024:.1f} MB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
