import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qamoosi/data/word_insights.dart';
import 'package:qamoosi/features/quiz/quiz_mistakes_review.dart';
import 'package:qamoosi/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a wrong word shows its pronunciation and Arabic explanation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: QuizPage()));
    await tester.pumpAndSettle();

    final wrongIndex = List<int>.generate(4, (i) => i).firstWhere((i) {
      final button = tester.widget<OutlinedButton>(
        find.byKey(Key('quiz_choice_$i')),
      );
      return (button.child! as Text).data != lessons.first.cards.first.translation;
    });
    await tester.tap(find.byKey(Key('quiz_choice_$wrongIndex')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quiz_wrong_feedback')), findsOneWidget);
    expect(find.text('النطق: ڤيريَبُل'), findsOneWidget);
    expect(find.text(wordInsights['variable']!.explanation), findsOneWidget);
    expect(find.byKey(const Key('quiz_next')), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('السؤال 1 من 6'), findsOneWidget);
  });

  testWidgets('a missed word can be reviewed after all six quiz questions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'known_cards': ['constant'],
    });
    final questions = buildQuizCards(0);
    await tester.pumpWidget(const MaterialApp(home: QuizPage()));
    await tester.pumpAndSettle();

    String? wrongTranslation;
    for (var i = 0; i < questions.length; i++) {
      final options = <String>[
        for (var j = 0; j < 4; j++)
          (tester.widget<OutlinedButton>(
            find.byKey(Key('quiz_choice_$j')),
          ).child! as Text).data!,
      ];
      final choice = i == 0
          ? options.indexWhere((text) => text != questions[i].translation)
          : options.indexOf(questions[i].translation);
      expect(choice, inInclusiveRange(0, 3));
      if (i == 0) wrongTranslation = options[choice];
      await tester.tap(find.byKey(Key('quiz_choice_$choice')));
      await tester.pump();
      if (i == 0) {
        expect(find.byKey(const Key('quiz_wrong_feedback')), findsOneWidget);
        await tester.tap(find.byKey(const Key('quiz_next')));
        await tester.pumpAndSettle();
      } else {
        expect(find.byKey(const Key('quiz_next')), findsNothing);
        await tester.pump(const Duration(milliseconds: 750));
        await tester.pumpAndSettle();
      }
    }

    expect(find.text('نتيجتك: 5 من 6'), findsOneWidget);
    expect(find.text('لديك 1 كلمات تحتاج مراجعة.'), findsOneWidget);
    expect(find.byKey(const Key('quiz_review_mistakes')), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('quiz_attempts'), 1);
    expect(prefs.getInt('quiz_last_score'), 5);
    expect(prefs.getStringList('known_cards'), ['constant']);

    await tester.tap(find.byKey(const Key('quiz_review_mistakes')));
    await tester.pumpAndSettle();
    expect(find.text('مراجعة كلمات الاختبار'), findsOneWidget);
    expect(find.byKey(const Key('quiz_mistakes_list')), findsOneWidget);
    expect(find.byKey(const Key('quiz_mistake_0')), findsOneWidget);
    expect(find.text('Variable'), findsOneWidget);
    expect(find.text('إجابتك: $wrongTranslation'), findsOneWidget);
    expect(find.text('الصحيح: متغير'), findsOneWidget);
    expect(find.text(wordInsights['variable']!.explanation), findsOneWidget);
    expect(prefs.getStringList('known_cards'), ['constant']);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('نتيجتك: 5 من 6'), findsOneWidget);
    expect(prefs.getInt('quiz_attempts'), 1);

    await tester.tap(find.text('اختبار جديد'));
    await tester.pumpAndSettle();
    expect(find.text('Constant'), findsOneWidget);
    expect(find.byKey(const Key('quiz_mistake_summary')), findsNothing);
  });

  testWidgets('review page handles an empty set gracefully', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: QuizMistakesReviewPage(mistakes: <QuizMistake>[]),
    ));
    await tester.pumpAndSettle();
    expect(find.text('لم تخطئ في أي كلمة!'), findsOneWidget);
  });
}
