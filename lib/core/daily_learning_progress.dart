/// Locally saved study activity. A card counts once per calendar day when
/// its learner marks it as known, whether from a lesson or a review session.
class DailyLearningProgress {
  DailyLearningProgress({
    int dailyGoal = 5,
    Map<String, Set<String>>? activity,
  }) : dailyGoal = allowedGoals.contains(dailyGoal) ? dailyGoal : 5,
       activity = {
          for (final entry in (activity ?? <String, Set<String>>{}).entries)
            entry.key: Set<String>.from(entry.value),
        };

  static const storageKey = 'daily_learning_progress_v1';
  static const allowedGoals = <int>[3, 5, 10];

  final int dailyGoal;
  final Map<String, Set<String>> activity;

  static String dateKey(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  int countOn(DateTime date) => activity[dateKey(date)]?.length ?? 0;

  int remainingOn(DateTime date) {
    final left = dailyGoal - countOn(date);
    return left > 0 ? left : 0;
  }

  double fractionOn(DateTime date) =>
      (countOn(date) / dailyGoal).clamp(0.0, 1.0).toDouble();

  int get activeDays =>
      activity.values.where((cards) => cards.isNotEmpty).length;

  /// If today is still empty, count a streak ending yesterday, not zero.
  int streakOn(DateTime date) {
    final local = date.toLocal();
    var cursor = DateTime(local.year, local.month, local.day);
    if (countOn(cursor) == 0) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var streak = 0;
    while (countOn(cursor) > 0) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return streak;
  }

  DailyLearningProgress recordSuccess(String cardId, DateTime date) {
    final cleaned = cardId.trim();
    if (cleaned.isEmpty) {
      return this;
    }
    final key = dateKey(date);
    if (activity[key]?.contains(cleaned) ?? false) {
      return this;
    }
    final updated = {
      for (final entry in activity.entries)
        entry.key: Set<String>.from(entry.value),
    };
    updated.putIfAbsent(key, () => <String>{}).add(cleaned);
    return DailyLearningProgress(dailyGoal: dailyGoal, activity: updated);
  }

  DailyLearningProgress withGoal(int goal) {
    if (!allowedGoals.contains(goal)) {
      return this;
    }
    return DailyLearningProgress(dailyGoal: goal, activity: activity);
  }

  Map<String, Object> toJson() => {
        'dailyGoal': dailyGoal,
        'days': {
          for (final entry in activity.entries)
            entry.key: entry.value.toList()..sort(),
        },
      };

  static DailyLearningProgress fromJson(Object? value) {
    if (value is! Map) {
      return DailyLearningProgress();
    }
    final rawGoal = value['dailyGoal'];
    final goal = rawGoal is int && allowedGoals.contains(rawGoal)
        ? rawGoal
        : 5;
    final days = <String, Set<String>>{};
    final rawDays = value['days'];
    if (rawDays is Map) {
      for (final entry in rawDays.entries) {
        final key = entry.key;
        final cards = entry.value;
        if (key is! String ||
            !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key) ||
            DateTime.tryParse(key) == null ||
            dateKey(DateTime.parse(key)) != key ||
            cards is! List) {
          continue;
        }
        final validIds = cards.whereType<String>()
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty).toSet();
        if (validIds.isNotEmpty) {
          days[key] = validIds;
        }
      }
    }
    return DailyLearningProgress(dailyGoal: goal, activity: days);
  }
}
