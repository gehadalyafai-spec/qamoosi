import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'practice_questions.dart';

/// The number of incorrect answers for each *practical question*, not the
/// vocabulary card's spaced-repetition score. Stored independently offline.
class PracticeMistakes {
  const PracticeMistakes(this.counts);

  static const storageKey = 'practice_mistakes_v1';
  static const maxMistakeCount = 999;
  static const empty = PracticeMistakes(<String, int>{});

  final Map<String, int> counts;

  int get pendingCount => counts.length;

  int mistakesFor(String questionId) => counts[questionId] ?? 0;

  static PracticeMistakes fromPreferences(SharedPreferences prefs) {
    Object? raw;
    try {
      final value = prefs.getString(storageKey);
      raw = value == null ? null : jsonDecode(value);
    } on FormatException {
      return empty;
    } on TypeError {
      return empty;
    }

    if (raw is! Map) {
      return empty;
    }

    // Retired or renamed questions cannot appear in the current review queue.
    final available = {for (final question in practiceQuestions) question.id};
    final values = <String, int>{};
    for (final entry in raw.entries) {
      if (entry.key is String &&
          available.contains(entry.key) &&
          entry.value is int &&
          (entry.value as int) > 0) {
        values[entry.key as String] =
            (entry.value as int).clamp(1, maxMistakeCount).toInt();
      }
    }
    return PracticeMistakes(Map.unmodifiable(values));
  }

  /// Most repeated mistakes first. Equal priorities keep the original catalog
  /// order, making the review deterministic and easy to understand.
  List<PracticeQuestion> prioritized({int maxQuestions = 6}) {
    if (maxQuestions <= 0) {
      return const [];
    }
    final originalOrder = <String, int>{
      for (var i = 0; i < practiceQuestions.length; i++)
        practiceQuestions[i].id: i,
    };
    final pending = [
      for (final question in practiceQuestions)
        if (mistakesFor(question.id) > 0) question,
    ];
    pending.sort((a, b) {
      final countDifference = mistakesFor(b.id).compareTo(mistakesFor(a.id));
      if (countDifference != 0) {
        return countDifference;
      }
      return originalOrder[a.id]!.compareTo(originalOrder[b.id]!);
    });
    return pending.take(maxQuestions).toList();
  }

  /// An incorrect response increases priority; a correct one clears that
  /// question. Other mistakes and existing vocabulary progress are untouched.
  static Future<PracticeMistakes> recordAnswer(
    SharedPreferences prefs, {
    required String questionId,
    required bool wasCorrect,
  }) async {
    final current = fromPreferences(prefs);
    if (!practiceQuestions.any((question) => question.id == questionId)) {
      return current;
    }

    final next = Map<String, int>.from(current.counts);
    if (wasCorrect) {
      next.remove(questionId);
    } else {
      final previous = next[questionId] ?? 0;
      next[questionId] = previous < maxMistakeCount
          ? previous + 1
          : maxMistakeCount;
    }
    final sorted = next.keys.toList()..sort();
    final stored = <String, int>{
      for (final id in sorted) id: next[id]!,
    };
    final saved = await prefs.setString(storageKey, jsonEncode(stored));
    if (!saved) {
      throw StateError('تعذّر حفظ سجل أخطاء التدريب');
    }
    return PracticeMistakes(Map.unmodifiable(next));
  }
}
