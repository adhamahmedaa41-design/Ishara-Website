## Arabic Sign Language Recognition – Version 6

A modular, production-oriented system for building custom Arabic sign language models from scratch. It handles the full pipeline: recording hand/body keypoints via webcam, training an LSTM sequence classifier, running real-time detection, evaluating accuracy, and exporting a TFLite model for the Ishara Flutter app.

---

### How the Sign Language Model is Created

1. **Data Collection** (menu option 1)  
   You choose Arabic words (labels) and record yourself performing each sign on camera. MediaPipe Holistic tracks your pose, face, and both hands in real-time, extracting a **1692-dimensional keypoint vector** per frame:
   - Pose: 33 landmarks × 4 values (x, y, z, visibility) = 132
   - Face: 478 landmarks × 3 values (x, y, z) = 1434
   - Left hand: 21 landmarks × 3 values = 63
   - Right hand: 21 landmarks × 3 values = 63

   Each sign is recorded as multiple **sequences** (recommended 30–60 per word), where each sequence is 30 consecutive frames of keypoints saved as `.npy` files.

2. **Training** (menu option 2)  
   An LSTM neural network learns to classify sequences of keypoints into sign labels:
   - **Architecture**: 2 LSTM layers (128 → 256 units) with batch normalization, followed by 2 dense layers (256 → 128) with dropout and L2 regularization, ending in a softmax output.
   - **Training features**: stratified train/validation split, class weights for imbalanced data, early stopping, learning rate reduction on plateau, and model checkpointing.
   - Training curves (accuracy/loss plots) and history are saved to the logs folder.

3. **Real-time Detection** (menu option 3)  
   Opens your webcam and continuously feeds 30-frame keypoint sequences into the trained model. Uses temporal smoothing (averaging predictions over a sliding window) and confidence thresholding to produce stable, accurate sign detections displayed on screen with probability bars.

4. **Evaluation** (menu option 4)  
   Evaluates the model on the saved validation split and outputs overall accuracy, a confusion matrix, and a per-class classification report. Metrics are exported as JSON and CSV files.

5. **Export for Flutter** (menu option 8)  
   Converts the trained Keras model to TensorFlow Lite format and copies it, along with a label map and a metadata manifest, directly into the Ishara Flutter app's `assets/models/` folder. The Flutter app uses MediaPipe on-device to extract the same keypoint vectors and feeds them into the TFLite model for inference.

---

### Project Layout

```
V6/
├── config.py               – Central configuration (paths, training, inference, capture)
├── main.py                 – CLI entrypoint with interactive menu
├── export_app_model.py     – TFLite export for Flutter integration
├── requirements.txt        – Python dependencies
├── data/
│   ├── capture.py          – Camera-based data collection with quality checks
│   └── dataset.py          – Sequence loading, splitting, and dataset summary
├── models/
│   └── asl_model.py        – LSTM model architecture definition
├── training/
│   └── train.py            – Full training pipeline with callbacks and history
├── inference/
│   └── realtime.py         – Real-time camera detection with temporal smoothing
├── evaluation/
│   └── evaluate.py         – Offline evaluation with metrics export (JSON + CSV)
└── utils/
    ├── arabic_text.py      – Arabic reshaping + bidi-aware text rendering on OpenCV frames
    ├── mediapipe_utils.py   – MediaPipe detection and keypoint extraction helpers
    ├── smoothing.py        – Temporal smoothing for prediction stability
    └── logging_utils.py    – Logging setup
```

### How to Run

1. Create/activate a virtual environment and install dependencies:

   ```bash
   pip install -r V6/requirements.txt
   ```

2. From the `V6` folder, run:

   ```bash
   python main.py
   ```

3. Use the interactive menu:

| # | Option | Description |
|---|--------|-------------|
| 1 | Collect Data | Record sign language sequences via webcam with hand-detection quality checks |
| 2 | Train Model | Train the LSTM classifier with early stopping, class weights, and curve logging |
| 3 | Real-time Detection | Live camera detection with temporal smoothing and probability bars |
| 4 | Evaluate Model | Run evaluation on validation split; exports accuracy, confusion matrix, per-class metrics |
| 5 | Dataset Summary | Print a summary of collected sequences per word |
| 6 | Rerecord Word | Select a word by number and re-record its sequences from scratch |
| 7 | Delete Word | Select a word by number and remove all its sequences |
| 8 | Export for Flutter | Convert the trained model to TFLite and copy to the Ishara app's assets |
| 9 | Exit | Quit the program |

Options 6 and 7 list all recorded words with numbers — just type the number to select a word.

### Export for Flutter (TFLite)

After training (option 2), export the model for the Ishara Flutter app using option 8 from the menu, or directly from the command line:

```bash
python export_app_model.py              # default export
python export_app_model.py --quantize   # dynamic-range quantization (smaller/faster)
python export_app_model.py --base_dir X # override data root directory
```

The export produces these files in the Flutter app's `assets/models/` folder:

| File | Purpose |
|------|---------|
| `asl_v6.tflite` | The converted LSTM model |
| `label_map_v6.json` | Maps class names to indices |
| `manifest.json` | Metadata: input/output shapes, keypoint layout, label list |

The Flutter app uses MediaPipe Holistic on-device to extract the same 1662-dim keypoint vector per frame, builds 30-frame sequences, and runs inference through the TFLite model.

### Data and Model Storage

By default, persistent artifacts are stored under `D:/Arabic_Sign_Language/`:

| Path | Contents |
|------|----------|
| `MP_Data_Custom/` | Recorded keypoint sequences (`.npy` files per frame) |
| `models_v6/` | Trained models (`best_model_v6.keras`, `final_model_v6.keras`), label map, exported TFLite |
| `logs_v6/` | Training history, accuracy/loss plots |
| `evaluation_v6/` | Validation splits (`X_val.npy`, `y_val.npy`), metrics JSON and CSV |

The base directory can be changed in [config.py](config.py) (`PathsConfig.base_dir`).

