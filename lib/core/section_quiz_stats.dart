import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Results for quizzes launched from one of the six topical sections.
/// Deliberately independent from global QuizStats, which must keep its
/// historic attempts/best/last results unchanged.
class SectionQuizStats {
  const SectionQuizStats({
    this.attempts = 0,
    this.lastScore = 0,
    this.bestScore = 0,
  });

  static const storageKey = 'section_quiz_stats_v1';
  final int attempts;
  final int lastScore;
  final int bestScore;

  static int _nonnegative(Object? source) =>
      source is int && source > 0 ? source : 0;

  static int _score(Object? source) => _nonnegative(source).clamp(0, 6);

  factory SectionQuizStats.fromJson(Object? raw) {
    if (raw is! Map) return const SectionQuizStats();
    return SectionQuizStats(
      attempts: _nonnegative(raw['attempts']),
      lastScore: _score(raw['lastScore']),
      bestScore: _score(raw['bestScore']),
    );
  }

  Map<String, int> toJson() => {
    'attempts': attempts,
    'lastScore': lastScore,
    'bestScore': bestScore,
  };

  static Map<String, SectionQuizStats> allFromPreferences(
      SharedPreferences prefs) {
    final saved = prefs.getString(storageKey);
    if (saved == null) return {};
    Object? json;
    try {
      json = jsonDecode(saved);
    } on FormatException {
      return {};
    }
    if (json is! Map) return {};
    final result = <String, SectionQuizStats>{};
    for (final entry in json.entries) {
      if (entry.key is String && (entry.key as String).isNotEmpty) {
        result[entry.key as String] = SectionQuizStats.fromJson(entry.value);
      }
    }
    return result;
  }

  static SectionQuizStats fromPreferences(
    SharedPreferences prefs,
    String sectionId,
  ) => allFromPreferences(prefs)[sectionId] ?? const SectionQuizStats();

  static Future<SectionQuizStats> record(
    SharedPreferences prefs,
    String sectionId,
    int correct,
  ) async {
    if (sectionId.trim().isEmpty) {
      throw ArgumentError.value(sectionId, 'sectionId');
    }
    final all = allFromPreferences(prefs);
    final previous = all[sectionId] ?? const SectionQuizStats();
    final score = correct.clamp(0, 6);
    final updated = SectionQuizStats(
      attempts: previous.attempts + 1,
      lastScore: score,
      bestScore: score > previous.bestScore ? score : previous.bestScore,
    );
    all[sectionId] = updated;
    final encoded = <String, Object?>{
      for (final entry in all.entries) entry.key: entry.value.toJson(),
    };
    final saved = await prefs.setString(storageKey, jsonEncode(encoded));
    if (!saved) throw StateError('تعذّر حفظ نتيجة اختبار القسم');
    return updated;
  }
}
