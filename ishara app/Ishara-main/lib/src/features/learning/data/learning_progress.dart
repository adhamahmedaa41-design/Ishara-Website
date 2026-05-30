/// Persistent learner progress — synced to MongoDB per user.
///
/// State is held in a [LearningProgressNotifier] (StateNotifier) so any
/// widget that calls `ref.watch(learningProgressProvider)` rebuilds
/// automatically when quizzes are passed or lessons are watched.
///
/// Sync strategy:
///   • On init: load from DB (logged-in) or SharedPrefs (guest/offline).
///   • On every mutation: update state immediately (instant UI), then push
///     to DB in the background. SharedPrefs is always kept in sync as the
///     offline cache.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/auth_provider.dart';
import '../../../core/api/data_service.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class LessonProgress {
  const LessonProgress({this.watched = false, this.quizPassed = false});

  final bool watched;
  final bool quizPassed;

  LessonProgress copyWith({bool? watched, bool? quizPassed}) => LessonProgress(
        watched: watched ?? this.watched,
        quizPassed: quizPassed ?? this.quizPassed,
      );

  Map<String, dynamic> toJson() => {'watched': watched, 'quizPassed': quizPassed};

  factory LessonProgress.fromJson(Map<String, dynamic> j) => LessonProgress(
        watched: j['watched'] == true || j['w'] == true,
        quizPassed: j['quizPassed'] == true || j['q'] == true,
      );
}

// ── State ─────────────────────────────────────────────────────────────────────

class LearningProgressState {
  const LearningProgressState({
    this.progress = const {},
    this.activityDates = const {},
    this.isLoading = false,
  });

  final Map<String, LessonProgress> progress;
  final Set<String> activityDates;
  final bool isLoading;

  LearningProgressState copyWith({
    Map<String, LessonProgress>? progress,
    Set<String>? activityDates,
    bool? isLoading,
  }) =>
      LearningProgressState(
        progress: progress ?? this.progress,
        activityDates: activityDates ?? this.activityDates,
        isLoading: isLoading ?? this.isLoading,
      );

  LessonProgress get(String lessonId) =>
      progress[lessonId] ?? const LessonProgress();

  // ── Streak ────────────────────────────────────────────────────────
  int get streak {
    if (activityDates.isEmpty) return 0;
    var count = 0;
    var cursor = DateTime.now();
    while (true) {
      if (activityDates.contains(_dateStr(cursor))) {
        count++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (count == 0) {
        cursor = cursor.subtract(const Duration(days: 1));
        if (activityDates.contains(_dateStr(cursor))) {
          count++;
          cursor = cursor.subtract(const Duration(days: 1));
        } else {
          break;
        }
      } else {
        break;
      }
    }
    return count;
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class LearningProgressNotifier extends StateNotifier<LearningProgressState> {
  LearningProgressNotifier(this._prefs, this._dataService, this._isLoggedIn)
      : super(const LearningProgressState()) {
    _load();
  }

  final SharedPreferences _prefs;
  final DataService _dataService;
  final bool _isLoggedIn;

  static const _prefsKey = 'learn_progress_v2';
  static const _datesKey = 'learn_activity_dates_v2';

  // ── Init ───────────────────────────────────────────────────────────

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);

    // Always start from local cache for instant display.
    final local = _readLocal();
    state = local.copyWith(isLoading: _isLoggedIn);

    if (!_isLoggedIn) return;

    // Then fetch from DB and merge (DB wins for quizPassed; keep local watched).
    final result = await _dataService.fetchLearningProgress();
    if (result.success && result.data != null) {
      final data = result.data!;
      final dbProgress = _parseDbProgress(data['progress']);
      final dbDates = _parseDates(data['activityDates']);

      // Merge: take the maximum (true beats false) for each field.
      final merged = Map<String, LessonProgress>.from(local.progress);
      for (final entry in dbProgress.entries) {
        final existing = merged[entry.key] ?? const LessonProgress();
        merged[entry.key] = LessonProgress(
          watched: existing.watched || entry.value.watched,
          quizPassed: existing.quizPassed || entry.value.quizPassed,
        );
      }
      final mergedDates = {...local.activityDates, ...dbDates};

      state = LearningProgressState(
        progress: merged,
        activityDates: mergedDates,
        isLoading: false,
      );
      _saveLocal(state);
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  // ── Mutations ──────────────────────────────────────────────────────

  Future<void> markWatched(String lessonId) async {
    final cur = state.get(lessonId);
    if (cur.watched) return;
    _updateProgress(lessonId, cur.copyWith(watched: true));
  }

  Future<void> markQuizPassed(String lessonId) async {
    final cur = state.get(lessonId);
    _updateProgress(lessonId, cur.copyWith(quizPassed: true));
  }

  Future<void> recordActivity() async {
    final today = LearningProgressState._dateStr(DateTime.now());
    if (state.activityDates.contains(today)) return;
    final newDates = {...state.activityDates, today};
    state = state.copyWith(activityDates: newDates);
    _saveLocal(state);
    _syncToDb();
  }

  void _updateProgress(String lessonId, LessonProgress updated) {
    final newProgress = Map<String, LessonProgress>.from(state.progress);
    newProgress[lessonId] = updated;
    state = state.copyWith(progress: newProgress);
    _saveLocal(state);
    _syncToDb();
  }

  // ── DB sync ────────────────────────────────────────────────────────

  void _syncToDb() {
    if (!_isLoggedIn) return;
    final snap = state;
    _dataService.saveLearningProgress(
      progress: snap.progress.map(
        (k, v) => MapEntry(k, {'watched': v.watched, 'quizPassed': v.quizPassed}),
      ),
      activityDates: snap.activityDates.toList(),
    );
    // Fire-and-forget — local state is already updated.
  }

  // ── Local cache (SharedPrefs) ──────────────────────────────────────

  LearningProgressState _readLocal() {
    final raw = _prefs.getString(_prefsKey);
    final dates = _prefs.getStringList(_datesKey)?.toSet() ?? {};
    if (raw == null || raw.isEmpty) {
      return LearningProgressState(activityDates: dates);
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final progress = decoded.map(
        (k, v) => MapEntry(k, LessonProgress.fromJson(Map<String, dynamic>.from(v as Map))),
      );
      return LearningProgressState(progress: progress, activityDates: dates);
    } catch (_) {
      return LearningProgressState(activityDates: dates);
    }
  }

  void _saveLocal(LearningProgressState s) {
    _prefs.setString(
      _prefsKey,
      jsonEncode(s.progress.map((k, v) => MapEntry(k, v.toJson()))),
    );
    _prefs.setStringList(_datesKey, s.activityDates.toList());
  }

  // ── Helpers ────────────────────────────────────────────────────────

  Map<String, LessonProgress> _parseDbProgress(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map((k, v) {
      final map = v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
      return MapEntry(k.toString(), LessonProgress.fromJson(map));
    });
  }

  Set<String> _parseDates(dynamic raw) {
    if (raw is List) return raw.map((e) => e.toString()).toSet();
    return {};
  }

  Future<void> reset() async {
    await _prefs.remove(_prefsKey);
    await _prefs.remove(_datesKey);
    state = const LearningProgressState();
    if (_isLoggedIn) {
      _dataService.saveLearningProgress(progress: {}, activityDates: []);
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final learningProgressProvider =
    StateNotifierProvider<LearningProgressNotifier, LearningProgressState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final dataService = ref.watch(dataServiceProvider);
  final isLoggedIn = ref.watch(isLoggedInProvider);
  return LearningProgressNotifier(prefs, dataService, isLoggedIn);
});

/// Back-compat alias — existing code that calls
/// `ref.watch(learningProgressStoreProvider)` will still compile.
/// Returns the current [LearningProgressState] which has the same
/// `.get(lessonId)` API as the old store.
@Deprecated('Use learningProgressProvider instead')
final learningProgressStoreProvider =
    Provider<LearningProgressState>((ref) => ref.watch(learningProgressProvider));
