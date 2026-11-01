import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persisted weak-word priorities based solely on completed quizzes.
/// This does not change flashcard mastery, spaced reviews or global scores.
class QuizWeakWords {
  const QuizWeakWords(this.priority);

  static const storageKey = 'quiz_weak_words_v1';
  static const maximumPriority = 5;
  static const mistakesPerQuestion = 2;
  final Map<String, int> priority;

  int get count => priority.length;
  int priorityOf(String id) => priority[id] ?? 0;

  static QuizWeakWords fromPreferences(
    SharedPreferences prefs, {
    Set<String>? validIds,
  }) {
    final raw = prefs.getString(storageKey);
    if (raw == null) return const QuizWeakWords({});
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const QuizWeakWords({});
    }
    if (decoded is! Map) return const QuizWeakWords({});
    final restored = <String, int>{};
    for (final item in decoded.entries) {
      if (item.key is! String || (item.key as String).trim().isEmpty ||
          (validIds != null && !validIds.contains(item.key))) {
        continue;
      }
      final value = item.value;
      if (value is int && value > 0) {
        restored[item.key as String] = value.clamp(1, maximumPriority).toInt();
      }
    }
    return QuizWeakWords(Map.unmodifiable(restored));
  }

  /// A wrong answer adds two priority points, while a correct answer removes
  /// one point. The learner must answer twice correctly to clear one mistake.
  /// Each card appears at most once in a completed six-question quiz.
  QuizWeakWords applyAnswers(Map<String, bool> answers) {
    final updated = Map<String, int>.from(priority);
    for (final answer in answers.entries) {
      final id = answer.key.trim();
      if (id.isEmpty) continue;
      final old = updated[id] ?? 0;
      final next = answer.value
          ? old - 1
          : (old + mistakesPerQuestion).clamp(1, maximumPriority).toInt();
      if (next <= 0) {
        updated.remove(id);
      } else {
        updated[id] = next;
      }
    }
    return QuizWeakWords(Map.unmodifiable(updated));
  }

  static Future<QuizWeakWords> recordCompletedQuiz(
    SharedPreferences prefs,
    Map<String, bool> answers, {
    Set<String>? validIds,
  }) async {
    final current = fromPreferences(prefs, validIds: validIds);
    final filtered = {
      for (final entry in answers.entries)
        if (validIds == null || validIds.contains(entry.key))
          entry.key: entry.value,
    };
    final updated = current.applyAnswers(filtered);
    final saved = await prefs.setString(storageKey, jsonEncode(updated.priority));
    if (!saved) throw StateError('تعذّر حفظ كلمات الاختبار الصعبة');
    return updated;
  }
}

/// Select six different questions: up to four words needing reinforcement,
/// followed by a deterministic rotating selection from the full catalog.
/// Does not alter the existing ordinary or per-section quiz rotation.
List<T> buildAdaptiveQuizCards<T>({
  required List<T> catalog,
  required String Function(T card) cardId,
  required QuizWeakWords weaknesses,
  required int completedAttempts,
  int questionCount = 6,
}) {
  if (catalog.isEmpty || questionCount <= 0) return <T>[];
  final maxQuestions = questionCount < catalog.length
      ? questionCount : catalog.length;
  final byId = <String, T>{};
  for (final card in catalog) {
    byId.putIfAbsent(cardId(card), () => card);
  }
  if (byId.isEmpty) return <T>[];
  final all = byId.values.toList();
  final count = maxQuestions < all.length ? maxQuestions : all.length;
  final attempts = completedAttempts < 0 ? 0 : completedAttempts;
  final weak = [
    for (final card in all)
      if (weaknesses.priorityOf(cardId(card)) > 0) card,
  ];
  weak.sort((a, b) {
    final difference = weaknesses.priorityOf(cardId(b))
        .compareTo(weaknesses.priorityOf(cardId(a)));
    return difference != 0 ? difference : 0;
  });
  // Rotate equally weak words between attempts; tie order remains stable.
  final ranked = <T>[];
  for (var i = 0; i < weak.length;) {
    var end = i + 1;
    while (end < weak.length &&
        weaknesses.priorityOf(cardId(weak[end])) ==
            weaknesses.priorityOf(cardId(weak[i]))) {
      end++;
    }
    final group = weak.sublist(i, end);
    final offset = attempts % group.length;
    ranked.addAll([...group.skip(offset), ...group.take(offset)]);
    i = end;
  }
  final weakLimit = count > 1 ? count - 2 : count;
  final chosen = <T>[];
  final used = <String>{};
  for (final card in ranked) {
    if (chosen.length >= weakLimit) break;
    if (used.add(cardId(card))) chosen.add(card);
  }
  final start = ((attempts % all.length) * (count % all.length)) % all.length;
  for (var i = 0; i < all.length && chosen.length < count; i++) {
    final card = all[(start + i) % all.length];
    if (used.add(cardId(card))) chosen.add(card);
  }
  return List<T>.unmodifiable(chosen);
}
