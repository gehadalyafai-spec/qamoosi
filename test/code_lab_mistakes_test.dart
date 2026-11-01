import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qamoosi/core/code_lab_mistakes.dart';
import 'package:qamoosi/core/section_quiz_stats.dart';
import 'package:qamoosi/features/code_lab/code_lab_page.dart';
import 'package:qamoosi/features/quiz/quiz_difficulty_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mistakes persist, reject obsolete IDs and update idempotently', () async {
    SharedPreferences.setMockInitialValues({
      CodeLabMistakes.storageKey: ['dart_variable', 'retired_task'],
    });
    final prefs = await SharedPreferences.getInstance();
    expect(CodeLabMistakes.fromPreferences(prefs).pendingIds,
      ['dart_variable']);
    final updated = await CodeLabMistakes.recordRound(prefs, {
      'dart_variable': true,
      'dart_return': false,
      'nonexistent': false,
    });
    expect(updated.pendingIds, ['dart_return']);
    final retried = await CodeLabMistakes.recordRound(prefs, {
      'dart_variable': true,
      'dart_return': false,
    });
    expect(retried.pendingIds, ['dart_return']);
    expect(retried.pendingExercises().single.id, 'dart_return');
    expect(retried.pendingExercises(maxExercises: 0), isEmpty);
  });

  testWidgets('review clears corrected tasks but preserves quiz scores',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      CodeLabMistakes.storageKey: ['dart_variable'],
      SectionQuizStats.storageKey:
        '{"code_lab":{"attempts":3,"lastScore":4,"bestScore":5}}',
    });
    await tester.pumpWidget(
      const MaterialApp(home: CodeLabPage(reviewMistakes: true)));
    await tester.pumpAndSettle();
    expect(find.text('مراجعة أخطاء المختبر'), findsOneWidget);
    expect(find.text('المراجعة 1 من 1'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('code_option_0')));
    await tester.tap(find.byKey(const Key('code_option_0')));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(find.text('اكتملت مراجعة أخطاء المختبر'), findsOneWidget);
    expect(find.text('لا توجد أخطاء متبقية للمراجعة'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(CodeLabMistakes.fromPreferences(prefs).pendingCount, 0);
    final stats = SectionQuizStats.fromPreferences(
      prefs, CodeLabPage.statsId);
    expect(stats.attempts, 3);
    expect(stats.lastScore, 4);
    expect(stats.bestScore, 5);
  });

  testWidgets('incorrect review remains pending without changing attempts',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      CodeLabMistakes.storageKey: ['dart_variable'],
    });
    await tester.pumpWidget(
      const MaterialApp(home: CodeLabPage(reviewMistakes: true)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('code_option_1')));
    await tester.tap(find.byKey(const Key('code_option_1')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('code_next')));
    await tester.tap(find.byKey(const Key('code_next')));
    await tester.pumpAndSettle();
    expect(find.text('تمارين تحتاج مراجعة: 1'), findsOneWidget);
    expect(find.byKey(const Key('code_lab_restart')), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(CodeLabMistakes.fromPreferences(prefs).pendingCount, 1);
    expect(SectionQuizStats.fromPreferences(
      prefs, CodeLabPage.statsId).attempts, 0);
  });

  testWidgets('challenge picker shows review only when pending mistakes',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      CodeLabMistakes.storageKey: ['dart_variable', 'dart_return'],
    });
    var opened = false;
    await tester.pumpWidget(MaterialApp(
      home: QuizDifficultyPicker(
        onStart: (_) async {},
        onCodeLab: () async {},
        onCodeLabMistakes: () async { opened = true; },
      ),
    ));
    await tester.pumpAndSettle();
    // The review card is below the three difficulty levels; ListView builds
    // its children lazily, so scroll before looking for the card.
    final review = find.byKey(const Key('open_code_lab_mistakes'));
    await tester.scrollUntilVisible(
      review, 180, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(review, findsOneWidget);
    expect(find.text('راجع أخطاء مختبر الكود (2)'), findsOneWidget);
    await tester.ensureVisible(review);
    await tester.tap(review);
    await tester.pumpAndSettle();
    expect(opened, isTrue);
  });
}
