from pathlib import Path
from typing import Dict, List, Tuple

import numpy as np
from sklearn.model_selection import train_test_split

from config import TrainingConfig, PathsConfig


def discover_actions(data_dir: Path) -> List[str]:
    """
    Discover available actions (class labels) based on subdirectories
    under the MediaPipe data directory.
    """
    if not data_dir.exists():
        return []
    return sorted(
        [
            d.name
            for d in data_dir.iterdir()
            if d.is_dir() and not d.name.startswith(".")
        ]
    )


def load_sequences_for_actions(
    data_dir: Path,
    actions: List[str],
    sequence_length: int,
) -> Tuple[np.ndarray, np.ndarray, Dict[str, int]]:
    """
    Load sequences of keypoints from disk into (X, y, label_map).

    X shape: (num_sequences, sequence_length, 1692)
    y shape: (num_sequences,)
    label_map: {action_name: index}
    """
    sequences: List[np.ndarray] = []
    labels: List[int] = []
    label_map: Dict[str, int] = {label: idx for idx, label in enumerate(actions)}

    for action in actions:
        action_dir = data_dir / action
        if not action_dir.exists():
            continue
        sequence_dirs = [
            d for d in action_dir.iterdir() if d.is_dir() and d.name.isdigit()
        ]

        for seq_dir in sequence_dirs:
            window: List[np.ndarray] = []
            for frame_idx in range(sequence_length):
                npy_path = seq_dir / f"{frame_idx}.npy"
                if npy_path.exists():
                    arr = np.load(str(npy_path))
                else:
                    arr = np.zeros(1692, dtype=np.float32)
                window.append(arr)

            if len(window) == sequence_length:
                try:
                    sequences.append(np.stack(window, axis=0))
                    labels.append(label_map[action])
                except ValueError as e:
                    print(f"Error stacking sequence {seq_dir.name} from {action}:")
                    for i, arr in enumerate(window):
                        print(f"  Frame {i}: shape {arr.shape}, dtype {arr.dtype}")
                    raise

    if not sequences:
        return np.empty((0, sequence_length, 1692)), np.empty((0,), dtype=int), label_map

    X = np.stack(sequences, axis=0).astype(np.float32)
    y = np.array(labels, dtype=int)
    return X, y, label_map


def stratified_split(
    X: np.ndarray,
    y: np.ndarray,
    cfg: TrainingConfig,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """
    Stratified train/validation split with parameters from TrainingConfig.
    """
    return train_test_split(
        X,
        y,
        test_size=cfg.test_size,
        random_state=cfg.random_state,
        stratify=y,
    )


def summarize_dataset(
    data_dir: Path,
    actions: List[str],
    sequence_length: int,
) -> None:
    """
    Print a high-level dataset summary: number of actions, sequences, frames.
    Intended for CLI usage.
    """
    total_sequences = 0
    total_frames = 0
    print("\n================ DATASET SUMMARY (V6) ================")
    print(f"Data directory: {data_dir}")
    print(f"Actions: {len(actions)}")

    for action in actions:
        action_dir = data_dir / action
        if not action_dir.exists():
            print(f"  - {action}: MISSING DIRECTORY")
            continue
        sequence_dirs = [
            d for d in action_dir.iterdir() if d.is_dir() and d.name.isdigit()
        ]
        num_seq = len(sequence_dirs)
        total_sequences += num_seq
        total_frames += num_seq * sequence_length
        print(f"  - {action}: {num_seq} sequences")

    print("------------------------------------------------------")
    print(f"Total sequences: {total_sequences}")
    print(f"Sequence length: {sequence_length}")
    print(f"Total frames  : {total_frames}")
    print("======================================================\n")

