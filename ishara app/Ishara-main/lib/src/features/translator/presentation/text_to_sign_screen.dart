/// Arabic text → Sign clips player — bold layout.
///
/// Tokenizes input via [SignDictionary], then plays each clip in order using
/// the [video_player] package. When a clip is missing, the slot shows an
/// inline letter card with TTS pronunciation as a graceful fallback.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/services/tts_service.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';
import '../data/sign_dictionary_service.dart';

class TextToSignScreen extends ConsumerStatefulWidget {
  const TextToSignScreen({super.key});

  @override
  ConsumerState<TextToSignScreen> createState() => _TextToSignScreenState();
}

class _TextToSignScreenState extends ConsumerState<TextToSignScreen> {
  final _ctrl = TextEditingController();
  List<SignToken> _playlist = const [];
  int _index = 0;
  VideoPlayerController? _video;
  bool _muted = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _video?.dispose();
    super.dispose();
  }

  Future<void> _build() async {
    HapticFeedback.selectionClick();
    final dict = await ref.read(signDictionaryProvider.future);
    final list = dict.tokenize(_ctrl.text.trim());
    setState(() {
      _playlist = list;
      _index = 0;
    });
    if (list.isEmpty) return;
    await _playAt(0);
  }

  Future<void> _playAt(int i) async {
    if (i < 0 || i >= _playlist.length) return;
    final tok = _playlist[i];
    setState(() => _index = i);

    try {
      await ref.read(ttsServiceProvider).speak(tok.token);
    } catch (_) {}

    if (tok.clip.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      await _playAt(i + 1);
      return;
    }

    await _video?.dispose();
    _video = await _initVideo(tok.clip);
    if (_video == null) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      await _playAt(i + 1);
      return;
    }
    _video!
      ..setVolume(_muted ? 0 : 1)
      ..addListener(_onTick)
      ..play();
    if (mounted) setState(() {});
  }

  Future<VideoPlayerController?> _initVideo(String path) async {
    try {
      VideoPlayerController c;
      if (path.startsWith('http')) {
        c = VideoPlayerController.networkUrl(Uri.parse(path));
      } else if (path.startsWith('assets/')) {
        c = VideoPlayerController.asset(path);
      } else {
        c = VideoPlayerController.file(File(path));
      }
      await c.initialize();
      return c;
    } catch (_) {
      return null;
    }
  }

  void _onTick() {
    final c = _video;
    if (c == null) return;
    if (c.value.position >= c.value.duration &&
        c.value.duration > Duration.zero) {
      c.removeListener(_onTick);
      _playAt(_index + 1);
    }
  }

  void _toggleMute() {
    HapticFeedback.selectionClick();
    setState(() => _muted = !_muted);
    _video?.setVolume(_muted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange =
        isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Mute',
            icon: Icon(_muted
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded),
            onPressed: _toggleMute,
          ),
        ],
      ),
      body: Stack(
        children: [
          const IsharaAuroraBackground(intensity: 0.7),
          SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IsharaHero(
                  eyebrow: 'Text → Sign',
                  title: 'Type Arabic, see signs',
                  description:
                      'Each word resolves to its sign clip; unknown words fall back to letter-by-letter signing.',
                  icon: Icons.translate_rounded,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Arabic text input
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? IsharaColors.darkCard
                                : IsharaColors.lightCard,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? IsharaColors.darkBorder
                                  : IsharaColors.lightBorder,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: TextField(
                            controller: _ctrl,
                            maxLines: 2,
                            minLines: 2,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'اكتب جملة بالعربي…',
                              hintStyle: TextStyle(
                                color: (isDark
                                        ? IsharaColors.mutedDark
                                        : IsharaColors.mutedLight)
                                    .withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: teal.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.translate_rounded,
                                    size: 18,
                                    color: teal,
                                  ),
                                ),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _build(),
                          ),
                        ),
                      ).animate().fadeIn(
                            duration: IsharaMotion.base,
                            delay: 60.ms,
                          ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: IsharaActionTile(
                              label: 'Show signs',
                              icon: Icons.play_arrow_rounded,
                              onTap: _build,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _StopButton(
                            enabled: _playlist.isNotEmpty,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _video?.dispose();
                              _video = null;
                              setState(() => _playlist = const []);
                            },
                          ),
                        ],
                      ).animate().fadeIn(
                            duration: IsharaMotion.base,
                            delay: 120.ms,
                          ),
                    ],
                  ),
                ),
                if (_playlist.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
                    child: Row(
                      children: [
                        IsharaStatusPill(
                          label:
                              'Step ${_index + 1} / ${_playlist.length}',
                          tone: IsharaStatusTone.accent,
                          icon: Icons.timeline_rounded,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _playlist[_index].token,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Video stage
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF080C14),
                        borderRadius: IsharaColors.surfaceRadius,
                        boxShadow: IsharaColors.elevatedShadow(
                          dark: isDark,
                          glow: true,
                        ),
                        border: Border.all(
                          color: teal.withValues(alpha: 0.24),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: IsharaColors.surfaceRadius,
                        child: Center(
                          child: _video != null &&
                                  _video!.value.isInitialized
                              ? AspectRatio(
                                  aspectRatio: _video!.value.aspectRatio,
                                  child: VideoPlayer(_video!),
                                )
                              : _Placeholder(
                                  text: _playlist.isEmpty
                                      ? 'Type Arabic text and tap "Show signs"'
                                      : 'Token: ${_playlist[_index].token}',
                                  teal: teal,
                                  orange: orange,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                if (_playlist.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_playlist.length, (i) {
                        final tok = _playlist[i];
                        final selected = i == _index;
                        Color color;
                        switch (tok.kind) {
                          case SignTokenKind.word:
                            color = const Color(0xFF22C55E);
                            break;
                          case SignTokenKind.letter:
                            color = const Color(0xFFF59E0B);
                            break;
                          case SignTokenKind.unknown:
                            color = isDark
                                ? IsharaColors.mutedDark
                                : IsharaColors.mutedLight;
                            break;
                        }
                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _playAt(i);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(
                                alpha: selected ? 0.32 : 0.14,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: color.withValues(
                                  alpha: selected ? 0.7 : 0.32,
                                ),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              tok.token,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }),
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

class _StopButton extends StatelessWidget {
  const _StopButton({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final disabled = !enabled;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: disabled
              ? (isDark
                  ? IsharaColors.darkCard
                  : IsharaColors.lightCard)
              : (isDark
                  ? IsharaColors.darkCard
                  : IsharaColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: disabled
                ? (isDark
                    ? IsharaColors.darkBorder
                    : IsharaColors.lightBorder)
                : teal.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Icon(
          Icons.stop_rounded,
          color: disabled
              ? (isDark
                  ? IsharaColors.mutedDark
                  : IsharaColors.mutedLight)
              : teal,
          size: 26,
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.text,
    required this.teal,
    required this.orange,
  });
  final String text;
  final Color teal;
  final Color orange;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: -30,
          child: IsharaGlowBlob(size: 200, color: teal, opacity: 0.5),
        ),
        Positioned(
          bottom: -10,
          child: IsharaGlowBlob(size: 160, color: orange, opacity: 0.35),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [teal, orange]),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.sign_language_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                    begin: 1.0,
                    end: 1.05,
                    duration: 1800.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 16),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
