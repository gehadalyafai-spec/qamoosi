import 'daily_learning_progress.dart';

/// A Sunday-to-Saturday learning challenge calculated from the learner's
/// existing locally saved daily activity. No new history or account is needed.
///
/// The same card reviewed on multiple days counts once in the week. A card
/// only contributes if it still exists in the current catalog. This measures
/// cards practised, not necessarily brand-new words mastered.
class WeeklyChallenge {
  const WeeklyChallenge({
    required this.weekStart,
    required this.goal,
    required this.cardIds,
    required this.activeDays,
  });

  static const storageKey = 'weekly_challenge_goal_v1';
  static const allowedGoals = <int>[10, 20, 30];
  static const defaultGoal = 20;

  final DateTime weekStart;
  final int goal;
  final Set<String> cardIds;
  final int activeDays;

  int get completedCards => cardIds.length;
  int get remainingCards => completedCards >= goal ? 0 : goal - completedCards;
  bool get isComplete => completedCards >= goal;
  double get progress => (completedCards / goal).clamp(0.0, 1.0).toDouble();
  DateTime get weekEnd => DateTime(
      weekStart.year, weekStart.month, weekStart.day + 6);

  static DateTime beginningOfWeek(DateTime date) {
    final local = date.toLocal();
    final midnight = DateTime(local.year, local.month, local.day);
    // Dart DateTime.weekday: Monday=1 ... Sunday=7. Saudi learning week
    // starts on Sunday. Use calendar dates, not 24-hour durations.
    return DateTime(
      midnight.year, midnight.month,
      midnight.day - midnight.weekday % 7,
    );
  }

  static WeeklyChallenge build({
    required DailyLearningProgress dailyProgress,
    required Set<String> validCardIds,
    required DateTime now,
    int goal = defaultGoal,
  }) {
    final start = beginningOfWeek(now);
    final finish = DateTime(start.year, start.month, start.day + 6);
    final startKey = DailyLearningProgress.dateKey(start);
    final endKey = DailyLearningProgress.dateKey(finish);
    final ids = <String>{};
    var days = 0;
    for (final entry in dailyProgress.activity.entries) {
      if (entry.key.compareTo(startKey) < 0 ||
          entry.key.compareTo(endKey) > 0) {
        continue;
      }
      final active = entry.value.intersection(validCardIds);
      if (active.isEmpty) continue;
      days++;
      ids.addAll(active);
    }
    return WeeklyChallenge(
      weekStart: start,
      goal: allowedGoals.contains(goal) ? goal : defaultGoal,
      cardIds: Set<String>.unmodifiable(ids),
      activeDays: days,
    );
  }
}
