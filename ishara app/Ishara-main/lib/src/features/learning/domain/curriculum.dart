/// Linear multi-word curriculum.
///
/// Each LESSON teaches a small set of related signs. The QUIZ that follows
/// shows the sign video for each word and asks the user to pick the correct
/// meaning from 4 MCQ options.
///
/// Sign clips are resolved at runtime through [PslVideoService] (PSL —
/// Pakistan Sign Language dataset), the same source used by the Communicate
/// page. Each [SignWord] holds the Arabic surface form; the screen does the
/// lookup and plays the resulting MP4 with `video_player`.
///
/// A node is locked until the previous node is completed:
///   • a lesson is "completed" once the user opens it (marks `watched`)
///   • a quiz is "completed" once score ≥ 70%
library;

import 'package:equatable/equatable.dart';

enum CurriculumNodeKind { lesson, quiz }

/// A single sign taught inside a multi-word lesson.
///
/// `wordAr` is the Arabic surface form fed into [PslVideoService.lookup]
/// — every entry in this file MUST be present in `_arabicToEnglish` and
/// resolve to a clip URL.
class SignWord extends Equatable {
  const SignWord({
    required this.wordAr,
    required this.wordEn,
    this.description = '',
  });
  final String wordAr;
  final String wordEn;
  final String description;

  @override
  List<Object?> get props => [wordAr, wordEn];
}

class CurriculumNode extends Equatable {
  const CurriculumNode({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    this.lessonId,
    this.words = const [],
  });

  final String id;
  final CurriculumNodeKind kind;
  final String title;
  final String subtitle;

  /// For a quiz: which lesson it tests.
  /// For a lesson: its own stable id (used as progress key).
  final String? lessonId;

  /// Words taught in this lesson (lessons only). Quizzes derive their
  /// questions from `kLessons[lessonId].words` plus distractors from
  /// other lessons' words.
  final List<SignWord> words;

  @override
  List<Object?> get props => [id, kind];
}

// ── Word bank ────────────────────────────────────────────────────────────────
// Every word here is verified to resolve through PslVideoService → MP4 URL.

const _father = SignWord(
  wordAr: 'أب',
  wordEn: 'Father',
  description: 'A male parent.',
);
const _mother = SignWord(
  wordAr: 'أم',
  wordEn: 'Mother',
  description: 'A female parent.',
);
const _brother = SignWord(
  wordAr: 'أخ',
  wordEn: 'Brother',
);
const _sister = SignWord(
  wordAr: 'أخت',
  wordEn: 'Sister',
);

const _book = SignWord(
  wordAr: 'كتاب',
  wordEn: 'Book',
  description: 'Something you read.',
);
const _pen = SignWord(
  wordAr: 'قلم',
  wordEn: 'Pen',
  description: 'Something you write with.',
);
const _house = SignWord(
  wordAr: 'بيت',
  wordEn: 'House',
);
const _school = SignWord(
  wordAr: 'مدرسة',
  wordEn: 'School',
);

const _police = SignWord(
  wordAr: 'شرطة',
  wordEn: 'Police',
);
const _hospital = SignWord(
  wordAr: 'مستشفى',
  wordEn: 'Hospital',
);
const _car = SignWord(
  wordAr: 'سيارة',
  wordEn: 'Car',
);
const _doctor = SignWord(
  wordAr: 'طبيب',
  wordEn: 'Doctor',
);

// Numbers
const _one = SignWord(wordAr: 'واحد', wordEn: 'One');
const _two = SignWord(wordAr: 'اثنان', wordEn: 'Two');
const _three = SignWord(wordAr: 'ثلاثة', wordEn: 'Three');
const _four = SignWord(wordAr: 'اربعة', wordEn: 'Four');
const _five = SignWord(wordAr: 'خمسة', wordEn: 'Five');

// Colors
const _red = SignWord(wordAr: 'احمر', wordEn: 'Red');
const _blue = SignWord(wordAr: 'ازرق', wordEn: 'Blue');
const _green = SignWord(wordAr: 'اخضر', wordEn: 'Green');
const _yellow = SignWord(wordAr: 'اصفر', wordEn: 'Yellow');

// Animals
const _cat = SignWord(wordAr: 'قطة', wordEn: 'Cat');
const _dog = SignWord(wordAr: 'كلب', wordEn: 'Dog');
const _horse = SignWord(wordAr: 'حصان', wordEn: 'Horse');
const _bird = SignWord(wordAr: 'عصفور', wordEn: 'Sparrow');

// Food
const _bread = SignWord(wordAr: 'خبز', wordEn: 'Bread');
const _rice = SignWord(wordAr: 'ارز', wordEn: 'Rice');
const _milk = SignWord(wordAr: 'حليب', wordEn: 'Milk');
const _apple = SignWord(wordAr: 'تفاح', wordEn: 'Apple');

// Time
const _day = SignWord(wordAr: 'يوم', wordEn: 'Day');
const _night = SignWord(wordAr: 'ليل', wordEn: 'Night');
const _today = SignWord(wordAr: 'اليوم', wordEn: 'Today');
const _tomorrow = SignWord(wordAr: 'غدا', wordEn: 'Tomorrow');

// ── Lessons ──────────────────────────────────────────────────────────────────

const Map<String, List<SignWord>> kLessons = {
  'lesson_family': [_father, _mother, _brother, _sister],
  'lesson_daily': [_book, _pen, _house, _school],
  'lesson_emergency': [_police, _hospital, _car, _doctor],
  'lesson_numbers': [_one, _two, _three, _four, _five],
  'lesson_colors': [_red, _blue, _green, _yellow],
  'lesson_animals': [_cat, _dog, _horse, _bird],
  'lesson_food': [_bread, _rice, _milk, _apple],
  'lesson_time': [_day, _night, _today, _tomorrow],
};

/// Ordered curriculum: lesson → quiz → lesson → quiz → …
const List<CurriculumNode> kCurriculum = [
  CurriculumNode(
    id: 'l_family',
    kind: CurriculumNodeKind.lesson,
    title: 'Lesson 1 · Family',
    subtitle: 'Father · Mother · Brother · Sister',
    lessonId: 'lesson_family',
    words: [_father, _mother, _brother, _sister],
  ),
  CurriculumNode(
    id: 'q_family',
    kind: CurriculumNodeKind.quiz,
    title: 'Quiz 1 · Family',
    subtitle: 'Watch the sign · pick the meaning',
    lessonId: 'lesson_family',
  ),
  CurriculumNode(
    id: 'l_daily',
    kind: CurriculumNodeKind.lesson,
    title: 'Lesson 2 · Daily life',
    subtitle: 'Book · Pen · House · School',
    lessonId: 'lesson_daily',
    words: [_book, _pen, _house, _school],
  ),
  CurriculumNode(
    id: 'q_daily',
    kind: CurriculumNodeKind.quiz,
    title: 'Quiz 2 · Daily life',
    subtitle: 'Watch the sign · pick the meaning',
    lessonId: 'lesson_daily',
  ),
  CurriculumNode(
    id: 'l_emergency',
    kind: CurriculumNodeKind.lesson,
    title: 'Lesson 3 · Emergency',
    subtitle: 'Police · Hospital · Car · Doctor',
    lessonId: 'lesson_emergency',
    words: [_police, _hospital, _car, _doctor],
  ),
  CurriculumNode(
    id: 'q_emergency',
    kind: CurriculumNodeKind.quiz,
    title: 'Quiz 3 · Emergency',
    subtitle: 'Watch the sign · pick the meaning',
    lessonId: 'lesson_emergency',
  ),
  CurriculumNode(
    id: 'l_numbers',
    kind: CurriculumNodeKind.lesson,
    title: 'Lesson 4 · Numbers',
    subtitle: 'One · Two · Three · Four · Five',
    lessonId: 'lesson_numbers',
    words: [_one, _two, _three, _four, _five],
  ),
  CurriculumNode(
    id: 'q_numbers',
    kind: CurriculumNodeKind.quiz,
    title: 'Quiz 4 · Numbers',
    subtitle: 'Watch the sign · pick the meaning',
    lessonId: 'lesson_numbers',
  ),
  CurriculumNode(
    id: 'l_colors',
    kind: CurriculumNodeKind.lesson,
    title: 'Lesson 5 · Colors',
    subtitle: 'Red · Blue · Green · Yellow',
    lessonId: 'lesson_colors',
    words: [_red, _blue, _green, _yellow],
  ),
  CurriculumNode(
    id: 'q_colors',
    kind: CurriculumNodeKind.quiz,
    title: 'Quiz 5 · Colors',
    subtitle: 'Watch the sign · pick the meaning',
    lessonId: 'lesson_colors',
  ),
  CurriculumNode(
    id: 'l_animals',
    kind: CurriculumNodeKind.lesson,
    title: 'Lesson 6 · Animals',
    subtitle: 'Cat · Dog · Horse · Sparrow',
    lessonId: 'lesson_animals',
    words: [_cat, _dog, _horse, _bird],
  ),
  CurriculumNode(
    id: 'q_animals',
    kind: CurriculumNodeKind.quiz,
    title: 'Quiz 6 · Animals',
    subtitle: 'Watch the sign · pick the meaning',
    lessonId: 'lesson_animals',
  ),
  CurriculumNode(
    id: 'l_food',
    kind: CurriculumNodeKind.lesson,
    title: 'Lesson 7 · Food',
    subtitle: 'Bread · Rice · Milk · Apple',
    lessonId: 'lesson_food',
    words: [_bread, _rice, _milk, _apple],
  ),
  CurriculumNode(
    id: 'q_food',
    kind: CurriculumNodeKind.quiz,
    title: 'Quiz 7 · Food',
    subtitle: 'Watch the sign · pick the meaning',
    lessonId: 'lesson_food',
  ),
  CurriculumNode(
    id: 'l_time',
    kind: CurriculumNodeKind.lesson,
    title: 'Lesson 8 · Time',
    subtitle: 'Day · Night · Today · Tomorrow',
    lessonId: 'lesson_time',
    words: [_day, _night, _today, _tomorrow],
  ),
  CurriculumNode(
    id: 'q_time',
    kind: CurriculumNodeKind.quiz,
    title: 'Quiz 8 · Time',
    subtitle: 'Watch the sign · pick the meaning',
    lessonId: 'lesson_time',
  ),
];

/// All words across all lessons — used to build distractor options.
List<SignWord> get kAllWords =>
    kLessons.values.expand((w) => w).toList(growable: false);

double get kPassThreshold => 0.7;

// ── Localized labels for Path-tab nodes ──────────────────────────────────────
// The const `CurriculumNode.title`/`subtitle` fields are English-only because
// they have to be `const`. The Path tab calls these helpers instead so the
// labels track the active app language.

class LocalizedNode {
  const LocalizedNode({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
}

const Map<String, LocalizedNode> _kNodeLabelsEn = {
  'l_family':    LocalizedNode(title: 'Lesson 1 · Family',     subtitle: 'Father · Mother · Brother · Sister'),
  'q_family':    LocalizedNode(title: 'Quiz 1 · Family',       subtitle: 'Watch the sign · pick the meaning'),
  'l_daily':     LocalizedNode(title: 'Lesson 2 · Daily life', subtitle: 'Book · Pen · House · School'),
  'q_daily':     LocalizedNode(title: 'Quiz 2 · Daily life',   subtitle: 'Watch the sign · pick the meaning'),
  'l_emergency': LocalizedNode(title: 'Lesson 3 · Emergency',  subtitle: 'Police · Hospital · Car · Doctor'),
  'q_emergency': LocalizedNode(title: 'Quiz 3 · Emergency',    subtitle: 'Watch the sign · pick the meaning'),
  'l_numbers':   LocalizedNode(title: 'Lesson 4 · Numbers',    subtitle: 'One · Two · Three · Four · Five'),
  'q_numbers':   LocalizedNode(title: 'Quiz 4 · Numbers',      subtitle: 'Watch the sign · pick the meaning'),
  'l_colors':    LocalizedNode(title: 'Lesson 5 · Colors',     subtitle: 'Red · Blue · Green · Yellow'),
  'q_colors':    LocalizedNode(title: 'Quiz 5 · Colors',       subtitle: 'Watch the sign · pick the meaning'),
  'l_animals':   LocalizedNode(title: 'Lesson 6 · Animals',    subtitle: 'Cat · Dog · Horse · Sparrow'),
  'q_animals':   LocalizedNode(title: 'Quiz 6 · Animals',      subtitle: 'Watch the sign · pick the meaning'),
  'l_food':      LocalizedNode(title: 'Lesson 7 · Food',       subtitle: 'Bread · Rice · Milk · Apple'),
  'q_food':      LocalizedNode(title: 'Quiz 7 · Food',         subtitle: 'Watch the sign · pick the meaning'),
  'l_time':      LocalizedNode(title: 'Lesson 8 · Time',       subtitle: 'Day · Night · Today · Tomorrow'),
  'q_time':      LocalizedNode(title: 'Quiz 8 · Time',         subtitle: 'Watch the sign · pick the meaning'),
};

const Map<String, LocalizedNode> _kNodeLabelsAr = {
  'l_family':    LocalizedNode(title: 'الدرس ١ · العائلة',       subtitle: 'أب · أم · أخ · أخت'),
  'q_family':    LocalizedNode(title: 'اختبار ١ · العائلة',     subtitle: 'شاهد الإشارة واختر المعنى'),
  'l_daily':     LocalizedNode(title: 'الدرس ٢ · الحياة اليومية', subtitle: 'كتاب · قلم · بيت · مدرسة'),
  'q_daily':     LocalizedNode(title: 'اختبار ٢ · الحياة اليومية', subtitle: 'شاهد الإشارة واختر المعنى'),
  'l_emergency': LocalizedNode(title: 'الدرس ٣ · الطوارئ',      subtitle: 'شرطة · مستشفى · سيارة · طبيب'),
  'q_emergency': LocalizedNode(title: 'اختبار ٣ · الطوارئ',     subtitle: 'شاهد الإشارة واختر المعنى'),
  'l_numbers':   LocalizedNode(title: 'الدرس ٤ · الأرقام',       subtitle: 'واحد · اثنان · ثلاثة · أربعة · خمسة'),
  'q_numbers':   LocalizedNode(title: 'اختبار ٤ · الأرقام',     subtitle: 'شاهد الإشارة واختر المعنى'),
  'l_colors':    LocalizedNode(title: 'الدرس ٥ · الألوان',      subtitle: 'أحمر · أزرق · أخضر · أصفر'),
  'q_colors':    LocalizedNode(title: 'اختبار ٥ · الألوان',    subtitle: 'شاهد الإشارة واختر المعنى'),
  'l_animals':   LocalizedNode(title: 'الدرس ٦ · الحيوانات',    subtitle: 'قطة · كلب · حصان · عصفور'),
  'q_animals':   LocalizedNode(title: 'اختبار ٦ · الحيوانات',  subtitle: 'شاهد الإشارة واختر المعنى'),
  'l_food':      LocalizedNode(title: 'الدرس ٧ · الطعام',        subtitle: 'خبز · أرز · حليب · تفاح'),
  'q_food':      LocalizedNode(title: 'اختبار ٧ · الطعام',      subtitle: 'شاهد الإشارة واختر المعنى'),
  'l_time':      LocalizedNode(title: 'الدرس ٨ · الوقت',          subtitle: 'يوم · ليل · اليوم · غداً'),
  'q_time':      LocalizedNode(title: 'اختبار ٨ · الوقت',        subtitle: 'شاهد الإشارة واختر المعنى'),
};

LocalizedNode localizedNode(CurriculumNode node, {required bool isArabic}) {
  final table = isArabic ? _kNodeLabelsAr : _kNodeLabelsEn;
  return table[node.id] ??
      LocalizedNode(title: node.title, subtitle: node.subtitle);
}
