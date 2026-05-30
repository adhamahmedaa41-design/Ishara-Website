/// YOLOv13 object detector running on-device via `tflite_flutter`.
///
/// Expects an exported TFLite at `assets/models/yolov13n_float16.tflite`
/// (or `_int8.tflite`) plus the COCO label set at
/// `assets/models/coco_labels.txt`. See `scripts/export_yolov13.py` for
/// the one-time export pipeline.
///
/// Output handling
/// ---------------
/// Ultralytics' TFLite export with `nms=True` produces a single tensor
/// shaped `[1, N, 6]` where each row is
/// `[x1, y1, x2, y2, score, class_id]` in normalised image coords (0-1).
/// We filter by [minConfidence] and apply a final per-frame top-K cap.
///
/// If the model file is missing, [isReady] returns false and the
/// vision controller falls back to its existing ML-Kit object detector.
library;

import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import '../../translator/data/tflite_flutter_web_stub.dart'
    if (dart.library.io) 'package:tflite_flutter/tflite_flutter.dart';

import 'image_labeling_service.dart' show DetectedObject, DetectionSource;

class YoloObjectDetector {
  YoloObjectDetector._(this._interpreter, this._labels, this._inputSize);

  final Interpreter? _interpreter;
  final List<String> _labels;
  final int _inputSize;

  static YoloObjectDetector? _cached;

  /// Single COCO YOLO bundle. First existing file wins; falls back
  /// across float16 / int8 / generic naming.
  static const List<String> _modelCandidates = <String>[
    'assets/models/yolov13n_float16.tflite',
    'assets/models/yolov13n_int8.tflite',
    'assets/models/yolov13n.tflite',
  ];
  static const String _labelsPath = 'assets/models/coco_labels.txt';

  static Future<YoloObjectDetector> create() async {
    final cached = _cached;
    if (cached != null) return cached;

    Interpreter? interp;
    var labels = const <String>[];
    var inputSize = 640;

    for (final asset in _modelCandidates) {
      try {
        await rootBundle.load(asset);
        interp = await Interpreter.fromAsset(asset);
        break;
      } catch (_) {
        continue;
      }
    }

    if (interp != null) {
      try {
        final raw = await rootBundle.loadString(_labelsPath);
        labels = raw
            .split(RegExp(r'\r?\n'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      } catch (_) {}
      try {
        final shape = interp.getInputTensors().first.shape; // [1, H, W, 3]
        if (shape.length == 4 && shape[1] > 0) inputSize = shape[1];
      } catch (_) {}
    }

    final detector = YoloObjectDetector._(interp, labels, inputSize);
    _cached = detector;
    return detector;
  }

  bool get isReady => _interpreter != null && _labels.isNotEmpty;
  int get inputSize => _inputSize;

  /// Run inference on a still image file (camera capture or gallery pick).
  Future<List<DetectedObject>> detect(
    File file, {
    double minConfidence = 0.40,
    int topK = 12,
  }) async {
    final interp = _interpreter;
    if (interp == null || _labels.isEmpty) return const [];

    final raw = await file.readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) return const [];
    final originalW = decoded.width.toDouble();
    final originalH = decoded.height.toDouble();

    // Letterbox resize to inputSize × inputSize.
    final resized = img.copyResize(
      decoded,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // [1, H, W, 3] float32 normalised to 0-1.
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(_inputSize, (x) {
          final p = resized.getPixel(x, y);
          return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
        }),
      ),
    );

    // Output buffer sized for the worst case (300 detections × 6 floats).
    final outputShape = interp.getOutputTensors().first.shape;
    final n = outputShape.length >= 2 ? outputShape[outputShape.length - 2] : 300;
    final perRow = outputShape.last;
    final output = List.generate(
      1,
      (_) => List.generate(n, (_) => List.filled(perRow, 0.0)),
    );

    interp.run(input, output);

    final detections = <DetectedObject>[];
    for (final row in output[0]) {
      if (row.length < 6) continue;
      final x1 = row[0].toDouble();
      final y1 = row[1].toDouble();
      final x2 = row[2].toDouble();
      final y2 = row[3].toDouble();
      final score = row[4].toDouble();
      final clsIdx = row[5].toInt();
      if (score < minConfidence) continue;
      if (clsIdx < 0 || clsIdx >= _labels.length) continue;
      detections.add(
        DetectedObject(
          label: _labels[clsIdx],
          confidence: score,
          boundingBox: Rect.fromLTRB(
            x1 * originalW,
            y1 * originalH,
            x2 * originalW,
            y2 * originalH,
          ),
          source: DetectionSource.objectDetector,
        ),
      );
    }

    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    if (detections.length > topK) {
      return detections.sublist(0, topK);
    }
    return detections;
  }

  void dispose() {
    _interpreter?.close();
    _cached = null;
  }
}
