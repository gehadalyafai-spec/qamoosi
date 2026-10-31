import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qamoosi/main.dart';
import 'package:qamoosi/features/practice/practice_mistakes.dart';
import 'package:qamoosi/features/practice/practice_page.dart';
import 'package:qamoosi/features/practice/practice_questions.dart';
import 'package:qamoosi/features/practice/practice_stats.dart';

Future<void> useLargeTestScreen(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(900, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty mistake review is reassuring and does not record a score',
      (tester) async {
    await useLargeTestScreen(tester);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(
      home: PracticePage(reviewMistakes: true),
    ));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد أخطاء معلّقة للمراجعة'), findsOneWidget);
    expect(find.byKey(const Key('practice_empty_state')), findsOneWidget);
    expect(find.byKey(const Key('practice_choice_0')), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(PracticeStats.fromPreferences(prefs).attempts, 0);
  });

  testWidgets('mistake review clears answered errors in priority order',
      (tester) async {
    await useLargeTestScreen(tester);
    SharedPreferences.setMockInitialValues({
      PracticeMistakes.storageKey: jsonEncode({
        'bug': 1,
        'variable': 3,
      }),
      PracticeStats.storageKey: jsonEncode({
        'attempts': 4, 'lastScore': 3, 'bestScore': 5,
      }),
    });
    await tester.pumpWidget(const MaterialApp(
      home: PracticePage(reviewMistakes: true),
    ));
    await tester.pumpAndSettle();

    expect(find.text('الموقف 1 من 2'), findsOneWidget);
    expect(find.text(practiceQuestions.first.prompt), findsOneWidget);
    await tester.tap(find.byKey(const Key('practice_choice_1')));
    await tester.pumpAndSettle();
    expect(find.text('إجابة صحيحة!'), findsOneWidget);
    await tester.tap(find.byKey(const Key('practice_next')));
    await tester.pumpAndSettle();

    expect(find.text('الموقف 2 من 2'), findsOneWidget);
    expect(find.text(practiceQuestions[2].prompt), findsOneWidget);
    await tester.tap(find.byKey(const Key('practice_choice_0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('practice_next')));
    await tester.pumpAndSettle();

    expect(find.text('أنهيت مراجعة أخطائك!'), findsOneWidget);
    expect(find.text('مواقف تحتاج مراجعة: 0'), findsOneWidget);
    expect(find.text('ممتاز! لا توجد أخطاء متبقية حاليًا.'),
      findsOneWidget);
    expect(find.byKey(const Key('practice_retry')), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(PracticeMistakes.fromPreferences(prefs).pendingCount, 0);
    final stats = PracticeStats.fromPreferences(prefs);
    expect(stats.attempts, 4);
    expect(stats.bestScore, 5);
  });

  testWidgets('wrong normal answer creates a review that can be corrected',
      (tester) async {
    await useLargeTestScreen(tester);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: PracticePage()));
    await tester.pumpAndSettle();

    final questions = buildPracticeSession(0);
    for (var i = 0; i < questions.length; i++) {
      final choice = i == 0
          ? (questions[i].correctIndex + 1) % 4
          : questions[i].correctIndex;
      await tester.tap(find.byKey(Key('practice_choice_$choice')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('practice_next')));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const Key('practice_result')), findsOneWidget);
    expect(find.text('نتيجتك: 5 من 6'), findsOneWidget);
    expect(find.text('مواقف تحتاج مراجعة: 1'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(PracticeMistakes.fromPreferences(prefs).mistakesFor('variable'), 1);
    expect(PracticeStats.fromPreferences(prefs).attempts, 1);

    await tester.tap(find.byKey(const Key('practice_review_mistakes')));
    await tester.pumpAndSettle();
    expect(find.text('مراجعة أخطائي'), findsOneWidget);
    expect(find.text('الموقف 1 من 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('practice_choice_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('practice_next')));
    await tester.pumpAndSettle();
    expect(find.text('مواقف تحتاج مراجعة: 0'), findsOneWidget);

    expect(PracticeMistakes.fromPreferences(prefs).pendingCount, 0);
    expect(PracticeStats.fromPreferences(prefs).attempts, 1);
    expect(PracticeStats.fromPreferences(prefs).bestScore, 5);
  });

  testWidgets('home shows persisted mistake count and opens review',
      (tester) async {
    await useLargeTestScreen(tester);
    SharedPreferences.setMockInitialValues({
      PracticeMistakes.storageKey: jsonEncode({'function': 2}),
      'known_cards': ['variable'],
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    final review = find.byKey(const Key('open_mistake_review'));
    await tester.scrollUntilVisible(
      review, 150, scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('مواقف تحتاج مراجعة: 1'), findsOneWidget);
    await Scrollable.ensureVisible(tester.element(review), alignment: 0.2);
    await tester.pumpAndSettle();
    await tester.tap(review);
    await tester.pumpAndSettle();
    expect(find.text('مراجعة أخطائي'), findsOneWidget);
    expect(find.text('الموقف 1 من 1'), findsOneWidget);
    expect(find.text(practiceQuestions[1].prompt), findsOneWidget);

    await tester.tap(find.byKey(const Key('practice_choice_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('practice_next')));
    await tester.pumpAndSettle();
    expect(find.text('مواقف تحتاج مراجعة: 0'), findsOneWidget);

    await tester.tap(find.text('العودة للرئيسية'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد أخطاء معلّقة حاليًا'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(PracticeMistakes.fromPreferences(prefs).pendingCount, 0);
  });
}
