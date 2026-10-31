import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qamoosi/core/daily_learning_progress.dart';
import 'package:qamoosi/core/smart_study_plan.dart';
import 'package:qamoosi/features/plan/smart_study_plan_page.dart';
import 'package:qamoosi/main.dart';

SmartStudyPlan samplePlan({
  int todayLearned = 0,
  int dueCount = 2,
  int newCount = 3,
  int mistakes = 1,
}) => SmartStudyPlan(
  todayLearned: todayLearned,
  dailyGoal: 5,
  mastered: 10,
  totalCards: 60,
  dueCount: dueCount,
  dueCards: [
    for (var i = 0; i < dueCount && i < 5; i++)
      StudyPlanCard(id: 'due$i', word: 'Due$i'),
  ],
  newCards: [
    for (var i = 0; i < newCount; i++)
      StudyPlanCard(id: 'new$i', word: 'New$i'),
  ],
  nextLesson: newCount == 0 ? null : 'أساسيات البرمجة',
  pendingPracticeMistakes: mistakes,
  nextScheduledReview: null,
);

Future<void> scrollToPlanButton(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key), 210,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(
    tester.element(find.byKey(key)), alignment: 0.25,
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a guided plan offers review, new words, and mistakes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var refreshes = 0;
    var reviewCalls = 0;
    var learnCalls = 0;
    var mistakeCalls = 0;
    var practiceCalls = 0;
    var current = samplePlan();
    await tester.pumpWidget(MaterialApp(
      home: SmartStudyPlanPage(
        loadPlan: () async {
          refreshes++;
          return current;
        },
        onReviewCards: (ids) async {
          expect(ids, ['due0', 'due1']);
          reviewCalls++;
          current = samplePlan(dueCount: 0);
        },
        onLearnCards: (ids) async {
          expect(ids, ['new0', 'new1', 'new2']);
          learnCalls++;
          current = samplePlan(dueCount: 0, newCount: 0, todayLearned: 3);
        },
        onReviewMistakes: () async {
          mistakeCalls++;
          current = samplePlan(
            dueCount: 0, newCount: 0, todayLearned: 3, mistakes: 0);
        },
        onPractice: () async {
          practiceCalls++;
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('خطتي الذكية اليوم'), findsOneWidget);
    expect(find.text('0 من 5 بطاقات'), findsOneWidget);
    expect(find.text('مستحقة: 2'), findsOneWidget);
    expect(find.text('متقنة: 10/60'), findsOneWidget);

    await scrollToPlanButton(tester, const Key('smart_plan_review_button'));
    await tester.tap(find.byKey(const Key('smart_plan_review_button')));
    await tester.pumpAndSettle();
    expect(reviewCalls, 1);
    expect(find.text('مستحقة: 0'), findsOneWidget);

    await scrollToPlanButton(tester, const Key('smart_plan_new_button'));
    await tester.tap(find.byKey(const Key('smart_plan_new_button')));
    await tester.pumpAndSettle();
    expect(learnCalls, 1);
    expect(find.text('3 من 5 بطاقات'), findsOneWidget);

    await scrollToPlanButton(tester, const Key('smart_plan_mistakes_button'));
    await tester.tap(find.byKey(const Key('smart_plan_mistakes_button')));
    await tester.pumpAndSettle();
    expect(mistakeCalls, 1);
    expect(find.text('أخطاء: 0'), findsOneWidget);

    await scrollToPlanButton(tester, const Key('smart_plan_practice_button'));
    await tester.tap(find.byKey(const Key('smart_plan_practice_button')));
    await tester.pumpAndSettle();
    expect(practiceCalls, 1);
    expect(refreshes, greaterThanOrEqualTo(5));
  });

  testWidgets('completed goal retains practice without disabled-work taps',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var practices = 0;
    await tester.pumpWidget(MaterialApp(
      home: SmartStudyPlanPage(
        loadPlan: () async => SmartStudyPlan(
          todayLearned: 5,
          dailyGoal: 5,
          mastered: 60,
          totalCards: 60,
          dueCount: 0,
          dueCards: const [],
          newCards: const [],
          nextLesson: null,
          pendingPracticeMistakes: 0,
          nextScheduledReview: DateTime(2026, 11, 1, 14),
        ),
        onReviewCards: (_) async => fail('review disabled'),
        onLearnCards: (_) async => fail('learning disabled'),
        onReviewMistakes: () async => fail('mistakes disabled'),
        onPractice: () async { practices++; },
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('5 من 5 بطاقات'), findsOneWidget);
    expect(find.byKey(const Key('smart_plan_completed')), findsOneWidget);
    await scrollToPlanButton(tester, const Key('smart_plan_review_button'));
    expect(tester.widget<FilledButton>(
      find.byKey(const Key('smart_plan_review_button'))).onPressed, isNull);
    await scrollToPlanButton(tester, const Key('smart_plan_new_button'));
    expect(tester.widget<FilledButton>(
      find.byKey(const Key('smart_plan_new_button'))).onPressed, isNull);
    await scrollToPlanButton(tester, const Key('smart_plan_mistakes_button'));
    expect(tester.widget<FilledButton>(
      find.byKey(const Key('smart_plan_mistakes_button'))).onPressed, isNull);
    await scrollToPlanButton(tester, const Key('smart_plan_practice_button'));
    await tester.tap(find.byKey(const Key('smart_plan_practice_button')));
    await tester.pumpAndSettle();
    expect(practices, 1);
  });

  testWidgets('plan displays retry if data cannot be loaded',
      (tester) async {
    var attempt = 0;
    await tester.pumpWidget(MaterialApp(
      home: SmartStudyPlanPage(
        loadPlan: () async {
          attempt++;
          if (attempt == 1) throw StateError('simulated offline failure');
          return samplePlan(dueCount: 0, newCount: 1, mistakes: 0);
        },
        onReviewCards: (_) async {},
        onLearnCards: (_) async {},
        onReviewMistakes: () async {},
        onPractice: () async {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('smart_plan_retry')), findsOneWidget);
    expect(find.textContaining('تعذّر تحميل خطة اليوم'), findsOneWidget);
    await tester.tap(find.byKey(const Key('smart_plan_retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('smart_plan_goal')), findsOneWidget);
    expect(attempt, 2);
  });

  testWidgets('home plan navigates into selected new cards and refreshes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      DailyLearningProgress.storageKey: jsonEncode(
        DailyLearningProgress(dailyGoal: 3).toJson(),
      ),
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();

    final open = find.byKey(const Key('open_smart_study_plan'));
    await tester.scrollUntilVisible(
      open, 170, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(open), alignment: 0.2);
    await tester.pumpAndSettle();
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.text('خطتي الذكية اليوم'), findsOneWidget);
    expect(find.text('0 من 3 بطاقات'), findsOneWidget);

    await scrollToPlanButton(tester, const Key('smart_plan_new_button'));
    await tester.tap(find.byKey(const Key('smart_plan_new_button')));
    await tester.pumpAndSettle();
    expect(find.text('كلمات جديدة لليوم'), findsOneWidget);
    expect(find.text('Variable'), findsOneWidget);
    expect(find.text('البطاقة 1 من 3'), findsOneWidget);

    await tester.tap(find.text('عرفتها'));
    await tester.pumpAndSettle();
    expect(find.text('Constant'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('1 من 3 بطاقات'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('known_cards'), contains('variable'));
    expect(DailyLearningProgress.fromJson(
      jsonDecode(prefs.getString(DailyLearningProgress.storageKey)!)
    ).countOn(DateTime.now()), 1);
  });
}
