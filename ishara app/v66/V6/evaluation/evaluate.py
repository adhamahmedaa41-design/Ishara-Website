import csv
import json
from pathlib import Path
from typing import Dict

import numpy as np
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
)
from tensorflow.keras.models import load_model

from config import Config
from utils.logging_utils import get_logger


def evaluate(config: Config, export: bool = True) -> None:
    """
    Evaluate a trained V6 model on the saved validation split.

    Produces:
      - Accuracy
      - Confusion matrix
      - Classification report
      - Optional JSON + CSV exports of metrics
    """
    logger = get_logger(__name__)
    paths = config.paths

    model_path = paths.models_dir / "final_model_v6.keras"
    label_map_path = paths.models_dir / "label_map_v6.json"
    X_val_path = paths.evaluation_dir / "X_val.npy"
    y_val_path = paths.evaluation_dir / "y_val.npy"

    if not model_path.exists() or not label_map_path.exists():
        print("❌ No trained V6 model or label map found. Train first.")
        logger.error("Missing model (%s) or label map (%s).", model_path, label_map_path)
        return

    if not X_val_path.exists() or not y_val_path.exists():
        print("❌ No saved validation split found. Train first.")
        logger.error("Missing validation split at %s / %s.", X_val_path, y_val_path)
        return

    logger.info("Loading model from %s", model_path)
    model = load_model(str(model_path))

    logger.info("Loading validation split...")
    X_val = np.load(str(X_val_path))
    y_val = np.load(str(y_val_path))

    with open(label_map_path, "r", encoding="utf-8") as f:
        label_map: Dict[str, int] = json.load(f)

    index_to_label = [""] * len(label_map)
    for action, idx in label_map.items():
        index_to_label[idx] = action

    y_true = np.argmax(y_val, axis=1)
    y_pred = np.argmax(model.predict(X_val, verbose=0), axis=1)

    overall_acc = accuracy_score(y_true, y_pred)
    cm = confusion_matrix(y_true, y_pred)
    cls_report = classification_report(
        y_true, y_pred, target_names=index_to_label, digits=3, output_dict=True
    )

    print("\n================ V6 MODEL EVALUATION ================")
    print(f"Overall accuracy: {overall_acc:.4f}\n")

    print("Confusion matrix:")
    print(cm)

    print("\nClassification report:")
    print(
        classification_report(
            y_true, y_pred, target_names=index_to_label, digits=3
        )
    )

    if not export:
        return

    # Export metrics as JSON + CSV
    metrics_dir = paths.evaluation_dir
    metrics_dir.mkdir(parents=True, exist_ok=True)

    metrics_json_path = metrics_dir / "metrics_v6.json"
    with open(metrics_json_path, "w", encoding="utf-8") as f:
        json.dump(
            {
                "overall_accuracy": overall_acc,
                "classification_report": cls_report,
                "confusion_matrix": cm.tolist(),
                "labels": index_to_label,
            },
            f,
            ensure_ascii=False,
            indent=2,
        )

    # Per-class accuracy CSV
    csv_path = metrics_dir / "per_class_accuracy_v6.csv"
    with open(csv_path, "w", newline="", encoding="utf-8") as f_csv:
        writer = csv.writer(f_csv)
        writer.writerow(["index", "label", "accuracy", "support"])
        for idx, label in enumerate(index_to_label):
            support = int(cls_report.get(label, {}).get("support", 0))
            acc = 0.0
            if support > 0:
                mask = y_true == idx
                acc = accuracy_score(y_true[mask], y_pred[mask])
            writer.writerow([idx, label, f"{acc:.4f}", support])

    logger.info("Metrics exported to %s and %s", metrics_json_path, csv_path)
    print(f"\n✅ Metrics exported to:\n  - {metrics_json_path}\n  - {csv_path}")

