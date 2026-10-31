import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qamoosi/main.dart';
import 'package:qamoosi/core/quiz_stats.dart';
import 'package:qamoosi/core/daily_learning_progress.dart';
import 'package:qamoosi/features/achievements/achievements_panel.dart';
import 'package:qamoosi/features/path/learning_path_card.dart';

/// A home action may not exist in the element tree until its sliver is
/// scrolled into view. Move it away from the floating bottom navigation
/// before tapping so the test behaves like a real user.
Future<void> openHomeAction(WidgetTester tester, Key actionKey) async {
  final action = find.byKey(actionKey);
  await tester.scrollUntilVisible(
    action,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(
    tester.element(action),
    alignment: 0.25,
  );
  await tester.pumpAndSettle();
  await tester.tap(action);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('achievement summary clamps and safely handles empty lessons', () {
    const empty = LessonAchievement(title: 'فارغ', completed: 0, total: 0);
    const partial = LessonAchievement(title: 'جزئي', completed: 2, total: 5);
    const finished = LessonAchievement(title: 'مكتمل', completed: 5, total: 5);
    expect(empty.progress, 0);
    expect(empty.isCompleted, isFalse);
    expect(partial.progress, 0.4);
    expect(partial.isCompleted, isFalse);
    expect(finished.progress, 1);
    expect(finished.isCompleted, isTrue);
  });

  testWidgets('achievements display saved learning progress', (tester) async {
    SharedPreferences.setMockInitialValues({
      'known_cards': ['variable'],
      'quiz_attempts': 2,
      'quiz_last_score': 3,
      'quiz_best_score': 5,
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنجازاتي').last);
    await tester.pumpAndSettle();
    expect(find.text('أتقنت 1 من 60 بطاقة'), findsOneWidget);
    expect(find.text('دروس مكتملة'), findsOneWidget);
    expect(find.text('مستحقة للمراجعة'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('achievements_quiz_stats')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('آخر نتيجة: 3 من 6'), findsOneWidget);
    expect(find.text('الاختبارات المكتملة: 2'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('تفاصيل الدروس'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('تفاصيل الدروس'), findsOneWidget);
  });

  test('quiz covers all six lessons and rotates after each attempt', () {
    final firstAttempt = buildQuizCards(0);
    final secondAttempt = buildQuizCards(1);
    expect(firstAttempt.length, lessons.length);
    expect(firstAttempt.map((card) => card.id).toSet().length, lessons.length);
    for (var i = 0; i < lessons.length; i++) {
      expect(lessons[i].cards.contains(firstAttempt[i]), isTrue);
      expect(lessons[i].cards.contains(secondAttempt[i]), isTrue);
      expect(firstAttempt[i].id, isNot(secondAttempt[i].id));
    }
    expect(firstAttempt.first.word, 'Variable');
    expect(secondAttempt.first.word, 'Constant');
  });

  test('six-question quizzes cycle through all sixty words in ten attempts', () {
    final seen = <String>{};
    for (var attempt = 0; attempt < 10; attempt++) {
      final questions = buildQuizCards(attempt);
      expect(questions.length, 6);
      for (final card in questions) {
        expect(seen.add(card.id), isTrue,
          reason: 'Duplicate question for ${card.id} before full rotation');
      }
    }
    expect(seen.length, 60);
  });

  test('completed quiz history keeps best result and counts attempts', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(QuizStats.fromPreferences(prefs).attempts, 0);
    final first = await QuizStats.record(prefs, 4);
    expect(first.attempts, 1);
    expect(first.lastScore, 4);
    expect(first.bestScore, 4);
    final second = await QuizStats.record(prefs, 2);
    expect(second.attempts, 2);
    expect(second.lastScore, 2);
    expect(second.bestScore, 4);
    expect(QuizStats.fromPreferences(prefs).bestScore, 4);
  });

  testWidgets('daily goal loads and saves a changed target', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final progress = DailyLearningProgress()
        .recordSuccess('variable', now)
        .recordSuccess('function', now);
    SharedPreferences.setMockInitialValues({
      DailyLearningProgress.storageKey: jsonEncode(progress.toJson()),
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    expect(find.text('هدفك اليوم'), findsOneWidget);
    expect(find.text('2 من 5 بطاقات'), findsOneWidget);
    await tester.tap(find.byKey(const Key('daily_goal_selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 بطاقات يوميًا').last);
    await tester.pumpAndSettle();
    expect(find.text('2 من 3 بطاقات'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    final json = jsonDecode(prefs.getString(DailyLearningProgress.storageKey)!);
    final restored = DailyLearningProgress.fromJson(json);
    expect(restored.dailyGoal, 3);
    expect(restored.countOn(now), 2);
  });

  testWidgets('achievements show seven-day learning activity', (tester) async {
    final now = DateTime.now();
    final progress = DailyLearningProgress()
        .recordSuccess('variable', now);
    SharedPreferences.setMockInitialValues({
      DailyLearningProgress.storageKey: jsonEncode(progress.toJson()),
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنجازاتي').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('weekly_activity_panel')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('نشاط آخر 7 أيام'), findsOneWidget);
    expect(find.text('سلسلة التعلم: 1 يوم'), findsOneWidget);
    expect(find.text('أيام النشاط: 1'), findsOneWidget);
  });

  test('lesson progress counts only known cards in that lesson', () {
    final lesson = lessons.first;
    expect(lessonProgress(lesson, {}), 0);
    expect(lessonProgress(lesson, {lesson.cards.first.id}), 0.1);
    expect(lessonProgress(lesson, {for (final card in lesson.cards) card.id}), 1);
    expect(lessonProgress(lesson, {'unknown-card'}), 0);
  });

  test('learning path suggests unfinished beginner lessons first', () {
    expect(recommendNextLesson(lessons, {} )?.title, 'أساسيات البرمجة');

    final basicsDone = {
      for (final card in lessons.first.cards) card.id,
    };
    expect(
      recommendNextLesson(lessons, basicsDone)?.title,
      'الملفات والمجلدات',
    );

    final beginnerDone = {
      for (final lesson in lessons)
        if (lesson.level == LearningLevel.beginner)
          for (final card in lesson.cards) card.id,
    };
    expect(
      recommendNextLesson(lessons, beginnerDone)?.title,
      'الأخطاء والتطوير',
    );
    final allDone = {
      for (final lesson in lessons)
        for (final card in lesson.cards) card.id,
    };
    expect(recommendNextLesson(lessons, allDone), isNull);
    expect(recommendNextLesson(const <Lesson>[], {}), isNull);
    expect(
      recommendNextLesson(
        const [Lesson('فارغ', <CardEntry>[])],
        {},
      ),
      isNull,
    );
  });

  test('learning path resumes remaining cards with unchanged IDs', () {
    final original = lessons.first;
    final remaining = lessonRemainingToLearn(original, {'variable'});
    expect(original.cards.length, 10);
    expect(remaining.cards.length, 9);
    expect(remaining.title, original.title);
    expect(remaining.level, original.level);
    expect(remaining.cards.first.word, 'Constant');
    expect(
      remaining.cards.map((card) => card.id).toList(),
      original.cards.skip(1).map((card) => card.id).toList(),
    );
    expect(lessonRemainingToLearn(original, {
      for (final card in original.cards) card.id,
    }).cards, isEmpty);
  });

  testWidgets('recommended path opens first unlearned card', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'known_cards': ['variable'],
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    await openHomeAction(tester, const Key('learning_path_start'));
    expect(find.text('أساسيات البرمجة'), findsOneWidget);
    expect(find.text('Constant'), findsOneWidget);
    expect(find.text('البطاقة 1 من 9'), findsOneWidget);
  });

  testWidgets('finishing suggested lesson advances to next beginner lesson',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'known_cards': [
        for (final card in lessons.first.cards.take(9)) card.id,
      ],
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();

    await openHomeAction(tester, const Key('learning_path_start'));
    expect(find.text('Object'), findsOneWidget);
    expect(find.text('البطاقة 1 من 1'), findsOneWidget);

    await tester.tap(find.text('عرفتها'));
    await tester.pumpAndSettle();

    final card = tester.widget<LearningPathCard>(
      find.byKey(const Key('learning_path_card')),
    );
    expect(card.lessonTitle, 'الملفات والمجلدات');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('known_cards'), contains('object'));
  });

  testWidgets('completed path displays celebration instead of start',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'known_cards': [
        for (final lesson in lessons)
          for (final card in lesson.cards) card.id,
      ],
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('learning_path_complete')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('أكملت المسار الحالي'), findsOneWidget);
    expect(find.byKey(const Key('learning_path_start')), findsNothing);
  });

  test('levels partition all lessons without duplicate cards', () {
    final beginner = filterLessonsByLevel(lessons, LearningLevel.beginner);
    final intermediate = filterLessonsByLevel(lessons, LearningLevel.intermediate);
    final all = filterLessonsByLevel(lessons, null);
    expect(all.length, 6);
    expect(beginner.length, 3);
    expect(intermediate.length, 3);
    expect(beginner.map((lesson) => lesson.title).toSet(), {
      'أساسيات البرمجة', 'الملفات والمجلدات', 'تشغيل البرامج',
    });
    expect(intermediate.map((lesson) => lesson.title).toSet(), {
      'الأخطاء والتطوير', 'Git وGitHub', 'الويب وقواعد البيانات',
    });
    final idsByLevel = {
      for (final lesson in beginner) ...lesson.cards.map((card) => card.id),
      for (final lesson in intermediate) ...lesson.cards.map((card) => card.id),
    };
    expect(idsByLevel.length, 60);
    expect(filterLessonsByLevel(const [], null), isEmpty);
  });

  testWidgets('lesson level filters do not reset saved progress', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'known_cards': ['variable'],
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('level_intermediate')),
      170,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('الدروس المعروضة: 6'), findsOneWidget);

    await tester.tap(find.byKey(const Key('level_intermediate')));
    await tester.pumpAndSettle();
    expect(find.text('الدروس المعروضة: 3'), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(
        find.byKey(const Key('level_intermediate')),
      ).selected,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('level_beginner')));
    await tester.pumpAndSettle();
    expect(find.text('الدروس المعروضة: 3'), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(
        find.byKey(const Key('level_beginner')),
      ).selected,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('level_all')));
    await tester.pumpAndSettle();
    expect(find.text('الدروس المعروضة: 6'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('known_cards'), ['variable']);
  });

  test('expansion preserves original learning identifiers and their order', () {
    const originalIds = <List<String>>[
      ['variable', 'constant', 'function', 'parameter', 'return'],
      ['bug', 'debug', 'syntax', 'build', 'release'],
      ['repository', 'branch', 'commit', 'push', 'pull'],
      ['file', 'folder', 'path', 'save', 'open'],
      ['server', 'client', 'database', 'api', 'request'],
      ['run', 'compile', 'output', 'input', 'result'],
    ];
    for (var i = 0; i < lessons.length; i++) {
      expect(
        lessons[i].cards.take(5).map((card) => card.id).toList(),
        originalIds[i],
      );
    }
  });

  test('vocabulary has six lessons, sixty unique cards', () {
    expect(lessons.length, 6);
    final cards = [for (final lesson in lessons) ...lesson.cards];
    expect(cards.length, 60);
    expect(lessons.every((lesson) => lesson.cards.length == 10), isTrue);
    expect(cards.map((card) => card.id).toSet().length, cards.length);
    expect(cards.every((card) => card.word.isNotEmpty && card.translation.isNotEmpty && card.pronunciation.isNotEmpty), isTrue);
  });
  testWidgets('home lists lessons and opens first flashcard', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    expect(find.text('الإنجليزية التقنية'), findsOneWidget);
    await openHomeAction(tester, const Key('lesson_0'));
    expect(find.text('Variable'), findsOneWidget);
    await tester.tap(find.byKey(const Key('flip_card')));
    await tester.pumpAndSettle();
    expect(find.text('متغير'), findsOneWidget);
  });

  testWidgets('bottom navigation opens progress and review', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنجازاتي').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('أتقنت'), findsOneWidget);
    await tester.tap(find.text('المراجعة').last);
    await tester.pumpAndSettle();
    expect(find.text('بطاقات مستحقة: 0'), findsOneWidget);
  });
  testWidgets('review tab launches only due flashcards', (tester) async {
    SharedPreferences.setMockInitialValues({
      'review_states': jsonEncode({
        'variable': {
          'dueAt': '2020-01-01T00:00:00.000Z',
          'intervalDays': 1,
          'successfulReviews': 1,
        },
      }),
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('المراجعة').last);
    await tester.pumpAndSettle();
    expect(find.text('بطاقات مستحقة: 1'), findsOneWidget);
    await tester.tap(find.text('ابدأ المراجعة الآن'));
    await tester.pumpAndSettle();
    expect(find.text('مراجعة البطاقات المستحقة'), findsOneWidget);
    expect(find.text('Variable'), findsOneWidget);
    expect(find.text('البطاقة 1 من 1'), findsOneWidget);
  });

  testWidgets('quiz starts and shows first question', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    await openHomeAction(tester, const Key('open_quiz'));
    expect(find.text('اختبار الكلمات'), findsOneWidget);
    expect(find.text('السؤال 1 من 6'), findsOneWidget);
    expect(find.text('Variable'), findsOneWidget);
  });
  testWidgets('six-question quiz saves score and advances to new words', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: QuizPage()));
    await tester.pumpAndSettle();
    expect(find.text('Variable'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      expect(find.text('السؤال ${i + 1} من 6'), findsOneWidget);
      await tester.tap(find.byKey(const Key('quiz_choice_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quiz_next')));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('نتيجتك:'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('quiz_attempts'), 1);
    expect(prefs.getInt('quiz_last_score'), isNotNull);
    await tester.tap(find.text('اختبار جديد'));
    await tester.pumpAndSettle();
    expect(find.text('Constant'), findsOneWidget);
  });

  testWidgets('favorites can be saved, filtered and reopened offline', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: WordSearchPage()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('word_search_field')), 'Variable',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('favorite_variable')));
    await tester.pumpAndSettle();

    expect(find.text('المفضلة (1)'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorite_word_ids_v1'), ['variable']);

    await tester.tap(find.byKey(const Key('favorites_filter')));
    await tester.pumpAndSettle();
    expect(find.text('متغير'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('word_search_field')), 'Function',
    );
    await tester.pumpAndSettle();
    expect(find.text('لم نعثر على كلمات مطابقة'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: WordSearchPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('favorites_filter')));
    await tester.pumpAndSettle();
    expect(find.text('Variable'), findsOneWidget);

    await tester.tap(find.byKey(const Key('favorite_variable')));
    await tester.pumpAndSettle();
    expect(find.text('المفضلة (0)'), findsOneWidget);
    expect(find.text('لم نعثر على كلمات مطابقة'), findsOneWidget);
    expect(prefs.getStringList('favorite_word_ids_v1'), isEmpty);
  });

  testWidgets('search finds English and Arabic vocabulary', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    await openHomeAction(tester, const Key('open_word_search'));
    expect(find.text('البحث في قاموسي'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('word_search_field')), 'Variable');
    await tester.pumpAndSettle();
    expect(find.text('Variable'), findsWidgets);
    expect(find.text('متغير'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('word_search_field')), 'لا يوجد');
    await tester.pumpAndSettle();
    expect(find.text('لم نعثر على كلمات مطابقة'), findsOneWidget);
  });

}

