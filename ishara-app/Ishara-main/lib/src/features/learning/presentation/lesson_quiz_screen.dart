/// Per-lesson quiz: for each word in the lesson, show the PSL sign-language
/// clip and ask the user to pick the correct English meaning from four
/// options (one correct + three distractors drawn from other lesson words).
/// Pass = ≥70% correct → unlocks the next lesson.
///
/// Clips are MP4s served via [PslVideoService] (looping, silent), the same
/// source the Communicate page and lesson screen use.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';
import '../../communicate/data/psl_video_service.dart';
import '../data/learning_progress.dart';
import '../domain/curriculum.dart';

class LessonQuizScreen extends ConsumerStatefulWidget {
  const LessonQuizScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  ConsumerState<LessonQuizScreen> createState() => _LessonQuizScreenState();
}

class _QuizQuestion {
  _QuizQuestion({
    required this.target,
    required this.options,
    required this.answerIndex,
  });
  final SignWord target;
  final List<String> options; // English meanings
  final int answerIndex;
}

class _LessonQuizScreenState extends ConsumerState<LessonQuizScreen> {
  late final List<_QuizQuestion> _questions = _buildQuestions();
  int _index = 0;
  int _correct = 0;
  int? _selected;
  bool _revealed = false;

  List<_QuizQuestion> _buildQuestions() {
    final lessonWords = kLessons[widget.lessonId] ?? const [];
    if (lessonWords.isEmpty) return [];
    final rng = Random();
    final pool = kAllWords;

    return lessonWords.map((target) {
      final distractors = pool
          .where((w) => w.wordEn != target.wordEn)
          .toList()
        ..shuffle(rng);
      final picks = distractors.take(3).map((w) => w.wordEn).toList();
      final options = [target.wordEn, ...picks]..shuffle(rng);
      final answerIndex = options.indexOf(target.wordEn);
      return _QuizQuestion(
        target: target,
        options: options,
        answerIndex: answerIndex,
      );
    }).toList();
  }

  void _select(int i) {
    if (_revealed) return;
    setState(() {
      _selected = i;
      _revealed = true;
      if (i == _questions[_index].answerIndex) _correct++;
    });
  }

  Future<void> _next() async {
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _revealed = false;
      });
      return;
    }
    final ratio = _correct / _questions.length;
    final passed = ratio >= kPassThreshold;
    if (passed) {
      final notifier = ref.read(learningProgressProvider.notifier);
      await notifier.markQuizPassed(widget.lessonId);
      await notifier.recordActivity();
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(passed ? 'Lesson complete' : 'Try again'),
        content: Text(
          passed
              ? 'You scored $_correct / ${_questions.length}. The next lesson is unlocked!'
              : 'You scored $_correct / ${_questions.length}. You need at least '
                  '${(kPassThreshold * 100).round()}% to unlock the next lesson.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: Text('No questions configured.')),
      );
    }

    final pslAsync = ref.watch(pslVideoServiceProvider);
    final q = _questions[_index];
    final url = pslAsync.maybeWhen(
      data: (psl) => psl.lookup(q.target.wordAr)?.videoUrl,
      orElse: () => null,
    );
    final progress = (_index + (_revealed ? 1 : 0)) / _questions.length;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IsharaStatusPill(
              label: 'Question ${_index + 1} / ${_questions.length}',
              tone: IsharaStatusTone.accent,
              icon: Icons.psychology_rounded,
            ),
            const Spacer(),
            Text(
              '$_correct correct',
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFF22C55E),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: teal.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(teal),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'What does this sign mean?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 14),
        _PslLoopPlayer(
          key: ValueKey('quiz-${q.target.wordAr}-${url ?? "loading"}'),
          videoUrl: url,
          loading: pslAsync.isLoading,
          teal: teal,
          isDark: isDark,
          theme: theme,
        ).animate().fadeIn(
              duration: IsharaMotion.base,
              delay: 60.ms,
            ),
        const SizedBox(height: 20),
        for (var i = 0; i < q.options.length; i++)
          _OptionTile(
            label: q.options[i],
            isSelected: _selected == i,
            isCorrect: q.answerIndex == i,
            revealed: _revealed,
            onTap: () {
              HapticFeedback.selectionClick();
              _select(i);
            },
            teal: teal,
            isDark: isDark,
          ).animate().fadeIn(
                duration: IsharaMotion.base,
                delay: Duration(milliseconds: 100 + 40 * i),
              ),
        const SizedBox(height: 8),
        if (_revealed) ...[
          if (_selected != q.answerIndex)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.32),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Correct answer: ${q.target.wordEn} (${q.target.wordAr})',
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IsharaActionTile(
            label: _index == _questions.length - 1
                ? 'Finish'
                : 'Next question',
            icon: _index == _questions.length - 1
                ? Icons.flag_rounded
                : Icons.arrow_forward_rounded,
            onTap: () {
              HapticFeedback.mediumImpact();
              _next();
            },
          ),
        ],
      ],
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Lesson quiz',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          const IsharaAuroraBackground(intensity: 0.5),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.isSelected,
    required this.isCorrect,
    required this.revealed,
    required this.onTap,
    required this.teal,
    required this.isDark,
  });
  final String label;
  final bool isSelected;
  final bool isCorrect;
  final bool revealed;
  final VoidCallback onTap;
  final Color teal;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;

    if (revealed && isCorrect) {
      borderColor = const Color(0xFF22C55E);
      bgColor = const Color(0xFF22C55E).withValues(alpha: 0.12);
    } else if (revealed && isSelected && !isCorrect) {
      borderColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFEF4444).withValues(alpha: 0.12);
    } else if (isSelected) {
      borderColor = teal;
      bgColor = teal.withValues(alpha: 0.1);
    } else {
      borderColor = isDark ? Colors.white12 : Colors.black12;
      bgColor =
          isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: revealed ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (revealed && isCorrect)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF22C55E))
              else if (revealed && isSelected && !isCorrect)
                const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444)),
            ],
          ),
        ),
      ),
    );
  }
}
