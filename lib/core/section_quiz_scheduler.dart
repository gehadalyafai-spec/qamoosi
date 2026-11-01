/// Build a short fair quiz from one or more lessons without changing their
/// original card order or IDs. Each round picks from an interleaved pool:
/// one word per lesson, then the next word per lesson, and so on.
///
/// Across successive completed sessions, the quiz will cover every card
/// before repeating (except for the unavoidable wrap in the last session).
List<T> buildSectionQuizCards<T>(
  List<List<T>> lessons,
  int completedAttempts, {
  int questionsPerAttempt = 6,
}) {
  if (questionsPerAttempt <= 0) return <T>[];
  final widest = lessons.fold<int>(
    0,
    (length, cards) => cards.length > length ? cards.length : length,
  );
  final pool = <T>[];
  for (var wordIndex = 0; wordIndex < widest; wordIndex++) {
    for (final cards in lessons) {
      if (wordIndex < cards.length) pool.add(cards[wordIndex]);
    }
  }
  if (pool.isEmpty) return <T>[];
  final attempt = completedAttempts < 0 ? 0 : completedAttempts;
  final start = ((attempt % pool.length) *
      (questionsPerAttempt % pool.length)) % pool.length;
  final count =
      questionsPerAttempt < pool.length ? questionsPerAttempt : pool.length;
  return List<T>.unmodifiable([
    for (var i = 0; i < count; i++) pool[(start + i) % pool.length],
  ]);
}
