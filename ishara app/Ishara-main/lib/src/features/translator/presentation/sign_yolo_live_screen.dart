/// Live YOLO sign-language translator screen.
///
/// This is the fast path — bypasses the existing MediaPipe-pose / 1692-dim
/// LSTM pipeline (which has a known camera-desync bug on some Samsung
/// devices) and instead runs the YOLOv8 sign detector
/// ([SignYoloDetector]) on a still frame captured every ~700 ms.
///
/// Detected sign → Arabic display name (via the [signLabelArabic] map) →
/// TTS (`flutter_tts` already configured in [TtsService]) → on-screen
/// label with confidence ring.
///
/// Hard-fails gracefully when `assets/models/sign_yolo.tflite` is missing;
/// the user is told to train via `scripts/train_sign_yolo.py`.
library;

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/tts_service.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';
import '../data/sign_roboflow_service.dart';
import '../data/sign_yolo_detector.dart';

class SignYoloLiveScreen extends ConsumerStatefulWidget {
  const SignYoloLiveScreen({super.key});

  @override
  ConsumerState<SignYoloLiveScreen> createState() => _SignYoloLiveScreenState();
}

class _SignYoloLiveScreenState extends ConsumerState<SignYoloLiveScreen> {
  CameraController? _camera;
  SignYoloDetector? _detector; // native (TFLite) path
  SignRoboflowService? _remote; // web (Hosted Inference API) path
  Timer? _loopTimer;
  bool _busy = false;
  SignDetection? _last;
  String? _error;
  // Ring buffer of recently-spoken signs to debounce TTS repetition.
  final List<String> _recent = [];
  String _sentence = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _error = null);
    try {
      // Permission handler is unsupported on web; the camera plugin
      // negotiates getUserMedia() permission directly when initialised.
      if (!kIsWeb) {
        final granted = await Permission.camera.request();
        if (!granted.isGranted) {
          setState(() => _error = 'Camera permission was denied.');
          return;
        }
      }

      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() => _error =
            'No camera detected. On web, allow camera access in Chrome and reload the page.');
        return;
      }

      final front = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      // Web ignores `imageFormatGroup`; use a sensible mobile-only choice.
      final ctrl = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: kIsWeb ? null : ImageFormatGroup.yuv420,
      );

      try {
        await ctrl.initialize().timeout(const Duration(seconds: 12));
      } on TimeoutException {
        setState(() => _error =
            'Camera initialisation timed out. Click the camera icon in the address bar, allow camera access, and tap Retry.');
        return;
      } catch (e) {
        setState(() => _error = 'Could not start camera: $e');
        return;
      }

      // Single bundled Arabic sign model. Web uses Roboflow Hosted; on
      // mobile we go straight to on-device.
      if (kIsWeb) {
        _remote = SignRoboflowService();
      } else {
        final det = await SignYoloDetector.create();
        if (!det.isReady) {
          setState(() => _error =
              'Sign YOLO model not bundled. Run scripts/train_sign_yolo.py and rebuild the app.');
          return;
        }
        _detector = det;
      }

      if (!mounted) return;
      setState(() => _camera = ctrl);
      _loopTimer =
          Timer.periodic(const Duration(milliseconds: 700), (_) => _tick());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Setup failed: $e');
    }
  }

  Future<void> _tick() async {
    if (_busy) return;
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    if (!kIsWeb && _detector == null) return;
    if (kIsWeb && _remote == null) return;
    _busy = true;
    try {
      final shot = await cam.takePicture();
      final bytes = await shot.readAsBytes();

      SignDetection? result;
      if (kIsWeb) {
        result = await _remote!.detect(bytes, minConfidence: 0.40);
      } else {
        result = await _detector!.detect(File(shot.path), minConfidence: 0.30);
        try {
          await File(shot.path).delete();
        } catch (_) {}
      }

      if (!mounted) return;
      if (result == null) {
        setState(() => _last = null);
      } else {
        final detection = result;
        setState(() {
          _last = detection;
          // Append to running sentence with debouncing.
          if (_recent.isEmpty || _recent.last != detection.labelArabic) {
            _recent.add(detection.labelArabic);
            if (_recent.length > 8) _recent.removeAt(0);
            _sentence = _recent.join(' • ');
            // Speak the new word once.
            unawaited(ref.read(ttsServiceProvider).speak(detection.labelArabic));
          }
        });
      }
    } catch (_) {
      // Silent — next tick will try again.
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _camera?.dispose();
    _detector?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    return Scaffold(
      backgroundColor: const Color(0xFF050911),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const IsharaStatusPill(
              label: 'LIVE',
              tone: IsharaStatusTone.danger,
              pulse: true,
            ),
            const SizedBox(width: 10),
            Text(
              'YOLO Sign Translator',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Icon(
                        Icons.videocam_off_rounded,
                        size: 38,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 220,
                      child: IsharaActionTile(
                        label: 'Retry',
                        icon: Icons.refresh_rounded,
                        onTap: () async {
                          await _camera?.dispose();
                          _loopTimer?.cancel();
                          _camera = null;
                          _detector = null;
                          _remote = null;
                          await _bootstrap();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: _camera != null && _camera!.value.isInitialized
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            CameraPreview(_camera!),
                            // Frame guides
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: teal.withValues(alpha: 0.16),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_last != null)
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 16,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    14,
                                    18,
                                    16,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: teal.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _last!.labelArabic,
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.displaySmall
                                              ?.copyWith(
                                            color: Colors.white,
                                            fontSize: 38,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.8,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: teal.withValues(alpha: 0.22),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: teal.withValues(
                                              alpha: 0.55,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          '${(_last!.confidence * 100).toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            color: teal,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                ),

                // Bottom panel — sentence + actions
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0F1A),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DETECTED · SENTENCE',
                        style: TextStyle(
                          color: teal,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          _sentence.isEmpty ? '—' : _sentence,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: IsharaActionTile(
                              label: 'Speak',
                              icon: Icons.volume_up_rounded,
                              trailingIcon: null,
                              onTap: _sentence.isEmpty
                                  ? null
                                  : () => ref
                                      .read(ttsServiceProvider)
                                      .speak(_sentence.replaceAll('•', ' ')),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: IsharaActionTile(
                              label: 'Reset',
                              icon: Icons.refresh_rounded,
                              variant: IsharaActionVariant.outline,
                              trailingIcon: null,
                              onTap: () => setState(() {
                                _recent.clear();
                                _sentence = '';
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
