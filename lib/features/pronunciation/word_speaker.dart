import 'package:flutter_tts/flutter_tts.dart';

/// An injectable contract so speaking controls can be widget-tested without
/// relying on the device's installed voice engine.
abstract class WordSpeaker {
  Future<void> speak(String word, {bool slowly = false});
  Future<void> stop();
}

/// Spoken forms for common technical initialisms. Most words are passed to
/// the English synthesizer unchanged; these are spelled out as letters.
const spokenTechnicalInitialisms = <String, String>{
  'API': 'A P I',
  'APK': 'A P K',
  'AAB': 'A A B',
  'AI': 'A I',
  'CI': 'C I',
  'CD': 'C D',
  'CPU': 'C P U',
  'CSS': 'C S S',
  'DNS': 'D N S',
  'DOM': 'D O M',
  'HTML': 'H T M L',
  'HTTP': 'H T T P',
  'HTTPS': 'H T T P S',
  'IP': 'I P',
  'JSON': 'J S O N',
  'KPI': 'K P I',
  'LLM': 'L L M',
  'PDF': 'P D F',
  'RAG': 'R A G',
  'RAM': 'ram',
  'REST': 'rest',
  'SDK': 'S D K',
  'SKU': 'S K U',
  'SQL': 'S Q L',
  'SLA': 'S L A',
  'UI': 'U I',
  'UX': 'U X',
};

String englishTextForSpeech(String word) {
  final trimmed = word.trim();
  return spokenTechnicalInitialisms[trimmed] ?? trimmed;
}

/// Uses the native Android/iOS voice or browser speech synthesis.
/// A native voice may need installation; no audio files or internet API keys
/// are downloaded or used by this app.
class FlutterWordSpeaker implements WordSpeaker {
  FlutterTts? _tts;

  @override
  Future<void> speak(String word, {bool slowly = false}) async {
    final spoken = englishTextForSpeech(word);
    if (spoken.isEmpty) {
      throw StateError('لا توجد كلمة قابلة للنطق');
    }
    final tts = _tts ??= FlutterTts();
    // Stop the previous utterance if another card is selected.
    await tts.stop();

    String language = 'en-US';
    try {
      final available = await tts.getLanguages;
      if (available is List && available.isNotEmpty) {
        final langs = available
            .whereType<String>()
            .map((item) => item.toLowerCase().replaceAll('_', '-'))
            .toSet();
        if (langs.contains('en-us')) {
          language = 'en-US';
        } else if (langs.contains('en-gb')) {
          language = 'en-GB';
        } else {
          final otherEnglish = langs.where(
            (item) => item == 'en' || item.startsWith('en-'),
          );
          if (otherEnglish.isEmpty) {
            throw StateError('لا يوجد صوت إنجليزي على هذا الجهاز');
          }
          language = otherEnglish.first;
        }
      }
    } on StateError {
      rethrow;
    } catch (_) {
      // Some browsers do not expose the full list of available voices.
      // Try the system's English voice directly in that case.
    }

    await tts.setLanguage(language);
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);
    await tts.setSpeechRate(slowly ? 0.34 : 0.48);
    await tts.speak(spoken);
  }

  @override
  Future<void> stop() async {
    final tts = _tts;
    if (tts != null) await tts.stop();
  }
}
