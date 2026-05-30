import json
import sys

from config import get_default_config
from data.capture import CaptureManager
from data.dataset import discover_actions, summarize_dataset
from evaluation.evaluate import evaluate
from export_app_model import export as export_tflite
from inference.realtime import run_realtime_inference
from training.train import train as train_v6
from utils.logging_utils import setup_logging, get_logger


def print_banner() -> None:
    print("\n" + "=" * 70)
    print("🤟 V6 ARABIC SIGN LANGUAGE RECOGNITION SYSTEM")
    print("=" * 70)
    print("   🎥 Camera-based Data Collection")
    print("   🧠 LSTM-based Sequence Model with Early Stopping")
    print("   🔍 Real-time Detection with Temporal Smoothing")
    print("   📊 Evaluation: accuracy, confusion matrix, per-class metrics")
    print("=" * 70)


def main() -> None:
    cfg = get_default_config()
    setup_logging(cfg.paths.logs_dir)
    logger = get_logger(__name__)

    logger.info("Starting V6 main CLI.")

    capture_manager = CaptureManager(cfg.paths, cfg.capture)

    while True:
        print_banner()
        print("\n📋 MAIN MENU (V6):")
        print("1. 📷 Collect Arabic Sign Data (Camera)")
        print("2. 🤖 Train Model (Early Stopping, Curves, Metrics)")
        print("3. 🔍 Real-time Detection (Camera)")
        print("4. 📊 Evaluate Model on Validation Set")
        print("5. 🗂 Dataset Summary")
        print("6. 🔄 Rerecord Word (Replace existing sequences)")
        print("7. 🗑 Delete Word (Remove all sequences for a word)")
        print("8. 📱 Export Model for Flutter App (TFLite)")
        print("9. ❌ Exit")
        print("=" * 70)

        try:
            choice = input("Enter your choice (1-9): ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\n👋 Exiting. Goodbye!")
            break

        if choice.lower() in {"q", "quit", "exit"}:
            print("\n👋 Exiting. Goodbye!")
            break

        if choice == "1":
            capture_manager.collect_from_camera()
        elif choice == "2":
            train_v6(cfg)
        elif choice == "3":
            run_realtime_inference(cfg)
        elif choice == "4":
            evaluate(cfg, export=True)
        elif choice == "5":
            actions = discover_actions(cfg.paths.data_dir)
            if not actions:
                print("No data found yet.")
            else:
                summarize_dataset(
                    cfg.paths.data_dir, actions, cfg.training.sequence_length
                )
            input("Press ENTER to return to main menu...")
        elif choice == "6":
            # Rerecord word
            actions = discover_actions(cfg.paths.data_dir)
            if not actions:
                print("❌ No words found in dataset. Use option 1 to record words first.")
                input("Press ENTER to return to main menu...")
            else:
                print("\nAvailable words:")
                for i, word in enumerate(actions, 1):
                    print(f"  {i}. {word}")
                word_input = input("\nEnter the number of the word to rerecord (or press ENTER to cancel): ").strip()
                if word_input:
                    try:
                        idx = int(word_input)
                        if 1 <= idx <= len(actions):
                            capture_manager.rerecord_word(actions[idx - 1])
                        else:
                            print(f"❌ Invalid number. Please enter 1–{len(actions)}.")
                    except ValueError:
                        print("❌ Please enter a valid number.")
                input("Press ENTER to return to main menu...")
        elif choice == "7":
            # Delete word
            actions = discover_actions(cfg.paths.data_dir)
            if not actions:
                print("❌ No words found in dataset.")
                input("Press ENTER to return to main menu...")
            else:
                print("\nAvailable words:")
                for i, word in enumerate(actions, 1):
                    print(f"  {i}. {word}")
                word_input = input("\nEnter the number of the word to delete (or press ENTER to cancel): ").strip()
                if word_input:
                    try:
                        idx = int(word_input)
                        if 1 <= idx <= len(actions):
                            selected_word = actions[idx - 1]
                            confirm = input(f"⚠️  Are you sure you want to delete ALL sequences for '{selected_word}'? (yes/no): ").strip().lower()
                            if confirm == "yes":
                                capture_manager.delete_word(selected_word)
                            else:
                                print("Deletion cancelled.")
                        else:
                            print(f"❌ Invalid number. Please enter 1–{len(actions)}.")
                    except ValueError:
                        print("❌ Please enter a valid number.")
                input("Press ENTER to return to main menu...")
        elif choice == "8":
            # Export TFLite model for Flutter
            quantize_input = input("Apply quantization? (y/n, default: n): ").strip().lower()
            quantize = quantize_input in {"y", "yes"}
            export_tflite(quantize=quantize)
            input("Press ENTER to return to main menu...")
        elif choice == "9":
            print("\n👋 Exiting. Goodbye!")
            break
        else:
            print("Invalid choice. Please select 1–9.")


if __name__ == "__main__":
    # Ensure proper UTF-8 output on Windows terminals
    if sys.stdout.encoding.lower() != "utf-8":  # type: ignore[attr-defined]
        try:
            import io

            sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")  # type: ignore[attr-defined]
            sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8")  # type: ignore[attr-defined]
        except Exception:
            pass

    main()

