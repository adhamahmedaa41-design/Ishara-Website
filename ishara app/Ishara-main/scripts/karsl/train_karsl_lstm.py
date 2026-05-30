"""Train an LSTM on the KArSL keypoint shards produced by
`extract_holistic_keypoints.py`, then export TFLite for the Flutter app.

Architecture mirrors the original V6 model so the [1, 30, 1692]→[1, N]
contract stays identical and `sign_language_service.dart` can swap models
just by pointing at the new asset path.

Usage:

    pip install tensorflow==2.15.0 scikit-learn numpy
    python scripts/karsl/train_karsl_lstm.py \
        --keypoints data/karsl/keypoints \
        --epochs 200 \
        --out-tflite assets/models/karsl_v89.tflite \
        --out-manifest assets/models/manifest_karsl.json \
        --out-label-map assets/models/karsl_label_map.json
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np


def build_model(num_classes: int) -> "tf.keras.Model":  # noqa: F821
    import tensorflow as tf  # type: ignore
    from tensorflow.keras import layers, regularizers  # type: ignore

    inputs = tf.keras.Input(shape=(30, 1692))
    x = layers.Bidirectional(layers.LSTM(128, return_sequences=True, kernel_regularizer=regularizers.l2(1e-4)))(inputs)
    x = layers.Dropout(0.4)(x)
    x = layers.Bidirectional(layers.LSTM(128, kernel_regularizer=regularizers.l2(1e-4)))(x)
    x = layers.Dropout(0.4)(x)
    x = layers.Dense(256, activation="relu", kernel_regularizer=regularizers.l2(1e-4))(x)
    x = layers.Dropout(0.3)(x)
    x = layers.Dense(128, activation="relu")(x)
    out = layers.Dense(num_classes, activation="softmax")(x)
    return tf.keras.Model(inputs, out)


def load_shards(root: Path) -> tuple[np.ndarray, np.ndarray, list[str]]:
    classes_path = root / "classes.json"
    if not classes_path.exists():
        raise FileNotFoundError(f"Missing {classes_path}")
    classes = json.loads(classes_path.read_text(encoding="utf-8"))
    seqs: list[np.ndarray] = []
    labels: list[int] = []
    for npz in sorted(root.glob("*.npz")):
        data = np.load(npz, allow_pickle=False)
        seqs.append(data["seq"].astype(np.float32))
        labels.append(int(data["label"]))
    if not seqs:
        raise RuntimeError(f"No .npz shards under {root}")
    return np.stack(seqs, axis=0), np.array(labels, dtype=np.int64), classes


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--keypoints", default="data/karsl/keypoints")
    parser.add_argument("--epochs", type=int, default=200)
    parser.add_argument("--batch", type=int, default=16)
    parser.add_argument("--out-tflite", default="assets/models/karsl_v89.tflite")
    parser.add_argument("--out-manifest", default="assets/models/manifest_karsl.json")
    parser.add_argument("--out-label-map", default="assets/models/karsl_label_map.json")
    parser.add_argument("--quantize", action="store_true", help="Apply dynamic-range quantisation on export")
    args = parser.parse_args()

    try:
        import tensorflow as tf  # type: ignore
        from sklearn.model_selection import train_test_split  # type: ignore
        from sklearn.utils.class_weight import compute_class_weight  # type: ignore
    except ImportError:
        print("Run: pip install tensorflow==2.15.0 scikit-learn")
        return 1

    X, y, classes = load_shards(Path(args.keypoints))
    print(f"Loaded {X.shape[0]} sequences, {len(classes)} classes")

    Xtr, Xva, ytr, yva = train_test_split(X, y, test_size=0.15, random_state=42, stratify=y)

    cw = compute_class_weight("balanced", classes=np.arange(len(classes)), y=ytr)
    class_weights = {i: float(w) for i, w in enumerate(cw)}

    model = build_model(len(classes))
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=5e-4),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    cb = [
        tf.keras.callbacks.EarlyStopping(patience=30, restore_best_weights=True, monitor="val_accuracy"),
        tf.keras.callbacks.ReduceLROnPlateau(patience=10, factor=0.5, min_lr=1e-6),
    ]
    model.fit(
        Xtr, ytr,
        validation_data=(Xva, yva),
        batch_size=args.batch,
        epochs=args.epochs,
        class_weight=class_weights,
        callbacks=cb,
        verbose=2,
    )

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS,  # LSTM ops
    ]
    if args.quantize:
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite = converter.convert()

    out_tflite = Path(args.out_tflite)
    out_tflite.parent.mkdir(parents=True, exist_ok=True)
    out_tflite.write_bytes(tflite)
    print(f"Wrote {out_tflite} ({out_tflite.stat().st_size / 1024:.1f} KB)")

    Path(args.out_label_map).write_text(
        json.dumps({c: i for i, c in enumerate(classes)}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    Path(args.out_manifest).write_text(
        json.dumps(
            {
                "model": "karsl_v89",
                # These four keys are what the Flutter SignLanguageService
                # reads at runtime — keep names + types stable.
                "model_file": Path(args.out_tflite).name,
                "label_map_file": Path(args.out_label_map).name,
                "sequence_length": 30,
                "num_keypoints": 1692,
                # Informational only.
                "input_shape": [1, 30, 1692],
                "output_shape": [1, len(classes)],
                "frames": 30,
                "feature_layout": [
                    {"part": "pose", "landmarks": 33, "channels": 4},
                    {"part": "face", "landmarks": 468, "channels": 3},
                    {"part": "left_hand", "landmarks": 21, "channels": 3},
                    {"part": "right_hand", "landmarks": 21, "channels": 3},
                ],
            },
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )
    print("Wrote manifest + label map.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
