import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qamoosi/core/quiz_stats.dart';
import 'package:qamoosi/core/section_quiz_scheduler.dart';
import 'package:qamoosi/core/section_quiz_stats.dart';
import 'package:qamoosi/features/catalog/vocabulary_sections.dart';
import 'package:qamoosi/main.dart';

List<Lesson> lessonsInSection(String id) {
  final section = vocabularySections.singleWhere(
    (section) => section.id == id);
  final byTitle = {for (final lesson in lessons) lesson.title: lesson};
  return [
    for (final title in section.lessonTitles) byTitle[title]!,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('section question rotation samples multiple lessons in a short quiz',
      () {
    final selected = lessonsInSection('programming');
    final first = buildSectionQuizCards(
      [for (final lesson in selected) lesson.cards], 0);
    expect(first.length, 6);
    expect(first.map((card) => card.word).toList(),
      ['Variable', 'Bug', 'Repository', 'Dart', 'Map', 'APK']);
    expect(first.map((card) => card.id).toSet().length, 6);

    final seen = <String>{};
    for (var attempt = 0; attempt < 12; attempt++) {
      final quiz = buildSectionQuizCards(
        [for (final lesson in selected) lesson.cards], attempt);
      expect(quiz.length, 6);
      expect(quiz.map((card) => card.id).toSet().length, 6);
      if (attempt < 11) {
        for (final word in quiz) {
          expect(seen.add(word.id), isTrue,
            reason: 'Repeated section card before 66 unique questions');
        }
      } else {
        seen.addAll(quiz.map((card) => card.id));
      }
    }
    expect(seen.length, 70);
    expect(buildSectionQuizCards(
      [for (final lesson in selected) lesson.cards], 1).first.word,
      'Architecture');
    expect(buildSectionQuizCards(
      [for (final lesson in selected) lesson.cards], -1).first.id,
      first.first.id);
  });

  test('tiny and empty sections remain valid and never create duplicates', () {
    expect(buildSectionQuizCards<int>([], 0), isEmpty);
    expect(buildSectionQuizCards<int>([[]], 3), isEmpty);
    expect(buildSectionQuizCards<int>([[1, 2], [3]], 0), [1, 3, 2]);
    expect(buildSectionQuizCards<int>([[1, 2, 3]], 0, questionsPerAttempt: 0),
      isEmpty);
    expect(buildSectionQuizCards<int>(
      [[1, 2, 3]], 1, questionsPerAttempt: 2), [3, 1]);
  });

  test('section results persist separately and do not overwrite global quiz',
      () async {
    SharedPreferences.setMockInitialValues({
      QuizStats.attemptsKey: 8,
      QuizStats.lastScoreKey: 2,
      QuizStats.bestScoreKey: 6,
    });
    final prefs = await SharedPreferences.getInstance();
    expect(SectionQuizStats.fromPreferences(prefs, 'programming').attempts, 0);

    final first = await SectionQuizStats.record(prefs, 'programming', 4);
    expect(first.attempts, 1);
    expect(first.lastScore, 4);
    expect(first.bestScore, 4);
    await SectionQuizStats.record(prefs, 'security_cloud', 6);
    final second = await SectionQuizStats.record(prefs, 'programming', 2);
    expect(second.attempts, 2);
    expect(second.lastScore, 2);
    expect(second.bestScore, 4);
    expect(SectionQuizStats.fromPreferences(prefs, 'security_cloud').bestScore, 6);
    expect(SectionQuizStats.allFromPreferences(prefs).length, 2);
    expect(QuizStats.fromPreferences(prefs).attempts, 8);
    expect(QuizStats.fromPreferences(prefs).lastScore, 2);
    expect(QuizStats.fromPreferences(prefs).bestScore, 6);

    final clamped = await SectionQuizStats.record(prefs, 'data_ai', 100);
    expect(clamped.bestScore, 6);
    expect(clamped.lastScore, 6);
    expect(() => SectionQuizStats.record(prefs, '', 3),
      throwsArgumentError);
  });

  test('corrupted quiz history is handled safely on offline startup', () async {
    SharedPreferences.setMockInitialValues({
      SectionQuizStats.storageKey: 'not json',
    });
    final prefs = await SharedPreferences.getInstance();
    expect(SectionQuizStats.allFromPreferences(prefs), isEmpty);

    await prefs.setString(SectionQuizStats.storageKey,
      '{"programming":{"attempts":-9,"lastScore":80,"bestScore":"bad"},'
      '"security_cloud":{"attempts":2,"lastScore":3,"bestScore":5}}');
    final bad = SectionQuizStats.fromPreferences(prefs, 'programming');
    expect(bad.attempts, 0);
    expect(bad.lastScore, 6);
    expect(bad.bestScore, 0);
    expect(SectionQuizStats.fromPreferences(prefs, 'security_cloud').attempts, 2);
    await SectionQuizStats.record(prefs, 'programming', 3);
    expect(SectionQuizStats.fromPreferences(prefs, 'security_cloud').bestScore, 5);
  });

  testWidgets('category quiz auto-advances and keeps global scores intact',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      QuizStats.attemptsKey: 10,
      QuizStats.lastScoreKey: 3,
      QuizStats.bestScoreKey: 5,
    });
    await tester.pumpWidget(MaterialApp(home: QuizPage.forSection(
      sectionId: 'programming',
      sectionTitle: 'البرمجة وتطوير التطبيقات',
      sectionLessons: lessonsInSection('programming'),
    )));
    await tester.pumpAndSettle();
    expect(find.text('اختبار: البرمجة وتطوير التطبيقات'), findsOneWidget);
    expect(find.text('Variable'), findsOneWidget);
    expect(find.text('السؤال 1 من 6'), findsOneWidget);

    final questions = buildSectionQuizCards(
      [for (final lesson in lessonsInSection('programming')) lesson.cards], 0);
    for (var i = 0; i < questions.length; i++) {
      final options = [
        for (var j = 0; j < 4; j++)
          (tester.widget<OutlinedButton>(
            find.byKey(Key('quiz_choice_$j')),
          ).child! as Text).data!,
      ];
      final answer = i == 0
          ? options.indexWhere((t) => t != questions[i].translation)
          : options.indexOf(questions[i].translation);
      expect(answer, inInclusiveRange(0, 3));
      await tester.tap(find.byKey(Key('quiz_choice_$answer')));
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
    expect(find.text('أفضل نتيجة: 5 من 6'), findsOneWidget);
    expect(find.text('العودة للقسم'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(SectionQuizStats.fromPreferences(prefs, 'programming').attempts, 1);
    expect(SectionQuizStats.fromPreferences(prefs, 'programming').lastScore, 5);
    expect(QuizStats.fromPreferences(prefs).attempts, 10);
    expect(QuizStats.fromPreferences(prefs).lastScore, 3);

    await tester.tap(find.text('اختبار جديد'));
    await tester.pumpAndSettle();
    expect(find.text('Architecture'), findsOneWidget);
    expect(find.text('السؤال 1 من 6'), findsOneWidget);
  });
}
