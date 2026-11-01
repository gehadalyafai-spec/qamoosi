import 'package:shared_preferences/shared_preferences.dart';

import '../features/code_lab/code_lab_exercises.dart';

/// Pending code-lab exercises are independent from word and quiz statistics.
class CodeLabMistakes {
  const CodeLabMistakes(this.pendingIds);

  static const storageKey = 'code_lab_mistakes_v1';
  static const empty = CodeLabMistakes(<String>[]);

  final List<String> pendingIds;
  int get pendingCount => pendingIds.length;

  static CodeLabMistakes fromPreferences(
    SharedPreferences prefs, {
    List<CodeLabExercise> catalog = codeLabCatalog,
  }) {
    List<String> saved;
    try {
      saved = prefs.getStringList(storageKey) ?? const [];
    } on TypeError {
      saved = const [];
    }
    final pending = saved.toSet();
    return CodeLabMistakes(List.unmodifiable([
      for (final exercise in catalog)
        if (pending.contains(exercise.id)) exercise.id,
    ]));
  }

  List<CodeLabExercise> pendingExercises({
    List<CodeLabExercise> catalog = codeLabCatalog,
    int maxExercises = 6,
  }) {
    if (maxExercises <= 0) return const [];
    final pending = pendingIds.toSet();
    return List.unmodifiable([
      for (final exercise in catalog)
        if (pending.contains(exercise.id)) exercise,
    ].take(maxExercises));
  }

  /// Only call after a completed session; applying answers twice is safe.
  static Future<CodeLabMistakes> recordRound(
    SharedPreferences prefs,
    Map<String, bool> answers, {
    List<CodeLabExercise> catalog = codeLabCatalog,
  }) async {
    final existing = fromPreferences(prefs, catalog: catalog);
    if (answers.isEmpty) return existing;
    final validIds = {for (final task in catalog) task.id};
    final pending = existing.pendingIds.toSet();
    for (final answer in answers.entries) {
      if (!validIds.contains(answer.key)) continue;
      if (answer.value) {
        pending.remove(answer.key);
      } else {
        pending.add(answer.key);
      }
    }
    final ordered = [
      for (final task in catalog)
        if (pending.contains(task.id)) task.id,
    ];
    if (!await prefs.setStringList(storageKey, ordered)) {
      throw StateError('تعذّر حفظ أخطاء مختبر الكود');
    }
    return CodeLabMistakes(List.unmodifiable(ordered));
  }
}
