import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qamoosi/main.dart';
import 'package:qamoosi/core/quiz_stats.dart';
import 'package:qamoosi/features/achievements/achievements_panel.dart';

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
    expect(find.text('أتقنت 1 من 30 بطاقة'), findsOneWidget);
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

  test('lesson progress counts only known cards in that lesson', () {
    final lesson = lessons.first;
    expect(lessonProgress(lesson, {}), 0);
    expect(lessonProgress(lesson, {lesson.cards.first.id}), 0.2);
    expect(lessonProgress(lesson, {for (final card in lesson.cards) card.id}), 1);
    expect(lessonProgress(lesson, {'unknown-card'}), 0);
  });

  test('vocabulary has six lessons, thirty unique cards', () {
    expect(lessons.length, 6);
    final cards = [for (final lesson in lessons) ...lesson.cards];
    expect(cards.length, 30);
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
    await tester.ensureVisible(find.byKey(const Key('lesson_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lesson_0')));
    await tester.pumpAndSettle();
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
    await tester.ensureVisible(find.byKey(const Key('open_quiz')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_quiz')));
    await tester.pumpAndSettle();
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

  testWidgets('search finds English and Arabic vocabulary', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_word_search')));
    await tester.pumpAndSettle();
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

