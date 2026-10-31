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
    expect(find.text('أتقنت 1 من 300 بطاقة'), findsOneWidget);
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

  test('quiz covers all thirty lessons in five consecutive attempts', () {
    expect(lessons.length, 30);
    for (var attempt = 0; attempt < 5; attempt++) {
      final cards = buildQuizCards(attempt);
      expect(cards.length, 6);
      expect(cards.map((card) => card.id).toSet().length, 6);
      for (var offset = 0; offset < 6; offset++) {
        expect(lessons[attempt * 6 + offset].cards.contains(cards[offset]), isTrue);
      }
    }
    expect(buildQuizCards(0).first.word, 'Variable');
    expect(buildQuizCards(1).first.word, 'CPU');
    expect(buildQuizCards(2).first.word, 'Table');
    expect(buildQuizCards(3).first.word, 'Smartphone');
    expect(buildQuizCards(4).first.word, 'Catalog');
    expect(buildQuizCards(5).first.word, 'Constant');
  });

  test('six-question quizzes cover all 300 terms in fifty attempts', () {
    final seen = <String>{};
    for (var attempt = 0; attempt < 50; attempt++) {
      final questions = buildQuizCards(attempt);
      expect(questions.length, 6);
      for (final card in questions) {
        expect(seen.add(card.id), isTrue,
          reason: 'Duplicate question for ${card.id} before full rotation');
      }
    }
    expect(seen.length, 300);
    expect(buildQuizCards(50).first.id, 'variable');
    expect(buildQuizCards(-1).first.id, 'variable');
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

    // Verify persistence and recommendation independently before touching
    // the sliver-built widget. A card can be outside the current viewport
    // after returning from the full-screen lesson.
    final prefs = await SharedPreferences.getInstance();
    final persisted = prefs.getStringList('known_cards') ?? <String>[];
    expect(persisted, contains('object'),
      reason: 'Completing the final card must persist its original ID.');
    expect(recommendNextLesson(lessons, persisted.toSet())?.title,
      'الملفات والمجلدات',
      reason: 'The next unfinished beginner lesson should be recommended.');

    final pathCard = find.byKey(const Key('learning_path_card'));
    await tester.scrollUntilVisible(
      pathCard,
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(pathCard),
      alignment: 0.2,
    );
    await tester.pumpAndSettle();

    // The key belongs to the Container rendered *inside* LearningPathCard,
    // so inspect its typed ancestor rather than casting the Container itself.
    final pathWidget = find.ancestor(
      of: pathCard,
      matching: find.byType(LearningPathCard),
    );
    expect(pathWidget, findsOneWidget);
    final card = tester.widget<LearningPathCard>(pathWidget);
    expect(card.lessonTitle, 'الملفات والمجلدات',
      reason: 'The home card should reflect the newly completed lesson.');
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
    expect(all.length, 30);
    expect(beginner.length, 11);
    expect(intermediate.length, 19);
    expect(beginner.map((lesson) => lesson.title).toSet(), {
      'أساسيات البرمجة', 'الملفات والمجلدات', 'تشغيل البرامج',
      'الحاسوب ومكوناته', 'عناصر واجهة التطبيق',
      'التصميم وتجربة المستخدم', 'الحسابات والحماية الأساسية',
      'الهاتف والتطبيقات اليومية', 'الإنترنت والاتصال بالشبكة',
      'الملفات والمستندات الرقمية', 'إدارة المشاريع والعمل الجماعي',
    });
    expect(intermediate.map((lesson) => lesson.title).toSet(), {
      'الأخطاء والتطوير', 'Git وGitHub', 'الويب وقواعد البيانات',
      'أساسيات Dart وFlutter', 'هياكل البيانات والكائنات',
      'قواعد البيانات وSQL', 'تقنيات الويب الحديثة',
      'واجهات API والاتصال', 'مفاهيم الأمان الرقمي',
      'السحابة والتشغيل الاحترافي', 'الذكاء الاصطناعي وتحليل البيانات',
      'تطوير تطبيقات الجوال ونشرها', 'بنية البرامج وصيانتها',
      'التجارة الإلكترونية وإدارة المنتجات', 'الطلبات والسداد الإلكتروني',
      'الشحن والطلبات وخدمة العملاء', 'التكاملات وأحداث الأنظمة',
      'تحليل الأعمال ولوحات البيانات', 'نماذج اللغة والذكاء الاصطناعي',
    });
    final idsByLevel = {
      for (final lesson in beginner) ...lesson.cards.map((card) => card.id),
      for (final lesson in intermediate) ...lesson.cards.map((card) => card.id),
    };
    expect(idsByLevel.length, 300);
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
    expect(find.text('الدروس المعروضة: 30'), findsOneWidget);

    await tester.tap(find.byKey(const Key('level_intermediate')));
    await tester.pumpAndSettle();
    expect(find.text('الدروس المعروضة: 19'), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(
        find.byKey(const Key('level_intermediate')),
      ).selected,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('level_beginner')));
    await tester.pumpAndSettle();
    expect(find.text('الدروس المعروضة: 11'), findsOneWidget);
    expect(
      tester.widget<ChoiceChip>(
        find.byKey(const Key('level_beginner')),
      ).selected,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('level_all')));
    await tester.pumpAndSettle();
    expect(find.text('الدروس المعروضة: 30'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('known_cards'), ['variable']);
  });

  test('lesson quick search supports title, English and Arabic offline', () {
    final integration = lessons.singleWhere((lesson) =>
        lesson.title == 'التكاملات وأحداث الأنظمة');
    expect(matchesLessonQuery(integration, 'webhook'), isTrue);
    expect(matchesLessonQuery(integration, 'ويب هوك'), isTrue);
    expect(matchesLessonQuery(integration, 'التكاملات'), isTrue);
    expect(matchesLessonQuery(integration, '  '), isTrue);
    expect(matchesLessonQuery(integration, 'ألعاب'), isFalse);
    expect(matchesLessonQuery(lessons.first, 'WEBHOOK'), isFalse);
  });

  testWidgets('home lesson search filters catalog without modifying progress',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'known_cards': ['variable', 'extra_smartphone'],
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('lesson_search_field'));
    await tester.scrollUntilVisible(
      field, 200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(field, 'Webhook');
    await tester.pumpAndSettle();
    expect(find.text('الدروس المعروضة: 1'), findsOneWidget);
    expect(find.text('التكاملات وأحداث الأنظمة'), findsOneWidget);
    expect(find.byKey(const Key('no_lesson_matches')), findsNothing);

    await tester.enterText(field, 'لا توجد كلمة بهذا الاسم');
    await tester.pumpAndSettle();
    expect(find.text('الدروس المعروضة: 0'), findsOneWidget);
    expect(find.byKey(const Key('no_lesson_matches')), findsOneWidget);

    await tester.tap(find.byKey(const Key('clear_lesson_search')));
    await tester.pumpAndSettle();
    expect(find.text('الدروس المعروضة: 30'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('known_cards'),
      ['variable', 'extra_smartphone']);
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
    for (var i = 0; i < originalIds.length; i++) {
      expect(
        lessons[i].cards.take(5).map((card) => card.id).toList(),
        originalIds[i],
      );
    }
  });

  test('vocabulary has thirty lessons and 300 unique cards', () {
    expect(lessons.length, 30);
    final cards = [for (final lesson in lessons) ...lesson.cards];
    expect(cards.length, 300);
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
  testWidgets('correct quiz answers advance automatically and save score',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final questions = buildQuizCards(0);
    await tester.pumpWidget(const MaterialApp(home: QuizPage()));
    await tester.pumpAndSettle();
    expect(find.text('Variable'), findsOneWidget);
    for (var i = 0; i < questions.length; i++) {
      expect(find.text('السؤال ${i + 1} من 6'), findsOneWidget);
      final correctChoice = List<int>.generate(4, (j) => j).singleWhere((j) {
        final option = tester.widget<OutlinedButton>(
          find.byKey(Key('quiz_choice_$j')),
        );
        return (option.child! as Text).data == questions[i].translation;
      });
      await tester.tap(find.byKey(Key('quiz_choice_$correctChoice')));
      await tester.pump();
      expect(find.text('إجابة صحيحة! الانتقال تلقائيًا...'),
        findsOneWidget);
      expect(find.byKey(const Key('quiz_next')), findsNothing);
      // Let the success state remain visible briefly before the timer fires.
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pumpAndSettle();
    }
    expect(find.text('نتيجتك: 6 من 6'), findsOneWidget);
    expect(find.byKey(const Key('quiz_no_mistakes')), findsOneWidget);
    expect(find.byKey(const Key('quiz_review_mistakes')), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('quiz_attempts'), 1);
    expect(prefs.getInt('quiz_last_score'), 6);
    await tester.tap(find.text('اختبار جديد'));
    await tester.pumpAndSettle();
    expect(find.text('CPU'), findsOneWidget);
  });

  testWidgets('wrong quiz answer requires manual continuation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: QuizPage()));
    await tester.pumpAndSettle();

    final wrongChoice = List<int>.generate(4, (j) => j).firstWhere((j) {
      final option = tester.widget<OutlinedButton>(
        find.byKey(Key('quiz_choice_$j')),
      );
      return (option.child! as Text).data != lessons.first.cards.first.translation;
    });
    await tester.tap(find.byKey(Key('quiz_choice_$wrongChoice')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();

    expect(find.text('السؤال 1 من 6'), findsOneWidget);
    expect(find.byKey(const Key('quiz_next')), findsOneWidget);
    await tester.tap(find.byKey(const Key('quiz_next')));
    await tester.pumpAndSettle();
    expect(find.text('السؤال 2 من 6'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('quiz_attempts'), isNull);
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

