import 'package:flutter_test/flutter_test.dart';

import 'package:qamoosi/core/daily_learning_progress.dart';
import 'package:qamoosi/core/review_scheduler.dart';
import 'package:qamoosi/core/smart_study_plan.dart';

void main() {
  final now = DateTime(2026, 10, 31, 14);

  const beginner = StudyPlanLesson(
    title: 'أساسيات البرمجة',
    levelRank: 0,
    cards: [
      StudyPlanCard(id: 'variable', word: 'Variable'),
      StudyPlanCard(id: 'constant', word: 'Constant'),
      StudyPlanCard(id: 'function', word: 'Function'),
    ],
  );
  const intermediate = StudyPlanLesson(
    title: 'الأخطاء والتطوير',
    levelRank: 1,
    cards: [
      StudyPlanCard(id: 'bug', word: 'Bug'),
      StudyPlanCard(id: 'debug', word: 'Debug'),
    ],
  );

  test('prioritizes overdue cards, then beginner new words up to goal', () {
    final activity = DailyLearningProgress(dailyGoal: 3)
        .recordSuccess('function', now);
    final plan = SmartStudyPlan.build(
      // Even if source lessons are reordered, beginner comes first.
      lessons: [intermediate, beginner],
      knownIds: {'variable', 'function', 'debug'},
      reviews: {
        'function': ReviewState(
          dueAt: now.subtract(const Duration(days: 3)),
          intervalDays: 1, successfulReviews: 1),
        'variable': ReviewState(
          dueAt: now.subtract(const Duration(days: 6)),
          intervalDays: 2, successfulReviews: 2),
        'bug': ReviewState(
          dueAt: now.add(const Duration(days: 2)),
          intervalDays: 2, successfulReviews: 1),
        'retired': ReviewState(
          dueAt: now.subtract(const Duration(days: 30)),
          intervalDays: 2, successfulReviews: 1),
      },
      dailyProgress: activity,
      now: now,
      pendingPracticeMistakes: 2,
    );

    expect(plan.dueCount, 2);
    expect(plan.dueCards.map((card) => card.id).toList(),
      ['variable', 'function']);
    expect(plan.newCards.map((card) => card.id).toList(),
      ['constant', 'bug']);
    expect(plan.nextLesson, 'أساسيات البرمجة');
    expect(plan.todayLearned, 1);
    expect(plan.remainingToday, 2);
    expect(plan.mastered, 3);
    expect(plan.totalCards, 5);
    expect(plan.pendingPracticeMistakes, 2);
    expect(plan.nextScheduledReview, now.add(const Duration(days: 2)));
    expect(plan.hasActions, isTrue);
  });

  test('short sessions cap review and new words and never repeat IDs', () {
    final cards = [
      for (var i = 0; i < 15; i++)
        StudyPlanCard(id: 'card$i', word: 'Word$i'),
    ];
    final reviews = {
      for (var i = 0; i < 10; i++)
        'card$i': ReviewState(
          dueAt: now.subtract(Duration(hours: i + 1)),
          intervalDays: 1, successfulReviews: 1),
    };
    final plan = SmartStudyPlan.build(
      lessons: [
        StudyPlanLesson(title: 'أ', levelRank: 0, cards: cards),
      ],
      knownIds: {'card1', 'card2'},
      reviews: reviews,
      dailyProgress: DailyLearningProgress(dailyGoal: 10),
      now: now,
      pendingPracticeMistakes: 1,
    );
    expect(plan.dueCount, 10);
    expect(plan.dueCards.length, 5);
    expect(plan.dueCards.first.id, 'card9');
    expect(plan.newCards.length, 5);
    expect(plan.newCards.map((card) => card.id).toList(),
      ['card10', 'card11', 'card12', 'card13', 'card14']);
    final dueIds = plan.dueCards.map((card) => card.id).toSet();
    expect(plan.newCards.any((card) => dueIds.contains(card.id)), isFalse);

    final capped = SmartStudyPlan.build(
      lessons: [
        StudyPlanLesson(title: 'أ', levelRank: 0, cards: cards),
      ],
      knownIds: const {},
      reviews: const {},
      dailyProgress: DailyLearningProgress(dailyGoal: 10),
      now: now,
      pendingPracticeMistakes: -5,
      maxReviewCards: -1,
      maxNewCards: 2,
    );
    expect(capped.newCards.length, 2);
    expect(capped.dueCards, isEmpty);
    expect(capped.pendingPracticeMistakes, 0);
  });

  test('goal met suppresses new words but keeps overdue review', () {
    var activity = DailyLearningProgress(dailyGoal: 3);
    for (final id in ['variable', 'constant', 'bug']) {
      activity = activity.recordSuccess(id, now);
    }
    final plan = SmartStudyPlan.build(
      lessons: [beginner, intermediate],
      knownIds: {'variable'},
      reviews: {
        'variable': ReviewState(
          dueAt: now.subtract(const Duration(days: 1)),
          intervalDays: 1, successfulReviews: 1),
      },
      dailyProgress: activity,
      now: now,
      pendingPracticeMistakes: 0,
    );

    expect(plan.goalMet, isTrue);
    expect(plan.todayFraction, 1);
    expect(plan.newCards, isEmpty);
    expect(plan.dueCards.single.id, 'variable');
    expect(plan.allCardsMastered, isFalse);
    expect(plan.hasActions, isTrue);
  });

  test('completed journey and empty catalog do not invent review work', () {
    final complete = SmartStudyPlan.build(
      lessons: [beginner, intermediate],
      knownIds: {'variable', 'constant', 'function', 'bug', 'debug'},
      reviews: const {},
      dailyProgress: DailyLearningProgress(),
      now: now,
      pendingPracticeMistakes: 0,
    );
    expect(complete.allCardsMastered, isTrue);
    expect(complete.newCards, isEmpty);
    expect(complete.hasActions, isFalse);
    expect(complete.nextLesson, isNull);

    final empty = SmartStudyPlan.build(
      lessons: const [],
      knownIds: {'retired'},
      reviews: {},
      dailyProgress: DailyLearningProgress(),
      now: now,
      pendingPracticeMistakes: 0,
    );
    expect(empty.totalCards, 0);
    expect(empty.mastered, 0);
    expect(empty.dueCount, 0);
    expect(empty.allCardsMastered, isFalse);
  });

  test('duplicate and retired IDs are ignored with stable ordering', () {
    const duplicate = StudyPlanLesson(
      title: 'دروس أخرى',
      levelRank: 0,
      cards: [
        StudyPlanCard(id: 'variable', word: 'Duplicate'),
        StudyPlanCard(id: 'folder', word: 'Folder'),
        StudyPlanCard(id: '', word: 'Invalid'),
      ],
    );
    final plan = SmartStudyPlan.build(
      lessons: [beginner, duplicate],
      knownIds: {'retired'},
      reviews: const {},
      dailyProgress: DailyLearningProgress(),
      now: now,
      pendingPracticeMistakes: 0,
    );
    expect(plan.totalCards, 4);
    expect(plan.newCards.map((card) => card.id).toList(),
      ['variable', 'constant', 'function', 'folder']);
    expect(plan.newCards.first.word, 'Variable');
  });
}
