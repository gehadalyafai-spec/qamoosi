import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qamoosi/core/android_tts_manifest.dart';
import 'package:qamoosi/features/pronunciation/word_pronunciation_button.dart';
import 'package:qamoosi/features/pronunciation/word_speaker.dart';
import 'package:qamoosi/main.dart';

class _FakeWordSpeaker implements WordSpeaker {
  final words = <String>[];
  final speeds = <bool>[];
  int stopCalls = 0;
  bool fail = false;

  @override
  Future<void> speak(String word, {bool slowly = false}) async {
    if (fail) throw StateError('Voice not installed');
    words.add(word);
    speeds.add(slowly);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('technical initialisms are spoken as letters without changing IDs', () {
    expect(englishTextForSpeech('API'), 'A P I');
    expect(englishTextForSpeech('SKU'), 'S K U');
    expect(englishTextForSpeech('SQL'), 'S Q L');
    expect(englishTextForSpeech('CPU'), 'C P U');
    expect(englishTextForSpeech('LLM'), 'L L M');
    expect(englishTextForSpeech('RAM'), 'ram');
    expect(englishTextForSpeech('Flutter'), 'Flutter');
    expect(englishTextForSpeech('  Variable  '), 'Variable');
    expect(englishTextForSpeech(''), isEmpty);
  });

  test('Android TTS manifest update preserves previous declarations', () {
    const original = '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '  <application android:label="قاموسي"></application>\n'
        '</manifest>\n';
    final changed = ensureAndroidTtsVisibility(original);
    expect(changed, contains('android.intent.action.TTS_SERVICE'));
    expect(changed, contains('android:label="قاموسي"'));
    expect(changed.indexOf('<queries>'), lessThan(changed.indexOf('<application')));
    expect(ensureAndroidTtsVisibility(changed), changed);

    const withQueries = '<manifest>\n'
        '  <application />\n'
        '  <queries>\n'
        '    <intent><action android:name="android.intent.action.PROCESS_TEXT" /></intent>\n'
        '  </queries>\n'
        '</manifest>';
    final merged = ensureAndroidTtsVisibility(withQueries);
    expect(merged, contains('android.intent.action.PROCESS_TEXT'));
    expect(merged, contains('android.intent.action.TTS_SERVICE'));
    expect(merged.split('<queries>').length, 2);
    expect(ensureAndroidTtsVisibility('not a manifest'), throwsFormatException);
  });

  testWidgets('button speaks normal and slow English without real audio',
      (tester) async {
    final fake = _FakeWordSpeaker();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Row(children: [
          WordPronunciationButton(
            key: const Key('normal_voice'),
            word: 'Variable',
            speaker: fake,
          ),
          WordPronunciationButton(
            key: const Key('slow_voice'),
            word: 'Variable',
            speaker: fake,
            slowly: true,
          ),
        ]),
      ),
    ));
    await tester.tap(find.byKey(const Key('normal_voice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('slow_voice')));
    await tester.pumpAndSettle();
    expect(fake.words, ['Variable', 'Variable']);
    expect(fake.speeds, [false, true]);
  });

  testWidgets('missing English voice shows friendly message rather than crash',
      (tester) async {
    final fake = _FakeWordSpeaker()..fail = true;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WordPronunciationButton(
          key: const Key('voice_error'),
          word: 'Flutter',
          speaker: fake,
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('voice_error')));
    await tester.pump();
    expect(find.textContaining('تحقّق من توفر صوت إنجليزي'), findsOneWidget);
  });

  testWidgets('flashcard speech does not flip or advance the card',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fake = _FakeWordSpeaker();
    await tester.pumpWidget(MaterialApp(
      home: LessonPage(
        lesson: lessons.first,
        onKnown: (_, __) async {},
        speaker: fake,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('lesson_speak_normal')));
    await tester.pumpAndSettle();
    expect(fake.words, ['Variable']);
    expect(fake.speeds, [false]);
    expect(find.text('البطاقة 1 من 10'), findsOneWidget);
    expect(find.text('اضغط على البطاقة لمعرفة المعنى'), findsOneWidget);

    await tester.tap(find.byKey(const Key('lesson_speak_slow')));
    await tester.pumpAndSettle();
    expect(fake.words, ['Variable', 'Variable']);
    expect(fake.speeds, [false, true]);
    expect(find.text('البطاقة 1 من 10'), findsOneWidget);
    expect(find.text('اضغط على البطاقة لمعرفة المعنى'), findsOneWidget);

    await tester.tap(find.byKey(const Key('flip_card')));
    await tester.pumpAndSettle();
    expect(find.text('متغير'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(fake.stopCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('quiz speech leaves answer state untouched',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final fake = _FakeWordSpeaker();
    await tester.pumpWidget(MaterialApp(home: QuizPage(speaker: fake)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quiz_speak_word')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quiz_speak_slow')));
    await tester.pumpAndSettle();
    expect(fake.words, ['Variable', 'Variable']);
    expect(fake.speeds, [false, true]);
    expect(find.text('السؤال 1 من 6'), findsOneWidget);
    expect(find.byKey(const Key('quiz_next')), findsNothing);
    expect(tester.widget<OutlinedButton>(
      find.byKey(const Key('quiz_choice_0'))).onPressed, isNotNull);
  });

  testWidgets('search results speak exact word and slow replay',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final fake = _FakeWordSpeaker();
    await tester.pumpWidget(MaterialApp(
      home: WordSearchPage(speaker: fake),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('word_search_field')), 'Webhook',
    );
    await tester.pumpAndSettle();

    final play = find.byKey(const Key('search_speak_extra_webhook'));
    expect(play, findsOneWidget);
    await tester.tap(play);
    await tester.pumpAndSettle();
    expect(fake.words, ['Webhook']);

    await tester.tap(find.text('Webhook'));
    await tester.pumpAndSettle();
    final slow = find.byKey(const Key('search_speak_slow_extra_webhook'));
    await tester.ensureVisible(slow);
    await tester.tap(slow);
    await tester.pumpAndSettle();
    expect(fake.words, ['Webhook', 'Webhook']);
    expect(fake.speeds, [false, true]);
  });
}
