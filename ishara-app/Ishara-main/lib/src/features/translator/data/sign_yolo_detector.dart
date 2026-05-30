/// On-device YOLO-based sign-language detector.
///
/// This is the **fast path** that replaces the broken MediaPipe-pose →
/// 1692-dim-LSTM pipeline. It runs an Ultralytics-exported YOLOv8 TFLite
/// (trained on Roboflow Arabic Sign Language datasets) on each camera
/// frame and returns the top-1 detected sign with confidence.
///
/// Output layout matches the Ultralytics export with `nms=True`:
/// `[1, N, 6]` rows = `[x1, y1, x2, y2, score, class_id]` in normalised
/// coords. The translator only needs the label, not boxes, so coordinates
/// are dropped after the score check.
///
/// Required assets (drop-in once trained — see scripts/train_sign_yolo.py):
///   * `assets/models/sign_yolo.tflite`
///   * `assets/models/sign_labels.txt`  (one class per line, English)
///
/// Arabic display names live in [signLabelArabic]; the translator screen
/// maps an English label to its Arabic gloss before showing / speaking it.
library;

import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
// Conditional import: dart:ffi (and therefore tflite_flutter) is unavailable
// on web, so swap to a no-op stub when compiling for the web target.
import 'tflite_flutter_web_stub.dart'
    if (dart.library.io) 'package:tflite_flutter/tflite_flutter.dart';

class SignDetection {
  const SignDetection({
    required this.labelEnglish,
    required this.labelArabic,
    required this.confidence,
  });
  final String labelEnglish;
  final String labelArabic;
  final double confidence;
}

/// English → Arabic display map. Populate with every class that appears in
/// `assets/models/sign_labels.txt`. Anything missing falls back to the
/// English token so nothing crashes.
const signLabelArabic = <String, String>{
  // 10-class Arabic-sign-language-translator-ijbp3 v7
  'Smile': 'ابتسامة',
  'Thanks': 'شكراً',
  'Love': 'حب',
  'Sorry': 'آسف',
  'Mother': 'أم',
  'You': 'أنت',
  'Fine': 'بخير',
  'Hello': 'مرحباً',
  'Yes': 'نعم',
  'No': 'لا',
  // ── Sign Words Extended (xpq5z, 120 classes) Arabic gloss ──────────
  // Anything not pre-translated falls through to its English label so
  // the user always gets *something* on screen.
  // Restaurant / food domain (the dataset is restaurant-context).
  'A': 'أ', 'B': 'ب', 'C': 'ج', 'D': 'د', 'E': 'هـ', 'F': 'ف',
  'G': 'ج', 'H': 'هـ', 'I': 'ي', 'J': 'ج', 'K': 'ك', 'L': 'ل',
  'M': 'م', 'N': 'ن', 'O': 'و', 'P': 'پ', 'Q': 'ق', 'R': 'ر',
  'S': 'س', 'T': 'ت', 'U': 'و', 'V': 'ڤ', 'W': 'و', 'X': 'كس',
  'Y': 'ي', 'Z': 'ز',
  'additional': 'إضافي',
  'alcohol': 'كحول',
  'allergy': 'حساسية',
  'bacon': 'لحم مقدد',
  'bad': 'سيء',
  'bag': 'حقيبة',
  'barbecue': 'مشوي',
  'bill': 'فاتورة',
  'biscuit': 'بسكويت',
  'bitter': 'مر',
  'bread': 'خبز',
  'burger': 'برجر',
  'bye': 'مع السلامة',
  'cake': 'كيكة',
  'cash': 'نقد',
  'cheese': 'جبن',
  'chicken': 'دجاج',
  'coke': 'كولا',
  'cold': 'بارد',
  'correct': 'صحيح',
  'cost': 'سعر',
  'coupon': 'كوبون',
  'credit card': 'بطاقة ائتمان',
  'cup': 'كوب',
  'dessert': 'حلوى',
  'don-t want': 'لا أريد',
  'drink': 'مشروب',
  'drive': 'يقود',
  'eat': 'أكل',
  'eggs': 'بيض',
  'enjoy': 'استمتع',
  'fine': 'بخير',
  'forget': 'انسى',
  'fork': 'شوكة',
  'french fries': 'بطاطا مقلية',
  'fresh': 'طازج',
  'go': 'يذهب',
  'hello': 'مرحباً',
  'help': 'مساعدة',
  'hot': 'حار',
  'icecream': 'آيس كريم',
  'ingredients': 'مكونات',
  'juicy': 'مليء بالعصير',
  'ketchup': 'كاتشب',
  'lactose': 'لاكتوز',
  'lettuce': 'خس',
  'lid': 'غطاء',
  'like': 'يحب',
  'manager': 'مدير',
  'menu': 'قائمة',
  'milk': 'حليب',
  'more': 'المزيد',
  'mustard': 'خردل',
  'napkin': 'منديل',
  'need': 'يحتاج',
  'no': 'لا',
  'not': 'ليس',
  'order': 'طلب',
  'pepper': 'فلفل',
  'pickle': 'مخلل',
  'pizza': 'بيتزا',
  'please': 'من فضلك',
  'ready': 'جاهز',
  'receipt': 'إيصال',
  'refill': 'إعادة ملء',
  'repeat': 'كرر',
  'safe': 'آمن',
  'salt': 'ملح',
  'sandwich': 'ساندويتش',
  'sauce': 'صلصة',
  'small': 'صغير',
  'soda': 'صودا',
  'sorry': 'آسف',
  'spicy': 'حار التوابل',
  'spoon': 'ملعقة',
  'straw': 'شاليموه',
  'sugar': 'سكر',
  'sweet': 'حلو',
  'thank-you': 'شكراً',
  'tissues': 'مناديل',
  'tomato': 'طماطم',
  'total': 'الإجمالي',
  'urgent': 'عاجل',
  'vegetables': 'خضروات',
  'wait': 'انتظر',
  'want': 'يريد',
  'warm': 'دافئ',
  'water': 'ماء',
  'what': 'ماذا',
  'would': 'سـ',
  'wrong': 'خطأ',
  'yes': 'نعم',
  'yoghurt': 'زبادي',
  'your': 'لك',
};

class SignYoloDetector {
  SignYoloDetector._(this._interpreter, this._labels, this._inputSize);

  final Interpreter? _interpreter;
  final List<String> _labels;
  final int _inputSize;

  static SignYoloDetector? _cached;

  /// Single Arabic-10 bundle. First-existing wins.
  static const List<String> _modelCandidates = <String>[
    'assets/models/sign_yolo_int8.tflite',
    'assets/models/sign_yolo_float16.tflite',
    'assets/models/sign_yolo.tflite',
  ];
  static const String _labelsPath = 'assets/models/sign_labels.txt';

  static Future<SignYoloDetector> create() async {
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
        final shape = interp.getInputTensors().first.shape;
        if (shape.length == 4 && shape[1] > 0) inputSize = shape[1];
      } catch (_) {}
    }
    final det = SignYoloDetector._(interp, labels, inputSize);
    _cached = det;
    return det;
  }

  bool get isReady => _interpreter != null && _labels.isNotEmpty;
  int get inputSize => _inputSize;

  /// Returns the highest-confidence sign detection for the given still
  /// image, or null if nothing crosses the threshold.
  ///
  /// **Output-shape handling** — Ultralytics' TFLite export ships two
  /// distinct layouts depending on the `nms` flag at export time:
  ///   * **NMS-True**: shape `[1, N, 6]`, rows = `[x1, y1, x2, y2, score, class_id]`.
  ///   * **NMS-False (anchor-based)**: shape `[1, 4 + num_classes, 8400]`
  ///     (often transposed to `[1, 8400, 4 + num_classes]`), rows =
  ///     `[cx, cy, w, h, cls_0, cls_1, …]` and we need to argmax over
  ///     the class slots to get a score + class index.
  /// The model files we ship were exported with `nms=True`, but some
  /// Ultralytics versions silently fall back to the anchor format when
  /// they detect post-processing issues. Detecting which layout we got
  /// and parsing both prevents the silent "zero detections" failure
  /// mode.
  Future<SignDetection?> detect(File file, {double minConfidence = 0.30}) async {
    final interp = _interpreter;
    if (interp == null || _labels.isEmpty) return null;

    final raw = await file.readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) return null;

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
    if (outputShape.length < 3) {
      dev.log(
        'unexpected output shape: $outputShape',
        name: 'sign_yolo',
      );
      return null;
    }
    final d1 = outputShape[outputShape.length - 2];
    final d2 = outputShape.last;
    final output = List.generate(
      1,
      (_) => List.generate(d1, (_) => List.filled(d2, 0.0)),
    );

    interp.run(input, output);

    final numClasses = _labels.length;
    final nmsTrueFormat = d2 == 6;
    final anchorTransposed = d2 == 4 + numClasses; // [1, N, 4+nc]
    final anchorRaw = d1 == 4 + numClasses; // [1, 4+nc, N]

    SignDetection? best;
    int sawAboveZero = 0;
    int sawAboveThreshold = 0;
    double maxSeen = 0;

    void consider(double score, int clsIdx) {
      if (score > maxSeen) maxSeen = score;
      if (score > 0) sawAboveZero++;
      if (score < minConfidence) return;
      sawAboveThreshold++;
      if (clsIdx < 0 || clsIdx >= numClasses) return;
      if (best != null && score <= best!.confidence) return;
      final eng = _labels[clsIdx];
      best = SignDetection(
        labelEnglish: eng,
        labelArabic: signLabelArabic[eng] ??
            signLabelArabic[eng.toLowerCase()] ??
            eng,
        confidence: score,
      );
    }

    if (nmsTrueFormat) {
      for (final row in output[0]) {
        if (row.length < 6) continue;
        consider(row[4].toDouble(), row[5].toInt());
      }
    } else if (anchorTransposed) {
      // `[1, N, 4+nc]` — each row is [cx, cy, w, h, cls_0, …, cls_{nc-1}]
      for (final row in output[0]) {
        if (row.length < 4 + numClasses) continue;
        double bestScore = 0;
        int bestCls = -1;
        for (var c = 0; c < numClasses; c++) {
          final v = row[4 + c].toDouble();
          if (v > bestScore) {
            bestScore = v;
            bestCls = c;
          }
        }
        consider(bestScore, bestCls);
      }
    } else if (anchorRaw) {
      // `[1, 4+nc, N]` — channels-first; argmax across the class
      // channels for each anchor index.
      final rows = output[0]; // length == 4+nc
      final anchorCount = d2;
      for (var i = 0; i < anchorCount; i++) {
        double bestScore = 0;
        int bestCls = -1;
        for (var c = 0; c < numClasses; c++) {
          final v = rows[4 + c][i].toDouble();
          if (v > bestScore) {
            bestScore = v;
            bestCls = c;
          }
        }
        consider(bestScore, bestCls);
      }
    } else {
      dev.log(
        'unrecognised output shape $outputShape '
        '(numClasses=$numClasses) — no detections will be emitted. '
        'Re-export the TFLite from Ultralytics with `nms=True` to fix.',
        name: 'sign_yolo',
      );
      return null;
    }

    dev.log(
      'detect shape=$outputShape format=${nmsTrueFormat ? "nms" : anchorTransposed ? "anchor_t" : "anchor_raw"} '
      'rawAboveZero=$sawAboveZero aboveThr=$sawAboveThreshold '
      'maxConf=${maxSeen.toStringAsFixed(2)} '
      'best=${best?.labelEnglish}/${best?.confidence.toStringAsFixed(2)}',
      name: 'sign_yolo',
    );

    return best;
  }

  void dispose() {
    _interpreter?.close();
    _cached = null;
  }
}
