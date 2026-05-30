import time
from collections import deque
from typing import List, Dict

import cv2
import mediapipe as mp
import numpy as np
from tensorflow.keras.models import load_model

from config import Config
from utils.arabic_text import put_arabic_text
from utils.logging_utils import get_logger
from utils.mediapipe_utils import (
    create_holistic_landmarker,
    mediapipe_detection,
    draw_styled_landmarks,
    extract_keypoints,
)
from utils.smoothing import TemporalSmoother


def run_realtime_inference(config: Config) -> None:
    """
    Run the real-time Arabic Sign Language detection UI for V6.

    Features:
      - Temporal smoothing over recent predictions
      - Confidence thresholding
      - Cooldown between accepted words
      - Probability bars per class
    """
    logger = get_logger(__name__)
    paths = config.paths
    icfg = config.inference

    model_path = paths.models_dir / "final_model_v6.keras"
    label_map_path = paths.models_dir / "label_map_v6.json"
    if not model_path.exists() or not label_map_path.exists():
        print("❌ V6 model or label map not found. Train the model first.")
        logger.error("Missing model (%s) or label map (%s).", model_path, label_map_path)
        return

    model = load_model(str(model_path))

    import json

    with open(label_map_path, "r", encoding="utf-8") as f:
        label_map: Dict[str, int] = json.load(f)

    index_to_label: List[str] = [""] * len(label_map)
    for action, idx in label_map.items():
        index_to_label[idx] = action

    print("\n" + "=" * 60)
    print("🔍 V6 REAL-TIME ARABIC SIGN DETECTION")
    print("=" * 60)
    print("Controls:")
    print("  Q - Quit")
    print("  S - Toggle skeleton/landmarks")
    print("  R - Reset sentence")
    print("=" * 60)

    smoother = TemporalSmoother(
        window_size=icfg.smoothing_window,
        confidence_threshold=icfg.confidence_threshold,
        cooldown_seconds=icfg.prediction_cooldown,
    )

    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("❌ Cannot open camera. Please check your camera connection.")
        return

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
    cap.set(cv2.CAP_PROP_FPS, 30)

    time.sleep(2)

    holistic = create_holistic_landmarker(
        min_detection_confidence=0.7,
        min_tracking_confidence=0.7,
        model_complexity=1,
    )

    sequence: List[np.ndarray] = []
    sentence: List[str] = []
    show_skeleton = True

    window_name = "Arabic Sign Language V6 - Press Q to quit"
    cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
    cv2.resizeWindow(window_name, 1200, 800)

    try:
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            frame = cv2.flip(frame, 1)
            img, results = mediapipe_detection(frame, holistic)

            if show_skeleton:
                draw_styled_landmarks(img, results)

            hands_detected = bool(
                results.left_hand_landmarks or results.right_hand_landmarks
            )
            face_detected = results.face_landmarks is not None

            keypoints = extract_keypoints(results)
            sequence.append(keypoints)
            sequence = sequence[-config.training.sequence_length :]

            if len(sequence) == config.training.sequence_length and hands_detected:
                # Model expects shape (1, T, F)
                probs = model.predict(
                    np.expand_dims(np.asarray(sequence, dtype=np.float32), axis=0),
                    verbose=0,
                )[0]

                pred_idx, conf = smoother.update(probs)
                if pred_idx is not None and conf is not None:
                    word = index_to_label[pred_idx]
                    if not sentence or word != sentence[-1]:
                        sentence.append(word)
                        print(f"🎯 Detected: {word} ({conf:.2%})")

                    # Limit sentence length
                    if len(sentence) > 10:
                        sentence = sentence[-10:]

                # Probability bars
                overlay = img.copy()
                bar_height = 28
                top = 40
                left = 10
                width = 220

                cv2.rectangle(
                    overlay,
                    (left, top - 20),
                    (left + 500, top + bar_height * len(index_to_label) + 20),
                    (0, 0, 0),
                    -1,
                )
                img = cv2.addWeighted(overlay, 0.5, img, 0.5, 0)

                for i, (label, p) in enumerate(zip(index_to_label, probs)):
                    y1 = top + i * bar_height
                    y2 = y1 + bar_height - 6
                    p_width = int(p * width)
                    color = (0, 255, 0) if p >= icfg.confidence_threshold else (0, 140, 255)

                    cv2.rectangle(img, (left, y1), (left + width, y2), (50, 50, 50), 1)
                    if p_width > 0:
                        cv2.rectangle(img, (left, y1), (left + p_width, y2), color, -1)

                    try:
                        img = put_arabic_text(
                            img,
                            f"{label}: {p:.2f}",
                            (left + width + 10, y1 - 2),
                            font_size=18,
                            text_color=(255, 255, 255),
                            bold=False,
                        )
                    except Exception:
                        cv2.putText(
                            img,
                            f"{p:.2f}",
                            (left + width + 10, y1 + 15),
                            cv2.FONT_HERSHEY_SIMPLEX,
                            0.5,
                            (255, 255, 255),
                            1,
                        )

            # Detection status
            hand_status = "HANDS: DETECTED" if hands_detected else "HANDS: NOT DETECTED"
            face_status = "FACE: DETECTED" if face_detected else "FACE: NOT DETECTED"
            hand_color = (0, 255, 0) if hands_detected else (0, 0, 255)
            face_color = (0, 255, 0) if face_detected else (0, 0, 255)

            cv2.putText(
                img,
                hand_status,
                (img.shape[1] - 260, 50),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6,
                hand_color,
                2,
            )
            cv2.putText(
                img,
                face_status,
                (img.shape[1] - 260, 80),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6,
                face_color,
                2,
            )

            # Sentence display (last few words)
            if sentence:
                current_text = " ".join(sentence[-4:])
                overlay = img.copy()
                cv2.rectangle(
                    overlay,
                    (0, img.shape[0] - 80),
                    (img.shape[1], img.shape[0]),
                    (0, 0, 0),
                    -1,
                )
                img = cv2.addWeighted(overlay, 0.7, img, 0.3, 0)
                try:
                    img = put_arabic_text(
                        img,
                        current_text,
                        (40, img.shape[0] - 55),
                        font_size=28,
                        text_color=(255, 255, 0),
                        bold=True,
                    )
                except Exception:
                    cv2.putText(
                        img,
                        current_text[:40],
                        (40, img.shape[0] - 40),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.7,
                        (255, 255, 0),
                        2,
                    )

            # Controls info
            cv2.putText(
                img,
                "Q: Quit  S: Skeleton  R: Reset sentence",
                (20, 25),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6,
                (255, 255, 255),
                1,
            )

            cv2.imshow(window_name, img)

            key = cv2.waitKey(10) & 0xFF
            if key == ord("q"):
                break
            elif key == ord("s"):
                show_skeleton = not show_skeleton
                logger.info("Skeleton display toggled: %s", show_skeleton)
            elif key == ord("r"):
                sentence.clear()
                smoother.reset()
                logger.info("Sentence and smoother reset.")

    finally:
        cap.release()
        cv2.destroyAllWindows()
        holistic.close()

