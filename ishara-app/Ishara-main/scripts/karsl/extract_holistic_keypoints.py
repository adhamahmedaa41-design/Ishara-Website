"""Run MediaPipe Holistic on every KArSL video and dump 30-frame
1692-dim keypoint sequences as `.npz` shards — exactly the input shape
the existing V6 model expects, so the trained KArSL model is a drop-in
replacement.

Layout per frame (1692 floats, matches `assets/models/manifest.json`):
  - 33 pose landmarks × 4 (x, y, z, visibility)        = 132
  - 468 face landmarks × 3 (x, y, z)                   = 1404
  - 21 left-hand landmarks × 3                         = 63
  - 21 right-hand landmarks × 3                        = 63

Usage:

    pip install mediapipe opencv-python numpy tqdm
    python scripts/karsl/extract_holistic_keypoints.py \
        --root data/karsl --frames 30 --out data/karsl/keypoints

The script writes one `<class>__<file>.npz` per video with arrays:
  - `seq`  shape (30, 1692) float32
  - `label` int   (index in `classes` list)
  - `signer` str
And one `data/karsl/keypoints/classes.json` listing the canonical class
order — used downstream by `train_karsl_lstm.py`.
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path

import numpy as np


def _holistic_landmarks(mp_holistic, results) -> np.ndarray:
    pose = np.zeros(33 * 4, dtype=np.float32)
    if results.pose_landmarks:
        for i, lm in enumerate(results.pose_landmarks.landmark):
            pose[i * 4 : i * 4 + 4] = (lm.x, lm.y, lm.z, lm.visibility)
    face = np.zeros(468 * 3, dtype=np.float32)
    if results.face_landmarks:
        for i, lm in enumerate(results.face_landmarks.landmark):
            face[i * 3 : i * 3 + 3] = (lm.x, lm.y, lm.z)
    left = np.zeros(21 * 3, dtype=np.float32)
    if results.left_hand_landmarks:
        for i, lm in enumerate(results.left_hand_landmarks.landmark):
            left[i * 3 : i * 3 + 3] = (lm.x, lm.y, lm.z)
    right = np.zeros(21 * 3, dtype=np.float32)
    if results.right_hand_landmarks:
        for i, lm in enumerate(results.right_hand_landmarks.landmark):
            right[i * 3 : i * 3 + 3] = (lm.x, lm.y, lm.z)
    return np.concatenate([pose, face, left, right])  # 1692


def uniform_sample(n: int, k: int) -> list[int]:
    if n <= 0:
        return []
    if n <= k:
        return list(range(n)) + [n - 1] * (k - n)
    return [round(i * (n - 1) / (k - 1)) for i in range(k)]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default="data/karsl")
    parser.add_argument("--frames", type=int, default=30)
    parser.add_argument("--out", default="data/karsl/keypoints")
    args = parser.parse_args()

    try:
        import cv2  # type: ignore
        import mediapipe as mp  # type: ignore
        from tqdm import tqdm  # type: ignore
    except ImportError:
        print("Run: pip install mediapipe opencv-python numpy tqdm")
        return 1

    root = Path(args.root)
    meta_path = root / "meta.csv"
    if not meta_path.is_file():
        print(f"Missing {meta_path} — run download_karsl.py first.")
        return 1

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    videos: list[tuple[str, str, str]] = []
    with meta_path.open(encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        for r in reader:
            videos.append((r["path"], r["class"], r["signer"]))

    classes = sorted({c for _, c, _ in videos})
    (out_dir / "classes.json").write_text(json.dumps(classes, ensure_ascii=False, indent=2))
    cls_idx = {c: i for i, c in enumerate(classes)}

    mp_holistic = mp.solutions.holistic
    holistic = mp_holistic.Holistic(
        model_complexity=1,
        smooth_landmarks=True,
        refine_face_landmarks=False,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
    )

    skipped = 0
    for rel, cls, signer in tqdm(videos, desc="extracting"):
        out_path = out_dir / f"{cls}__{Path(rel).stem}.npz"
        if out_path.exists():
            continue
        cap = cv2.VideoCapture(str(root / rel))
        all_frames: list[np.ndarray] = []
        ok, frame = cap.read()
        while ok:
            all_frames.append(frame)
            ok, frame = cap.read()
        cap.release()
        if not all_frames:
            skipped += 1
            continue
        idxs = uniform_sample(len(all_frames), args.frames)
        seq = np.zeros((args.frames, 1692), dtype=np.float32)
        for j, fi in enumerate(idxs):
            rgb = cv2.cvtColor(all_frames[fi], cv2.COLOR_BGR2RGB)
            results = holistic.process(rgb)
            seq[j] = _holistic_landmarks(mp_holistic, results)
        np.savez_compressed(
            out_path,
            seq=seq,
            label=np.int32(cls_idx[cls]),
            signer=np.str_(signer),
        )

    holistic.close()
    print(f"Done. {len(videos) - skipped} sequences in {out_dir}, {skipped} skipped (empty videos).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
