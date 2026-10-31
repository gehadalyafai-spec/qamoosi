import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qamoosi/features/practice/practice_mistakes.dart';
import 'package:qamoosi/features/practice/practice_questions.dart';
import 'package:qamoosi/features/practice/practice_stats.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('wrong answers increase priority; correct answers remove the mistake',
      () async {
    SharedPreferences.setMockInitialValues({
      'known_cards': ['variable'],
      'quiz_attempts': 7,
    });
    final prefs = await SharedPreferences.getInstance();
    expect(PracticeMistakes.fromPreferences(prefs).pendingCount, 0);

    var state = await PracticeMistakes.recordAnswer(
      prefs, questionId: 'variable', wasCorrect: false);
    expect(state.mistakesFor('variable'), 1);
    expect(state.pendingCount, 1);

    state = await PracticeMistakes.recordAnswer(
      prefs, questionId: 'variable', wasCorrect: false);
    state = await PracticeMistakes.recordAnswer(
      prefs, questionId: 'function', wasCorrect: false);
    expect(state.mistakesFor('variable'), 2);
    expect(state.mistakesFor('function'), 1);
    expect(state.pendingCount, 2);
    expect(state.prioritized().map((q) => q.id).toList(),
        ['variable', 'function']);

    state = await PracticeMistakes.recordAnswer(
      prefs, questionId: 'variable', wasCorrect: true);
    expect(state.mistakesFor('variable'), 0);
    expect(state.pendingCount, 1);
    expect(state.prioritized().single.id, 'function');

    final reloaded = PracticeMistakes.fromPreferences(
      await SharedPreferences.getInstance());
    expect(reloaded.pendingCount, 1);
    expect(reloaded.mistakesFor('function'), 1);
    expect(prefs.getStringList('known_cards'), ['variable']);
    expect(prefs.getInt('quiz_attempts'), 7);
    expect(prefs.getString(PracticeStats.storageKey), isNull);
  });

  test('sorting prioritizes repeated mistakes and respects review limit',
      () async {
    SharedPreferences.setMockInitialValues({
      PracticeMistakes.storageKey: jsonEncode({
        'variable': 2,
        'function': 3,
        'bug': 3,
        'test': 1,
        'branch': 2,
        'merge': 2,
        'folder': 1,
        'extension': 1,
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    final state = PracticeMistakes.fromPreferences(prefs);
    expect(state.pendingCount, 8);
    final questions = state.prioritized();
    expect(questions.length, 6);
    expect(questions.map((q) => q.id).toList(),
        ['function', 'bug', 'variable', 'branch', 'merge', 'test']);
    expect(state.prioritized(maxQuestions: 1).single.id, 'function');
    expect(state.prioritized(maxQuestions: 0), isEmpty);
    expect(state.prioritized(maxQuestions: -1), isEmpty);
    expect(practiceQuestions.length, 12);
  });

  test('persisted mistakes are capped, validated, and filtered by question ID',
      () async {
    SharedPreferences.setMockInitialValues({
      PracticeMistakes.storageKey: jsonEncode({
        'variable': 1200,
        'bug': -3,
        'function': 'bad',
        'unknown-id': 6,
        'merge': 0,
        'folder': 2,
      }),
    });
    var prefs = await SharedPreferences.getInstance();
    var state = PracticeMistakes.fromPreferences(prefs);
    expect(state.counts, {'variable': 999, 'folder': 2});
    state = await PracticeMistakes.recordAnswer(
      prefs, questionId: 'variable', wasCorrect: false);
    expect(state.mistakesFor('variable'), 999);
    state = await PracticeMistakes.recordAnswer(
      prefs, questionId: 'unknown-id', wasCorrect: false);
    expect(state.pendingCount, 2);

    SharedPreferences.setMockInitialValues({
      PracticeMistakes.storageKey: '{invalid-json',
    });
    prefs = await SharedPreferences.getInstance();
    expect(PracticeMistakes.fromPreferences(prefs).pendingCount, 0);
    SharedPreferences.setMockInitialValues({
      PracticeMistakes.storageKey: '[]',
    });
    prefs = await SharedPreferences.getInstance();
    expect(PracticeMistakes.fromPreferences(prefs).pendingCount, 0);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    expect(PracticeMistakes.fromPreferences(prefs).prioritized(), isEmpty);
  });

  test('no queued mistake is recorded for an unknown or already-correct term',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final noChange = await PracticeMistakes.recordAnswer(
      prefs, questionId: 'made-up', wasCorrect: false);
    expect(noChange.pendingCount, 0);
    final correct = await PracticeMistakes.recordAnswer(
      prefs, questionId: 'variable', wasCorrect: true);
    expect(correct.pendingCount, 0);
    expect(jsonDecode(prefs.getString(PracticeMistakes.storageKey)!), {});
  });
}
