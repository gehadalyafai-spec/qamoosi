import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qamoosi/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('home lists lessons and opens first flashcard', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    expect(find.text('الإنجليزية التقنية'), findsOneWidget);
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
    expect(find.textContaining('بطاقات مستحقة'), findsOneWidget);
  });
}

