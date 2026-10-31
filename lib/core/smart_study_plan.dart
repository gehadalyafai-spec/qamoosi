import 'daily_learning_progress.dart';
import 'review_scheduler.dart';

/// Metadata for a card; these IDs are the existing stable vocabulary IDs.
class StudyPlanCard {
  const StudyPlanCard({required this.id, required this.word});
  final String id;
  final String word;
}

class StudyPlanLesson {
  const StudyPlanLesson({
    required this.title,
    required this.levelRank,
    required this.cards,
  });

  final String title;
  final int levelRank;
  final List<StudyPlanCard> cards;
}

/// A read-only view of today's learning priorities. No extra storage,
/// artificial scores, or guessed historical data are introduced.
class SmartStudyPlan {
  const SmartStudyPlan({
    required this.todayLearned,
    required this.dailyGoal,
    required this.mastered,
    required this.totalCards,
    required this.dueCount,
    required this.dueCards,
    required this.newCards,
    required this.nextLesson,
    required this.pendingPracticeMistakes,
    required this.nextScheduledReview,
  });

  final int todayLearned;
  final int dailyGoal;
  final int mastered;
  final int totalCards;
  final int dueCount;
  final List<StudyPlanCard> dueCards;
  final List<StudyPlanCard> newCards;
  final String? nextLesson;
  final int pendingPracticeMistakes;
  final DateTime? nextScheduledReview;

  int get remainingToday {
    final count = dailyGoal - todayLearned;
    return count > 0 ? count : 0;
  }

  bool get goalMet => remainingToday == 0;

  double get todayFraction =>
      dailyGoal <= 0 ? 0 : (todayLearned / dailyGoal).clamp(0.0, 1.0).toDouble();

  bool get allCardsMastered => totalCards > 0 && mastered == totalCards;

  bool get hasActions =>
      dueCards.isNotEmpty || newCards.isNotEmpty || pendingPracticeMistakes > 0;

  /// Due cards always appear first (oldest due date first); up to five are
  /// offered in one manageable session. New cards follow catalog lesson
  /// order, beginner levels before intermediate, and never repeat due IDs.
  static SmartStudyPlan build({
    required Iterable<StudyPlanLesson> lessons,
    required Set<String> knownIds,
    required Map<String, ReviewState> reviews,
    required DailyLearningProgress dailyProgress,
    required DateTime now,
    required int pendingPracticeMistakes,
    int maxReviewCards = 5,
    int maxNewCards = 5,
  }) {
    final orderedLessons = lessons.toList().asMap().entries.toList()
      ..sort((a, b) {
        final rank = a.value.levelRank.compareTo(b.value.levelRank);
        return rank != 0 ? rank : a.key.compareTo(b.key);
      });

    final cards = <StudyPlanCard>[];
    final originalIndex = <String, int>{};
    String? nextLesson;
    final seen = <String>{};
    for (final entry in orderedLessons) {
      var hasNew = false;
      for (final card in entry.value.cards) {
        if (card.id.isEmpty || !seen.add(card.id)) continue;
        originalIndex[card.id] = cards.length;
        cards.add(card);
        if (!knownIds.contains(card.id)) hasNew = true;
      }
      if (hasNew && nextLesson == null) nextLesson = entry.value.title;
    }

    final due = <StudyPlanCard>[];
    DateTime? nextReview;
    for (final card in cards) {
      final state = reviews[card.id];
      if (state == null) continue;
      if (state.isDue(now)) {
        due.add(card);
      } else if (nextReview == null || state.dueAt.isBefore(nextReview)) {
        nextReview = state.dueAt;
      }
    }
    due.sort((a, b) {
      final time = reviews[a.id]!.dueAt.compareTo(reviews[b.id]!.dueAt);
      return time != 0
          ? time
          : originalIndex[a.id]!.compareTo(originalIndex[b.id]!);
    });

    final today = dailyProgress.countOn(now);
    final left = (dailyProgress.dailyGoal - today).clamp(0, dailyProgress.dailyGoal).toInt();
    final dueIds = due.map((card) => card.id).toSet();
    final newCards = [
      for (final card in cards)
        if (!knownIds.contains(card.id) && !dueIds.contains(card.id)) card,
    ];

    final allKnown = cards.where((card) => knownIds.contains(card.id)).length;
    return SmartStudyPlan(
      todayLearned: today,
      dailyGoal: dailyProgress.dailyGoal,
      mastered: allKnown,
      totalCards: cards.length,
      dueCount: due.length,
      dueCards: List.unmodifiable(
        due.take(maxReviewCards < 0 ? 0 : maxReviewCards),
      ),
      newCards: List.unmodifiable(
        newCards.take(
          left < maxNewCards
              ? left
              : (maxNewCards < 0 ? 0 : maxNewCards),
        ),
      ),
      nextLesson: nextLesson,
      pendingPracticeMistakes:
          pendingPracticeMistakes < 0 ? 0 : pendingPracticeMistakes,
      nextScheduledReview: nextReview,
    );
  }
}
