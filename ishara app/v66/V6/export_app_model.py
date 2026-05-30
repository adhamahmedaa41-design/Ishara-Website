"""
Export the trained V6 Keras model to TensorFlow Lite for use in the
Ishara Flutter app.

Outputs (written to IsharaApp/ishara_app/assets/models):
  - asl_v6.tflite       – the converted LSTM model
  - label_map_v6.json   – class-index mapping (copy)
  - manifest.json       – metadata the Flutter app can read at runtime

Usage:
    python export_app_model.py                 # default export
    python export_app_model.py --quantize      # dynamic-range quantization
    python export_app_model.py --base_dir X    # override data root
"""

import argparse
import json
import shutil
from pathlib import Path

import tensorflow as tf
from tensorflow.keras.models import load_model

from config import get_default_config


def export(quantize: bool = False, base_dir: str | None = None) -> None:
    cfg = get_default_config()
    if base_dir is not None:
        cfg.paths.base_dir = Path(base_dir)

    models_dir = cfg.paths.models_dir
    model_path = models_dir / "final_model_v6.keras"
    label_map_path = models_dir / "label_map_v6.json"

    if not model_path.exists():
        print(f"❌ Trained model not found at {model_path}. Train first (menu option 2).")
        return
    if not label_map_path.exists():
        print(f"❌ Label map not found at {label_map_path}. Train first (menu option 2).")
        return

    # --- Determine Flutter assets target ---------------------------------
    project_root = Path(__file__).resolve().parent          # V6/
    repo_root = project_root.parent                         # Ishara/ workspace root

    # Try several likely locations for the Flutter app assets folder
    candidate_dirs = [
        repo_root / "Ishara" / "assets" / "models",        # main Ishara app
        repo_root / "IsharaApp" / "ishara_app" / "assets" / "models",
        repo_root / "Isharaapptest" / "assets" / "models",
    ]
    flutter_assets = None
    for d in candidate_dirs:
        if d.parent.exists():                               # assets/ folder exists
            flutter_assets = d
            break

    if flutter_assets is None:
        flutter_assets = candidate_dirs[0]

    flutter_assets.mkdir(parents=True, exist_ok=True)

    # --- Load Keras model ------------------------------------------------
    print(f"📂 Loading model from {model_path}")
    model = load_model(str(model_path))

    # --- Convert to TFLite -----------------------------------------------
    print("🔁 Converting to TensorFlow Lite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    # SELECT_TF_OPS is required because LSTM uses TensorList ops
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS,
    ]
    converter._experimental_lower_tensor_list_ops = False

    if quantize:
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        print("   Dynamic-range quantization enabled.")

    tflite_bytes = converter.convert()

    tflite_dst = flutter_assets / "asl_v6.tflite"
    tflite_dst.write_bytes(tflite_bytes)
    print(f"✅ TFLite model saved to {tflite_dst}  ({len(tflite_bytes) / 1024:.0f} KB)")

    # --- Copy label map --------------------------------------------------
    label_dst = flutter_assets / "label_map_v6.json"
    shutil.copy2(label_map_path, label_dst)
    print(f"✅ Label map copied to {label_dst}")

    # --- Write manifest.json ---------------------------------------------
    with open(label_map_path, "r", encoding="utf-8") as f:
        label_map = json.load(f)

    manifest = {
        "model_file": "asl_v6.tflite",
        "label_map_file": "label_map_v6.json",
        "input_shape": [1, cfg.training.sequence_length, 1692],
        "output_shape": [1, len(label_map)],
        "sequence_length": cfg.training.sequence_length,
        "num_keypoints": 1692,
        "labels": list(label_map.keys()),
        "quantized": quantize,
        "keypoint_layout": {
            "pose": {"count": 33, "components": 4, "total": 132},
            "face": {"count": 468, "components": 3, "total": 1404},
            "left_hand": {"count": 21, "components": 3, "total": 63},
            "right_hand": {"count": 21, "components": 3, "total": 63},
        },
    }

    manifest_dst = flutter_assets / "manifest.json"
    with open(manifest_dst, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    print(f"✅ Manifest written to {manifest_dst}")

    # Also save a copy next to the V6 models for reference
    (models_dir / "asl_v6.tflite").write_bytes(tflite_bytes)
    print(f"   (TFLite copy also saved in {models_dir})")

    # --- Summary ---------------------------------------------------------
    print("\n📌 Flutter integration notes:")
    print(f"  • Input:  Float32 tensor [1, {cfg.training.sequence_length}, 1692]")
    print(f"  • Output: Float32 tensor [1, {len(label_map)}] (softmax probabilities)")
    print(f"  • Labels: {list(label_map.keys())}")
    print(f"  • Assets: {flutter_assets}")
    print("  • Use MediaPipe Holistic in the Flutter app to extract the same 1692-dim")
    print("    keypoint vector per frame (pose 33×4 + face 468×3 + hands 21×3 each).")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Export the V6 model to TFLite for the Ishara Flutter app."
    )
    parser.add_argument(
        "--quantize",
        action="store_true",
        help="Apply dynamic-range quantization (smaller, slightly less accurate).",
    )
    parser.add_argument(
        "--base_dir",
        type=str,
        default=None,
        help="Override the data root (default: D:/Arabic_Sign_Language).",
    )
    args = parser.parse_args()
    export(quantize=args.quantize, base_dir=args.base_dir)


if __name__ == "__main__":
    main()
