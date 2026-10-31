import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qamoosi/features/achievements/learning_overview.dart';
import 'package:qamoosi/features/practice/practice_mistakes.dart';
import 'package:qamoosi/features/practice/practice_stats.dart';
import 'package:qamoosi/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('level progress counts only the known cards in that level', () {
    final summary = LearningLevelProgress.fromCardIds(
      label: 'مبتدئ',
      lessonCardIds: [
        ['variable', 'constant', 'variable'],
        ['file', 'folder'],
        <String>[],
      ],
      knownIds: {'variable', 'file', 'unknown'},
    );
    expect(summary.label, 'مبتدئ');
    expect(summary.total, 4);
    expect(summary.learned, 2);
    expect(summary.remaining, 2);
    expect(summary.fraction, 0.5);
    expect(summary.completedLessons, 0);
    expect(summary.lessonCount, 3);

    final completed = LearningLevelProgress.fromCardIds(
      label: 'مكتمل',
      lessonCardIds: [
        ['file', 'folder'],
        ['variable'],
      ],
      knownIds: {'file', 'folder', 'variable'},
    );
    expect(completed.completedLessons, 2);
    expect(completed.fraction, 1);
    expect(completed.remaining, 0);
  });

  test('empty learning levels have valid zero percentages', () {
    final empty = LearningLevelProgress.fromCardIds(
      label: 'جديد',
      lessonCardIds: [<String>[], <String>[]],
      knownIds: {'variable'},
    );
    expect(empty.total, 0);
    expect(empty.fraction, 0);
    expect(empty.completedLessons, 0);
    expect(empty.lessonCount, 2);
    expect(empty.remaining, 0);
    final noLessons = LearningLevelProgress.fromCardIds(
      label: 'فارغ',
      lessonCardIds: const <List<String>>[],
      knownIds: {},
    );
    expect(noLessons.fraction, 0);
    expect(noLessons.lessonCount, 0);
  });

  testWidgets('overview shows zero state and completed journey',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var starts = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.all(16),
        child: LearningOverviewPanel(
          levels: const [
            LearningLevelProgress(
              label: 'مبتدئ',
              learned: 0,
              total: 30,
              completedLessons: 0,
              lessonCount: 3,
            ),
          ],
          practiceStats: const PracticeStats(),
          pendingMistakes: 0,
          nextLessonTitle: null,
          onContinueLesson: null,
          onPractice: () => starts++,
          onReviewMistakes: null,
        ),
      ))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('المتبقي: 30'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('أكملت المسار التعليمي!'), findsOneWidget);
    expect(find.byKey(const Key('achievements_continue_lesson')),
      findsNothing);
    expect(find.text('لم تكمل تدريبًا عمليًا بعد.'), findsOneWidget);
    expect(find.text('أخطاء تحتاج مراجعة: 0'), findsOneWidget);
    expect(find.byKey(const Key('achievements_review_mistakes')),
      findsNothing);
    final practice = find.byKey(const Key('achievements_open_practice'));
    await tester.ensureVisible(practice);
    await tester.tap(practice);
    expect(starts, 1);
  });

  testWidgets('overview has working next lesson and review actions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var continued = 0;
    var reviewed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.all(16),
        child: LearningOverviewPanel(
          levels: const [
            LearningLevelProgress(
              label: 'متوسط',
              learned: 12,
              total: 30,
              completedLessons: 1,
              lessonCount: 3,
            ),
          ],
          practiceStats: const PracticeStats(
            attempts: 3, lastScore: 4, bestScore: 6),
          pendingMistakes: 2,
          nextLessonTitle: 'Git وGitHub',
          onContinueLesson: () => continued++,
          onPractice: () {},
          onReviewMistakes: () => reviewed++,
        ),
      ))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('المتبقي: 18'), findsOneWidget);
    expect(find.text('الدروس المكتملة: 1 / 3'), findsOneWidget);
    expect(find.text('خطوتك التالية: Git وGitHub'), findsOneWidget);
    expect(find.text('آخر نتيجة: 4 من 6'), findsOneWidget);
    expect(find.text('أفضل نتيجة: 6 من 6'), findsOneWidget);
    expect(find.text('التدريبات المكتملة: 3'), findsOneWidget);
    expect(find.text('أخطاء تحتاج مراجعة: 2'), findsOneWidget);

    final next = find.byKey(const Key('achievements_continue_lesson'));
    await tester.ensureVisible(next);
    await tester.tap(next);
    expect(continued, 1);

    final review = find.byKey(const Key('achievements_review_mistakes'));
    await tester.ensureVisible(review);
    await tester.tap(review);
    expect(reviewed, 1);
  });

  testWidgets('achievements loads saved data separately and opens learning',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'known_cards': ['variable', 'constant', 'file'],
      PracticeStats.storageKey: jsonEncode({
        'attempts': 3, 'lastScore': 4, 'bestScore': 5,
      }),
      PracticeMistakes.storageKey: jsonEncode({'function': 2}),
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنجازاتي').last);
    await tester.pumpAndSettle();

    final overview = find.byKey(const Key('achievements_learning_overview'));
    await tester.scrollUntilVisible(
      overview, 220, scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('achievements_level_0')), findsOneWidget);
    expect(find.byKey(const Key('achievements_level_1')), findsOneWidget);
    expect(find.text('خطوتك التالية: أساسيات البرمجة'), findsOneWidget);

    final practiceStats = find.byKey(const Key('achievements_practice_stats'));
    await tester.scrollUntilVisible(
      practiceStats, 180, scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('آخر نتيجة: 4 من 6'), findsOneWidget);
    expect(find.text('التدريبات المكتملة: 3'), findsOneWidget);
    expect(find.text('أخطاء تحتاج مراجعة: 1'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('known_cards'),
      ['variable', 'constant', 'file']);
    expect(PracticeStats.fromPreferences(prefs).attempts, 3);
    expect(PracticeMistakes.fromPreferences(prefs).pendingCount, 1);

    final review = find.byKey(const Key('achievements_review_mistakes'));
    await Scrollable.ensureVisible(tester.element(review), alignment: 0.2);
    await tester.pumpAndSettle();
    await tester.tap(review);
    await tester.pumpAndSettle();
    expect(find.text('مراجعة أخطائي'), findsOneWidget);
    expect(find.text('الموقف 1 من 1'), findsOneWidget);
  });
}
