/// A small, deterministic spaced-review scheduler.
///
/// Ratings are explicit; the UI may use [ReviewRating.again] and
/// [ReviewRating.good] initially and add [ReviewRating.easy] later.
enum ReviewRating { again, good, easy }

class ReviewState {
  const ReviewState({
    required this.dueAt,
    required this.intervalDays,
    required this.successfulReviews,
  });

  final DateTime dueAt;
  final int intervalDays;
  final int successfulReviews;

  bool isDue(DateTime now) => !dueAt.isAfter(now);

  Map<String, dynamic> toJson() => {
    'dueAt': dueAt.toUtc().toIso8601String(),
    'intervalDays': intervalDays,
    'successfulReviews': successfulReviews,
  };

  static ReviewState? fromJson(Object? value) {
    if (value is! Map) return null;
    final due = DateTime.tryParse(value['dueAt']?.toString() ?? '');
    final days = value['intervalDays'];
    final reviews = value['successfulReviews'];
    if (due == null || days is! int || reviews is! int ||
        days < 0 || reviews < 0) return null;
    return ReviewState(
      dueAt: due.toUtc(),
      intervalDays: days,
      successfulReviews: reviews,
    );
  }
}

ReviewState scheduleReview({
  required DateTime now,
  required ReviewRating rating,
  ReviewState? previous,
}) {
  final instant = now.toUtc();
  if (rating == ReviewRating.again) {
    return ReviewState(
      dueAt: instant.add(const Duration(minutes: 10)),
      intervalDays: 0,
      successfulReviews: 0,
    );
  }

  final previousDays = previous?.intervalDays ?? 0;
  final previousSuccesses = previous?.successfulReviews ?? 0;
  final nextDays = switch (rating) {
    ReviewRating.again => 0,
    ReviewRating.good => previousDays == 0 ? 1 : (previousDays * 2).clamp(1, 365).toInt(),
    ReviewRating.easy => previousDays == 0 ? 3 : (previousDays * 3).clamp(3, 365).toInt(),
  };

  return ReviewState(
    dueAt: instant.add(Duration(days: nextDays)),
    intervalDays: nextDays,
    successfulReviews: previousSuccesses + 1,
  );
}
