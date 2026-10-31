import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qamoosi/data/vocabulary_expansion.dart';
import 'package:qamoosi/data/word_insights.dart';
import 'package:qamoosi/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all new terms keep stable namespaced IDs and rich educational content',
      () {
    expect(expandedVocabulary.length, 12);
    final newCards = [
      for (final lesson in expandedVocabulary) ...lesson.cards,
    ];
    expect(newCards.length, 120);
    expect(newCards.map((card) => card.id).toSet().length, 120);
    expect(newCards.every((card) => card.id.startsWith('extra_')), isTrue);

    final original = [
      for (final lesson in lessons.take(6)) ...lesson.cards,
    ];
    expect(original.length, 60);
    final originalIds = original.map((card) => card.id).toSet();
    expect(newCards.every((card) => !originalIds.contains(card.id)), isTrue);

    for (final card in newCards) {
      expect(card.word.trim(), isNotEmpty, reason: card.id);
      expect(card.pronunciation.trim(), isNotEmpty, reason: card.id);
      expect(card.translation.trim(), isNotEmpty, reason: card.id);
      expect(card.example.trim(), isNotEmpty, reason: card.id);
      expect(card.explanation.trim().length, greaterThan(20),
        reason: card.id);
      expect(card.projectUse.trim().length, greaterThan(20),
        reason: card.id);
      expect(card.practiceQuestion.trim().length, greaterThan(10),
        reason: card.id);
      final insight = wordInsightFor(card.id);
      expect(insight, isNotNull, reason: card.id);
      expect(insight!.explanation, card.explanation);
      expect(insight.projectUse, card.projectUse);
      expect(insight.practiceQuestion, card.practiceQuestion);
    }
  });

  test('expanded lessons are grouped correctly without modifying old lessons',
      () {
    expect(lessons.length, 18);
    expect(lessons.every((lesson) => lesson.cards.length == 10), isTrue);
    expect(lessons[0].title, 'أساسيات البرمجة');
    expect(lessons[5].title, 'تشغيل البرامج');
    expect(lessons[6].title, 'الحاسوب ومكوناته');
    expect(lessons[17].title, 'الذكاء الاصطناعي وتحليل البيانات');

    expect(lessons[6].level, LearningLevel.beginner);
    expect(lessons[9].level, LearningLevel.beginner);
    expect(lessons[10].level, LearningLevel.intermediate);
    expect(lessons[17].level, LearningLevel.intermediate);
    final ids = {
      for (final lesson in lessons)
        for (final card in lesson.cards) card.id,
    };
    expect(ids.length, 180);
    expect(ids.containsAll([
      'variable', 'extra_cpu', 'extra_flutter', 'extra_sql_query',
      'extra_encryption', 'extra_prompt', 'extra_inference',
    ]), isTrue);
  });

  test('new technical terms are indexed in Arabic, English and explanation',
      () {
    final cards = [
      for (final lesson in lessons) ...lesson.cards,
    ];
    final ai = cards.singleWhere((card) => card.id == 'extra_embedding');
    final security = cards.singleWhere((card) => card.id == 'extra_https');
    final flutter = cards.singleWhere((card) => card.id == 'extra_hot_reload');
    expect(matchesVocabularyQuery(ai, 'Embedding'), isTrue);
    expect(matchesVocabularyQuery(ai, 'تمثيل عددي'), isTrue);
    expect(matchesVocabularyQuery(ai, 'التشابه التقريبي'), isTrue);
    expect(matchesVocabularyQuery(security, 'اتصال ويب مشفر'), isTrue);
    expect(matchesVocabularyQuery(security, 'TLS'), isTrue);
    expect(matchesVocabularyQuery(flutter, 'التحديث السريع'), isTrue);
    expect(matchesVocabularyQuery(flutter, 'تعديل المسافات'), isTrue);
    expect(matchesVocabularyQuery(ai, 'نص لا يطابق هذا المصطلح'), isFalse);
  });

  testWidgets('expanded flashcard can be flipped and shows its own teaching',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      home: LessonPage(
        lesson: lessons[6],
        onKnown: (_, __) async {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('CPU'), findsOneWidget);
    expect(find.text('البطاقة 1 من 10'), findsOneWidget);
    await tester.tap(find.byKey(const Key('flip_card')));
    await tester.pumpAndSettle();
    expect(find.text('وحدة المعالجة المركزية'), findsOneWidget);
    expect(find.text(wordInsights['extra_cpu']!.explanation), findsOneWidget);
    expect(find.text(wordInsights['extra_cpu']!.projectUse), findsOneWidget);
  });

  testWidgets('offline search opens detailed explanation for a new term',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: WordSearchPage()));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('word_search_field')),
      'التشابه التقريبي',
    );
    await tester.pumpAndSettle();
    expect(find.text('1 كلمة'), findsOneWidget);
    expect(find.text('Embedding'), findsOneWidget);
    await tester.tap(find.text('Embedding'));
    await tester.pumpAndSettle();
    expect(find.text(wordInsights['extra_embedding']!.explanation),
      findsOneWidget);
  });

  testWidgets('existing saved mastery stays in place after vocabulary update',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'known_cards': ['variable', 'file', 'extra_cpu'],
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    expect(find.text('3 من 180 بطاقة'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('known_cards'),
      ['variable', 'file', 'extra_cpu']);
    expect(lessonProgress(lessons.first, {'variable'}), 0.1);
    expect(lessonProgress(lessons[6], {'extra_cpu'}), 0.1);
  });
}
