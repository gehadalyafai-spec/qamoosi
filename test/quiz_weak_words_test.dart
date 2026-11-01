import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qamoosi/core/quiz_stats.dart';
import 'package:qamoosi/core/quiz_weak_words.dart';
import 'package:qamoosi/core/section_quiz_stats.dart';
import 'package:qamoosi/main.dart';

Future<void> completeQuizWithChoices(
  WidgetTester tester,
  List<CardEntry> questions, {
  bool missFirst = false,
}) async {
  for (var i = 0; i < questions.length; i++) {
    final translations = [
      for (var j = 0; j < 4; j++)
        (tester.widget<OutlinedButton>(
          find.byKey(Key('quiz_choice_$j')),
        ).child! as Text).data!,
    ];
    final correct = questions[i].translation;
    final selected = missFirst && i == 0
        ? translations.indexWhere((item) => item != correct)
        : translations.indexOf(correct);
    expect(selected, inInclusiveRange(0, 3));
    await tester.tap(find.byKey(Key('quiz_choice_$selected')));
    await tester.pump();
    if (missFirst && i == 0) {
      expect(find.byKey(const Key('quiz_wrong_feedback')), findsOneWidget);
      await tester.tap(find.byKey(const Key('quiz_next')));
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pumpAndSettle();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('completed quizzes accumulate weak priorities without duplicate IDs',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(QuizWeakWords.fromPreferences(prefs).count, 0);
    final first = await QuizWeakWords.recordCompletedQuiz(
      prefs, {'variable': false, 'api': false, 'file': true},
    );
    expect(first.count, 2);
    expect(first.priorityOf('variable'), 2);
    expect(first.priorityOf('api'), 2);
    expect(first.priorityOf('file'), 0);
    final second = await QuizWeakWords.recordCompletedQuiz(
      prefs, {'variable': false, 'api': true},
    );
    expect(second.priorityOf('variable'), 4);
    expect(second.priorityOf('api'), 1);
    final third = await QuizWeakWords.recordCompletedQuiz(
      prefs, {'variable': true, 'api': true},
    );
    expect(third.priorityOf('variable'), 3);
    expect(third.priorityOf('api'), 0);
    expect(third.count, 1);
    final persisted = QuizWeakWords.fromPreferences(prefs);
    expect(persisted.priorityOf('variable'), 3);
    expect(persisted.count, 1);
    await QuizWeakWords.recordCompletedQuiz(
      prefs, {'variable': false, 'not-a-word': false},
      validIds: {'variable'},
    );
    expect(QuizWeakWords.fromPreferences(prefs,
      validIds: {'variable'}).priorityOf('variable'), 5);
    expect(QuizWeakWords.fromPreferences(prefs,
      validIds: {'variable'}).count, 1);
  });

  test('corrupted and unknown IDs are ignored rather than blocking learning',
      () async {
    SharedPreferences.setMockInitialValues({
      QuizWeakWords.storageKey: 'not json',
    });
    final prefs = await SharedPreferences.getInstance();
    expect(QuizWeakWords.fromPreferences(prefs).count, 0);
    await prefs.setString(QuizWeakWords.storageKey,
      '{"variable": 99, "file": -4, "api": "wrong",'
      '"retired": 2, "": 3, "folder": 1}');
    final recovered = QuizWeakWords.fromPreferences(
      prefs, validIds: {'variable', 'file', 'folder'},
    );
    expect(recovered.priorityOf('variable'), 5);
    expect(recovered.priorityOf('folder'), 1);
    expect(recovered.priorityOf('retired'), 0);
    expect(recovered.count, 2);
  });

  test('adaptive selection prioritizes errors while preserving variety', () {
    final catalog = List.generate(30, (index) => 'word$index');
    final misses = QuizWeakWords({
      'word18': 5, 'word9': 4, 'word7': 3, 'word6': 2,
      'word5': 1, 'word4': 1,
    });
    final picked = buildAdaptiveQuizCards<String>(
      catalog: catalog,
      cardId: (word) => word,
      weaknesses: misses,
      completedAttempts: 0,
    );
    expect(picked.length, 6);
    expect(picked.toSet().length, 6);
    expect(picked.take(4), ['word18', 'word9', 'word7', 'word6']);
    expect(picked.skip(4).any((word) => !misses.priority.containsKey(word)),
      isTrue);
    final next = buildAdaptiveQuizCards<String>(
      catalog: catalog,
      cardId: (word) => word,
      weaknesses: misses,
      completedAttempts: 1,
    );
    expect(next.length, 6);
    expect(next.toSet().length, 6);
    expect(next.first, 'word18');
    expect(next.skip(4).toList(), isNot(picked.skip(4).toList()));
  });

  test('adaptive mode has safe fallbacks for fresh and tiny catalogs', () {
    final fresh = buildAdaptiveQuizCards<String>(
      catalog: ['one', 'two', 'three', 'four', 'five', 'six'],
      cardId: (word) => word,
      weaknesses: const QuizWeakWords({}),
      completedAttempts: 0,
    );
    expect(fresh, ['one', 'two', 'three', 'four', 'five', 'six']);
    expect(buildAdaptiveQuizCards<String>(
      catalog: ['one', 'one', 'two'],
      cardId: (word) => word,
      weaknesses: const QuizWeakWords({}),
      completedAttempts: 5,
    ).toSet(), {'one', 'two'});
    expect(buildAdaptiveQuizCards<String>(
      catalog: [],
      cardId: (word) => word,
      weaknesses: const QuizWeakWords({}),
      completedAttempts: 0,
    ), isEmpty);
    expect(buildAdaptiveQuizCards<String>(
      catalog: ['one'],
      cardId: (word) => word,
      weaknesses: const QuizWeakWords({'one': 4}),
      completedAttempts: -7,
    ), ['one']);
  });

  testWidgets('general quiz records weakness and smart quiz reduces it',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final originalQuestions = buildQuizCards(0);
    await tester.pumpWidget(const MaterialApp(home: QuizPage()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quiz_weak_words_after')), findsNothing);
    await completeQuizWithChoices(tester, originalQuestions, missFirst: true);
    expect(find.text('نتيجتك: 5 من 6'), findsOneWidget);
    expect(find.text('كلمات تحتاج تقوية الآن: 1'), findsOneWidget);
    expect(find.byKey(const Key('quiz_start_adaptive')), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(QuizWeakWords.fromPreferences(prefs).priorityOf('variable'), 2);
    expect(QuizStats.fromPreferences(prefs).attempts, 1);
    expect(SectionQuizStats.fromPreferences(prefs, 'adaptive_review').attempts,
      0);

    await tester.tap(find.byKey(const Key('quiz_start_adaptive')));
    await tester.pumpAndSettle();
    expect(find.text('اختبار تقوية الكلمات'), findsOneWidget);
    final adaptiveQuestions = buildAdaptiveQuizCards<CardEntry>(
      catalog: [for (final lesson in lessons) ...lesson.cards],
      cardId: (word) => word.id,
      weaknesses: QuizWeakWords.fromPreferences(prefs),
      completedAttempts: 0,
    );
    expect(adaptiveQuestions.first.id, 'variable');
    expect(find.text('Variable'), findsOneWidget);
    await completeQuizWithChoices(tester, adaptiveQuestions);
    expect(find.text('نتيجتك: 6 من 6'), findsOneWidget);
    expect(QuizWeakWords.fromPreferences(prefs).priorityOf('variable'), 1);
    expect(SectionQuizStats.fromPreferences(prefs, 'adaptive_review').attempts,
      1);
    expect(QuizStats.fromPreferences(prefs).attempts, 1);
    expect(find.byKey(const Key('quiz_start_adaptive')), findsNothing);

    await tester.tap(find.text('اختبار جديد'));
    await tester.pumpAndSettle();
    final secondQuestions = buildAdaptiveQuizCards<CardEntry>(
      catalog: [for (final lesson in lessons) ...lesson.cards],
      cardId: (word) => word.id,
      weaknesses: QuizWeakWords.fromPreferences(prefs),
      completedAttempts: 1,
    );
    expect(secondQuestions.first.id, 'variable');
    await completeQuizWithChoices(tester, secondQuestions);
    expect(QuizWeakWords.fromPreferences(prefs).count, 0);
    expect(SectionQuizStats.fromPreferences(prefs, 'adaptive_review').attempts,
      2);
    expect(QuizStats.fromPreferences(prefs).attempts, 1);
    expect(prefs.getStringList('known_cards'), isNull);
  });

  testWidgets('unfinished quizzes never enter the persistent weak-word bank',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: QuizPage()));
    await tester.pumpAndSettle();
    final options = [
      for (var i = 0; i < 4; i++)
        (tester.widget<OutlinedButton>(
          find.byKey(Key('quiz_choice_$i')),
        ).child! as Text).data!,
    ];
    final wrong = options.indexWhere((text) => text != 'متغير');
    await tester.tap(find.byKey(Key('quiz_choice_$wrong')));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(QuizWeakWords.fromPreferences(prefs).count, 0);
    expect(QuizStats.fromPreferences(prefs).attempts, 0);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();
    expect(QuizWeakWords.fromPreferences(prefs).count, 0);
  });
}
