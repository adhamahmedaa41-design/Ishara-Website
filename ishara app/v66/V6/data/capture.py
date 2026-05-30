import time
from pathlib import Path
from typing import List

import cv2
import numpy as np
import mediapipe as mp

from config import CaptureConfig, PathsConfig
from utils.arabic_text import put_arabic_text
from utils.mediapipe_utils import (
    create_holistic_landmarker,
    mediapipe_detection,
    draw_styled_landmarks,
    extract_keypoints,
)
from utils.logging_utils import get_logger


class CaptureManager:
    """
    Camera-based data collection with quality checks and user guidance.
    """

    def __init__(self, paths: PathsConfig, cfg: CaptureConfig) -> None:
        self.paths = paths
        self.cfg = cfg
        self.logger = get_logger(__name__)
        self.data_dir = self.paths.data_dir

    def _create_action_dirs(self, actions: List[str], num_sequences: int) -> None:
        for action in actions:
            for seq_idx in range(num_sequences):
                seq_dir = self.data_dir / action / str(seq_idx)
                seq_dir.mkdir(parents=True, exist_ok=True)

    def _sequence_exists(self, action: str, seq_idx: int) -> bool:
        seq_dir = self.data_dir / action / str(seq_idx)
        if not seq_dir.exists():
            return False
        # Consider it existing if at least 80% of frames are present
        existing = 0
        for frame_idx in range(self.cfg.sequence_length):
            if (seq_dir / f"{frame_idx}.npy").exists():
                existing += 1
        return existing >= int(0.8 * self.cfg.sequence_length)

    def delete_word(self, word: str) -> bool:
        """
        Delete all sequences for a given word.
        Returns True if deletion was successful, False otherwise.
        """
        word_dir = self.data_dir / word
        if not word_dir.exists():
            print(f"❌ Word '{word}' not found in dataset.")
            return False
        
        import shutil
        import json
        try:
            shutil.rmtree(word_dir)
            print(f"✅ Deleted all sequences for word: {word}")
            
            # Update actions list
            actions_path = self.paths.base_dir / "custom_actions_v6.json"
            if actions_path.exists():
                with open(actions_path, "r", encoding="utf-8") as f:
                    existing_actions = json.load(f)
                if word in existing_actions:
                    existing_actions.remove(word)
                with open(actions_path, "w", encoding="utf-8") as f:
                    json.dump(existing_actions, f, ensure_ascii=False, indent=2)
            
            return True
        except Exception as e:
            print(f"❌ Error deleting word '{word}': {e}")
            return False
    
    def rerecord_word(self, word: str) -> None:
        """
        Rerecord sequences for an existing word, replacing old data.
        """
        if not (self.data_dir / word).exists():
            print(f"❌ Word '{word}' not found. Use option 1 to record new words.")
            return
        
        num_sequences_str = input(
            f"How many sequences do you want to record for '{word}'? (recommended: 30–60): "
        ).strip()
        try:
            num_sequences = int(num_sequences_str)
        except ValueError:
            print("Invalid number, cancelling.")
            return
        
        # Delete existing sequences
        import shutil
        word_dir = self.data_dir / word
        if word_dir.exists():
            shutil.rmtree(word_dir)
        
        # Create directories for new sequences
        self._create_action_dirs([word], num_sequences)
        
        # Now record new sequences (reuse the main collection logic)
        success = self._record_sequences_for_word([word], num_sequences, start_seq_idx=0)
        
        if success:
            # Update actions list
            actions_path = self.paths.base_dir / "custom_actions_v6.json"
            import json
            existing_actions = []
            if actions_path.exists():
                with open(actions_path, "r", encoding="utf-8") as f:
                    existing_actions = json.load(f)
            if word not in existing_actions:
                existing_actions.append(word)
            with open(actions_path, "w", encoding="utf-8") as f:
                json.dump(existing_actions, f, ensure_ascii=False, indent=2)
            print(f"\n🎉 Rerecording complete for '{word}'. Actions list updated.")
        else:
            print(f"\n❌ Rerecording failed for '{word}' due to camera issues. Please try again.")
    
    def _record_sequences_for_word(self, actions: List[str], num_sequences: int, start_seq_idx: int = 0) -> bool:
        """
        Internal helper to record sequences for given actions.
        Used by both collect_from_camera and rerecord_word.
        Returns True if recording was successful, False otherwise.
        """
        # Try different camera indices (0, 1, 2)
        cap = None
        for idx in range(3):
            cap = cv2.VideoCapture(idx)
            if cap.isOpened():
                print(f"✅ Camera opened at index {idx}")
                break
        if not cap or not cap.isOpened():
            print("❌ Cannot open camera. Please check your camera connection and ensure no other applications are using it.")
            return False

        cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        cap.set(cv2.CAP_PROP_FPS, 30)

        time.sleep(2)

        holistic = create_holistic_landmarker(
            min_detection_confidence=0.6,
            min_tracking_confidence=0.6,
            model_complexity=1,
        )

        successful_sequences = 0

        try:
            for action in actions:
                print(f"\n🎯 Recording for label: {action}")
                for seq_idx in range(start_seq_idx, start_seq_idx + num_sequences):
                    if self._sequence_exists(action, seq_idx) and start_seq_idx == 0:
                        print(
                            f"   ⏩ Sequence {seq_idx + 1}/{num_sequences} already exists, skipping."
                        )
                        continue

                    print(
                        f"   ▶ Sequence {seq_idx + 1}/{num_sequences} "
                        f"({self.cfg.sequence_length} frames)"
                    )

                    # Countdown overlay
                    countdown_start = time.time()
                    while time.time() - countdown_start < self.cfg.countdown_seconds:
                        ret, frame = cap.read()
                        if not ret:
                            break
                        frame = cv2.flip(frame, 1)
                        cv2.putText(
                            frame,
                            f"Starting in {int(self.cfg.countdown_seconds - (time.time() - countdown_start))}...",
                            (50, 100),
                            cv2.FONT_HERSHEY_SIMPLEX,
                            1.0,
                            (0, 255, 0),
                            2,
                        )
                        # Use Arabic text rendering
                        try:
                            frame = put_arabic_text(
                                frame,
                                f"الكلمة: {action}",
                                (50, 150),
                                font_size=32,
                                text_color=(0, 0, 255),
                            )
                        except Exception:
                            cv2.putText(
                                frame,
                                f"Word: {action}",
                                (50, 150),
                                cv2.FONT_HERSHEY_SIMPLEX,
                                0.8,
                                (0, 0, 255),
                                2,
                            )
                        cv2.imshow("ASL V6 Capture", frame)
                        if cv2.waitKey(30) & 0xFF == ord("q"):
                            print("User requested exit.")
                            return False

                    # Retry loop for low-quality sequences
                    retry_count = 0
                    quality_acceptable = False
                    
                    while retry_count <= self.cfg.max_retries_per_sequence and not quality_acceptable:
                        if retry_count > 0:
                            print(f"   🔄 Retrying sequence {seq_idx + 1} (attempt {retry_count + 1}/{self.cfg.max_retries_per_sequence + 1})...")
                            time.sleep(1)
                        
                        seq_dir = self.data_dir / action / str(seq_idx)
                        seq_dir.mkdir(parents=True, exist_ok=True)
                        
                        if retry_count > 0:
                            for existing_frame in seq_dir.glob("*.npy"):
                                existing_frame.unlink()

                        valid_frames = 0
                        paused = False
                        
                        for frame_idx in range(self.cfg.sequence_length):
                            ret, frame = cap.read()
                            if not ret:
                                self.logger.warning("Failed to grab frame from camera.")
                                continue

                            frame = cv2.flip(frame, 1)
                            img, results = mediapipe_detection(frame, holistic)
                            draw_styled_landmarks(img, results)

                            hands_detected = (
                                results.left_hand_landmarks or results.right_hand_landmarks
                            )

                            status_text = (
                                "HANDS: DETECTED" if hands_detected else "HANDS: NOT DETECTED"
                            )
                            color = (0, 255, 0) if hands_detected else (0, 0, 255)

                            cv2.putText(
                                img,
                                status_text,
                                (15, 40),
                                cv2.FONT_HERSHEY_SIMPLEX,
                                0.7,
                                color,
                                2,
                            )
                            
                            try:
                                img = put_arabic_text(
                                    img,
                                    f"الكلمة: {action}",
                                    (15, 80),
                                    font_size=28,
                                    text_color=(255, 255, 255),
                                    bold=True,
                                )
                            except Exception:
                                cv2.putText(
                                    img,
                                    f"Word: {action}",
                                    (15, 80),
                                    cv2.FONT_HERSHEY_SIMPLEX,
                                    0.6,
                                    (255, 255, 255),
                                    2,
                                )
                            
                            cv2.putText(
                                img,
                                f"Seq {seq_idx + 1}/{num_sequences} | "
                                f"Frame {frame_idx + 1}/{self.cfg.sequence_length}",
                                (15, 120),
                                cv2.FONT_HERSHEY_SIMPLEX,
                                0.6,
                                (255, 255, 255),
                                2,
                            )
                            
                            if paused:
                                cv2.putText(
                                    img,
                                    "⏸ PAUSED - Press SPACE to resume",
                                    (15, 160),
                                    cv2.FONT_HERSHEY_SIMPLEX,
                                    0.7,
                                    (0, 255, 255),
                                    2,
                                )

                            if not hands_detected:
                                cv2.putText(
                                    img,
                                    "⚠ No hands detected – try to keep hands visible",
                                    (15, 200 if paused else 160),
                                    cv2.FONT_HERSHEY_SIMPLEX,
                                    0.6,
                                    (0, 0, 255),
                                    2,
                                )
                            
                            cv2.putText(
                                img,
                                "Q: Quit | SPACE: Pause/Resume",
                                (15, img.shape[0] - 30),
                                cv2.FONT_HERSHEY_SIMPLEX,
                                0.5,
                                (200, 200, 200),
                                1,
                            )

                            if not paused:
                                keypoints = extract_keypoints(results)
                                np.save(str(seq_dir / f"{frame_idx}.npy"), keypoints)
                                valid_frames += 1 if hands_detected else 0

                            cv2.imshow("ASL V6 Capture", img)
                            
                            key = cv2.waitKey(10) & 0xFF
                            if key == ord("q"):
                                print("User requested exit.")
                                return False
                            elif key == ord(" "):
                                paused = not paused
                                if paused:
                                    print("   ⏸ Recording paused. Press SPACE to resume.")
                                else:
                                    print("   ▶ Recording resumed.")
                            
                            if paused:
                                frame_idx -= 1
                                time.sleep(0.1)

                        quality_ratio = valid_frames / float(self.cfg.sequence_length)
                        
                        if quality_ratio >= 0.5:
                            quality_acceptable = True
                            print(f"   ✅ Sequence {seq_idx + 1} recorded (quality OK: {quality_ratio * 100:.0f}%).")
                            successful_sequences += 1
                        else:
                            retry_count += 1
                            if retry_count <= self.cfg.max_retries_per_sequence:
                                print(
                                    f"   ⚠ Sequence {seq_idx + 1} has low hand visibility "
                                    f"({quality_ratio * 100:.0f}%). Retrying..."
                                )
                            else:
                                print(
                                    f"   ❌ Sequence {seq_idx + 1} failed quality check after {self.cfg.max_retries_per_sequence + 1} attempts "
                                    f"({quality_ratio * 100:.0f}% hand visibility). Moving to next sequence."
                                )
                                import shutil
                                if seq_dir.exists():
                                    shutil.rmtree(seq_dir)

        finally:
            cap.release()
            cv2.destroyAllWindows()
            holistic.close()
        
        if successful_sequences == 0:
            return False
        
        return True

    def collect_from_camera(self) -> None:
        """
        Interactive loop to record sequences for multiple actions from the webcam.
        Includes:
            - Countdown before each sequence
            - Hand/pose presence checks
            - Duplicate sequence avoidance
        """
        print("\n" + "=" * 60)
        print("📷 V6 CAMERA DATA COLLECTION")
        print("=" * 60)
        print("INSTRUCTIONS:")
        print("1. You will enter the Arabic words (labels) you want to record.")
        print("2. For each word, we will record several sequences of keypoints.")
        print("3. A short countdown appears before each sequence starts.")
        print("4. If no hands are detected, the frame is marked low-quality.")
        print("5. Existing sequences are skipped to avoid duplicates.")
        print("=" * 60)

        num_words_str = input(
            "How many Arabic words do you want to record? (or press ENTER to cancel): "
        ).strip()
        if not num_words_str:
            print("Cancelled.")
            return
        try:
            num_words = int(num_words_str)
        except ValueError:
            print("Invalid number, cancelling.")
            return

        actions: List[str] = []
        for i in range(num_words):
            label = input(f"Enter Arabic word {i + 1}: ").strip()
            if not label:
                print("Empty label, skipping.")
                continue
            actions.append(label)

        if not actions:
            print("No valid labels entered. Nothing to collect.")
            return

        num_sequences_str = input(
            "Number of sequences per word (recommended: 30–60): "
        ).strip()
        try:
            num_sequences = int(num_sequences_str)
        except ValueError:
            print("Invalid number, cancelling.")
            return

        self._create_action_dirs(actions, num_sequences)
        success = self._record_sequences_for_word(actions, num_sequences, start_seq_idx=0)

        if success:
            # Persist actions list alongside the data
            actions_path = self.paths.base_dir / "custom_actions_v6.json"
            import json

            with open(actions_path, "w", encoding="utf-8") as f:
                json.dump(actions, f, ensure_ascii=False, indent=2)
            print(f"\n🎉 Capture complete. Actions saved to {actions_path}")
        else:
            print("\n❌ Data collection failed due to camera issues. Please check your camera and try again.")

