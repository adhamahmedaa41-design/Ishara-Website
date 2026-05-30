/// Learn tab — three sub-tabs:
///   1. Path        — linear curriculum (lesson → quiz → next lesson…)
///   2. Dictionary  — every PSL word with a play button → modal video
///   3. Practice    — free-play PSL quiz
///
/// Lessons in the Path tab unlock sequentially: lesson N is locked until
/// the user passes quiz N–1. The lesson video opens in
/// [LessonDetailScreen] which uses `video_player` for a looping silent MP4
/// from the PSL dataset.
///
/// Dictionary lists every Arabic word that resolves through
/// [PslVideoService] and shows a tap-to-play sheet. Practice runs a quick
/// PSL-backed multiple-choice quiz.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/settings/translations.dart';
import '../../../core/theme/ishara_theme.dart';
import '../../../core/widgets/ishara_design_system.dart';
import '../../../core/settings/app_settings_controller.dart';
import '../../communicate/data/psl_video_service.dart';
import '../data/learning_progress.dart';
import '../domain/curriculum.dart';

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    // Warm the PSL index so Dictionary/Practice load instantly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pslVideoServiceProvider);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final orange = isDark ? IsharaColors.orangeDark : IsharaColors.orangeLight;
    final s = t(ref);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          const IsharaAuroraBackground(intensity: 0.7),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                IsharaHero(
                  eyebrow: 'Learn',
                  title: s.learnTitle,
                  description: s.learnSub,
                  icon: Icons.school_rounded,
                ),
                _StreakBanner(isDark: isDark, teal: teal, orange: orange),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 8),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? IsharaColors.darkCard
                          : IsharaColors.lightCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? IsharaColors.darkBorder
                            : IsharaColors.lightBorder,
                      ),
                    ),
                    child: TabBar(
                      controller: _tab,
                      indicator: BoxDecoration(
                        gradient: LinearGradient(colors: [teal, orange]),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: teal.withValues(alpha: 0.32),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      // Round the hover/pressed splash so it matches the
                      // selected pill (previously square because the default
                      // splashBorderRadius is null on TabBar).
                      splashBorderRadius: BorderRadius.circular(15),
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered) ||
                            states.contains(WidgetState.pressed) ||
                            states.contains(WidgetState.focused)) {
                          return teal.withValues(alpha: 0.12);
                        }
                        return null;
                      }),
                      labelColor: Colors.white,
                      unselectedLabelColor: teal,
                      dividerColor: Colors.transparent,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.1,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      tabs: const [
                        Tab(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Path', maxLines: 1),
                          ),
                        ),
                        Tab(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Dictionary', maxLines: 1),
                          ),
                        ),
                        Tab(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Practice', maxLines: 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: const [
                      _PathTab(),
                      _DictionaryTab(),
                      _PracticeTab(),
                    ],
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

// ─── Path tab ─────────────────────────────────────────────────────────────────
//
// Renders directly from the local `kCurriculum` constant + the local
// `learningProgressProvider`. Does NOT depend on the network-backed
// `LearningController`, which is why this tab now opens instantly.

class _PathTab extends ConsumerWidget {
  const _PathTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final progressStore = ref.watch(learningProgressProvider);
    final isArabic =
        ref.watch(appSettingsProvider).language == IsharaLanguage.ar;

    bool prevQuizPassed = true; // first lesson unlocked
    bool prevLessonWatched = false;
    final unlockMap = <String, bool>{};

    for (final node in kCurriculum) {
      final p = node.lessonId == null
          ? const LessonProgress()
          : progressStore.get(node.lessonId!);
      bool unlocked;
      if (node.kind == CurriculumNodeKind.lesson) {
        unlocked = prevQuizPassed;
        prevLessonWatched = p.watched;
      } else {
        unlocked = prevLessonWatched;
      }
      unlockMap[node.id] = unlocked;
      if (node.kind == CurriculumNodeKind.quiz) {
        prevQuizPassed = p.quizPassed;
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      itemCount: kCurriculum.length,
      itemBuilder: (context, i) {
        final node = kCurriculum[i];
        final unlocked = unlockMap[node.id] ?? false;
        final progress = node.lessonId == null
            ? const LessonProgress()
            : progressStore.get(node.lessonId!);
        final completed = node.kind == CurriculumNodeKind.lesson
            ? progress.watched
            : progress.quizPassed;

        return _PathNodeCard(
          node: node,
          unlocked: unlocked,
          completed: completed,
          isDark: isDark,
          teal: teal,
          isArabic: isArabic,
          onTap: () {
            if (!unlocked) return;
            if (node.kind == CurriculumNodeKind.lesson) {
              context.push('/learning/lesson/${node.lessonId}');
            } else {
              context.push('/learning/lesson-quiz/${node.lessonId}');
            }
          },
          showConnector: i < kCurriculum.length - 1,
        ).animate().fadeIn(
              delay: Duration(milliseconds: 30 * i),
              duration: 250.ms,
            );
      },
    );
  }
}

class _PathNodeCard extends StatelessWidget {
  const _PathNodeCard({
    required this.node,
    required this.unlocked,
    required this.completed,
    required this.isDark,
    required this.teal,
    required this.isArabic,
    required this.onTap,
    required this.showConnector,
  });
  final CurriculumNode node;
  final bool unlocked;
  final bool completed;
  final bool isDark;
  final Color teal;
  final bool isArabic;
  final VoidCallback onTap;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLesson = node.kind == CurriculumNodeKind.lesson;
    final accent = isLesson ? teal : const Color(0xFFF97316);
    final muted = isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight;

    final iconData = !unlocked
        ? Icons.lock_rounded
        : completed
            ? Icons.check_circle_rounded
            : isLesson
                ? Icons.play_circle_fill_rounded
                : Icons.quiz_rounded;

    final iconColor = !unlocked
        ? muted
        : completed
            ? const Color(0xFF22C55E)
            : accent;

    return Stack(
      children: [
        if (showConnector)
          Positioned(
            left: 27,
            top: 60,
            bottom: 0,
            child: Container(
              width: 2,
              color: (completed ? const Color(0xFF22C55E) : muted)
                  .withValues(alpha: 0.3),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: unlocked ? onTap : null,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? IsharaColors.darkCard.withValues(alpha: 0.6)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: unlocked
                        ? accent.withValues(alpha: 0.3)
                        : (isDark ? Colors.white12 : Colors.black12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: iconColor, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(builder: (_) {
                            final labels =
                                localizedNode(node, isArabic: isArabic);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  labels.title,
                                  style:
                                      theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: unlocked ? null : muted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  labels.subtitle,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: muted),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                    if (unlocked && !completed)
                      Icon(Icons.chevron_right_rounded, color: accent),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Dictionary tab ───────────────────────────────────────────────────────────
//
// Lists every Arabic word that resolves to a PSL clip. Each row has a
// circular play-button avatar; tapping the row (or button) opens a modal
// sheet with a looping silent MP4.

class _DictionaryTab extends ConsumerStatefulWidget {
  const _DictionaryTab();

  @override
  ConsumerState<_DictionaryTab> createState() => _DictionaryTabState();
}

class _DictionaryTabState extends ConsumerState<_DictionaryTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;
    final pslAsync = ref.watch(pslVideoServiceProvider);
    final isArabic =
        ref.watch(appSettingsProvider).language == IsharaLanguage.ar;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search_rounded, color: teal),
              hintText: 'Search words…',
              filled: true,
              fillColor: isDark
                  ? IsharaColors.darkCard.withValues(alpha: 0.6)
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: pslAsync.when(
            loading: () => Center(child: CircularProgressIndicator(color: teal)),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Failed to load dictionary: $e',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            data: (psl) {
              final all = psl.allEntries;
              final q = _query.toLowerCase();
              final filtered = q.isEmpty
                  ? all
                  : all
                      .where((e) =>
                          e.arabic.contains(_query) ||
                          e.english.toLowerCase().contains(q))
                      .toList(growable: false);

              if (filtered.isEmpty) {
                return Center(
                  child: Text('No entries match your search.',
                      style: theme.textTheme.bodyMedium),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final e = filtered[i];
                  return _DictionaryRow(
                    entry: e,
                    isDark: isDark,
                    teal: teal,
                    isArabic: isArabic,
                    onPlay: () =>
                        _showVideoSheet(context, e, teal, isDark, isArabic),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showVideoSheet(BuildContext context, PslEntry entry, Color teal,
      bool isDark, bool isArabic) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DictionaryVideoSheet(
        entry: entry,
        teal: teal,
        isDark: isDark,
        isArabic: isArabic,
      ),
    );
  }
}

class _DictionaryRow extends StatelessWidget {
  const _DictionaryRow({
    required this.entry,
    required this.isDark,
    required this.teal,
    required this.isArabic,
    required this.onPlay,
  });
  final PslEntry entry;
  final bool isDark;
  final Color teal;
  final bool isArabic;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final primary = isArabic ? entry.arabic : entry.english;
    final secondary = isArabic ? entry.english : entry.arabic;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPlay,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? IsharaColors.darkCard.withValues(alpha: 0.5)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: teal.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: teal,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        secondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? IsharaColors.mutedDark
                              : IsharaColors.mutedLight,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: isDark
                        ? IsharaColors.mutedDark
                        : IsharaColors.mutedLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DictionaryVideoSheet extends StatefulWidget {
  const _DictionaryVideoSheet({
    required this.entry,
    required this.teal,
    required this.isDark,
    required this.isArabic,
  });
  final PslEntry entry;
  final Color teal;
  final bool isDark;
  final bool isArabic;

  @override
  State<_DictionaryVideoSheet> createState() => _DictionaryVideoSheetState();
}

class _DictionaryVideoSheetState extends State<_DictionaryVideoSheet> {
  VideoPlayerController? _video;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.entry.videoUrl));
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
    final theme = Theme.of(context);
    final teal = widget.teal;
    final entry = widget.entry;

    Widget media;
    if (_video != null && _ready && !_failed) {
      final ar = _video!.value.aspectRatio > 0
          ? _video!.value.aspectRatio
          : 16 / 9;
      media = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(aspectRatio: ar, child: VideoPlayer(_video!)),
      );
    } else if (_failed) {
      media = Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: teal.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('Could not load clip', style: theme.textTheme.bodyMedium),
      );
    } else {
      media = Container(
        height: 220,
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

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          media,
          const SizedBox(height: 16),
          Text(
            widget.isArabic ? entry.arabic : entry.english,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isArabic ? entry.english : entry.arabic,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: teal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: teal,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ─── Practice tab ─────────────────────────────────────────────────────────────

class _PracticeTab extends ConsumerWidget {
  const _PracticeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final teal = isDark ? IsharaColors.tealDark : IsharaColors.tealLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [teal, const Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 36),
                const SizedBox(height: 12),
                const Text('Free Practice',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Random PSL signs from the dictionary. Watch the clip, pick the meaning.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/learning/quiz'),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start practice quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: teal,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tip: complete the Path tab first — every lesson you finish makes practice easier.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Streak banner ────────────────────────────────────────────────────────────

class _StreakBanner extends ConsumerWidget {
  const _StreakBanner({
    required this.isDark,
    required this.teal,
    required this.orange,
  });
  final bool isDark;
  final Color teal, orange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(learningProgressProvider);

    // Count quizzes passed out of total quizzes in curriculum
    final totalQuizzes =
        kCurriculum.where((n) => n.kind == CurriculumNodeKind.quiz).length;
    final passedQuizzes = kCurriculum
        .where((n) => n.kind == CurriculumNodeKind.quiz)
        .where((n) => n.lessonId != null && store.get(n.lessonId!).quizPassed)
        .length;
    final pct = totalQuizzes == 0 ? 0.0 : passedQuizzes / totalQuizzes;

    final streakDays = store.streak;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            teal.withValues(alpha: isDark ? 0.15 : 0.1),
            orange.withValues(alpha: isDark ? 0.1 : 0.07),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: teal.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ── Streak counter ──────────────────────────────────────
              _StatChip(
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFF97316),
                label: '$streakDays day${streakDays == 1 ? '' : 's'}',
                sublabel: 'streak',
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              // ── Completion stat ─────────────────────────────────────
              _StatChip(
                icon: Icons.emoji_events_rounded,
                iconColor: teal,
                label: '$passedQuizzes / $totalQuizzes',
                sublabel: 'quizzes passed',
                isDark: isDark,
              ),
              const Spacer(),
              // ── Pct badge ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (b) => LinearGradient(
                    colors: [teal, orange],
                  ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                  child: Text(
                    '${(pct * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Progress bar ────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: isDark
                  ? IsharaColors.darkBorder
                  : IsharaColors.lightBorder,
              valueColor: AlwaysStoppedAnimation<Color>(teal),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pct == 1.0
                ? 'Curriculum complete!'
                : '$passedQuizzes of $totalQuizzes lessons done · keep going!',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.05, end: 0, duration: 300.ms);
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    required this.isDark,
  });
  final IconData icon;
  final Color iconColor;
  final String label, sublabel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? IsharaColors.darkForeground : IsharaColors.lightForeground,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? IsharaColors.mutedDark : IsharaColors.mutedLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
