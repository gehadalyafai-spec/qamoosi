import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qamoosi/main.dart';
import 'package:qamoosi/features/achievements/achievements_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('achievement summary clamps and safely handles empty lessons', () {
    const empty = LessonAchievement(title: 'فارغ', completed: 0, total: 0);
    const partial = LessonAchievement(title: 'جزئي', completed: 2, total: 5);
    const finished = LessonAchievement(title: 'مكتمل', completed: 5, total: 5);
    expect(empty.progress, 0);
    expect(empty.isCompleted, isFalse);
    expect(partial.progress, 0.4);
    expect(partial.isCompleted, isFalse);
    expect(finished.progress, 1);
    expect(finished.isCompleted, isTrue);
  });

  testWidgets('achievements display saved learning progress', (tester) async {
    SharedPreferences.setMockInitialValues({
      'known_cards': ['variable'],
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنجازاتي').last);
    await tester.pumpAndSettle();
    expect(find.text('أتقنت 1 من 30 بطاقة'), findsOneWidget);
    expect(find.text('تفاصيل الدروس'), findsOneWidget);
    expect(find.text('دروس مكتملة'), findsOneWidget);
    expect(find.text('مستحقة للمراجعة'), findsOneWidget);
  });

  test('lesson progress counts only known cards in that lesson', () {
    final lesson = lessons.first;
    expect(lessonProgress(lesson, {}), 0);
    expect(lessonProgress(lesson, {lesson.cards.first.id}), 0.2);
    expect(lessonProgress(lesson, {for (final card in lesson.cards) card.id}), 1);
    expect(lessonProgress(lesson, {'unknown-card'}), 0);
  });

  test('vocabulary has six lessons, thirty unique cards', () {
    expect(lessons.length, 6);
    final cards = [for (final lesson in lessons) ...lesson.cards];
    expect(cards.length, 30);
    expect(cards.map((card) => card.id).toSet().length, cards.length);
    expect(cards.every((card) => card.word.isNotEmpty && card.translation.isNotEmpty && card.pronunciation.isNotEmpty), isTrue);
  });
  testWidgets('home lists lessons and opens first flashcard', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    expect(find.text('الإنجليزية التقنية'), findsOneWidget);
    await tester.ensureVisible(find.text('أساسيات البرمجة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أساسيات البرمجة'));
    await tester.pumpAndSettle();
    expect(find.text('Variable'), findsOneWidget);
    await tester.tap(find.byKey(const Key('flip_card')));
    await tester.pumpAndSettle();
    expect(find.text('متغير'), findsOneWidget);
  });

  testWidgets('bottom navigation opens progress and review', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنجازاتي').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('أتقنت'), findsOneWidget);
    await tester.tap(find.text('المراجعة').last);
    await tester.pumpAndSettle();
    expect(find.text('بطاقات مستحقة: 0'), findsOneWidget);
  });
  testWidgets('review tab launches only due flashcards', (tester) async {
    SharedPreferences.setMockInitialValues({
      'review_states': jsonEncode({
        'variable': {
          'dueAt': '2020-01-01T00:00:00.000Z',
          'intervalDays': 1,
          'successfulReviews': 1,
        },
      }),
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('المراجعة').last);
    await tester.pumpAndSettle();
    expect(find.text('بطاقات مستحقة: 1'), findsOneWidget);
    await tester.tap(find.text('ابدأ المراجعة الآن'));
    await tester.pumpAndSettle();
    expect(find.text('مراجعة البطاقات المستحقة'), findsOneWidget);
    expect(find.text('Variable'), findsOneWidget);
    expect(find.text('البطاقة 1 من 1'), findsOneWidget);
  });

  testWidgets('quiz starts and shows first question', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('اختبر معلوماتك'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اختبر معلوماتك'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('اختبار الكلمات'), findsOneWidget);
    expect(find.text('السؤال 1 من 5'), findsOneWidget);
    expect(find.text('Variable'), findsOneWidget);
  });
  testWidgets('search finds English and Arabic vocabulary', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_word_search')));
    await tester.pumpAndSettle();
    expect(find.text('البحث في قاموسي'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('word_search_field')), 'Variable');
    await tester.pumpAndSettle();
    expect(find.text('Variable'), findsWidgets);
    expect(find.text('متغير'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('word_search_field')), 'لا يوجد');
    await tester.pumpAndSettle();
    expect(find.text('لم نعثر على كلمات مطابقة'), findsOneWidget);
  });

}

