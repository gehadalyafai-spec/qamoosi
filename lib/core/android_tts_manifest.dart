/// Add Android 11+ TTS engine visibility to a Flutter-generated manifest.
///
/// Platform folders are generated locally in Qamoosi. This transform runs
/// after `flutter create` and never overwrites other application settings.
String ensureAndroidTtsVisibility(String manifest) {
  const action = 'android.intent.action.TTS_SERVICE';
  if (manifest.contains(action)) return manifest;
  if (!manifest.contains('<manifest') ||
      !manifest.contains('<application')) {
    throw const FormatException('AndroidManifest.xml is incomplete');
  }
  const intent = '    <intent>\n'
      '      <action android:name="android.intent.action.TTS_SERVICE" />\n'
      '    </intent>';
  if (manifest.contains('</queries>')) {
    return manifest.replaceFirst('</queries>', '$intent\n</queries>');
  }
  return manifest.replaceFirst(
    '<application',
    '<queries>\n$intent\n</queries>\n    <application',
  );
}
