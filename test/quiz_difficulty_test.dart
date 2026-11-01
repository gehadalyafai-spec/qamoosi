import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qamoosi/core/quiz_difficulty.dart';
import 'package:qamoosi/core/quiz_stats.dart';
import 'package:qamoosi/core/section_quiz_stats.dart';
import 'package:qamoosi/features/quiz/quiz_difficulty_picker.dart';
import 'package:qamoosi/main.dart';

final _catalog = [for (final lesson in lessons) ...lesson.cards];

List<CardEntry> _questions(QuizDifficulty difficulty, int attempts) =>
    buildDifficultyQuizCards<CardEntry>(
      catalog: _catalog,
      cardId: (card) => card.id,
      difficulty: difficulty,
      completedAttempts: attempts,
    );

Future<void> _answerAll(
  WidgetTester tester, QuizDifficulty difficulty, int attempts) async {
  final questions = _questions(difficulty, attempts);
  for (var i = 0; i < questions.length; i++) {
    final answer = difficulty == QuizDifficulty.easy
        ? questions[i].translation : questions[i].word;
    final options = [
      for (var j = 0; j < 4; j++)
        (tester.widget<OutlinedButton>(
          find.byKey(Key('quiz_choice_$j'))).child! as Text).data!,
    ];
    final index = options.indexOf(answer);
    expect(index, inInclusiveRange(0, 3), reason: questions[i].id);
    await tester.tap(find.byKey(Key('quiz_choice_$index')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pumpAndSettle();
  }
  expect(find.text('نتيجتك: 6 من 6'), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('advanced bank contains actual code and only existing vocabulary IDs', () {
    expect(advancedCodeScenarios.length, greaterThanOrEqualTo(60));
    final ids = _catalog.map((card) => card.id).toSet();
    expect(advancedCodeScenarios.keys.every(ids.contains), isTrue);
    for (final entry in advancedCodeScenarios.entries) {
      expect(entry.value.code.trim().length, greaterThan(10),
        reason: entry.key);
      expect(entry.value.question.trim().length, greaterThan(14),
        reason: entry.key);
    }
    expect(advancedCodeScenarios['variable']!.code, contains('score ='));
    expect(advancedCodeScenarios['extra_sql_query']!.code, contains('SELECT'));
    expect(advancedCodeScenarios['extra_widget']!.code, contains('Text('));
    expect(advancedCodeScenarios['extra_http_get']!.code, contains('GET'));
  });

  test('difficulty rounds contain distinct cards and rotate across attempts',
      () {
    for (final difficulty in QuizDifficulty.values) {
      final first = _questions(difficulty, 0);
      final second = _questions(difficulty, 1);
      expect(first.length, 6, reason: difficulty.name);
      expect(first.map((card) => card.id).toSet().length, 6);
      expect(second.map((card) => card.id).toSet().length, 6);
      expect(first.map((card) => card.id).toList(),
        isNot(second.map((card) => card.id).toList()));
      if (difficulty == QuizDifficulty.advanced) {
        expect(first.every((card) =>
          advancedCodeScenarios.containsKey(card.id)), isTrue);
        expect(second.every((card) =>
          advancedCodeScenarios.containsKey(card.id)), isTrue);
      }
      expect(buildDifficultyQuizCards<CardEntry>(
        catalog: _catalog,
        cardId: (card) => card.id,
        difficulty: difficulty,
        completedAttempts: -3,
      ).first.id, first.first.id);
    }
  });

  test('empty and repeated IDs are handled safely in challenge selection', () {
    expect(buildDifficultyQuizCards<String>(
      catalog: [],
      cardId: (card) => card,
      difficulty: QuizDifficulty.easy,
      completedAttempts: 0,
    ), isEmpty);
    expect(buildDifficultyQuizCards<String>(
      catalog: ['a', 'a', 'b'],
      cardId: (card) => card,
      difficulty: QuizDifficulty.easy,
      completedAttempts: 0,
    ), ['a', 'b']);
    expect(buildDifficultyQuizCards<String>(
      catalog: ['a'],
      cardId: (card) => card,
      difficulty: QuizDifficulty.advanced,
      completedAttempts: 0,
    ), isEmpty);
    expect(maskAnswerTerm('Flutter lets you build Flutter widgets',
      'Flutter'), '_____ lets you build _____ widgets');
    expect(maskAnswerTerm('No match', 'API'), 'No match');
  });

  testWidgets('easy challenge remains a translation quiz with separate stats',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      QuizStats.attemptsKey: 7,
      QuizStats.bestScoreKey: 5,
    });
    await tester.pumpWidget(const MaterialApp(
      home: QuizPage.forDifficulty(difficulty: QuizDifficulty.easy),
    ));
    await tester.pumpAndSettle();
    expect(find.text('تحدي سهل'), findsOneWidget);
    expect(find.text('ما معنى الكلمة التالية؟'), findsOneWidget);
    expect(find.text('Variable'), findsOneWidget);
    expect(find.byKey(const Key('quiz_speak_word')), findsOneWidget);
    await _answerAll(tester, QuizDifficulty.easy, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(SectionQuizStats.fromPreferences(
      prefs, QuizDifficulty.easy.storageId).attempts, 1);
    expect(QuizStats.fromPreferences(prefs).attempts, 7);
    expect(QuizStats.fromPreferences(prefs).bestScore, 5);
  });

  testWidgets('intermediate challenges test Arabic scenarios, not word hints',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(
      home: QuizPage.forDifficulty(difficulty: QuizDifficulty.intermediate),
    ));
    await tester.pumpAndSettle();
    expect(find.text('تحدي متوسط'), findsOneWidget);
    expect(find.byKey(const Key('quiz_practical_scenario')), findsOneWidget);
    expect(find.textContaining('في قاموسي يتغير رقم البطاقة'), findsOneWidget);
    expect(find.text('Variable'), findsOneWidget,
      reason: 'English choices are available but the prompt is Arabic');
    expect(find.byKey(const Key('quiz_revealed_word')), findsNothing);
    expect(find.byKey(const Key('quiz_speak_word')), findsNothing);
    final options = [
      for (var i = 0; i < 4; i++)
        (tester.widget<OutlinedButton>(
          find.byKey(Key('quiz_choice_$i'))).child! as Text).data!,
    ];
    await tester.tap(find.byKey(
      Key('quiz_choice_${options.indexOf('Variable')}')));
    await tester.pump();
    expect(find.byKey(const Key('quiz_revealed_word')), findsOneWidget);
    expect(find.byKey(const Key('quiz_speak_word')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pumpAndSettle();
    expect(find.text('السؤال 2 من 6'), findsOneWidget);
  });

  testWidgets('advanced challenges show real code and preserve old results',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      QuizStats.attemptsKey: 10,
      'section_quiz_stats_v1':
          '{"programming":{"attempts":3,"lastScore":4,"bestScore":5}}',
    });
    await tester.pumpWidget(const MaterialApp(
      home: QuizPage.forDifficulty(difficulty: QuizDifficulty.advanced),
    ));
    await tester.pumpAndSettle();
    expect(find.text('تحدي متقدم'), findsOneWidget);
    expect(find.byKey(const Key('quiz_scenario')), findsOneWidget);
    expect(find.textContaining('int score = 0;'), findsOneWidget);
    expect(find.textContaining('حفظ قيمة تتغير'), findsOneWidget);
    expect(find.byKey(const Key('quiz_speak_word')), findsNothing);
    await _answerAll(tester, QuizDifficulty.advanced, 0);

    final prefs = await SharedPreferences.getInstance();
    expect(SectionQuizStats.fromPreferences(prefs,
      QuizDifficulty.advanced.storageId).bestScore, 6);
    expect(QuizStats.fromPreferences(prefs).attempts, 10);
    expect(SectionQuizStats.fromPreferences(prefs, 'programming').attempts, 3);
    expect(prefs.getStringList('known_cards'), isNull);

    await tester.tap(find.text('اختبار جديد'));
    await tester.pumpAndSettle();
    expect(find.text('السؤال 1 من 6'), findsOneWidget);
    expect(find.textContaining('final amount = 42;'), findsOneWidget);
  });

  testWidgets('picker offers 3 difficulties and reloads latest score',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var starts = 0;
    await tester.pumpWidget(MaterialApp(
      home: QuizDifficultyPicker(onStart: (difficulty) async {
        starts++;
        final prefs = await SharedPreferences.getInstance();
        await SectionQuizStats.record(prefs, difficulty.storageId, 4);
      }),
    ));
    await tester.pumpAndSettle();
    expect(find.text('تحديات الإنجليزية التقنية'), findsOneWidget);
    expect(find.byKey(const Key('quiz_level_easy')), findsOneWidget);
    expect(find.byKey(const Key('quiz_level_intermediate')), findsOneWidget);
    expect(find.byKey(const Key('quiz_level_advanced')), findsOneWidget);
    await tester.tap(find.byKey(const Key('quiz_level_advanced')));
    await tester.pumpAndSettle();
    expect(starts, 1);
    expect(find.text('محاولات 1 • أفضل درجة 4/6'), findsOneWidget);
    expect(find.byKey(const Key('quiz_level_stats_advanced')), findsOneWidget);
  });

  testWidgets('home offers entry to difficulty picker without adding sections',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1250));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    final action = find.byKey(const Key('open_difficulty_quiz'));
    await tester.scrollUntilVisible(action, 190,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('اختر مستوى الاختبار'), findsOneWidget);
    expect(find.byKey(const Key('quiz_level_advanced')), findsOneWidget);
    await tester.tap(find.byKey(const Key('quiz_level_advanced')));
    await tester.pumpAndSettle();
    expect(find.text('تحدي متقدم'), findsOneWidget);
  });
}
