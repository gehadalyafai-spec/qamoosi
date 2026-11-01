import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qamoosi/core/quiz_weak_words.dart';
import 'package:qamoosi/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home suggests adaptive quiz only when mistakes were saved',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1250));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      QuizWeakWords.storageKey: '{"variable":2,"extra_sku":4}',
    });
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    final action = find.byKey(const Key('open_adaptive_quiz'));
    await tester.scrollUntilVisible(
      action, 190,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(action), alignment: 0.25);
    await tester.pumpAndSettle();
    expect(find.textContaining('كلمات تحتاج تقوية: 2'), findsOneWidget);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('اختبار تقوية الكلمات'), findsOneWidget);
    expect(find.text('SKU'), findsOneWidget);
    expect(find.text('السؤال 1 من 6'), findsOneWidget);
  });

  testWidgets('fresh install keeps a compact home without weak-word banner',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1250));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const QamoosiApp());
    await tester.pumpAndSettle();
    // The normal quiz action remains available on a new installation.
    final action = find.byKey(const Key('open_quiz'));
    await tester.scrollUntilVisible(action, 180,
      scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open_adaptive_quiz')), findsNothing);
  });
}
