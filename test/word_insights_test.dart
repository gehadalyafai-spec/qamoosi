import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qamoosi/data/word_insights.dart';
import 'package:qamoosi/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all 300 vocabulary cards have complete, unique teaching notes', () {
    final cards = [
      for (final lesson in lessons) ...lesson.cards,
    ];
    final expectedIds = cards.map((card) => card.id).toSet();
    expect(cards.length, 300);
    expect(wordInsights.keys.toSet(), expectedIds);
    expect(lessons.length, 30);
    expect(lessons.skip(6).length, 24);
    for (final card in cards) {
      final insight = wordInsightFor(card.id);
      expect(insight, isNotNull, reason: 'Missing lesson for ${card.id}');
      expect(insight!.explanation.trim().length, greaterThan(20));
      expect(insight.projectUse.trim().length, greaterThan(20));
      expect(insight.practiceQuestion.trim().length, greaterThan(10));
    }
    expect(wordInsightFor('not-a-real-card'), isNull);
  });

  test('new terms have explanations and remain locally searchable', () {
    final string = lessons.first.cards.firstWhere((card) => card.id == 'string');
    final json = [
      for (final lesson in lessons)
        for (final card in lesson.cards)
          if (card.id == 'json') card,
    ].single;
    expect(matchesVocabularyQuery(string, 'سلسلة نصية'), isTrue);
    expect(matchesVocabularyQuery(string, 'اسم الدرس'), isTrue);
    expect(matchesVocabularyQuery(json, 'صيغة نصية منظمة'), isTrue);
    expect(wordInsightFor('git')!.practiceQuestion, isNotEmpty);
    expect(wordInsightFor('process')!.projectUse, isNotEmpty);
  });

  test('offline search also indexes explanation and project-use text', () {
    final variable = lessons.first.cards.first;
    expect(matchesVocabularyQuery(variable, 'Variable'), isTrue);
    expect(matchesVocabularyQuery(variable, 'متغير'), isTrue);
    expect(matchesVocabularyQuery(variable, 'قيمة باسم واضح'), isTrue);
    expect(matchesVocabularyQuery(variable, 'رقم البطاقة الحالية'), isTrue);
    expect(matchesVocabularyQuery(variable, 'ما المتغير المناسب'), isTrue);
    expect(matchesVocabularyQuery(variable, 'مستحيل-سلسلة-غير-موجودة'), isFalse);
    expect(matchesVocabularyQuery(variable, '  '), isTrue);
  });

  testWidgets('flipped flashcard explains the meaning with a real use case',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: LessonPage(
        lesson: lessons.first,
        onKnown: (id, rating) async {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('شرح مبسط'), findsNothing);
    await tester.tap(find.byKey(const Key('flip_card')));
    await tester.pumpAndSettle();
    expect(find.text('شرح مبسط'), findsOneWidget);
    expect(find.text('من واقع المشاريع'), findsOneWidget);
    expect(find.text('سؤال للتفكير'), findsOneWidget);
    expect(find.text(wordInsights['variable']!.explanation), findsOneWidget);
  });

  testWidgets('search displays the explanation when a result is expanded',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: WordSearchPage()));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('word_search_field')),
      'قيمة باسم واضح',
    );
    await tester.pumpAndSettle();
    expect(find.text('1 كلمة'), findsOneWidget);
    expect(find.text('Variable'), findsOneWidget);
    await tester.tap(find.text('Variable'));
    await tester.pumpAndSettle();
    expect(find.text(wordInsights['variable']!.explanation), findsOneWidget);
    expect(find.text(wordInsights['variable']!.projectUse), findsOneWidget);
    expect(find.text('سؤال للتفكير'), findsOneWidget);
  });
}
