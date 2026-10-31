import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qamoosi/features/practice/practice_questions.dart';
import 'package:qamoosi/features/practice/practice_stats.dart';
import 'package:qamoosi/features/practice/practice_page.dart';
import 'package:qamoosi/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('practice has twelve scenarios, valid answers and matching vocabulary',
      () {
    final knownIds = {
      for (final lesson in lessons)
        for (final card in lesson.cards) card.id,
    };
    expect(practiceQuestions.length, 12);
    expect(practiceQuestions.map((q) => q.id).toSet().length, 12);
    for (var i = 0; i < practiceQuestions.length; i++) {
      final q = practiceQuestions[i];
      expect(q.lessonIndex, i ~/ 2);
      expect(knownIds.contains(q.id), isTrue);
      expect(q.prompt.trim().length, greaterThan(20));
      expect(q.explanation.trim().length, greaterThan(20));
      expect(q.options.length, 4);
      expect(q.options.toSet().length, 4);
      expect(q.correctIndex, inInclusiveRange(0, 3));
      expect(q.isCorrect(q.correctIndex), isTrue);
      expect(q.isCorrect((q.correctIndex + 1) % 4), isFalse);
    }
  });

  test('one practical question from each lesson; next attempt alternates',
      () {
    final first = buildPracticeSession(0);
    final second = buildPracticeSession(1);
    expect(first.length, 6);
    expect(second.length, 6);
    expect(buildPracticeSession(2).map((q) => q.id),
      first.map((q) => q.id));
    expect(buildPracticeSession(-1).map((q) => q.id),
      first.map((q) => q.id));
    for (var i = 0; i < 6; i++) {
      expect(first[i].lessonIndex, i);
      expect(second[i].lessonIndex, i);
      expect(first[i].id, isNot(second[i].id));
    }
  });

  test('completed results persist while ordinary quiz history is untouched',
      () async {
    SharedPreferences.setMockInitialValues({'quiz_attempts': 3});
    final initialPrefs = await SharedPreferences.getInstance();
    expect(PracticeStats.fromPreferences(initialPrefs).attempts, 0);

    final first = await PracticeStats.record(4);
    expect(first.attempts, 1);
    expect(first.lastScore, 4);
    expect(first.bestScore, 4);

    final second = await PracticeStats.record(2);
    expect(second.attempts, 2);
    expect(second.lastScore, 2);
    expect(second.bestScore, 4);

    final after = await SharedPreferences.getInstance();
    expect(PracticeStats.fromPreferences(after).bestScore, 4);
    expect(after.getInt('quiz_attempts'), 3);
    expect(after.getStringList('known_cards'), isNull);
  });

  test('invalid or out-of-range stored practice data is handled safely',
      () async {
    SharedPreferences.setMockInitialValues({
      PracticeStats.storageKey: '{bad json',
    });
    var prefs = await SharedPreferences.getInstance();
    expect(PracticeStats.fromPreferences(prefs).attempts, 0);

    SharedPreferences.setMockInitialValues({
      PracticeStats.storageKey: jsonEncode({
        'attempts': -3, 'lastScore': 99, 'bestScore': -10,
      }),
    });
    prefs = await SharedPreferences.getInstance();
    final restored = PracticeStats.fromPreferences(prefs);
    expect(restored.attempts, 0);
    expect(restored.lastScore, 6);
    expect(restored.bestScore, 0);
  });

  testWidgets('practice gives immediate feedback and locks answered choices',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: PracticePage()));
    await tester.pumpAndSettle();

    expect(find.text('الموقف 1 من 6'), findsOneWidget);
    expect(find.byKey(const Key('practice_prompt')), findsOneWidget);
    expect(find.byKey(const Key('practice_next')), findsNothing);

    await tester.tap(find.byKey(const Key('practice_choice_0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('practice_feedback')), findsOneWidget);
    expect(find.textContaining('الإجابة الأنسب:'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(
        find.byKey(const Key('practice_choice_1')),
      ).onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('practice_next')));
    await tester.pumpAndSettle();
    expect(find.text('الموقف 2 من 6'), findsOneWidget);
  });

  testWidgets('right practice answer advances without manual next',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: PracticePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('practice_choice_1')));
    await tester.pump();
    expect(find.text('الموقف 1 من 6'), findsOneWidget);
    expect(find.byKey(const Key('practice_next')), findsNothing);
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pumpAndSettle();

    expect(find.text('الموقف 2 من 6'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(PracticeStats.fromPreferences(prefs).attempts, 0);
    expect(prefs.getStringList('known_cards'), isNull);
  });

  testWidgets('all six answers save one attempt and retry changes questions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final first = buildPracticeSession(0);
    final second = buildPracticeSession(1);
    await tester.pumpWidget(const MaterialApp(home: PracticePage()));
    await tester.pumpAndSettle();

    for (var i = 0; i < first.length; i++) {
      expect(find.text('الموقف ${i + 1} من 6'), findsOneWidget);
      await tester.tap(
        find.byKey(Key('practice_choice_${first[i].correctIndex}')),
      );
      await tester.pump();
      expect(find.text('إجابة صحيحة!'), findsOneWidget);
      expect(find.text('إجابة صحيحة! الانتقال تلقائيًا...'), findsOneWidget);
      expect(find.byKey(const Key('practice_next')), findsNothing);
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('practice_result')), findsOneWidget);
    expect(find.text('نتيجتك: 6 من 6'), findsOneWidget);
    expect(find.text('أفضل نتيجة: 6 من 6'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(PracticeStats.fromPreferences(prefs).attempts, 1);
    expect(PracticeStats.fromPreferences(prefs).bestScore, 6);

    await tester.tap(find.byKey(const Key('practice_retry')));
    await tester.pumpAndSettle();
    expect(find.text(second.first.prompt), findsOneWidget);
    expect(find.text(first.first.prompt), findsNothing);
    expect(PracticeStats.fromPreferences(prefs).attempts, 1);
  });
}
