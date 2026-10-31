import 'package:flutter_test/flutter_test.dart';
import 'package:qamoosi/core/daily_learning_progress.dart';

void main() {
  final saturday = DateTime(2026, 10, 31);
  final friday = DateTime(2026, 10, 30);
  final thursday = DateTime(2026, 10, 29);

  test('a card counts only once each day and never on an empty rating', () {
    final initial = DailyLearningProgress();
    final first = initial.recordSuccess('variable', saturday);
    final duplicate = first.recordSuccess('variable', saturday);
    final another = duplicate.recordSuccess('function', saturday);
    final invalid = another.recordSuccess('  ', saturday);

    expect(initial.countOn(saturday), 0);
    expect(first.countOn(saturday), 1);
    expect(duplicate.countOn(saturday), 1);
    expect(another.countOn(saturday), 2);
    expect(invalid.countOn(saturday), 2);
    expect(another.remainingOn(saturday), 3);
    expect(another.fractionOn(saturday), 0.4);
    expect(another.fractionOn(friday), 0);
    expect(another.activeDays, 1);
  });

  test('a review of the same word may count on a different day', () {
    final progress = DailyLearningProgress()
        .recordSuccess('variable', friday)
        .recordSuccess('variable', saturday);
    expect(progress.countOn(friday), 1);
    expect(progress.countOn(saturday), 1);
    expect(progress.activeDays, 2);
  });

  test('daily goal is adjustable while history remains intact', () {
    final initial = DailyLearningProgress()
        .recordSuccess('variable', saturday)
        .recordSuccess('function', saturday)
        .recordSuccess('folder', saturday);
    final changed = initial.withGoal(3);
    expect(initial.dailyGoal, 5);
    expect(changed.dailyGoal, 3);
    expect(changed.fractionOn(saturday), 1);
    expect(changed.remainingOn(saturday), 0);
    expect(changed.withGoal(99).dailyGoal, 3);
    expect(changed.countOn(saturday), 3);
  });

  test('streak includes today or yesterday and stops at a missed day', () {
    final progressed = DailyLearningProgress()
        .recordSuccess('folder', thursday)
        .recordSuccess('variable', friday);
    expect(progressed.streakOn(saturday), 2);
    final today = progressed.recordSuccess('function', saturday);
    expect(today.streakOn(saturday), 3);
    final missed = DailyLearningProgress()
        .recordSuccess('folder', thursday)
        .recordSuccess('function', saturday);
    expect(missed.streakOn(saturday), 1);
    expect(DailyLearningProgress().streakOn(saturday), 0);
  });

  test('JSON round-trip preserves goals and deduplicates malformed history', () {
    final progress = DailyLearningProgress()
        .withGoal(10)
        .recordSuccess('server', saturday);
    final restored = DailyLearningProgress.fromJson(progress.toJson());
    expect(restored.dailyGoal, 10);
    expect(restored.countOn(saturday), 1);

    final malformed = DailyLearningProgress.fromJson({
      'dailyGoal': 999,
      'days': {
        '2026-10-31': ['variable', 'variable', null, 4, '  '],
        'wrong': ['server'],
        '2026-10-30': 'not a list',
      },
    });
    expect(malformed.dailyGoal, 5);
    expect(malformed.countOn(saturday), 1);
    expect(malformed.countOn(friday), 0);
    expect(DailyLearningProgress.fromJson(null).countOn(saturday), 0);
    expect(DailyLearningProgress.fromJson('invalid').dailyGoal, 5);
  });

  test('serialization returns independent objects and never mutates prior days', () {
    final first = DailyLearningProgress().recordSuccess('variable', friday);
    final updated = first.recordSuccess('function', saturday);
    expect(first.countOn(saturday), 0);
    expect(updated.countOn(saturday), 1);
    expect(first.countOn(friday), 1);
    expect(updated.countOn(friday), 1);
  });
}
