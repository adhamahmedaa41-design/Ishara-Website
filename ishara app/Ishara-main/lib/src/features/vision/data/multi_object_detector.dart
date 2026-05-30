/// Ensemble object detector that fans a single frame out to **multiple
/// bundled YOLOv8 TFLite models in parallel** and merges the results
/// with cross-model NMS, keeping the most-specific label per region.
///
/// Currently composes three on-device models:
///   * COCO 80 (`yolo_coco.tflite` + `yolo_coco_labels.txt`)
///   * Open Images V7 601 (`yolo_oiv7.tflite` + `yolo_oiv7_labels.txt`)
///   * E-Waste 77 (`yolo_ewaste.tflite` + `yolo_ewaste_labels.txt`)
///
/// Missing bundles are silently skipped so the ensemble degrades
/// gracefully — if you ship just COCO, you still get COCO output.
library;

import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import '../../translator/data/tflite_flutter_web_stub.dart'
    if (dart.library.io) 'package:tflite_flutter/tflite_flutter.dart';

import 'image_labeling_service.dart' show DetectedObject, DetectionSource;

class _Bundle {
  const _Bundle({required this.model, required this.labels, required this.specificity});
  final String model;
  final String labels;
  // Higher = more specific. When two boxes overlap, the higher-specificity
  // detection wins. OIv7 (601 classes) beats COCO (80) which beats nothing.
  // E-Waste (77 niche classes) beats both for the categories it covers.
  final int specificity;
}

class _Detector {
  _Detector(this.interp, this.labels, this.inputSize, this.specificity);
  final Interpreter interp;
  final List<String> labels;
  final int inputSize;
  final int specificity;
}

class MultiObjectDetector {
  MultiObjectDetector._(this._detectors);
  final List<_Detector> _detectors;
  static MultiObjectDetector? _cached;

  static const List<_Bundle> _bundles = [
    _Bundle(
      model: 'assets/models/yolo_oiv7.tflite',
      labels: 'assets/models/yolo_oiv7_labels.txt',
      specificity: 30,
    ),
    _Bundle(
      model: 'assets/models/yolo_ewaste.tflite',
      labels: 'assets/models/yolo_ewaste_labels.txt',
      specificity: 25,
    ),
    _Bundle(
      model: 'assets/models/yolo_coco.tflite',
      labels: 'assets/models/yolo_coco_labels.txt',
      specificity: 10,
    ),
  ];

  static Future<MultiObjectDetector> create() async {
    if (_cached != null) return _cached!;
    final out = <_Detector>[];
    for (final b in _bundles) {
      try {
        await rootBundle.load(b.model);
        final interp = await Interpreter.fromAsset(b.model);
        final raw = await rootBundle.loadString(b.labels);
        final labels = raw
            .split(RegExp(r'\r?\n'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
        var inputSize = 416;
        try {
          final shape = interp.getInputTensors().first.shape;
          if (shape.length == 4 && shape[1] > 0) inputSize = shape[1];
        } catch (_) {}
        out.add(_Detector(interp, labels, inputSize, b.specificity));
      } catch (_) {
        // Bundle missing — skip.
      }
    }
    return _cached = MultiObjectDetector._(out);
  }

  bool get isReady => _detectors.isNotEmpty;

  /// Run every loaded model on the same frame in parallel.
  /// Returns deduplicated [DetectedObject]s with IoU-based cross-model NMS.
  Future<List<DetectedObject>> detect(
    File file, {
    double minConfidence = 0.40,
    int topK = 20,
  }) async {
    if (_detectors.isEmpty) return const [];

    final raw = await file.readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) return const [];
    final imgW = decoded.width.toDouble();
    final imgH = decoded.height.toDouble();

    final futures = <Future<List<_Det>>>[];
    for (final det in _detectors) {
      futures.add(_runOne(det, decoded, minConfidence));
    }
    final allLists = await Future.wait(futures);
    final all = allLists.expand((x) => x).toList();

    // Cross-model NMS: sort by specificity desc, then confidence desc.
    // Drop any later detection whose IoU vs a kept one ≥ 0.45.
    all.sort((a, b) {
      final s = b.specificity.compareTo(a.specificity);
      if (s != 0) return s;
      return b.confidence.compareTo(a.confidence);
    });

    final kept = <_Det>[];
    for (final c in all) {
      var absorb = false;
      for (final k in kept) {
        if (_iou(c, k) >= 0.45) {
          absorb = true;
          break;
        }
      }
      if (!absorb) kept.add(c);
      if (kept.length >= topK) break;
    }

    return kept
        .map((d) => DetectedObject(
              label: d.label,
              confidence: d.confidence,
              boundingBox: Rect.fromLTRB(
                d.x1 * imgW,
                d.y1 * imgH,
                d.x2 * imgW,
                d.y2 * imgH,
              ),
              source: DetectionSource.objectDetector,
            ))
        .toList(growable: false);
  }

  static Future<List<_Det>> _runOne(
    _Detector det,
    img.Image decoded,
    double minConfidence,
  ) async {
    final resized = img.copyResize(
      decoded,
      width: det.inputSize,
      height: det.inputSize,
      interpolation: img.Interpolation.linear,
    );
    final input = List.generate(
      1,
      (_) => List.generate(
        det.inputSize,
        (y) => List.generate(det.inputSize, (x) {
          final p = resized.getPixel(x, y);
          return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
        }),
      ),
    );
    final outShape = det.interp.getOutputTensors().first.shape;
    final n = outShape.length >= 2 ? outShape[outShape.length - 2] : 300;
    final perRow = outShape.last;
    final output = List.generate(
      1,
      (_) => List.generate(n, (_) => List.filled(perRow, 0.0)),
    );
    det.interp.run(input, output);

    final results = <_Det>[];
    final nc = det.labels.length;
    final nmsTrue = perRow == 6;
    final anchorTransposed = perRow == 4 + nc;

    if (nmsTrue) {
      for (final row in output[0]) {
        if (row.length < 6) continue;
        final score = row[4].toDouble();
        final cls = row[5].toInt();
        if (score < minConfidence) continue;
        if (cls < 0 || cls >= nc) continue;
        results.add(_Det(
          label: det.labels[cls],
          confidence: score,
          x1: row[0].toDouble().clamp(0.0, 1.0),
          y1: row[1].toDouble().clamp(0.0, 1.0),
          x2: row[2].toDouble().clamp(0.0, 1.0),
          y2: row[3].toDouble().clamp(0.0, 1.0),
          specificity: det.specificity,
        ));
      }
    } else if (anchorTransposed) {
      for (final row in output[0]) {
        if (row.length < 4 + nc) continue;
        var bestScore = 0.0;
        var bestCls = -1;
        for (var c = 0; c < nc; c++) {
          final v = row[4 + c].toDouble();
          if (v > bestScore) {
            bestScore = v;
            bestCls = c;
          }
        }
        if (bestScore < minConfidence || bestCls < 0) continue;
        // anchor format is centre-xywh
        final cx = row[0].toDouble();
        final cy = row[1].toDouble();
        final w = row[2].toDouble();
        final h = row[3].toDouble();
        results.add(_Det(
          label: det.labels[bestCls],
          confidence: bestScore,
          x1: (cx - w / 2).clamp(0.0, 1.0),
          y1: (cy - h / 2).clamp(0.0, 1.0),
          x2: (cx + w / 2).clamp(0.0, 1.0),
          y2: (cy + h / 2).clamp(0.0, 1.0),
          specificity: det.specificity,
        ));
      }
    }
    return results;
  }

  static double _iou(_Det a, _Det b) {
    final x1 = a.x1 > b.x1 ? a.x1 : b.x1;
    final y1 = a.y1 > b.y1 ? a.y1 : b.y1;
    final x2 = a.x2 < b.x2 ? a.x2 : b.x2;
    final y2 = a.y2 < b.y2 ? a.y2 : b.y2;
    if (x2 <= x1 || y2 <= y1) return 0;
    final inter = (x2 - x1) * (y2 - y1);
    final aArea = (a.x2 - a.x1) * (a.y2 - a.y1);
    final bArea = (b.x2 - b.x1) * (b.y2 - b.y1);
    final union = aArea + bArea - inter;
    return union <= 0 ? 0 : inter / union;
  }

  void dispose() {
    for (final d in _detectors) {
      d.interp.close();
    }
    _cached = null;
  }
}

class _Det {
  _Det({
    required this.label,
    required this.confidence,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.specificity,
  });
  final String label;
  final double confidence;
  final double x1, y1, x2, y2;
  final int specificity;
}
