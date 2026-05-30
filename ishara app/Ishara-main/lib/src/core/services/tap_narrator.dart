/// Wraps a subtree and narrates whatever the user just tapped, when the
/// "Auto-TTS everywhere" accessibility setting is on.
///
/// Implementation: a top-level [Listener] catches every [PointerUpEvent],
/// runs a hit-test against the render tree at that screen position, and
/// walks up the chain looking for a [RenderSemanticsAnnotations] node with
/// a non-empty label, value, or hint. The first one wins. The label is
/// then spoken via [TtsService] in the user's app language (Arabic vs.
/// English).
///
/// This keeps existing screens completely untouched — they already use
/// `Semantics(label: ..., button: true, ...)` on most interactive widgets,
/// and standard Material widgets (IconButton, ElevatedButton, etc.) emit
/// semantics with their tooltip / child text automatically.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/accessibility_settings.dart';
import '../settings/app_settings_controller.dart';
import 'tts_service.dart';

class TapNarrator extends ConsumerStatefulWidget {
  const TapNarrator({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<TapNarrator> createState() => _TapNarratorState();
}

class _TapNarratorState extends ConsumerState<TapNarrator> {
  DateTime _lastSpoken = DateTime.fromMillisecondsSinceEpoch(0);
  String _lastSpokenText = '';

  void _onPointerUp(PointerUpEvent ev) {
    final autoTts = ref.read(accessibilityProvider).autoTts;
    if (!autoTts) return;

    String? label;
    try {
      label = _findSemanticLabelAt(ev.position);
    } catch (_) {
      // Hit-testing or semantics inspection can throw if called between
      // frames — silently swallow so the user's tap is never blocked.
      return;
    }
    if (label == null || label.isEmpty) return;
    final spoken = label;

    // Debounce: don't repeat the same phrase within 800 ms (e.g. when a
    // pointer-up fires on an overlay + the underlying widget).
    final now = DateTime.now();
    if (label == _lastSpokenText &&
        now.difference(_lastSpoken).inMilliseconds < 800) {
      return;
    }
    _lastSpokenText = label;
    _lastSpoken = now;

    final isArabic =
        ref.read(appSettingsProvider).language == IsharaLanguage.ar;
    final tts = ref.read(ttsServiceProvider);
    final rate = ref.read(accessibilityProvider).ttsRate;
    // Fire-and-forget — TTS calls are queued by the service.
    () async {
      await tts.setLanguage(isArabic ? 'ar-EG' : 'en-US');
      await tts.setRate(rate);
      await tts.speak(spoken);
    }();
  }

  /// Walks the render tree at [globalPosition] and returns the first
  /// non-empty semantic label / value / hint found on the way up.
  String? _findSemanticLabelAt(Offset globalPosition) {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return null;
    final renderObject = root.renderObject;
    if (renderObject is! RenderBox) return null;

    final result = BoxHitTestResult();
    renderObject.hitTest(result, position: globalPosition);

    for (final entry in result.path) {
      final target = entry.target;
      if (target is! RenderObject) continue;
      RenderObject? ro = target;
      // Walk up from the hit target to find the nearest semantics node.
      while (ro != null) {
        final node = ro.debugSemantics;
        if (node != null) {
          final data = node.getSemanticsData();
          final candidate = _pickLabel(data);
          if (candidate != null && candidate.trim().isNotEmpty) {
            return candidate.trim();
          }
        }
        ro = ro.parent;
      }
    }
    return null;
  }

  String? _pickLabel(SemanticsData d) {
    if (d.label.isNotEmpty) return d.label;
    if (d.value.isNotEmpty) return d.value;
    if (d.hint.isNotEmpty) return d.hint;
    if (d.tooltip.isNotEmpty) return d.tooltip;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerUp: _onPointerUp,
      child: widget.child,
    );
  }
}
