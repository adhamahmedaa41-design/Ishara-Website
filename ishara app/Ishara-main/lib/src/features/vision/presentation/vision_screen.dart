import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';
import '../data/image_labeling_service.dart';
import 'vision_controller.dart';

/// Vision — bold camera-understanding hub.
///
/// Currency totals render as a hero metric (currency total at 92pt
/// gradient type). Mode is switched via IsharaSegmented; results land
/// in IsharaSurface variants depending on tone.
class VisionScreen extends ConsumerStatefulWidget {
  const VisionScreen({super.key});

  @override
  ConsumerState<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends ConsumerState<VisionScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _pickedImageBytes;

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.mediumImpact();
    final xFile = await _picker.pickImage(source: source);
    if (xFile == null || !mounted) return;
    final bytes = await xFile.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedImageBytes = bytes;
    });
    await ref.read(visionControllerProvider.notifier).processImage(xFile);
  }

  void _resetAll() {
    HapticFeedback.selectionClick();
    ref.read(visionControllerProvider.notifier).clearResult();
    setState(() {
      _pickedImageBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(visionControllerProvider);
    final ctrl = ref.read(visionControllerProvider.notifier);
    final s = t(ref);
    final hasResults = state.recognizedText.isNotEmpty ||
        state.currencySum.isNotEmpty ||
        state.currencyBreakdown.isNotEmpty ||
        state.objectDetections.isNotEmpty;
    final showIdleState = _pickedImageBytes == null &&
        !state.liveMode &&
        !state.isProcessing &&
        !hasResults;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          const IsharaAuroraBackground(intensity: 0.75),
          SafeArea(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: IsharaHero(
                    eyebrow: 'Vision',
                    title: s.visionTitle,
                    description: s.visionSub,
                    icon: Icons.visibility_rounded,
                    trailing: hasResults
                        ? _ResetButton(onTap: _resetAll)
                        : null,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 6, 22, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Tool selector ──────────────────────────────────
                      IsharaSegmented<VisionTool>(
                        items: [
                          IsharaSegmentedItem(
                            value: VisionTool.currency,
                            label: s.currency,
                            icon: Icons.payments_rounded,
                          ),
                          IsharaSegmentedItem(
                            value: VisionTool.readText,
                            label: s.readText,
                            icon: Icons.text_fields_rounded,
                          ),
                          IsharaSegmentedItem(
                            value: VisionTool.objects,
                            label: s.objects,
                            icon: Icons.category_rounded,
                          ),
                        ],
                        selected: state.selectedTool,
                        onChanged: ctrl.selectTool,
                      ).animate().fadeIn(
                            duration: IsharaMotion.base,
                            delay: 60.ms,
                          ),

                      const SizedBox(height: 22),

                      // ── Capture actions ────────────────────────────────
                      IsharaActionTile(
                        label: state.isProcessing ? s.scanning : 'Capture photo',
                        icon: Icons.camera_alt_rounded,
                        loading: state.isProcessing,
                        onTap: state.isProcessing
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        subtitle:
                            'High-res still for the most accurate reading',
                      ).animate().fadeIn(
                            duration: IsharaMotion.base,
                            delay: 120.ms,
                          ),
                      const SizedBox(height: 10),
                      IsharaActionTile(
                        label: s.gallery,
                        icon: Icons.photo_library_rounded,
                        variant: IsharaActionVariant.outline,
                        trailingIcon: null,
                        onTap: state.isProcessing
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                      ).animate().fadeIn(
                            duration: IsharaMotion.base,
                            delay: 180.ms,
                          ),

                      // ── Idle state ─────────────────────────────────────
                      if (showIdleState) ...[
                        const SizedBox(height: 22),
                        _IdleHint(tool: state.selectedTool)
                            .animate()
                            .fadeIn(
                              duration: IsharaMotion.base,
                              delay: 240.ms,
                            ),
                      ],

                      // ── Picked image preview ──────────────────────────
                      if (_pickedImageBytes != null) ...[
                        const SizedBox(height: 18),
                        _PickedImagePreview(
                          bytes: _pickedImageBytes!,
                          isProcessing: state.isProcessing,
                          analysingLabel: s.analysing,
                        ).animate().fadeIn(duration: IsharaMotion.base),
                      ],

                      // ── Error ──────────────────────────────────────────
                      if (state.error != null) ...[
                        const SizedBox(height: 16),
                        _ErrorRow(message: state.error!)
                            .animate()
                            .fadeIn(duration: IsharaMotion.base)
                            .shakeX(duration: 400.ms),
                      ],

                      // ── Currency hero block ────────────────────────────
                      if (state.currencySum.isNotEmpty) ...[
                        const SizedBox(height: IsharaSpacing.sectionGap),
                        _CurrencyHero(
                          totalArabic: state.currencySum,
                          breakdown: state.currencyBreakdown,
                          confidence: state.lastCurrencyConfidence,
                          detections: state.overlayItems,
                        ).animate().fadeIn(
                              duration: IsharaMotion.base,
                              delay: 80.ms,
                            ),
                      ],

                      // ── Text recognition ──────────────────────────────
                      if (state.recognizedText.isNotEmpty &&
                          state.selectedTool != VisionTool.currency) ...[
                        const SizedBox(height: IsharaSpacing.sectionGap),
                        const IsharaSectionLabel(
                          'Recognized text',
                          icon: Icons.text_fields_rounded,
                        ),
                        IsharaSurface(
                          child: SelectableText(
                            state.recognizedText,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              height: 1.6,
                            ),
                          ),
                        ).animate().fadeIn(
                              duration: IsharaMotion.base,
                              delay: 80.ms,
                            ),
                      ],

                      // ── Objects detected ──────────────────────────────
                      if (state.objectDetections.isNotEmpty) ...[
                        const SizedBox(height: IsharaSpacing.sectionGap),
                        IsharaSectionLabel(
                          'Objects detected · ${state.objectDetections.length}',
                          icon: Icons.category_rounded,
                        ),
                        IsharaSurface(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final item in state.objectDetections)
                                _ObjectChip(item: item),
                            ],
                          ),
                        ).animate().fadeIn(
                              duration: IsharaMotion.base,
                              delay: 100.ms,
                            ),
                      ],

                      // ── Spoken history ────────────────────────────────
                      if (state.spokenHistory.isNotEmpty) ...[
                        const SizedBox(height: IsharaSpacing.sectionGap),
                        const IsharaSectionLabel(
                          'Spoken history',
                          icon: Icons.record_voice_over_rounded,
                        ),
                        IsharaSurface(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final e in state.spokenHistory.take(8))
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 7),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? IsharaColors.tealDark
                                              : IsharaColors.tealLight,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          e.text,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatHistoryTime(e.timestamp),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: isDark
                                              ? IsharaColors.mutedDark
                                              : IsharaColors.mutedLight,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ).animate().fadeIn(
                              duration: IsharaMotion.base,
                              delay: 120.ms,
                            ),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatHistoryTime(DateTime ts) {
  final hh = ts.hour.toString().padLeft(2, '0');
  final mm = ts.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

// ─────────────────────────────────────────────────────────────────────────────
// Reset button (header trailing)
// ─────────────────────────────────────────────────────────────────────────────

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: teal.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: teal.withValues(alpha: 0.32)),
          ),
          child: Icon(Icons.refresh_rounded, color: teal, size: 20),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Idle hint
// ─────────────────────────────────────────────────────────────────────────────

class _IdleHint extends StatelessWidget {
  const _IdleHint({required this.tool});
  final VisionTool tool;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    late final IconData icon;
    late final String title;
    late final String body;
    switch (tool) {
      case VisionTool.currency:
        icon = Icons.payments_rounded;
        title = 'Read banknotes';
        body =
            'Capture a photo of one or multiple Egyptian banknotes. The on-device YOLO detector totals them in real Arabic.';
        break;
      case VisionTool.readText:
        icon = Icons.text_fields_rounded;
        title = 'OCR Arabic & Latin text';
        body =
            'Capture signs, menus, receipts, labels. Text is recognised on-device with ML Kit and read aloud via TTS.';
        break;
      case VisionTool.objects:
        icon = Icons.category_rounded;
        title = 'Identify 758 objects';
        body =
            'Three YOLO models run in ensemble: COCO + Open Images V7 + e-waste. The most specific label wins.';
        break;
    }

    return IsharaSurface(
      variant: IsharaSurfaceVariant.accent,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isharaHorizontalGradient(dark: isDark),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? IsharaColors.mutedDark
                  : IsharaColors.mutedLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Currency hero — the big number + breakdown chips + per-detection list
// ─────────────────────────────────────────────────────────────────────────────

class _CurrencyHero extends StatelessWidget {
  const _CurrencyHero({
    required this.totalArabic,
    required this.breakdown,
    required this.confidence,
    required this.detections,
  });

  final String totalArabic;
  final String breakdown;
  final double confidence;
  final List<VisionOverlayItem> detections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange =
        isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;

    // Parse "100 جنيه" / "100.50 جنيه" — split number from suffix
    final m = RegExp(r'^([\d.,]+)\s*(.*)$').firstMatch(totalArabic.trim());
    final number = m?.group(1) ?? totalArabic;
    final unit = m?.group(2) ?? '';

    return Stack(
      children: [
        IsharaSurface(
          variant: IsharaSurfaceVariant.dark,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
          glow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [teal, orange]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'TOTAL DETECTED',
                    style: TextStyle(
                      color: teal,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const Spacer(),
                  IsharaStatusPill(
                    label: '${(confidence * 100).toStringAsFixed(0)}%',
                    icon: Icons.verified_rounded,
                    tone: confidence >= 0.8
                        ? IsharaStatusTone.good
                        : IsharaStatusTone.accent,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              // The giant gradient number
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        colors: [teal, orange],
                      ).createShader(rect),
                      child: Text(
                        number,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 88,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          letterSpacing: -3.5,
                          fontFamily: theme.textTheme.displayLarge?.fontFamily,
                        ),
                      ),
                    ).animate().scaleXY(
                          begin: 0.94,
                          end: 1.0,
                          duration: IsharaMotion.base,
                          curve: IsharaMotion.overshoot,
                        ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        unit,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          fontFamily: theme.textTheme.titleLarge?.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (breakdown.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 14),
                Text(
                  'BREAKDOWN',
                  style: TextStyle(
                    color: teal,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final chip in breakdown.split('  •  '))
                      _BreakdownChip(label: chip),
                  ],
                ),
              ],
              if (detections.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.center_focus_strong_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${detections.length} bill${detections.length == 1 ? "" : "s"} detected',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BreakdownChip extends StatelessWidget {
  const _BreakdownChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label.trim(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Object chip
// ─────────────────────────────────────────────────────────────────────────────

class _ObjectChip extends StatelessWidget {
  const _ObjectChip({required this.item});
  final DetectedObject item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: teal.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.label,
            style: TextStyle(
              color: teal,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${(item.confidence * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: teal.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Picked image preview
// ─────────────────────────────────────────────────────────────────────────────

class _PickedImagePreview extends StatelessWidget {
  const _PickedImagePreview({
    required this.bytes,
    required this.isProcessing,
    required this.analysingLabel,
  });
  final Uint8List bytes;
  final bool isProcessing;
  final String analysingLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    return ClipRRect(
      borderRadius: IsharaColors.surfaceRadius,
      child: Stack(
        children: [
          Image.memory(
            bytes,
            height: 280,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          if (isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: teal),
                      const SizedBox(height: 14),
                      Text(
                        analysingLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error row
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

