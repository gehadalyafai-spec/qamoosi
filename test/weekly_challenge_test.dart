import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qamoosi/core/daily_learning_progress.dart';
import 'package:qamoosi/core/weekly_challenge.dart';
import 'package:qamoosi/features/challenges/weekly_challenge_card.dart';
import 'package:qamoosi/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Sunday starts a new week; previous Saturday cannot add progress', () {
    final activity = DailyLearningProgress()
        .recordSuccess('variable', DateTime(2026, 10, 31))
        .recordSuccess('variable', DateTime(2026, 11, 1))
        .recordSuccess('function', DateTime(2026, 11, 1))
        .recordSuccess('variable', DateTime(2026, 11, 2))
        .recordSuccess('file', DateTime(2026, 11, 3))
        .recordSuccess('retired', DateTime(2026, 11, 3));
    final sunday = WeeklyChallenge.build(
      dailyProgress: activity,
      validCardIds: {'variable', 'function', 'file'},
      now: DateTime(2026, 11, 1),
      goal: 10,
    );
    expect(sunday.weekStart, DateTime(2026, 11, 1));
    expect(sunday.weekEnd, DateTime(2026, 11, 7));
    expect(sunday.completedCards, 3);
    expect(sunday.cardIds, {'variable', 'function', 'file'});
    expect(sunday.activeDays, 3);
    expect(sunday.remainingCards, 7);
    expect(sunday.progress, 0.3);
    expect(sunday.isComplete, isFalse);

    final saturday = WeeklyChallenge.build(
      dailyProgress: activity,
      validCardIds: {'variable', 'function', 'file'},
      now: DateTime(2026, 10, 31),
    );
    expect(saturday.weekStart, DateTime(2026, 10, 25));
    expect(saturday.completedCards, 1);
    expect(saturday.activeDays, 1);
  });

  test('weekly goal choices change the presentation, never the study history',
      () {
    var activity = DailyLearningProgress();
    for (var i = 0; i < 25; i++) {
      activity = activity.recordSuccess('word$i', DateTime(2026, 11, 4));
    }
    final catalog = {for (var i = 0; i < 25; i++) 'word$i'};
    final ten = WeeklyChallenge.build(
      dailyProgress: activity,
      validCardIds: catalog,
      now: DateTime(2026, 11, 5),
      goal: 10,
    );
    final thirty = WeeklyChallenge.build(
      dailyProgress: activity,
      validCardIds: catalog,
      now: DateTime(2026, 11, 5),
      goal: 30,
    );
    expect(ten.completedCards, 25);
    expect(ten.isComplete, isTrue);
    expect(ten.progress, 1);
    expect(ten.remainingCards, 0);
    expect(thirty.completedCards, 25);
    expect(thirty.isComplete, isFalse);
    expect(thirty.remainingCards, 5);
    expect(thirty.progress, closeTo(25 / 30, 0.001));
    expect(activity.countOn(DateTime(2026, 11, 4)), 25);

    final invalid = WeeklyChallenge.build(
      dailyProgress: activity,
      validCardIds: catalog,
      now: DateTime(2026, 11, 5),
      goal: 999,
    );
    expect(invalid.goal, WeeklyChallenge.defaultGoal);
    expect(WeeklyChallenge.build(
      dailyProgress: DailyLearningProgress(),
      validCardIds: catalog,
      now: DateTime(2026, 11, 5),
    ).completedCards, 0);
  });

  test('year boundaries and future activity do not inflate current week', () {
    final progress = DailyLearningProgress()
        .recordSuccess('future', DateTime(2027, 1, 3))
        .recordSuccess('previous', DateTime(2026, 12, 31))
        .recordSuccess('current', DateTime(2027, 1, 1));
    final week = WeeklyChallenge.build(
      dailyProgress: progress,
      validCardIds: {'previous', 'current', 'future'},
      now: DateTime(2027, 1, 2),
    );
    expect(week.weekStart, DateTime(2026, 12, 27));
    expect(week.weekEnd, DateTime(2027, 1, 2));
    expect(week.cardIds, {'previous', 'current'});
    expect(week.completedCards, 2);
    final next = WeeklyChallenge.build(
      dailyProgress: progress,
      validCardIds: {'previous', 'current', 'future'},
      now: DateTime(2027, 1, 3),
    );
    expect(next.completedCards, 1);
    expect(next.cardIds, {'future'});
  });

  testWidgets('weekly card updates goal, counts and runs an actual action',
      (tester) async {
    final progress = DailyLearningProgress()
        .recordSuccess('variable', DateTime(2026, 11, 1));
    var goal = 20;
    var starts = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: StatefulBuilder(builder: (context, setState) {
        return WeeklyChallengeCard(
          challenge: WeeklyChallenge.build(
            dailyProgress: progress,
            validCardIds: {'variable', 'function'},
            now: DateTime(2026, 11, 1),
            goal: goal,
          ),
          onGoalChanged: (value) async => setState(() => goal = value),
          onStart: () async { starts++; },
          canStart: true,
        );
      }),
    )));
    await tester.pumpAndSettle();
    expect(find.text('1 من 20 بطاقة'), findsOneWidget);
    expect(find.text('1 أيام تعلم'), findsOneWidget);
    await tester.tap(find.byKey(const Key('weekly_goal_10')));
    await tester.pumpAndSettle();
    expect(find.text('1 من 10 بطاقة'), findsOneWidget);
    await tester.tap(find.byKey(const Key('weekly_challenge_start')));
    await tester.pumpAndSettle();
    expect(starts, 1);
  });

  testWidgets('weekly start is disabled when no eligible card remains',
      (tester) async {
    final progress = WeeklyChallenge.build(
      dailyProgress: DailyLearningProgress(),
      validCardIds: const {},
      now: DateTime(2026, 11, 1),
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: WeeklyChallengeCard(
        challenge: progress,
        onGoalChanged: (_) async {},
        onStart: () async => fail('must not start'),
        canStart: false,
      ),
    )));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(
      find.byKey(const Key('weekly_challenge_start'))).onPressed, isNull);
  });

  testWidgets('home weekly challenge opens unpractised words and persists goal',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1250));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'known_cards': ['variable'],
      WeeklyChallenge.storageKey: 10,
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    final card = find.byKey(const Key('weekly_challenge_card'));
    await tester.scrollUntilVisible(card, 170,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(card), alignment: 0.2);
    await tester.pumpAndSettle();
    expect(find.text('0 من 10 بطاقة'), findsOneWidget);
    await tester.tap(find.byKey(const Key('weekly_goal_20')));
    await tester.pumpAndSettle();
    expect(find.text('0 من 20 بطاقة'), findsOneWidget);
    await tester.tap(find.byKey(const Key('weekly_challenge_start')));
    await tester.pumpAndSettle();

    expect(find.text('جلسة التحدي الأسبوعي'), findsOneWidget);
    expect(find.text('Constant'), findsOneWidget);
    expect(find.text('البطاقة 1 من 6'), findsOneWidget);
    await tester.tap(find.text('عرفتها'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('known_cards'), containsAll(['variable', 'constant']));
    expect(prefs.getInt(WeeklyChallenge.storageKey), 20);
    expect(DailyLearningProgress.fromJson(
      jsonDecode(prefs.getString(DailyLearningProgress.storageKey)!)
    ).countOn(DateTime.now()), greaterThanOrEqualTo(1));
    await tester.pageBack();
    await tester.pumpAndSettle();
    final counter = find.byKey(const Key('weekly_challenge_count'));
    await tester.scrollUntilVisible(counter, 140,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('1 من 20 بطاقة'), findsOneWidget);
  });
}
