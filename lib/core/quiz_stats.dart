import 'package:shared_preferences/shared_preferences.dart';

/// Persisted results for completed quizzes only.
class QuizStats {
  const QuizStats({
    this.attempts = 0,
    this.lastScore = 0,
    this.bestScore = 0,
  });

  static const attemptsKey = 'quiz_attempts';
  static const lastScoreKey = 'quiz_last_score';
  static const bestScoreKey = 'quiz_best_score';

  final int attempts;
  final int lastScore;
  final int bestScore;

  static QuizStats fromPreferences(SharedPreferences prefs) {
    final attempts = prefs.getInt(attemptsKey) ?? 0;
    final last = prefs.getInt(lastScoreKey) ?? 0;
    final best = prefs.getInt(bestScoreKey) ?? 0;
    return QuizStats(
      attempts: attempts < 0 ? 0 : attempts,
      lastScore: last.clamp(0, 6).toInt(),
      bestScore: best.clamp(0, 6).toInt(),
    );
  }

  static Future<QuizStats> record(SharedPreferences prefs, int score) async {
    final previous = fromPreferences(prefs);
    final correct = score.clamp(0, 6);
    final updated = QuizStats(
      attempts: previous.attempts + 1,
      lastScore: correct,
      bestScore: correct > previous.bestScore ? correct : previous.bestScore,
    );
    await prefs.setInt(attemptsKey, updated.attempts);
    await prefs.setInt(lastScoreKey, updated.lastScore);
    await prefs.setInt(bestScoreKey, updated.bestScore);
    return updated;
  }
}
