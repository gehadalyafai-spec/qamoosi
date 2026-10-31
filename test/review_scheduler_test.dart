import 'package:flutter_test/flutter_test.dart';
import 'package:qamoosi/core/review_scheduler.dart';

void main() {
  final now = DateTime.utc(2026, 10, 31, 12);

  test('first good answer schedules tomorrow', () {
    final next = scheduleReview(now: now, rating: ReviewRating.good);
    expect(next.intervalDays, 1);
    expect(next.successfulReviews, 1);
    expect(next.dueAt, now.add(const Duration(days: 1)));
  });

  test('repeated good answers grow interval', () {
    final first = scheduleReview(now: now, rating: ReviewRating.good);
    final second = scheduleReview(
      now: now.add(const Duration(days: 1)),
      rating: ReviewRating.good,
      previous: first,
    );
    expect(second.intervalDays, 2);
    expect(second.successfulReviews, 2);
  });

  test('forgotten card is due in ten minutes', () {
    final next = scheduleReview(now: now, rating: ReviewRating.again);
    expect(next.intervalDays, 0);
    expect(next.successfulReviews, 0);
    expect(next.dueAt, now.add(const Duration(minutes: 10)));
  });

  test('easy answer starts with three days', () {
    final next = scheduleReview(now: now, rating: ReviewRating.easy);
    expect(next.intervalDays, 3);
  });

  test('review state survives JSON serialization', () {
    final original = scheduleReview(now: now, rating: ReviewRating.good);
    final restored = ReviewState.fromJson(original.toJson());
    expect(restored?.dueAt, original.dueAt);
    expect(restored?.intervalDays, original.intervalDays);
    expect(restored?.successfulReviews, original.successfulReviews);
  });

  test('invalid stored data is ignored', () {
    expect(ReviewState.fromJson({'dueAt': 'bad'}), isNull);
    expect(ReviewState.fromJson(null), isNull);
  });
}
