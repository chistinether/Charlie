# Voice Options — Setup Notes

This adds voice OUTPUT (Charlie reads advice aloud) and voice INPUT
(dictate into text fields) to the app. New/changed files:

    lib/services/voice_service.dart          (new)
    lib/widgets/voice_mic_button.dart         (new)
    lib/widgets/speak_button.dart             (new)
    lib/screens/features/voice_settings_screen.dart   (new)
    lib/main.dart                             (calls VoiceService.init())
    lib/screens/dashboards/profile_page.dart  (new "Voice Settings" tile)
    lib/screens/features/ai_budget_screen.dart
    lib/screens/features/add_expense_screen.dart
    lib/screens/features/add_income_screen.dart
    lib/widgets/budget_table.dart
    lib/screens/features/about_charlie_screen.dart
    lib/screens/features/manual_budget_table_screen.dart

Your zip only contained lib/, so these two steps aren't done yet —
do them before building:

## 1. Add dependencies to pubspec.yaml

    dependencies:
      flutter_tts: ^4.2.0
      speech_to_text: ^7.0.0

Then run:

    flutter pub get

(Version numbers are current as of writing — `flutter pub outdated`
if you want the latest.)

## 2. Add platform permissions

Voice input needs microphone access; on iOS it also needs a speech
recognition usage string.

### Android — android/app/src/main/AndroidManifest.xml

Add inside the outer <manifest> tag, alongside any existing
<uses-permission> entries:

    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.INTERNET" />

### iOS — ios/Runner/Info.plist

Add inside the outer <dict>:

    <key>NSMicrophoneUsageDescription</key>
    <string>Charlie uses the microphone so you can dictate expenses and budgets instead of typing.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Charlie uses speech recognition to turn what you say into text.</string>

### Web

flutter_tts and speech_to_text both work on web via the browser's
Web Speech API, no extra config needed — but note browser support for
speech-to-text on web is inconsistent (best on Chrome). The mic
button already checks `VoiceService.speechInputAvailable` and shows
a friendly message if the device/browser doesn't support it, so
this degrades gracefully.

## 3. Where things showed up

- Settings → "Voice Settings": toggle voice output/input on or off,
  adjust speech rate, pick and test a specific device voice.
- AI Budget screen: mic icon on the "Budget Purpose" field; speaker
  icon on the Charlie AI Advisor card.
- Add Expense: mic icons on Title and Notes.
- Add Income: mic icon on Description.
- Manual budget table & the "Charlie's Suggestions" save dialog:
  speaker icon reads Charlie's advice aloud.
- About Charlie: speaker icon next to the "Charlie" heading.

All of it respects the on/off switches in Voice Settings — if
voice output is off, speaker icons disappear; if voice input is
off (or unsupported), mic icons disappear.

## 4. Not done / worth knowing

- I don't have a Flutter/Dart toolchain in this environment, so this
  hasn't been run through `flutter analyze` or a real build — only
  manually reviewed and checked for balanced braces/parens. Please
  do a build + quick smoke test before shipping.
- `VoiceService.getVoices()` on Android returns every TTS voice
  installed on the device, which can be a long list (many locales).
  If you want it trimmed to English-only voices, filter
  `availableVoices` in `voice_service.dart` by locale prefix
  (e.g. `v["locale"]!.startsWith("en")`).
- Amount fields (expense/income amounts) don't have mic buttons —
  dictating numbers reliably is hit-or-miss with speech recognition,
  so I left those as manual entry. Happy to add them if you'd
  rather have the option there too.
