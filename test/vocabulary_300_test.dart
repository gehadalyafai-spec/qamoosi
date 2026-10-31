import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qamoosi/data/expanded_vocabulary_everyday_mobile.dart';
import 'package:qamoosi/data/expanded_vocabulary_business_ai.dart';
import 'package:qamoosi/data/word_insights.dart';
import 'package:qamoosi/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('second expansion has 120 complete new entries and unique stable IDs',
      () {
    final lessonsOfStageTwo = [
      ...expandedVocabularyEverydayAndMobile,
      ...expandedVocabularyBusinessAndAi,
    ];
    expect(lessonsOfStageTwo.length, 12);
    expect(lessonsOfStageTwo.every((lesson) => lesson.cards.length == 10),
      isTrue);
    final terms = [
      for (final lesson in lessonsOfStageTwo) ...lesson.cards,
    ];
    expect(terms.length, 120);
    expect(terms.map((term) => term.id).toSet().length, 120);
    final historicIds = {
      for (final lesson in lessons.take(18))
        for (final card in lesson.cards) card.id,
    };
    expect(historicIds.length, 180);
    for (final term in terms) {
      expect(term.id.startsWith('extra_'), isTrue, reason: term.id);
      expect(historicIds.contains(term.id), isFalse, reason: term.id);
      expect(term.word.trim(), isNotEmpty, reason: term.id);
      expect(term.pronunciation.trim(), isNotEmpty, reason: term.id);
      expect(term.translation.trim(), isNotEmpty, reason: term.id);
      expect(term.example.trim(), isNotEmpty, reason: term.id);
      expect(term.explanation.length, greaterThan(20), reason: term.id);
      expect(term.projectUse.length, greaterThan(20), reason: term.id);
      expect(term.practiceQuestion.length, greaterThan(10), reason: term.id);
      final saved = wordInsightFor(term.id);
      expect(saved, isNotNull, reason: term.id);
      expect(saved!.explanation, term.explanation);
    }
  });

  test('commerce and AI terms can be found by text or Arabic teaching notes',
      () {
    final cards = [for (final lesson in lessons) ...lesson.cards];
    final checkout = cards.singleWhere((card) => card.id == 'extra_checkout');
    final webhook = cards.singleWhere((card) => card.id == 'extra_webhook');
    final rag = cards.singleWhere((card) => card.id == 'extra_rag');
    expect(matchesVocabularyQuery(checkout, 'إتمام الشراء'), isTrue);
    expect(matchesVocabularyQuery(webhook, 'Webhook'), isTrue);
    expect(matchesVocabularyQuery(webhook, 'يُرسلها نظام'), isTrue);
    expect(matchesVocabularyQuery(rag, 'توليد مدعوم بالاسترجاع'), isTrue);
    expect(matchesVocabularyQuery(rag, 'مصادر ذات صلة'), isTrue);
    expect(matchesLessonQuery(lessons[27], 'ويب هوك'), isTrue);
    expect(matchesLessonQuery(lessons[29], 'LLM'), isTrue);
    expect(matchesVocabularyQuery(rag, 'نص خارج نطاق البطاقة'), isFalse);
  });

  testWidgets('new commerce card opens learning notes and retains progress',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'known_cards': ['variable', 'extra_cpu', 'extra_webhook'],
    });
    await tester.pumpWidget(MaterialApp(
      home: LessonPage(
        lesson: lessons[24],
        onKnown: (_, __) async {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Catalog'), findsOneWidget);
    await tester.tap(find.byKey(const Key('flip_card')));
    await tester.pumpAndSettle();
    expect(find.text('كتالوج المنتجات'), findsOneWidget);
    expect(find.text(wordInsights['extra_product_catalog']!.explanation),
      findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('known_cards'),
      ['variable', 'extra_cpu', 'extra_webhook']);
  });

  testWidgets('search supports a new integration term without network',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: WordSearchPage()));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('word_search_field')),
      'webhook',
    );
    await tester.pumpAndSettle();
    expect(find.text('1 كلمة'), findsOneWidget);
    expect(find.text('Webhook'), findsOneWidget);
    await tester.tap(find.text('Webhook'));
    await tester.pumpAndSettle();
    expect(find.text(wordInsights['extra_webhook']!.explanation),
      findsOneWidget);
  });
}
