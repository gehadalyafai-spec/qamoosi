import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qamoosi/core/review_scheduler.dart';

import 'package:qamoosi/features/catalog/vocabulary_sections.dart';
import 'package:qamoosi/main.dart';

List<VocabularySectionSelection> sectionsFor({
  LearningLevel? level,
  String query = '',
}) => selectVocabularySections(
  lessonTitles: [for (final lesson in lessons) lesson.title],
  matchesLevel: (i) => level == null || lessons[i].level == level,
  matchesLesson: (i, query) => matchesLessonQuery(lessons[i], query),
  query: query,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('six topical sections cover all 30 lessons and 300 cards exactly once',
      () {
    final sections = sectionsFor();
    expect(vocabularySections.length, 6);
    expect(sections.length, 6);
    expect(sections.map((section) => section.section.id).toSet().length, 6);
    expect(sections.map((section) => section.lessonIndices.length).toList(),
      [5, 7, 5, 5, 4, 4]);
    final indices = [
      for (final section in sections) ...section.lessonIndices,
    ];
    expect(indices.length, 30);
    expect(indices.toSet().length, 30);
    expect(indices.toSet(), {for (var i = 0; i < lessons.length; i++) i});
    expect(indices.fold<int>(0,
      (sum, index) => sum + lessons[index].cards.length), 300);
    expect(sections[1].section.title, 'البرمجة وتطوير التطبيقات');
    expect(sections.last.section.title, 'البيانات والذكاء الاصطناعي');
  });

  test('level filtering hides empty sections but preserves all old lessons',
      () {
    final beginner = sectionsFor(level: LearningLevel.beginner);
    final intermediate = sectionsFor(level: LearningLevel.intermediate);
    expect(beginner.length, 5);
    expect(intermediate.length, 5);
    expect(beginner.fold<int>(0,
      (sum, section) => sum + section.lessonIndices.length), 11);
    expect(intermediate.fold<int>(0,
      (sum, section) => sum + section.lessonIndices.length), 19);
    final bIds = {
      for (final section in beginner)
        for (final index in section.lessonIndices)
          for (final card in lessons[index].cards) card.id,
    };
    final iIds = {
      for (final section in intermediate)
        for (final index in section.lessonIndices)
          for (final card in lessons[index].cards) card.id,
    };
    expect(bIds.intersection(iIds), isEmpty);
    expect(bIds.union(iIds).length, 300);
  });

  test('search finds a word in its category and section title opens whole topic',
      () {
    final webhook = sectionsFor(query: 'Webhook');
    expect(webhook.length, 1);
    expect(webhook.single.section.id, 'security_cloud');
    expect(webhook.single.lessonIndices.length, 1);
    expect(lessons[webhook.single.lessonIndices.single].title,
      'التكاملات وأحداث الأنظمة');

    final ai = sectionsFor(query: 'البيانات والذكاء الاصطناعي');
    expect(ai.length, 1);
    expect(ai.single.section.id, 'data_ai');
    expect(ai.single.lessonIndices.length, 4);
    final categoryBeginner = sectionsFor(
      query: 'البرمجة وتطوير التطبيقات',
      level: LearningLevel.beginner,
    );
    expect(categoryBeginner.single.lessonIndices.length, 1);
    expect(lessons[categoryBeginner.single.lessonIndices.single].title,
      'أساسيات البرمجة');

    expect(sectionsFor(query: 'محتوى غير موجود'), isEmpty);
    expect(sectionsFor(query: ' ').length, 6);
  });

  testWidgets('six collapsed sections expand and launch original lesson',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1250));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'known_cards': ['variable', 'extra_cpu'],
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    // The home screen uses a lazy sliver. Build its catalog area first,
    // exactly as a user does by scrolling down from the hero content.
    final field = find.byKey(const Key('lesson_search_field'));
    await tester.scrollUntilVisible(field, 200,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('vocabulary_section_list')), findsOneWidget);
    expect(find.byKey(const Key('section_programming')), findsOneWidget);
    expect(find.byKey(const Key('section_data_ai')), findsOneWidget);
    expect(find.byKey(const Key('lesson_0')), findsNothing);

    final group = find.byKey(const Key('section_expand_programming_all'));
    await tester.scrollUntilVisible(group, 200,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(group), alignment: 0.15);
    await tester.pumpAndSettle();
    await tester.tap(group);
    await tester.pumpAndSettle();

    final lesson = find.byKey(const Key('lesson_0'));
    await tester.scrollUntilVisible(lesson, 140,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(lesson), alignment: 0.2);
    await tester.pumpAndSettle();
    expect(find.text('أساسيات البرمجة'), findsOneWidget);
    await tester.tap(lesson);
    await tester.pumpAndSettle();
    expect(find.text('Variable'), findsOneWidget);
    expect(find.text('البطاقة 1 من 10'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('known_cards'), ['variable', 'extra_cpu']);
  });

  testWidgets('continue section shows only unmastered cards and saves progress',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1250));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'known_cards': ['variable'],
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    final group = find.byKey(const Key('section_expand_programming_all'));
    await tester.scrollUntilVisible(group, 200,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(group), alignment: 0.15);
    await tester.pumpAndSettle();
    await tester.tap(group);
    await tester.pumpAndSettle();

    final continueButton = find.byKey(
      const Key('section_continue_programming'));
    await tester.scrollUntilVisible(continueButton, 150,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(continueButton), alignment: 0.25);
    await tester.pumpAndSettle();
    expect(find.text('تعلّم 6 كلمات'), findsOneWidget);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('تعلّم: البرمجة وتطوير التطبيقات'), findsOneWidget);
    expect(find.text('Constant'), findsOneWidget);
    expect(find.text('البطاقة 1 من 6'), findsOneWidget);
    await tester.tap(find.text('عرفتها'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('known_cards'), containsAll(['variable', 'constant']));

    await tester.pageBack();
    await tester.pumpAndSettle();
    final progress = find.byKey(const Key('section_progress_programming'));
    await tester.scrollUntilVisible(progress, 150,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('2 من 70 كلمة'), findsOneWidget);
  });

  testWidgets('section quiz action opens its topic and shows previous score',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1250));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'section_quiz_stats_v1':
          '{"programming":{"attempts":2,"lastScore":4,"bestScore":5}}',
      'quiz_attempts': 9,
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    final group = find.byKey(const Key('section_expand_programming_all'));
    await tester.scrollUntilVisible(group, 200,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(group);
    await tester.pumpAndSettle();

    final quizButton = find.byKey(const Key('section_quiz_programming'));
    await tester.scrollUntilVisible(quizButton, 150,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('اختباراتك: 2 • آخر نتيجة: 4/6 • أفضل نتيجة: 5/6'),
      findsOneWidget);
    await Scrollable.ensureVisible(
      tester.element(quizButton), alignment: 0.3);
    await tester.pumpAndSettle();
    await tester.tap(quizButton);
    await tester.pumpAndSettle();
    expect(find.text('اختبار: البرمجة وتطوير التطبيقات'), findsOneWidget);
    expect(find.text('السؤال 1 من 6'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('quiz_attempts'), 9);
  });

  test('section progress includes only real catalog IDs and no duplicates', () {
    final summary = SectionProgressSummary.fromCardIds(
      cardIds: ['variable', 'function', 'variable', 'retired'],
      knownIds: {'variable', 'outside'},
      dueIds: {'function', 'outside'},
      weeklyIds: {'variable', 'retired', 'outside'},
    );
    expect(summary.total, 3);
    expect(summary.mastered, 1);
    expect(summary.dueReviews, 1);
    expect(summary.practisedThisWeek, 2);
    expect(summary.masteryPercent, 33);
    final empty = SectionProgressSummary.fromCardIds(
      cardIds: [],
      knownIds: {'variable'},
      dueIds: {'variable'},
      weeklyIds: {'variable'},
    );
    expect(empty.masteryFraction, 0);
    expect(empty.masteryPercent, 0);
    expect(empty.dueReviews, 0);
  });

  testWidgets('section due review works even when its lesson is filtered out',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1250));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final due = ReviewState(
      dueAt: DateTime.now().subtract(const Duration(days: 2)),
      intervalDays: 1, successfulReviews: 1,
    );
    SharedPreferences.setMockInitialValues({
      'known_cards': ['variable'],
      'review_states': jsonEncode({'variable': due.toJson()}),
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    final filter = find.byKey(const Key('level_intermediate'));
    await tester.scrollUntilVisible(filter, 180,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(filter);
    await tester.pumpAndSettle();

    final category = find.byKey(const Key('section_expand_programming_all'));
    await tester.scrollUntilVisible(category, 160,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('6 دروس • 1 من 70 كلمة'), findsOneWidget);
    expect(find.textContaining('مراجعات مستحقة 1'), findsWidgets);
    await tester.tap(category);
    await tester.pumpAndSettle();

    final review = find.byKey(const Key('section_due_review_programming'));
    await tester.scrollUntilVisible(review, 120,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(
      tester.element(review), alignment: 0.3);
    await tester.pumpAndSettle();
    await tester.tap(review);
    await tester.pumpAndSettle();
    // The beginner word still belongs to this category and needs reviewing,
    // even if the intermediate filter temporarily hides its normal lesson.
    expect(find.text('مراجعات: البرمجة وتطوير التطبيقات'), findsOneWidget);
    expect(find.text('Variable'), findsOneWidget);
    expect(find.text('البطاقة 1 من 1'), findsOneWidget);
    await tester.tap(find.text('عرفتها'));
    await tester.pumpAndSettle();
    // Completing the only due card automatically closes its lesson.
    expect(find.text('مراجعات: البرمجة وتطوير التطبيقات'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('review_states')!) as Map;
    final updated = ReviewState.fromJson(saved['variable'])!;
    expect(updated.isDue(DateTime.now()), isFalse);
    expect(prefs.getStringList('known_cards'), contains('variable'));
  });
}
