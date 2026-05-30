import json
import time
from pathlib import Path
from typing import Dict, Tuple

import matplotlib
matplotlib.use('Agg')  # Non-interactive backend to prevent opening windows
import matplotlib.pyplot as plt
import numpy as np
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
)
from tensorflow.keras.callbacks import (
    EarlyStopping,
    ReduceLROnPlateau,
    ModelCheckpoint,
)
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.utils import to_categorical
from sklearn.utils import class_weight

from config import Config, TrainingConfig
from data.dataset import (
    discover_actions,
    load_sequences_for_actions,
    stratified_split,
    summarize_dataset,
)
from models.asl_model import build_lstm_model
from utils.logging_utils import get_logger


def _save_history_curves(
    history: Dict[str, list], out_dir: Path
) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    hist_path = out_dir / "history.json"
    with open(hist_path, "w", encoding="utf-8") as f:
        json.dump(history, f, indent=2)

    # Plot accuracy
    if "categorical_accuracy" in history and "val_categorical_accuracy" in history:
        plt.figure(figsize=(8, 5))
        plt.plot(history["categorical_accuracy"], label="train_acc")
        plt.plot(history["val_categorical_accuracy"], label="val_acc")
        plt.xlabel("Epoch")
        plt.ylabel("Accuracy")
        plt.title("Training vs Validation Accuracy")
        plt.legend()
        plt.grid(True)
        plt.tight_layout()
        plt.savefig(out_dir / "accuracy.png")
        plt.close()

    # Plot loss
    if "loss" in history and "val_loss" in history:
        plt.figure(figsize=(8, 5))
        plt.plot(history["loss"], label="train_loss")
        plt.plot(history["val_loss"], label="val_loss")
        plt.xlabel("Epoch")
        plt.ylabel("Loss")
        plt.title("Training vs Validation Loss")
        plt.legend()
        plt.grid(True)
        plt.tight_layout()
        plt.savefig(out_dir / "loss.png")
        plt.close()


def train(config: Config) -> None:
    """
    High-level training entrypoint.

    Steps:
      1) Discover actions and load sequences
      2) Class weights + stratified split
      3) Build and compile model
      4) Train with callbacks
      5) Evaluate on validation set
      6) Save model, label map, history, and test split for later evaluation
    """
    logger = get_logger(__name__)
    paths = config.paths
    tcfg: TrainingConfig = config.training

    logger.info("Starting V6 training pipeline.")

    actions = discover_actions(paths.data_dir)
    if not actions:
        logger.error("No actions found in data directory: %s", paths.data_dir)
        print("❌ No data found. Please collect data first.")
        return

    summarize_dataset(paths.data_dir, actions, tcfg.sequence_length)

    logger.info("Loading sequences into memory...")
    X, y, label_map = load_sequences_for_actions(
        paths.data_dir, actions, tcfg.sequence_length
    )
    if X.shape[0] == 0:
        logger.error("No valid sequences loaded. Aborting training.")
        print("❌ No valid sequences found. Check your dataset.")
        return

    logger.info("Dataset size: %d sequences, %d features per frame.", X.shape[0], X.shape[2])

    y_categorical = to_categorical(y).astype(int)

    cw = class_weight.compute_class_weight(
        class_weight="balanced",
        classes=np.unique(y),
        y=y,
    )
    class_weights = dict(enumerate(cw))
    logger.info("Class weights: %s", class_weights)

    X_train, X_val, y_train, y_val = stratified_split(X, y_categorical, tcfg)
    logger.info(
        "Train/val split: %d / %d sequences.",
        X_train.shape[0],
        X_val.shape[0],
    )

    model = build_lstm_model(
        (tcfg.sequence_length, X.shape[2]),
        num_classes=len(label_map),
    )

    optimizer = Adam(
        learning_rate=tcfg.learning_rate,
        beta_1=0.9,
        beta_2=0.999,
        epsilon=1e-8,
    )
    model.compile(
        optimizer=optimizer,
        loss="categorical_crossentropy",
        metrics=["categorical_accuracy"],
    )

    logger.info("Model summary:")
    model.summary(print_fn=lambda line: logger.info(line))

    paths.models_dir.mkdir(parents=True, exist_ok=True)
    best_model_path = paths.models_dir / "best_model_v6.keras"

    callbacks = [
        EarlyStopping(
            monitor="val_categorical_accuracy",
            patience=tcfg.early_stopping_patience,
            restore_best_weights=True,
            min_delta=tcfg.min_delta,
            verbose=1,
        ),
        ReduceLROnPlateau(
            monitor="val_loss",
            factor=tcfg.reduce_lr_factor,
            patience=tcfg.reduce_lr_patience,
            verbose=1,
        ),
        ModelCheckpoint(
            str(best_model_path),
            monitor="val_categorical_accuracy",
            mode="max",
            save_best_only=True,
            verbose=1,
        ),
    ]

    logger.info("Beginning model.fit()...")
    start_time = time.time()

    history = model.fit(
        X_train,
        y_train,
        epochs=tcfg.epochs,
        batch_size=tcfg.batch_size,
        validation_data=(X_val, y_val),
        class_weight=class_weights,
        callbacks=callbacks,
        verbose=1,
    )

    elapsed = time.time() - start_time
    logger.info("Training completed in %.1f seconds.", elapsed)

    # Evaluation on validation set
    y_true = np.argmax(y_val, axis=1)
    y_pred = np.argmax(model.predict(X_val, verbose=0), axis=1)

    overall_acc = accuracy_score(y_true, y_pred)
    logger.info("Validation accuracy: %.4f", overall_acc)
    print(f"\n✅ Validation accuracy: {overall_acc:.4f}")

    index_to_label = [""] * len(label_map)
    for action, idx in label_map.items():
        index_to_label[idx] = action

    print("\n📋 Classification report (validation):")
    print(
        classification_report(
            y_true,
            y_pred,
            target_names=index_to_label,
            digits=3,
        )
    )

    print("📌 Confusion matrix (validation):")
    print(confusion_matrix(y_true, y_pred))

    # Save history plots and JSON
    _save_history_curves(history.history, paths.logs_dir)

    # Save final model and label map (using native Keras format)
    final_model_path = paths.models_dir / "final_model_v6.keras"
    model.save(str(final_model_path))
    logger.info("Final model saved to %s", final_model_path)

    label_map_path = paths.models_dir / "label_map_v6.json"
    with open(label_map_path, "w", encoding="utf-8") as f:
        json.dump(label_map, f, ensure_ascii=False, indent=2)
    logger.info("Label map saved to %s", label_map_path)

    # Save validation split for separate evaluation module
    paths.evaluation_dir.mkdir(parents=True, exist_ok=True)
    np.save(paths.evaluation_dir / "X_val.npy", X_val)
    np.save(paths.evaluation_dir / "y_val.npy", y_val)
    logger.info("Saved validation split to %s", paths.evaluation_dir)

    print("\n✅ Training finished. Best model and metrics have been saved.")

