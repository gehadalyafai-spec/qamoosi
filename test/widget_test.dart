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
}
