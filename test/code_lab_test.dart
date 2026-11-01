import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qamoosi/core/quiz_stats.dart';
import 'package:qamoosi/core/section_quiz_stats.dart';
import 'package:qamoosi/features/code_lab/code_lab_exercises.dart';
import 'package:qamoosi/features/code_lab/code_lab_page.dart';
import 'package:qamoosi/features/quiz/quiz_difficulty_picker.dart';
import 'package:qamoosi/main.dart';

Future<void> _tapVisible(WidgetTester tester, Finder button) async {
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pump();
}

Future<void> _answerCorrectly(
    WidgetTester tester, CodeLabExercise task) async {
  if (task.kind == CodeLabKind.missingLine) {
    final option = task.options.indexOf(task.correctAnswer);
    expect(option, greaterThanOrEqualTo(0), reason: task.id);
    await _tapVisible(tester, find.byKey(Key('code_option_$option')));
  } else {
    for (var i = 0; i < task.steps.length; i++) {
      await _tapVisible(tester, find.byKey(Key('code_step_$i')));
    }
    await _tapVisible(tester, find.byKey(const Key('code_check_order')));
  }
  expect(find.text('إجابة صحيحة!'), findsOneWidget);
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('code lab includes 12 missing-code and 12 ordering tasks, all complete',
      () {
    expect(codeLabCatalog.length, 24);
    expect(codeLabCatalog.map((task) => task.id).toSet().length, 24);
    expect(codeLabCatalog.where(
      (task) => task.kind == CodeLabKind.missingLine).length, 12);
    expect(codeLabCatalog.where(
      (task) => task.kind == CodeLabKind.orderSteps).length, 12);
    for (final task in codeLabCatalog) {
      expect(task.hasValidAnswer, isTrue, reason: task.id);
      expect(task.title.trim(), isNotEmpty);
      expect(task.prompt.trim().length, greaterThan(14), reason: task.id);
      expect(task.explanation.trim().length, greaterThan(25),
        reason: task.id);
      expect(task.term.trim(), isNotEmpty, reason: task.id);
      expect(task.translation.trim(), isNotEmpty, reason: task.id);
    }
    expect(codeLabCatalog.first.snippet, contains('_____'));
    expect(codeLabCatalog.last.id, 'release_process');
  });

  test('four sessions cover every task before repetition, alternating types',
      () {
    final seen = <String>{};
    for (var round = 0; round < 4; round++) {
      final questions = buildCodeLabRound(completedAttempts: round);
      expect(questions.length, 6);
      for (var i = 0; i < questions.length; i++) {
        expect(questions[i].kind,
          i.isEven ? CodeLabKind.missingLine : CodeLabKind.orderSteps);
        expect(seen.add(questions[i].id), isTrue, reason: questions[i].id);
      }
    }
    expect(seen.length, 24);
    expect(buildCodeLabRound(completedAttempts: 4).first.id,
      codeLabCatalog.first.id);
    expect(buildCodeLabRound(completedAttempts: -2).first.id,
      codeLabCatalog.first.id);
  });

  test('ordering is intentionally mixed, validates all steps and duplicates',
      () {
    final task = codeLabCatalog.firstWhere(
      (item) => item.kind == CodeLabKind.orderSteps);
    expect(task.shuffledStepIndices, [2, 3, 0, 1]);
    expect(task.matchesOrderedSteps([0, 1, 2, 3]), isTrue);
    expect(task.matchesOrderedSteps([2, 3, 0, 1]), isFalse);
    expect(task.matchesOrderedSteps([0, 0, 2, 3]), isFalse);
    expect(task.matchesOrderedSteps([0, 1, 2]), isFalse);
    final fill = codeLabCatalog.first;
    expect(fill.matchesOrderedSteps([]), isFalse);
  });

  test('empty catalog or disabled session creates no questions', () {
    expect(buildCodeLabRound(
      completedAttempts: 0, catalog: []), isEmpty);
    expect(buildCodeLabRound(
      completedAttempts: 0, questionCount: 0), isEmpty);
    expect(buildCodeLabRound(
      completedAttempts: 0,
      catalog: codeLabCatalog.take(2).toList(),
    ).length, 2);
  });

  testWidgets('wrong missing line reveals explanation and advances manually',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: CodeLabPage()));
    await tester.pumpAndSettle();
    expect(find.text('مختبر الكود'), findsOneWidget);
    expect(find.text('التمرين 1 من 6'), findsOneWidget);
    expect(find.byKey(const Key('code_lab_snippet')), findsOneWidget);
    await _tapVisible(tester, find.byKey(const Key('code_option_1')));
    expect(find.text('راجع الحل الصحيح'), findsOneWidget);
    expect(find.textContaining('int count = 1;'), findsWidgets);
    expect(find.byKey(const Key('code_lab_explanation')), findsOneWidget);
    expect(find.textContaining('Variable'), findsOneWidget);
    await _tapVisible(tester, find.byKey(const Key('code_next')));
    await tester.pumpAndSettle();
    expect(find.text('التمرين 2 من 6'), findsOneWidget);
    expect(find.text('رتّب الخطوات'), findsOneWidget);
    expect(find.text('الصحيح: 0'), findsOneWidget);
  });

  testWidgets('ordering supports undo, disables incomplete check and reveals solution',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1450));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: CodeLabPage()));
    await tester.pumpAndSettle();
    await _answerCorrectly(tester,
      buildCodeLabRound(completedAttempts: 0).first);
    expect(find.text('التمرين 2 من 6'), findsOneWidget);
    expect(tester.widget<FilledButton>(
      find.byKey(const Key('code_check_order'))).onPressed, isNull);
    await _tapVisible(tester, find.byKey(const Key('code_step_2')));
    expect(find.textContaining('1. نفّذ git add'), findsOneWidget);
    await _tapVisible(tester, find.byKey(const Key('code_undo_step')));
    expect(find.text('اضغط على الخطوات بالترتيب الصحيح'), findsOneWidget);

    for (final step in [2, 3, 0, 1]) {
      await _tapVisible(tester, find.byKey(Key('code_step_$step')));
    }
    await _tapVisible(tester, find.byKey(const Key('code_check_order')));
    expect(find.text('راجع الحل الصحيح'), findsOneWidget);
    expect(find.textContaining('1. أنشئ فرع تطوير'), findsOneWidget);
    expect(find.byKey(const Key('code_next')), findsOneWidget);
  });

  testWidgets('complete session saves isolated score and restarts next rotation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      QuizStats.attemptsKey: 9,
      QuizStats.bestScoreKey: 5,
      'section_quiz_stats_v1':
        '{"programming":{"attempts":2,"lastScore":3,"bestScore":5}}',
      'known_cards': ['variable'],
    });
    await tester.pumpWidget(const MaterialApp(home: CodeLabPage()));
    await tester.pumpAndSettle();
    final tasks = buildCodeLabRound(completedAttempts: 0);
    for (final task in tasks) {
      await _answerCorrectly(tester, task);
    }
    expect(find.text('اكتملت جلسة مختبر الكود'), findsOneWidget);
    expect(find.text('نتيجتك: 6 من 6'), findsOneWidget);
    expect(find.textContaining('أفضل نتيجة: 6 من 6'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(SectionQuizStats.fromPreferences(
      prefs, CodeLabPage.statsId).attempts, 1);
    expect(SectionQuizStats.fromPreferences(
      prefs, CodeLabPage.statsId).bestScore, 6);
    expect(SectionQuizStats.fromPreferences(
      prefs, 'programming').attempts, 2);
    expect(QuizStats.fromPreferences(prefs).attempts, 9);
    expect(QuizStats.fromPreferences(prefs).bestScore, 5);
    expect(prefs.getStringList('known_cards'), ['variable']);

    await _tapVisible(tester, find.byKey(const Key('code_lab_restart')));
    await tester.pumpAndSettle();
    expect(find.text('التمرين 1 من 6'), findsOneWidget);
    expect(find.text('التحقق من الشرط'), findsOneWidget);
    expect(SectionQuizStats.fromPreferences(
      prefs, CodeLabPage.statsId).attempts, 1);
  });

  testWidgets('abandoning a partial challenge does not persist a result',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: CodeLabPage()));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byKey(const Key('code_option_1')));
    expect(find.text('راجع الحل الصحيح'), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(SectionQuizStats.fromPreferences(
      prefs, CodeLabPage.statsId).attempts, 0);
  });

  testWidgets('code lab opens through challenge picker and refreshes saved best',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1450));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'section_quiz_stats_v1':
        '{"code_lab":{"attempts":2,"lastScore":3,"bestScore":5}}',
    });
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => QuizDifficultyPicker(
        onStart: (_) async {},
        onCodeLab: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const CodeLabPage()),
          );
        },
      )),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open_code_lab')), findsOneWidget);
    expect(find.byKey(const Key('code_lab_picker_stats')), findsOneWidget);
    expect(find.textContaining('أفضل درجة 5/6'), findsOneWidget);
    await _tapVisible(tester, find.byKey(const Key('open_code_lab')));
    await tester.pumpAndSettle();
    expect(find.text('مختبر الكود'), findsOneWidget);
    expect(find.text('التمرين 1 من 6'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('اختر مستوى الاختبار'), findsOneWidget);
  });

  testWidgets('home still routes to code lab through its existing challenge entry',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1450));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    final challenge = find.byKey(const Key('open_difficulty_quiz'));
    await tester.scrollUntilVisible(
      challenge, 190,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await _tapVisible(tester, challenge);
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byKey(const Key('open_code_lab')));
    await tester.pumpAndSettle();
    expect(find.text('مختبر الكود'), findsOneWidget);
    expect(find.text('التمرين 1 من 6'), findsOneWidget);
  });
}
