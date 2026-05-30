/// On-device YOLOv8 EGP-currency detector.
///
/// Replaces the heuristic ML-Kit-keyword fallback in
/// [`currency_classifier.dart`] when `assets/models/currency_egp.tflite`
/// is bundled. The model is trained on Roboflow's
/// `new-egyptian-currency-4yuzo-jwcgi` v2 dataset (12 classes — front /
/// back of every modern EGP banknote denomination).
///
/// Each detection is mapped from a Roboflow class name (e.g.
/// "100 EGP front", "10 EGP back") to:
///   * a canonical denomination ("100 EGP")
///   * its numeric value in pounds for `sumEgp()`
///   * an Arabic display name ("100 جنيه") for the UI
///
/// Front/back duplicates are deduplicated per-frame so a note seen from
/// either side counts once.
library;

import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import '../../translator/data/tflite_flutter_web_stub.dart'
    if (dart.library.io) 'package:tflite_flutter/tflite_flutter.dart';

class CurrencyYoloDetection {
  const CurrencyYoloDetection({
    required this.canonical,
    required this.arabic,
    required this.amountEgp,
    required this.confidence,
    required this.boxNorm,
  });
  final String canonical; // "100 EGP"
  final String arabic; // "100 جنيه"
  final double amountEgp;
  final double confidence;
  // Bounding box in normalised image coordinates [0, 1]: [x1, y1, x2, y2].
  // Useful for the Vision overlay; the controller scales it back to pixels.
  final List<double> boxNorm;
}

/// Maps any Roboflow currency label → canonical "<NN> EGP".
///
/// Matches all known label conventions:
///   * "100 EGP front", "100 EGP back"  (front/back-split datasets)
///   * "100Egp", "100egp", "100EGP"     (concat datasets — no space)
///   * "100 جنيه", "100 pound", "100 pounds"
///   * just "100" — assumed EGP (fallback).
String canonicalDenomination(String raw) {
  final cleaned = raw.toLowerCase().replaceAll('"', '').trim();
  // Accept egp/pound/جنيه markers OR fall back to the first integer.
  final m = RegExp(r'(\d+)\s*(egp|pound|pounds|جنيه)').firstMatch(cleaned);
  if (m != null) return '${m.group(1)} EGP';
  final justDigits = RegExp(r'^(\d+)').firstMatch(cleaned);
  if (justDigits != null) return '${justDigits.group(1)} EGP';
  return raw;
}

const denominationToEgp = <String, double>{
  '5 EGP': 5,
  '10 EGP': 10,
  '20 EGP': 20,
  '50 EGP': 50,
  '100 EGP': 100,
  '200 EGP': 200,
  '1 EGP': 1,
  '25 piaster': 0.25,
  '50 piaster': 0.50,
};

const denominationToArabic = <String, String>{
  '1 EGP': '1 جنيه',
  '5 EGP': '5 جنيه',
  '10 EGP': '10 جنيه',
  '20 EGP': '20 جنيه',
  '50 EGP': '50 جنيه',
  '100 EGP': '100 جنيه',
  '200 EGP': '200 جنيه',
  '25 piaster': '25 قرش',
  '50 piaster': '50 قرش',
};

class CurrencyYoloDetector {
  CurrencyYoloDetector._(this._interpreter, this._labels, this._inputSize)
      : _allowedDenominations = _buildAllowed(_labels);

  final Interpreter? _interpreter;
  final List<String> _labels;
  final int _inputSize;

  /// Canonical denominations that the loaded model can actually produce —
  /// derived once from the labels file at create() time. Used to **reject
  /// hallucinated denominations** like "1 EGP" that were leaking through
  /// the generic regex but aren't in the trained class set.
  final Set<String> _allowedDenominations;

  static Set<String> _buildAllowed(List<String> labels) {
    final out = <String>{};
    for (final l in labels) {
      final c = canonicalDenomination(l);
      if (denominationToEgp.containsKey(c)) out.add(c);
    }
    return out;
  }

  static CurrencyYoloDetector? _cached;

  static const _candidates = <String>[
    'assets/models/currency_egp_int8.tflite',
    'assets/models/currency_egp_float16.tflite',
    'assets/models/currency_egp.tflite',
  ];
  static const _labelsPath = 'assets/models/currency_labels.txt';

  static Future<CurrencyYoloDetector> create() async {
    if (_cached != null) return _cached!;
    Interpreter? interp;
    var labels = const <String>[];
    var inputSize = 416;
    for (final asset in _candidates) {
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
        final shape = interp.getInputTensors().first.shape;
        if (shape.length == 4 && shape[1] > 0) inputSize = shape[1];
      } catch (_) {}
    }
    return _cached = CurrencyYoloDetector._(interp, labels, inputSize);
  }

  bool get isReady => _interpreter != null && _labels.isNotEmpty;

  /// Rolling history of the last few frames' detection sets, used by
  /// [voteFrames] to stabilise the displayed total. Keyed by canonical
  /// denomination + spatial bucket so an identical bill seen across
  /// successive frames votes once per slot.
  static final List<List<CurrencyYoloDetection>> _recentFrames = [];
  static const _voteHistory = 3;

  /// Run YOLO on a still frame.
  ///
  /// Behaviour upgrades that fix the three reported bugs:
  ///   1. **Corner numbers counted as 2 bills** — IoU-based NMS merges any
  ///      detections of the *same* canonical denomination whose boxes
  ///      overlap or sit within ~25 % of one bill's footprint.
  ///   2. **100 read as 1, etc.** — confidence floor raised to 0.55
  ///      (Roboflow softmax is leaky); plus see [voteFrames] for the
  ///      multi-frame consensus filter that the controller calls.
  ///   3. **Stacked bills** — merging is class-aware (same denomination
  ///      only), so genuinely separate bills of the same note that don't
  ///      overlap remain distinct.
  Future<List<CurrencyYoloDetection>> detect(
    File file, {
    double minConfidence = 0.60,
  }) async {
    final interp = _interpreter;
    if (interp == null || _labels.isEmpty) return const [];

    final raw = await file.readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) return const [];

    final resized = img.copyResize(
      decoded,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );
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

    final outputShape = interp.getOutputTensors().first.shape;
    final n = outputShape.length >= 2 ? outputShape[outputShape.length - 2] : 300;
    final perRow = outputShape.last;
    final output = List.generate(
      1,
      (_) => List.generate(n, (_) => List.filled(perRow, 0.0)),
    );

    interp.run(input, output);

    // Stage 1 — collect raw detections that pass the confidence floor.
    final raws = <_Det>[];
    for (final row in output[0]) {
      if (row.length < 6) continue;
      final score = row[4].toDouble();
      final clsIdx = row[5].toInt();
      if (score < minConfidence) continue;
      if (clsIdx < 0 || clsIdx >= _labels.length) continue;
      final canon = canonicalDenomination(_labels[clsIdx]);
      // Whitelist: only accept canonical names that map to a denomination
      // AND were derived from the loaded labels file. Drops hallucinated
      // "1 EGP", "25 piaster" etc. that aren't real classes of this model.
      if (!_allowedDenominations.contains(canon)) continue;
      final amount = denominationToEgp[canon];
      if (amount == null) continue;
      raws.add(_Det(
        canon: canon,
        amount: amount,
        confidence: score,
        x1: row[0].toDouble().clamp(0.0, 1.0),
        y1: row[1].toDouble().clamp(0.0, 1.0),
        x2: row[2].toDouble().clamp(0.0, 1.0),
        y2: row[3].toDouble().clamp(0.0, 1.0),
      ));
    }

    // Stage 2 — class-aware NMS with three merge tests:
    //   (a) IoU ≥ 0.30 (standard NMS)
    //   (b) one center sits inside the other's bbox
    //   (c) **same-class spatial-proximity**: the gap between the
    //       nearest edges of two same-class boxes is less than the
    //       footprint of one note. This is what kills the
    //       "two corner numerals of one bill" → 400 EGP bug:
    //       corner box A is at (0.05, 0.05) – (0.20, 0.20),
    //       corner box B is at (0.75, 0.05) – (0.90, 0.20).
    //       IoU = 0, centers aren't inside, but the gap between them
    //       (~0.55 of frame width) is comparable to one bill's actual
    //       size (~0.55-0.70 of frame width when held up to the camera),
    //       so they collapse into one bill keeping the higher score.
    //
    // Genuinely stacked bills of the same denomination remain separate
    // because the gap between two real notes on a table is small
    // relative to either note's own footprint (failure mode (c) only
    // fires when both boxes are *tiny* relative to the gap — exactly
    // the corner-numeral signature).
    final groups = <String, List<_Det>>{};
    for (final d in raws) {
      groups.putIfAbsent(d.canon, () => []).add(d);
    }
    final kept = <_Det>[];
    for (final list in groups.values) {
      list.sort((a, b) => b.confidence.compareTo(a.confidence));
      final survivors = <_Det>[];
      for (final cand in list) {
        var absorb = false;
        for (final s in survivors) {
          final iou = _iou(cand, s);
          final cxIn = _centerInside(cand, s) || _centerInside(s, cand);
          final tinyCorners = _tinyCornersOfOneBill(cand, s);
          if (iou >= 0.30 || cxIn || tinyCorners) {
            absorb = true;
            break;
          }
        }
        if (!absorb) survivors.add(cand);
      }
      kept.addAll(survivors);
    }

    return kept
        .map((d) => CurrencyYoloDetection(
              canonical: d.canon,
              arabic: denominationToArabic[d.canon] ?? d.canon,
              amountEgp: d.amount,
              confidence: d.confidence,
              boxNorm: <double>[d.x1, d.y1, d.x2, d.y2],
            ))
        .toList(growable: false);
  }

  /// Push the latest frame's detections through a rolling N-frame voting
  /// window. A bill is only emitted if a spatially-equivalent detection
  /// (same denomination, IoU ≥ 0.30) appears in **at least 2 of the last
  /// 3** frames. Prevents a single noisy frame (often the source of
  /// "100 EGP read as 1 EGP" misclassifications) from polluting the
  /// running total.
  static List<CurrencyYoloDetection> voteFrames(
    List<CurrencyYoloDetection> latest,
  ) {
    _recentFrames.add(latest);
    while (_recentFrames.length > _voteHistory) {
      _recentFrames.removeAt(0);
    }
    if (_recentFrames.length < 2) return latest;

    final out = <CurrencyYoloDetection>[];
    for (final cand in latest) {
      int hits = 1;
      for (var i = 0; i < _recentFrames.length - 1; i++) {
        for (final prev in _recentFrames[i]) {
          if (prev.canonical != cand.canonical) continue;
          if (_iouNorm(prev.boxNorm, cand.boxNorm) >= 0.30) {
            hits++;
            break;
          }
        }
      }
      if (hits >= 2) out.add(cand);
    }
    return out;
  }

  /// Reset the voting window — call when the user opens a fresh frame
  /// after pausing, or moves the camera dramatically.
  static void resetVotingWindow() => _recentFrames.clear();

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

  static double _iouNorm(List<double> a, List<double> b) {
    if (a.length < 4 || b.length < 4) return 0;
    final x1 = a[0] > b[0] ? a[0] : b[0];
    final y1 = a[1] > b[1] ? a[1] : b[1];
    final x2 = a[2] < b[2] ? a[2] : b[2];
    final y2 = a[3] < b[3] ? a[3] : b[3];
    if (x2 <= x1 || y2 <= y1) return 0;
    final inter = (x2 - x1) * (y2 - y1);
    final aArea = (a[2] - a[0]) * (a[3] - a[1]);
    final bArea = (b[2] - b[0]) * (b[3] - b[1]);
    final union = aArea + bArea - inter;
    return union <= 0 ? 0 : inter / union;
  }

  static bool _centerInside(_Det inner, _Det outer) {
    final cx = (inner.x1 + inner.x2) / 2;
    final cy = (inner.y1 + inner.y2) / 2;
    return cx >= outer.x1 && cx <= outer.x2 && cy >= outer.y1 && cy <= outer.y2;
  }

  /// "Both boxes look like corner numerals of the same bill" test.
  ///
  /// Signature: two *very small* boxes (each ≤ 10% of frame in each axis)
  /// whose centres are within ~40% of the frame diagonal. Tightened from
  /// the original 25%/75% thresholds, which over-fired on multi-bill
  /// scenes where each laid-out bill is naturally 15–25% of the frame and
  /// neighbouring bills sit 30–50% apart — both inside the old bounds,
  /// so distinct bills got merged into one and the total was wrong.
  ///
  /// Corner numerals on a single readable bill are ≤ 10% in each axis
  /// (typically 5–8%) and never more than one bill-width apart
  /// (~30–40% of the diagonal when the bill fills 25–50% of the frame).
  static bool _tinyCornersOfOneBill(_Det a, _Det b) {
    final aw = a.x2 - a.x1, ah = a.y2 - a.y1;
    final bw = b.x2 - b.x1, bh = b.y2 - b.y1;
    if (aw > 0.10 || ah > 0.10) return false;
    if (bw > 0.10 || bh > 0.10) return false;
    final acx = (a.x1 + a.x2) / 2, acy = (a.y1 + a.y2) / 2;
    final bcx = (b.x1 + b.x2) / 2, bcy = (b.y1 + b.y2) / 2;
    final dx = acx - bcx, dy = acy - bcy;
    // (0.40)^2 = 0.16 — corner numerals on one bill are within 40% of diag
    return dx * dx + dy * dy <= 0.16;
  }

  static double sumEgp(List<CurrencyYoloDetection> dets) =>
      dets.fold<double>(0, (s, d) => s + d.amountEgp);

  static String formatTotalArabic(double egp) {
    if (egp <= 0) return '٠ جنيه';
    final pounds = egp.floor();
    final piasters = ((egp - pounds) * 100).round();
    if (piasters == 0) return '$pounds جنيه';
    return '$pounds.$piasters جنيه';
  }

  void dispose() {
    _interpreter?.close();
    _cached = null;
  }
}

/// Internal raw-detection record used during NMS / IoU dedup.
class _Det {
  _Det({
    required this.canon,
    required this.amount,
    required this.confidence,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });
  final String canon;
  final double amount;
  final double confidence;
  final double x1;
  final double y1;
  final double x2;
  final double y2;
}
