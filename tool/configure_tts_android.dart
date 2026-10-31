import 'dart:io';

import 'package:qamoosi/core/android_tts_manifest.dart';

/// Run after `flutter create --platforms=android .` (if needed).
/// Updates only Android's TTS visibility declaration, preserving the rest.
Future<void> main() async {
  final file = File('android/app/src/main/AndroidManifest.xml');
  if (!await file.exists()) {
    stderr.writeln('Missing AndroidManifest.xml. Run flutter create --platforms=android . first.');
    exitCode = 1;
    return;
  }
  final original = await file.readAsString();
  final updated = ensureAndroidTtsVisibility(original);
  if (original == updated) {
    stdout.writeln('Android speech-service visibility is already configured.');
    return;
  }
  await file.writeAsString(updated);
  stdout.writeln('Added speech-service visibility to AndroidManifest.xml.');
}
