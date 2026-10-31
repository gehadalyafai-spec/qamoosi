import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qamoosi/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('vocabulary has six lessons, thirty unique cards', () {
    expect(lessons.length, 6);
    final cards = [for (final lesson in lessons) ...lesson.cards];
    expect(cards.length, 30);
    expect(cards.map((card) => card.id).toSet().length, cards.length);
    expect(cards.every((card) => card.word.isNotEmpty && card.translation.isNotEmpty && card.pronunciation.isNotEmpty), isTrue);
  });
  testWidgets('home lists lessons and opens first flashcard', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    expect(find.text('الإنجليزية التقنية'), findsOneWidget);
    await tester.ensureVisible(find.text('أساسيات البرمجة'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
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
    await tester.tap(find.text('اختبر معلوماتك'));
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
    expect(find.text('Variable'), findsOneWidget);
    expect(find.text('متغير'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('word_search_field')), 'لا يوجد');
    await tester.pumpAndSettle();
    expect(find.text('لم نعثر على كلمات مطابقة'), findsOneWidget);
  });

}

