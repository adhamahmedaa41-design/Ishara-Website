/// Multi-word lesson screen — plays the PSL sign clip for each word in
/// sequence, lets the user step Prev / Next, then continues to the quiz.
///
/// Clips are MP4s served from GitHub Releases via [PslVideoService] (the
/// same source the Communicate page uses). They auto-loop silently.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';
import '../../communicate/data/psl_video_service.dart';
import '../data/learning_progress.dart';
import '../domain/curriculum.dart';

class LessonDetailScreen extends ConsumerStatefulWidget {
  const LessonDetailScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  int _index = 0;

  late final List<SignWord> _words = kLessons[widget.lessonId] ?? const [];
  late final CurriculumNode _node = kCurriculum.firstWhere(
    (n) => n.kind == CurriculumNodeKind.lesson && n.lessonId == widget.lessonId,
    orElse: () => kCurriculum.first,
  );

  @override
  void initState() {
    super.initState();
    // Mark the lesson watched the moment it opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(learningProgressProvider.notifier).markWatched(widget.lessonId);
    });
  }

  void _go(int delta) {
    final newIdx = (_index + delta).clamp(0, _words.length - 1);
    if (newIdx == _index) return;
    setState(() => _index = newIdx);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    if (_words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_node.title)),
        body: const Center(child: Text('No words configured.')),
      );
    }

    final pslAsync = ref.watch(pslVideoServiceProvider);
    final word = _words[_index];
    final atFirst = _index == 0;
    final atLast = _index == _words.length - 1;
    final url = pslAsync.maybeWhen(
      data: (psl) => psl.lookup(word.wordAr)?.videoUrl,
      orElse: () => null,
    );

    final progress = (_index + 1) / _words.length;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IsharaStatusPill(
              label: 'Word ${_index + 1} / ${_words.length}',
              tone: IsharaStatusTone.accent,
              icon: Icons.menu_book_rounded,
            ),
            const Spacer(),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: teal,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: teal.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(teal),
          ),
        ),
        const SizedBox(height: 16),

        _PslLoopPlayer(
          key: ValueKey('lesson-${word.wordAr}-${url ?? "loading"}'),
          videoUrl: url,
          loading: pslAsync.isLoading,
          teal: teal,
          isDark: isDark,
          theme: theme,
        ).animate().fadeIn(
              duration: IsharaMotion.base,
              delay: 60.ms,
            ),

        const SizedBox(height: 22),

        // Word + translation block
        IsharaSurface(
          variant: IsharaSurfaceVariant.accent,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                word.wordAr,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 42,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                word.wordEn.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: teal,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 1.4,
                ),
              ),
              if (word.description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: teal.withValues(alpha: 0.18),
                ),
                const SizedBox(height: 14),
                Text(
                  word.description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? IsharaColors.mutedDark
                        : IsharaColors.mutedLight,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(
              duration: IsharaMotion.base,
              delay: 120.ms,
            ),

        const Spacer(),

        Row(
          children: [
            Expanded(
              child: IsharaActionTile(
                label: 'Prev',
                icon: Icons.arrow_back_rounded,
                trailingIcon: null,
                variant: IsharaActionVariant.outline,
                onTap: atFirst
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        _go(-1);
                      },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: atLast
                  ? IsharaActionTile(
                      label: 'Take quiz',
                      icon: Icons.psychology_rounded,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.push(
                            '/learning/lesson-quiz/${widget.lessonId}');
                      },
                    )
                  : IsharaActionTile(
                      label: 'Next',
                      icon: Icons.arrow_forward_rounded,
                      trailingIcon: null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _go(1);
                      },
                    ),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _node.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const IsharaAuroraBackground(intensity: 0.5),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Looping silent MP4 player for a single sign clip ────────────────────────

class _PslLoopPlayer extends StatefulWidget {
  const _PslLoopPlayer({
    super.key,
    required this.videoUrl,
    required this.loading,
    required this.teal,
    required this.isDark,
    required this.theme,
  });
  final String? videoUrl;
  final bool loading;
  final Color teal;
  final bool isDark;
  final ThemeData theme;

  @override
  State<_PslLoopPlayer> createState() => _PslLoopPlayerState();
}

class _PslLoopPlayerState extends State<_PslLoopPlayer> {
  VideoPlayerController? _video;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final url = widget.videoUrl;
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
      setState(() => _ready = true);
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _failed = true);
    });
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teal = widget.teal;
    final theme = widget.theme;
    final isDark = widget.isDark;

    if (widget.loading || (_video != null && !_ready && !_failed)) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: teal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: teal),
        ),
      );
    }

    if (_video != null && _ready && !_failed) {
      final ar = _video!.value.aspectRatio > 0
          ? _video!.value.aspectRatio
          : 16 / 9;
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: ar,
          child: VideoPlayer(_video!),
        ),
      );
    }

    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sign_language_outlined,
            color: isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            'No sign clip for this word',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
