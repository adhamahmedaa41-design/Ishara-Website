import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';
import '../../translator/data/sign_language_service.dart';
import '../../translator/domain/esl_translation_models.dart';
import '../../translator/presentation/translator_controller.dart';
import '../data/psl_video_service.dart';

/// Communicate — bold landing screen.
///
/// The page is built as four discrete sections stacked under a hero
/// banner. Each section uses the design-system primitives so styling
/// stays consistent across screens.
class CommunicateScreen extends ConsumerStatefulWidget {
  const CommunicateScreen({super.key});

  @override
  ConsumerState<CommunicateScreen> createState() => _CommunicateScreenState();
}

class _CommunicateScreenState extends ConsumerState<CommunicateScreen> {
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(translatorControllerProvider);
      if (s.inputText.isNotEmpty) _inputController.text = s.inputText;
      ref.read(pslVideoServiceProvider);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _openLiveTranslator() async {
    GoRouter.of(context).push('/translator/yolo-live');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(translatorControllerProvider);
    final ctrl = ref.read(translatorControllerProvider.notifier);
    final s = t(ref);

    ref.listen(translatorControllerProvider, (_, next) {
      if (next.inputText != _inputController.text) {
        _inputController.value = TextEditingValue(
          text: next.inputText,
          selection: TextSelection.collapsed(offset: next.inputText.length),
        );
      }
    });

    final isEslToAr =
        state.direction == EslTranslationDirection.eslToArabic;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          const IsharaAuroraBackground(intensity: 0.8),
          SafeArea(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: IsharaHero(
                    eyebrow: 'Communicate',
                    title: s.communicate,
                    description: s.communicateSub,
                    icon: Icons.sign_language_rounded,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 6, 22, 140),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Direction segmented ────────────────────────────
                      IsharaSegmented<EslTranslationDirection>(
                        items: [
                          IsharaSegmentedItem(
                            value: EslTranslationDirection.eslToArabic,
                            label: s.eslToArabic,
                            icon: Icons.sign_language_rounded,
                          ),
                          IsharaSegmentedItem(
                            value: EslTranslationDirection.arabicToEsl,
                            label: s.arabicToEsl,
                            icon: Icons.translate_rounded,
                          ),
                        ],
                        selected: state.direction,
                        onChanged: (_) => ctrl.toggleDirection(),
                      ).animate().fadeIn(
                            duration: IsharaMotion.base,
                            delay: 60.ms,
                          ),
                      const SizedBox(height: IsharaSpacing.sectionGap),

                      // ── Primary input area ─────────────────────────────
                      if (isEslToAr)
                        _EslCameraSurface(state: state, ctrl: ctrl)
                            .animate()
                            .fadeIn(
                              duration: IsharaMotion.base,
                              delay: 120.ms,
                            )
                      else
                        _ArabicInputSurface(
                          state: state,
                          ctrl: ctrl,
                          inputController: _inputController,
                        ).animate().fadeIn(
                              duration: IsharaMotion.base,
                              delay: 120.ms,
                            ),

                      const SizedBox(height: 18),

                      // ── Output area ────────────────────────────────────
                      _OutputSurface(state: state, ctrl: ctrl)
                          .animate()
                          .fadeIn(
                            duration: IsharaMotion.base,
                            delay: 180.ms,
                          ),

                      const SizedBox(height: IsharaSpacing.sectionGap),

                      // ── How it works ────────────────────────────────────
                      const IsharaSectionLabel(
                        'How it works',
                        icon: Icons.lightbulb_outline_rounded,
                      ),
                      _HowItWorksCard(direction: state.direction)
                          .animate()
                          .fadeIn(
                            duration: IsharaMotion.base,
                            delay: 240.ms,
                          ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _LiveFab(onTap: _openLiveTranslator),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating live action — bold gradient FAB with arrow flicker
// ─────────────────────────────────────────────────────────────────────────────

class _LiveFab extends StatelessWidget {
  const _LiveFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          gradient: isharaHorizontalGradient(dark: isDark),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: teal.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: Colors.white, size: 18),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 1.0,
                  end: 1.08,
                  duration: 1400.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(width: 12),
            const Text(
              'Live Sign Translator',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ESL → Arabic camera surface
// ─────────────────────────────────────────────────────────────────────────────

class _EslCameraSurface extends ConsumerWidget {
  const _EslCameraSurface({required this.state, required this.ctrl});
  final TranslatorState state;
  final TranslatorController ctrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final signService = ref.watch(signLanguageServiceProvider);
    final cameraController = signService.cameraController;
    final hasPreview = state.isCameraActive &&
        cameraController != null &&
        cameraController.value.isInitialized;
    final s = t(ref);

    final detectedText = state.detectedSentence.trim().isNotEmpty
        ? state.detectedSentence.trim()
        : state.lastDetectedWord.trim();
    final hasDetection = detectedText.isNotEmpty;

    final loadingProgress = state.framesNeeded <= 0
        ? 0.0
        : (state.framesCollected / state.framesNeeded).clamp(0.0, 1.0);
    final waitingHint =
        state.handsDetected ? s.waitingForSigns : s.noSignDetected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IsharaSectionLabel(
          'Camera input',
          icon: Icons.videocam_rounded,
        ),

        // Camera preview frame
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: const Color(0xFF080C14),
            borderRadius: IsharaColors.surfaceRadius,
            boxShadow: IsharaColors.elevatedShadow(dark: isDark, glow: true),
            border: Border.all(
              color: teal.withValues(alpha: 0.22),
            ),
          ),
          child: ClipRRect(
            borderRadius: IsharaColors.surfaceRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasPreview)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width:
                          cameraController.value.previewSize?.height ?? 360,
                      height:
                          cameraController.value.previewSize?.width ?? 640,
                      child: CameraPreview(cameraController),
                    ),
                  )
                else
                  _CameraPlaceholder(message: s.pointCamera),

                // Top status chips
                Positioned(
                  left: 14,
                  right: 14,
                  top: 14,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      IsharaStatusPill(
                        label: state.isModelReady ? 'Model ready' : 'Loading…',
                        tone: state.isModelReady
                            ? IsharaStatusTone.good
                            : IsharaStatusTone.warn,
                        pulse: !state.isModelReady,
                      ),
                      IsharaStatusPill(
                        label: '${state.streamFps.toStringAsFixed(1)} FPS',
                        icon: Icons.speed_rounded,
                        tone: state.streamFps >= 6
                            ? IsharaStatusTone.good
                            : IsharaStatusTone.neutral,
                      ),
                      IsharaStatusPill(
                        label:
                            '${state.framesCollected}/${state.framesNeeded}',
                        icon: Icons.timelapse_rounded,
                        tone: state.framesCollected >= state.framesNeeded
                            ? IsharaStatusTone.good
                            : IsharaStatusTone.accent,
                      ),
                      if (state.lowLight)
                        const IsharaStatusPill(
                          label: 'Low light',
                          icon: Icons.wb_twilight_rounded,
                          tone: IsharaStatusTone.warn,
                        ),
                    ],
                  ),
                ),

                // Bottom detected text overlay
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: AnimatedContainer(
                    duration: IsharaMotion.base,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: hasDetection
                            ? teal.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: IsharaMotion.base,
                          child: Text(
                            hasDetection ? detectedText : waitingHint,
                            key: ValueKey<String>(
                              '${state.detectedSentence}_${state.framesCollected}',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontSize: hasDetection ? 30 : 15,
                              fontWeight: hasDetection
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              height: 1.1,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        if (hasDetection) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                '${(state.detectionConfidence * 100).toStringAsFixed(0)}% confident',
                                style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.volume_up_rounded,
                                color: teal,
                                size: 16,
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: loadingProgress,
                              minHeight: 5,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.18),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(teal),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Action button
        IsharaActionTile(
          label: state.isCameraActive ? s.stopCamera : s.startCamera,
          icon: state.isCameraActive
              ? Icons.stop_rounded
              : Icons.videocam_rounded,
          variant: state.isCameraActive
              ? IsharaActionVariant.outline
              : IsharaActionVariant.gradient,
          onTap: () => GoRouter.of(context).push('/translator/yolo-live'),
          subtitle: state.isCameraActive
              ? null
              : 'Opens the full-screen live translator',
        ),

        if (!state.hasCameraPermission && !state.isCameraActive) ...[
          const SizedBox(height: 10),
          Text(
            'Camera permission is required for live sign detection. '
            'If denied, Arabic to ESL text translation remains available.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? IsharaColors.mutedDark
                  : IsharaColors.mutedLight,
            ),
          ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  state.error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              if (state.isCameraActive)
                TextButton.icon(
                  onPressed: () => ctrl.resetModel(),
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: Text(s.resetModel,
                      style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange =
        isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;

    return Container(
      color: const Color(0xFF080C14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -40,
            child: IsharaGlowBlob(size: 220, color: teal, opacity: 0.6),
          ),
          Positioned(
            bottom: -20,
            child: IsharaGlowBlob(size: 180, color: orange, opacity: 0.4),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: isharaHorizontalGradient(dark: true),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.sign_language_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                    begin: 1.0,
                    end: 1.05,
                    duration: 1600.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arabic → ESL text input surface
// ─────────────────────────────────────────────────────────────────────────────

class _ArabicInputSurface extends ConsumerWidget {
  const _ArabicInputSurface({
    required this.state,
    required this.ctrl,
    required this.inputController,
  });
  final TranslatorState state;
  final TranslatorController ctrl;
  final TextEditingController inputController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = t(ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IsharaSectionLabel(
          'Arabic text',
          icon: Icons.edit_note_rounded,
        ),
        IsharaSurface(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                minLines: 3,
                maxLines: 6,
                controller: inputController,
                onChanged: ctrl.setInput,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: s.typeOrSpeak,
                  hintStyle: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    color: (isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight)
                        .withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: IsharaActionTile(
                      label: state.isTranslating ? s.translating : s.translate,
                      icon: state.isTranslating
                          ? Icons.hourglass_top_rounded
                          : Icons.translate_rounded,
                      loading: state.isTranslating,
                      onTap: state.isTranslating ? null : ctrl.translate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _MicButton(
                    listening: state.isListening,
                    onTap: () async {
                      if (state.isListening) {
                        await ctrl.stopListening();
                      } else {
                        await ctrl.startListening();
                      }
                    },
                  ),
                ],
              ),
              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(
                  state.error!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.listening, required this.onTap});
  final bool listening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    final pill = GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: listening ? isharaHorizontalGradient(dark: isDark) : null,
          color: listening
              ? null
              : (isDark ? IsharaColors.darkCard : IsharaColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: listening ? teal : teal.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: listening
              ? [
                  BoxShadow(
                    color: teal.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Icon(
          listening ? Icons.mic_rounded : Icons.mic_none_rounded,
          color: listening ? Colors.white : teal,
          size: 26,
        ),
      ),
    );

    if (!listening) return pill;
    return pill
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 1.0,
          end: 1.06,
          duration: 700.ms,
          curve: Curves.easeInOut,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Output surface
// ─────────────────────────────────────────────────────────────────────────────

class _OutputSurface extends ConsumerWidget {
  const _OutputSurface({required this.state, required this.ctrl});
  final TranslatorState state;
  final TranslatorController ctrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final s = t(ref);
    final hasOutput = state.outputText.isNotEmpty;
    final isEslToAr =
        state.direction == EslTranslationDirection.eslToArabic;
    final isArToEsl =
        state.direction == EslTranslationDirection.arabicToEsl;

    // Arabic → ESL with output → vertical stack of sign clip players
    if (isArToEsl && hasOutput) {
      final rawText = state.outputText.replaceAll(RegExp(r'^🤟\s*'), '');
      final pslAsync = ref.watch(pslVideoServiceProvider);
      final psl = pslAsync.maybeWhen(data: (s) => s, orElse: () => null);
      final tokens = _resolveSignVideos(rawText, psl);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IsharaSectionLabel(
            s.translation,
            icon: Icons.sign_language_rounded,
            trailing: TextButton.icon(
              onPressed: ctrl.speakOutput,
              icon: const Icon(Icons.volume_up_rounded, size: 16),
              label: Text(s.speak),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          for (var i = 0; i < tokens.length; i++) ...[
            _SignVideoCard(
              key: ValueKey('sign-${tokens[i].wordAr}-${tokens[i].videoUrl ?? "none"}'),
              token: tokens[i],
            ).animate().fadeIn(
                  delay: Duration(milliseconds: 60 * i),
                  duration: 280.ms,
                ),
            if (i < tokens.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    final confidenceValue = state.detectionConfidence.clamp(0.0, 1.0);
    final livePlaceholder =
        state.isCameraActive ? s.noSignDetected : s.pointCamera;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IsharaSectionLabel(
          isEslToAr ? s.liveTranslation : s.translation,
          icon: isEslToAr ? Icons.translate_rounded : Icons.auto_awesome,
          trailing: hasOutput
              ? TextButton.icon(
                  onPressed: ctrl.speakOutput,
                  icon: const Icon(Icons.volume_up_rounded, size: 16),
                  label: Text(s.speak),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                )
              : null,
        ),
        IsharaSurface(
          variant: hasOutput && isEslToAr
              ? IsharaSurfaceVariant.accent
              : IsharaSurfaceVariant.plain,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: IsharaMotion.base,
                child: Text(
                  key: ValueKey(state.outputText),
                  hasOutput
                      ? state.outputText
                      : (isEslToAr ? livePlaceholder : s.translatedTextHere),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: hasOutput
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.4),
                    fontSize: isEslToAr ? 34 : 22,
                    fontWeight: isEslToAr ? FontWeight.w800 : FontWeight.w600,
                    height: 1.18,
                    letterSpacing: isEslToAr ? -0.6 : -0.2,
                  ),
                ),
              ),
              if (isEslToAr) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    IsharaStatusPill(
                      label:
                          '${(confidenceValue * 100).toStringAsFixed(0)}% confident',
                      tone: confidenceValue >= 0.8
                          ? IsharaStatusTone.good
                          : IsharaStatusTone.accent,
                    ),
                    const Spacer(),
                    Text(
                      '${state.framesCollected}/${state.framesNeeded}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? IsharaColors.mutedDark
                            : IsharaColors.mutedLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: confidenceValue,
                    minHeight: 6,
                    backgroundColor: teal.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      confidenceValue >= 0.8
                          ? const Color(0xFF22C55E)
                          : teal,
                    ),
                  ),
                ),
              ],
              if (!isEslToAr && state.lastResult != null) ...[
                const SizedBox(height: 12),
                IsharaStatusPill(
                  label:
                      '${(state.lastResult!.confidence * 100).toStringAsFixed(0)}% confident',
                  tone: IsharaStatusTone.accent,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// How it works — stepped card with gradient numerals
// ─────────────────────────────────────────────────────────────────────────────

class _HowItWorksCard extends ConsumerWidget {
  const _HowItWorksCard({required this.direction});
  final EslTranslationDirection direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = t(ref);

    final steps = direction == EslTranslationDirection.eslToArabic
        ? [
            (Icons.videocam_rounded, s.stepCamera, s.stepCameraDesc),
            (Icons.swap_horiz_rounded, s.stepDirection, s.stepDirectionDesc),
            (Icons.translate_rounded, s.stepTranslate, s.stepTranslateDesc),
            (Icons.volume_up_rounded, s.stepListen, s.stepListenDesc),
          ]
        : [
            (Icons.edit_note_rounded, s.stepType, s.stepTypeDesc),
            (Icons.swap_horiz_rounded, s.stepDirection, s.stepDirectionDesc),
            (Icons.translate_rounded, s.stepTranslate, s.stepTranslateDesc),
            (Icons.volume_up_rounded, s.stepListen, s.stepListenDesc),
          ];

    return IsharaSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Padding(
              padding: EdgeInsets.only(bottom: i < steps.length - 1 ? 16 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Numbered gradient circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: isharaHorizontalGradient(dark: isDark),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].$2,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          steps[i].$3,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? IsharaColors.mutedDark
                                : IsharaColors.mutedLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    steps[i].$1,
                    color: (isDark
                            ? IsharaColors.tealDark
                            : IsharaColors.tealLight)
                        .withValues(alpha: 0.6),
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PSL sign-clip player
// ─────────────────────────────────────────────────────────────────────────────

class _SignVideoToken {
  const _SignVideoToken({required this.wordAr, this.videoUrl});
  final String wordAr;
  final String? videoUrl;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
}

List<_SignVideoToken> _resolveSignVideos(String text, PslVideoService? psl) {
  final cleaned = text.trim();
  if (cleaned.isEmpty) return const [];
  final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return words.map((w) {
    final hit = psl?.lookup(w);
    return _SignVideoToken(wordAr: w, videoUrl: hit?.videoUrl);
  }).toList(growable: false);
}

class _SignVideoCard extends StatefulWidget {
  const _SignVideoCard({super.key, required this.token});
  final _SignVideoToken token;

  @override
  State<_SignVideoCard> createState() => _SignVideoCardState();
}

class _SignVideoCardState extends State<_SignVideoCard> {
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    final url = widget.token.videoUrl;
    if (url == null || url.isEmpty) return;
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _video = c;
    c.initialize().then((_) async {
      if (!mounted) {
        await c.dispose();
        return;
      }
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      setState(() => _videoReady = true);
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _videoFailed = true);
    });
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final t = widget.token;

    Widget media;
    if (_video != null && _videoReady && !_videoFailed) {
      final ar =
          _video!.value.aspectRatio > 0 ? _video!.value.aspectRatio : 16 / 9;
      media = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: ar,
          child: VideoPlayer(_video!),
        ),
      );
    } else if (_video != null && !_videoFailed) {
      media = Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: teal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: teal),
        ),
      );
    } else {
      media = Container(
        height: 110,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sign_language_outlined,
              color: isDark
                  ? IsharaColors.mutedDark
                  : IsharaColors.mutedLight,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              'No sign clip for this word',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? IsharaColors.mutedDark
                    : IsharaColors.mutedLight,
              ),
            ),
          ],
        ),
      );
    }

    return IsharaSurface(
      variant: t.hasVideo
          ? IsharaSurfaceVariant.accent
          : IsharaSurfaceVariant.plain,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          media,
          const SizedBox(height: 10),
          Text(
            t.wordAr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
