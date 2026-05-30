# YOLOv13 Vision Integration + Pub-get Crash Fix

## A. Fix the `flutter pub get` crash you saw

**Error:** `PathAccessException: Deletion failed, path = '…\linux\flutter\ephemeral\.plugin_symlinks' (errno 32)`

**Root cause:** Windows Explorer / VS Code / a previous `dart.exe` is
holding a file handle inside `linux/flutter/ephemeral/.plugin_symlinks`
while `flutter pub get` tries to recreate the symlink tree. NTFS can't
delete an open file → the tool aborts and crashes.

**Why it's hitting Linux on a Windows machine:** the `linux/` directory
was scaffolded when the project was created, so Flutter regenerates its
plugin symlinks every `pub get` even though you only target Android +
iOS.

### Permanent fix (run once)

Close every editor/terminal/Gradle daemon that touches the project, then
in **PowerShell** (not Git Bash, so locks release cleanly):

```powershell
# 1. Kill any stragglers holding files in the project tree
taskkill /F /IM dart.exe 2>$null
taskkill /F /IM java.exe 2>$null

# 2. Remove the locked symlink tree (it gets re-created by pub get)
Remove-Item -Recurse -Force .\linux\flutter\ephemeral
Remove-Item -Recurse -Force .\macos\Flutter\ephemeral 2>$null
Remove-Item -Recurse -Force .\windows\flutter\ephemeral 2>$null

# 3. Clean Gradle + pub caches local to the project
flutter clean

# 4. Re-resolve
flutter pub get
flutter run
```

If you don't need Linux/macOS/Windows desktop builds at all, also run:

```powershell
flutter config --no-enable-linux-desktop --no-enable-macos-desktop --no-enable-windows-desktop
```

…and (optional) delete the `linux/`, `macos/`, `windows/` directories
from the repo. Flutter will not re-create them after the config flags.

### When it strikes again

The trigger is almost always **VS Code's Dart analyzer** locking a
plugin symlink. Workaround: close VS Code → run `flutter pub get` in a
plain PowerShell → reopen VS Code. (Or move the project off `G:\` to
`C:\`, where the analyzer's Win32 file-watcher behaves better.)

---

## B. YOLOv13 Object Detection — what was wired

### B1. New on-device YOLOv13 detector
**File:** [lib/src/features/vision/data/yolo_object_detector.dart](lib/src/features/vision/data/yolo_object_detector.dart)

- Loads `assets/models/yolov13n_float16.tflite` (or `_int8` / unsuffixed
  fallback) via `tflite_flutter`.
- Letterboxes the camera frame to the model's `inputSize` (read from
  the input tensor — defaults to 640).
- Runs inference; expects `[1, N, 6]` output with NMS already baked in
  (`nms=True` flag during export — see B3).
- Maps each `[x1,y1,x2,y2,score,class_id]` row into the existing
  `DetectedObject` value-object so the rest of the Vision pipeline
  doesn't change.
- Reads class names from `assets/models/coco_labels.txt` (80 COCO
  classes — already shipped in this commit).
- Falls back to ML-Kit Object Detector + Image Labeler if the .tflite
  isn't bundled, so the build keeps working before you export weights.

### B2. Vision controller wiring
**File:** [lib/src/features/vision/presentation/vision_controller.dart](lib/src/features/vision/presentation/vision_controller.dart)

`_processObjects()` now:
1. Calls `YoloObjectDetector.create()` (cached singleton).
2. If `isReady`, runs YOLO and uses its detections as the primary set.
3. Else falls back to the legacy ML-Kit detector.
4. Always merges with `ImageLabeler` (broad ImageNet-style hints).

### B3. Export script (one-time, run on a Python machine)
**File:** [scripts/export_yolov13.py](scripts/export_yolov13.py)

```bash
cd "G:/Old Downloads/Ishara/Ishara/ishara app/ishara app/yolov13-main/yolov13-main"
conda create -n yolov13 python=3.11 -y
conda activate yolov13
pip install -r requirements.txt
pip install tensorflow==2.15.0 onnx onnx2tf nvidia-pyindex sng4onnx

# Download YOLOv13n weights (~5 MB) — official release
curl -L -o yolov13n.pt https://github.com/iMoonLab/yolov13/releases/download/v1.0/yolov13n.pt

# Export to TFLite + copy into the Flutter app
python "../../Ishara-main/scripts/export_yolov13.py" --weights yolov13n.pt --imgsz 640
```

For a smaller / faster build:

```bash
python "../../Ishara-main/scripts/export_yolov13.py" --weights yolov13n.pt --int8
```

Output ends up at:

- `assets/models/yolov13n_float16.tflite` (≈ 6 MB)
  *or*
- `assets/models/yolov13n_int8.tflite`    (≈ 2 MB)

Add **one** of those filenames to `pubspec.yaml`'s asset list (the
detector tries all three names automatically — see `_candidateAssets`),
then `flutter pub get`.

### B4. Pubspec changes
- Registered `assets/models/coco_labels.txt`.
- After you produce the TFLite, also add the matching filename:

  ```yaml
  assets:
    - assets/models/yolov13n_float16.tflite   # or _int8.tflite
  ```

### B5. What you still need to do

1. **Run the export script** (B3) to generate the .tflite.
2. **Drop the .tflite into `assets/models/`** and add it to pubspec.
3. **`flutter pub get`** to register the new asset.
4. **`flutter run`** — open the Vision tab → Object mode → point at any
   COCO-class object (cup, laptop, phone, person, banana, …) and you'll
   see specific class names + confidence scores, not just "object".

For a richer label set than COCO 80 (e.g. Open Images 600), train
YOLOv13 on Open Images and replace `coco_labels.txt`. The detector
loader will pick up whatever labels it finds — no code change needed.

---

## C. Sanity-check after the fix

```powershell
flutter analyze
flutter run
```

The pub-get crash should not return (provided VS Code wasn't reopened
between the cleanup and the run). YOLO falls back gracefully if the
.tflite isn't yet bundled, so the app still builds today.
