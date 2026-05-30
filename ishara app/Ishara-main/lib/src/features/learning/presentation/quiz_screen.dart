/// Free-practice quiz, backed by the PSL video dataset.
///
/// Picks 10 random Arabic words that resolve to a real clip, plays each
/// sign as a looping silent MP4, and asks the user to pick the matching
/// English meaning from 4 shuffled options. Score + hearts + XP shown in
/// the app bar.
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

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, this.totalQuestions = 10});
  final int totalQuestions;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _Question {
  _Question({
    required this.target,
    required this.options,
    required this.answerIndex,
  });
  final PslEntry target;
  final List<String> options;
  final int answerIndex;
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  List<_Question> _questions = const [];
  int _index = 0;
  int _correct = 0;
  int _xp = 0;
  int _hearts = 3;
  int? _selected;
  bool _revealed = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final psl = await ref.read(pslVideoServiceProvider.future);
    if (!mounted) return;
    final all = psl.allEntries;
    if (all.length < 4) {
      setState(() => _ready = true);
      return;
    }
    final rng = Random();
    final pool = [...all]..shuffle(rng);
    final picks = pool.take(widget.totalQuestions).toList();

    final questions = picks.map((target) {
      final distractors = pool
          .where((e) => e.english.toLowerCase() != target.english.toLowerCase())
          .toList()
        ..shuffle(rng);
      final wrongs =
          distractors.take(3).map((e) => e.english).toList(growable: false);
      final options = [target.english, ...wrongs]..shuffle(rng);
      final answerIndex = options.indexOf(target.english);
      return _Question(
        target: target,
        options: options,
        answerIndex: answerIndex,
      );
    }).toList();

    setState(() {
      _questions = questions;
      _ready = true;
    });
  }

  void _select(int i) {
    if (_revealed || _hearts <= 0) return;
    setState(() {
      _selected = i;
      _revealed = true;
      if (i == _questions[_index].answerIndex) {
        _correct++;
        _xp += 10;
      } else {
        _hearts = max(0, _hearts - 1);
      }
    });
  }

  Future<void> _next() async {
    if (_index < _questions.length - 1 && _hearts > 0) {
      setState(() {
        _index++;
        _selected = null;
        _revealed = false;
      });
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_hearts <= 0 ? 'Out of hearts' : 'Practice complete'),
        content: Text(
          'Score: $_correct / ${_questions.length}\nXP earned: $_xp',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    if (!_ready) {
      return Scaffold(
        appBar: AppBar(title: const Text('Practice')),
        body: Center(child: CircularProgressIndicator(color: teal)),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Practice')),
        body: const Center(
            child: Text('Not enough words in the dictionary to start a quiz.')),
      );
    }

    final q = _questions[_index];
    final progress = (_index + (_revealed ? 1 : 0)) / _questions.length;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Practice',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Row(children: [
              _StatPill(
                icon: Icons.favorite_rounded,
                value: '$_hearts',
                color: const Color(0xFFEF4444),
              ),
              const SizedBox(width: 6),
              _StatPill(
                icon: Icons.bolt_rounded,
                value: '$_xp',
                color: const Color(0xFFF59E0B),
              ),
            ]),
          ),
        ],
      ),
      body: Stack(
        children: [
          const IsharaAuroraBackground(intensity: 0.5),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IsharaStatusPill(
                        label:
                            'Question ${_index + 1} / ${_questions.length}',
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
                  _PracticeVideo(
                    key: ValueKey('practice-${q.target.label}'),
                    url: q.target.videoUrl,
                    teal: teal,
                    isDark: isDark,
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
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.32),
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
                                  'Correct answer: ${q.target.english} (${q.target.arabic})',
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
                      label: _index == _questions.length - 1 ||
                              _hearts <= 0
                          ? 'Finish'
                          : 'Next question',
                      icon: _index == _questions.length - 1 ||
                              _hearts <= 0
                          ? Icons.flag_rounded
                          : Icons.arrow_forward_rounded,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _next();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeVideo extends StatefulWidget {
  const _PracticeVideo({
    super.key,
    required this.url,
    required this.teal,
    required this.isDark,
  });
  final String url;
  final Color teal;
  final bool isDark;

  @override
  State<_PracticeVideo> createState() => _PracticeVideoState();
}

class _PracticeVideoState extends State<_PracticeVideo> {
  VideoPlayerController? _video;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
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
    if (_video != null && _ready && !_failed) {
      final ar = _video!.value.aspectRatio > 0
          ? _video!.value.aspectRatio
          : 16 / 9;
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(aspectRatio: ar, child: VideoPlayer(_video!)),
      );
    }
    if (_failed) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: teal.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('Could not load clip'),
      );
    }
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
