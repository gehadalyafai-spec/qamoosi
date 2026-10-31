import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Separate local history for the practical training, so ordinary vocabulary
/// quiz scores and mastered/reviewed flashcards remain unaffected.
class PracticeStats {
  const PracticeStats({
    this.attempts = 0,
    this.lastScore = 0,
    this.bestScore = 0,
  });

  static const storageKey = 'practice_stats_v1';
  static const questionsPerSession = 6;

  final int attempts;
  final int lastScore;
  final int bestScore;

  static PracticeStats fromPreferences(SharedPreferences prefs) {
    Object? decoded;
    try {
      final raw = prefs.getString(storageKey);
      decoded = raw == null ? null : jsonDecode(raw);
    } on FormatException {
      return const PracticeStats();
    } on TypeError {
      return const PracticeStats();
    }
    if (decoded is! Map) {
      return const PracticeStats();
    }
    final attempts = decoded['attempts'];
    final last = decoded['lastScore'];
    final best = decoded['bestScore'];
    return PracticeStats(
      attempts: attempts is int && attempts > 0 ? attempts : 0,
      lastScore: last is int
          ? last.clamp(0, questionsPerSession).toInt()
          : 0,
      bestScore: best is int
          ? best.clamp(0, questionsPerSession).toInt()
          : 0,
    );
  }

  static Future<PracticeStats> record(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final old = fromPreferences(prefs);
    final normalized = score.clamp(0, questionsPerSession).toInt();
    final next = PracticeStats(
      attempts: old.attempts + 1,
      lastScore: normalized,
      bestScore: normalized > old.bestScore
          ? normalized
          : old.bestScore,
    );

    final success = await prefs.setString(storageKey, jsonEncode({
      'attempts': next.attempts,
      'lastScore': next.lastScore,
      'bestScore': next.bestScore,
    }));
    if (!success) {
      throw StateError('تعذّر حفظ نتيجة التدريب');
    }
    return next;
  }
}
