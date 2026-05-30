"""Train YOLOv8n on a downloaded Roboflow sign-language dataset and export
TFLite for the Flutter app.

Pipeline:
    1. Roboflow → YOLO-format dataset already at <data_dir>/data.yaml.
    2. Fine-tune `yolov8n.pt` (transfer-learning) for `--epochs` epochs.
    3. Export the best checkpoint to TFLite (float16 by default).
    4. Copy the artefact + labels into `assets/models/`.

Defaults are tuned for the 9 862-image / 10-class
`arabic-sign-language-translator-ijbp3` dataset on a CPU laptop:
  * imgsz 416  (smaller than the standard 640 → 4× faster training)
  * epochs 12  (transfer-learning converges fast on a small set)
  * batch  8

Usage:

    py -3.12 scripts/train_sign_yolo.py --data data/arabic_signs/data.yaml
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", required=True, help="Path to data.yaml from Roboflow export")
    parser.add_argument("--imgsz", type=int, default=416)
    parser.add_argument("--epochs", type=int, default=12)
    parser.add_argument("--batch", type=int, default=8)
    parser.add_argument("--base", default="yolov8n.pt")
    parser.add_argument(
        "--out-dir",
        default=str(Path(__file__).resolve().parents[1] / "assets" / "models"),
    )
    args = parser.parse_args()

    try:
        from ultralytics import YOLO  # type: ignore
    except ImportError:
        print("Run: pip install ultralytics tensorflow onnx onnx2tf onnxruntime")
        return 1

    model = YOLO(args.base)
    print(f"Training {args.base} on {args.data} for {args.epochs} epochs at {args.imgsz}px…")
    model.train(
        data=args.data,
        imgsz=args.imgsz,
        epochs=args.epochs,
        batch=args.batch,
        name="sign_yolo",
        plots=False,
        verbose=True,
        patience=20,
    )

    # Re-instantiate from the saved best.pt to ensure export uses the
    # post-training weights.
    best = Path("runs/detect/sign_yolo/weights/best.pt")
    if not best.is_file():
        # fall back to ultralytics' last reference
        best = Path(model.trainer.last)
    print(f"Loaded {best}")
    final = YOLO(str(best))

    out_path = Path(final.export(
        format="tflite",
        imgsz=args.imgsz,
        half=True,
        nms=True,
        data=args.data,
    ))

    target_dir = Path(args.out_dir)
    target_dir.mkdir(parents=True, exist_ok=True)
    target_tflite = target_dir / "sign_yolo.tflite"
    shutil.copy(out_path, target_tflite)
    print(f"Wrote {target_tflite} ({target_tflite.stat().st_size / 1024 / 1024:.1f} MB)")

    names = final.names if isinstance(final.names, dict) else dict(enumerate(final.names))
    labels_path = target_dir / "sign_labels.txt"
    with labels_path.open("w", encoding="utf-8") as fh:
        for i in range(len(names)):
            fh.write(f"{names[i]}\n")
    print(f"Wrote {labels_path} ({len(names)} classes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
