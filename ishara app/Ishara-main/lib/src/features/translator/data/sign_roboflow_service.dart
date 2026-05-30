/// Web-friendly fallback for sign-language inference: posts a frame to
/// the Roboflow Hosted Detect API and parses the predictions.
///
/// We trained the YOLO weights locally (Ultralytics) for the bundled
/// `sign_yolo.tflite`, but the **same dataset** is also hosted by the
/// Roboflow project (`arabic-sign-language-translator-ijbp3` v7) which
/// already serves a deployed model behind the Detect API. That means we
/// don't need to host anything ourselves — just call:
///
///     POST https://detect.roboflow.com/<project>/<version>?api_key=<key>
///         Content-Type: application/x-www-form-urlencoded
///         body: <base64-encoded JPEG bytes>
///
/// Returns:
///     { "predictions": [
///         {"x":..,"y":..,"width":..,"height":..,"confidence":..,"class":".."}
///       ] }
///
/// Used by [SignYoloLiveScreen] on web (where dart:ffi / TFLite are
/// unavailable). On Android / iOS we keep the on-device [SignYoloDetector]
/// path so detection stays free + offline.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'sign_yolo_detector.dart' show SignDetection, signLabelArabic;

class SignRoboflowService {
  SignRoboflowService({
    this.apiKey = _defaultApiKey,
    this.project = _defaultProject,
    this.version = _defaultVersion,
  });

  // Public Universe project we already trained on; the API key is the
  // user's free Roboflow private key (only useful for read access).
  static const _defaultApiKey = 'oCC7zcTRuhcJYC39831S';
  static const _defaultProject = 'arabic-sign-language-translator-ijbp3';
  static const _defaultVersion = 7;

  final String apiKey;
  final String project;
  final int version;

  Uri get _endpoint => Uri.parse(
        'https://detect.roboflow.com/$project/$version?api_key=$apiKey',
      );

  /// Posts the JPEG/PNG bytes to Roboflow Detect and returns the highest-
  /// confidence sign detection (or null below threshold).
  Future<SignDetection?> detect(
    Uint8List imageBytes, {
    double minConfidence = 0.40,
  }) async {
    try {
      final body = base64Encode(imageBytes);
      final r = await http
          .post(
            _endpoint,
            headers: const {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));
      if (r.statusCode < 200 || r.statusCode >= 300) return null;
      final decoded = jsonDecode(r.body) as Map<String, dynamic>;
      final preds = (decoded['predictions'] as List? ?? const []);
      SignDetection? best;
      for (final p in preds) {
        final m = Map<String, dynamic>.from(p as Map);
        final score = (m['confidence'] is num)
            ? (m['confidence'] as num).toDouble()
            : 0.0;
        final cls = (m['class'] ?? '').toString();
        if (score < minConfidence) continue;
        if (best != null && score <= best.confidence) continue;
        best = SignDetection(
          labelEnglish: cls,
          labelArabic:
              signLabelArabic[cls] ?? signLabelArabic[cls.toLowerCase()] ?? cls,
          confidence: score,
        );
      }
      return best;
    } catch (_) {
      return null;
    }
  }
}
