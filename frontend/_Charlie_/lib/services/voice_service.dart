import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Central place for everything voice-related in Charlie.
///
/// Handles:
///  - Text-to-speech ("Charlie speaks" advice/insights) with a selectable
///    device voice + speech rate, persisted with SharedPreferences.
///  - Speech-to-text (dictating into text fields instead of typing, and
///    single "say a command" navigation for the accessible voice mic).
///
/// Mirrors the app's existing lightweight static-provider style
/// (see ThemeProvider / LocalStorageService) rather than pulling in a new
/// state-management pattern.
///
/// IMPORTANT: [_speech] is a single native speech-recognition session.
/// The device microphone can only be opened by ONE caller at a time — if
/// two widgets (e.g. two [VoiceMicButton]s on the same form, or a mic
/// button plus the voice-navigation FAB) call [startListening] without
/// coordination, the platform ends up opening two overlapping recording
/// sessions ("both mics open at once"), and results get delivered to
/// whichever caller's callback happened to be registered last. Every
/// start/stop below goes through [_lock] and [_owner] specifically to
/// prevent that.
class VoiceService {
  VoiceService._();

  static final FlutterTts _tts = FlutterTts();
  static final stt.SpeechToText _speech = stt.SpeechToText();

  static bool _initialized = false;
  static bool _speechAvailable = false;

  // Serializes every start/stop call so two taps arriving back-to-back
  // (e.g. a double tap, or two different mic widgets tapped in quick
  // succession) can never both be "in flight" against the native plugin
  // at the same time.
  static Future<void> _lock = Future.value();

  // Identifies whichever caller currently "owns" the open mic session.
  // A caller that isn't the current owner will never report itself as
  // listening, which is what lets multiple VoiceMicButtons share one
  // global isListening flag without all lighting up together.
  static Object? _owner;

  // ---------------- Reactive state ----------------

  static final ValueNotifier<bool> voiceOutputEnabled = ValueNotifier(true);
  static final ValueNotifier<bool> voiceInputEnabled = ValueNotifier(true);

  /// Gates the "read this screen aloud" feature (the floating button in
  /// [ScreenReaderOverlay] and the "read this screen" voice command) —
  /// kept separate from [voiceOutputEnabled] so a person can have
  /// Charlie's spoken advice on without the whole-screen reader also
  /// being active, or vice versa. Off by default: it only starts
  /// reading screen contents once someone switches it on in Settings.
  static final ValueNotifier<bool> screenReaderEnabled = ValueNotifier(false);
  static final ValueNotifier<bool> isSpeaking = ValueNotifier(false);
  static final ValueNotifier<bool> isListening = ValueNotifier(false);

  /// Mirrors [isListening] but also exposes *who* is currently listening,
  /// so a widget can check `VoiceService.activeOwner.value == myToken`
  /// instead of assuming every listening session belongs to it.
  static final ValueNotifier<Object?> activeOwner = ValueNotifier(null);

  static final ValueNotifier<double> speechRate = ValueNotifier(0.5);
  static final ValueNotifier<Map<String, String>?> selectedVoice =
      ValueNotifier(null);

  static List<Map<String, String>> availableVoices = [];

  // ---------------- Persistence keys ----------------

  static const _kOutputKey = "voice_output_enabled";
  static const _kInputKey = "voice_input_enabled";
  static const _kScreenReaderKey = "screen_reader_enabled";
  static const _kRateKey = "voice_speech_rate";
  static const _kVoiceNameKey = "voice_selected_name";
  static const _kVoiceLocaleKey = "voice_selected_locale";

  static bool get speechInputAvailable => _speechAvailable;

  /// Call once at app startup (see main.dart).
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    voiceOutputEnabled.value = prefs.getBool(_kOutputKey) ?? true;
    voiceInputEnabled.value = prefs.getBool(_kInputKey) ?? true;
    screenReaderEnabled.value = prefs.getBool(_kScreenReaderKey) ?? false;
    speechRate.value = prefs.getDouble(_kRateKey) ?? 0.5;

    try {
      await _tts.setSpeechRate(speechRate.value);
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() => isSpeaking.value = true);
      _tts.setCompletionHandler(() => isSpeaking.value = false);
      _tts.setCancelHandler(() => isSpeaking.value = false);
      _tts.setErrorHandler((_) => isSpeaking.value = false);

      final rawVoices = await _tts.getVoices;
      availableVoices = List<Map<String, String>>.from(
        (rawVoices as List).map(
          (v) => Map<String, String>.from(
            (v as Map).map((k, val) => MapEntry(k.toString(), "$val")),
          ),
        ),
      );
    } catch (e) {
      debugPrint("VoiceService: TTS init failed: $e");
      availableVoices = [];
    }

    final savedName = prefs.getString(_kVoiceNameKey);
    final savedLocale = prefs.getString(_kVoiceLocaleKey);

    if (savedName != null && savedLocale != null) {
      final match = availableVoices.firstWhere(
        (v) => v["name"] == savedName && v["locale"] == savedLocale,
        orElse: () => {},
      );

      if (match.isNotEmpty) {
        selectedVoice.value = match;
        try {
          await _tts.setVoice({"name": savedName, "locale": savedLocale});
        } catch (e) {
          debugPrint("VoiceService: could not restore saved voice: $e");
        }
      }
    }

    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == "done" || status == "notListening") {
            isListening.value = false;
            activeOwner.value = null;
          }
        },
        onError: (error) {
          debugPrint("VoiceService: speech error: $error");
          isListening.value = false;
          activeOwner.value = null;
        },
      );
    } catch (e) {
      debugPrint("VoiceService: speech-to-text init failed: $e");
      _speechAvailable = false;
    }
  }

  // ---------------- Settings ----------------

  static Future<void> setVoiceOutputEnabled(bool value) async {
    voiceOutputEnabled.value = value;
    if (!value) await stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOutputKey, value);
  }

  static Future<void> setVoiceInputEnabled(bool value) async {
    voiceInputEnabled.value = value;
    if (!value) await stopListening();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kInputKey, value);
  }

  static Future<void> setScreenReaderEnabled(bool value) async {
    screenReaderEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kScreenReaderKey, value);
  }

  static Future<void> setSpeechRate(double rate) async {
    speechRate.value = rate;
    try {
      await _tts.setSpeechRate(rate);
    } catch (e) {
      debugPrint("VoiceService: setSpeechRate failed: $e");
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kRateKey, rate);
  }

  static Future<void> setVoice(Map<String, String> voice) async {
    selectedVoice.value = voice;
    try {
      await _tts.setVoice({
        "name": voice["name"] ?? "",
        "locale": voice["locale"] ?? "",
      });
    } catch (e) {
      debugPrint("VoiceService: setVoice failed: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVoiceNameKey, voice["name"] ?? "");
    await prefs.setString(_kVoiceLocaleKey, voice["locale"] ?? "");
  }

  // ---------------- Speaking (voice OUTPUT) ----------------

  static Future<void> speak(String text) async {
    if (!voiceOutputEnabled.value || text.trim().isEmpty) return;

    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint("VoiceService: speak failed: $e");
      isSpeaking.value = false;
    }
  }

  /// Speaks [text] and waits for it to finish before returning. Handy right
  /// before opening the mic, so prompts like "Listening" don't get cut off
  /// or talked over by the mic picking up the tail end of the TTS audio.
  static Future<void> speakAndWait(String text) async {
    if (!voiceOutputEnabled.value || text.trim().isEmpty) return;
    try {
      await _tts.stop();
      await _tts.awaitSpeakCompletion(true);
      await _tts.speak(text);
    } catch (e) {
      debugPrint("VoiceService: speakAndWait failed: $e");
      isSpeaking.value = false;
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    isSpeaking.value = false;
  }

  // ---------------- Listening (voice INPUT) ----------------

  /// Starts dictation for [owner]. [onResult] is called with the live
  /// transcript as the user speaks; check `result.finalResult`-driven
  /// `isListening` to know when it has stopped.
  ///
  /// [owner] identifies the caller (pass e.g. a unique object created once
  /// per widget/State). Only one owner can be listening at a time: if
  /// something else is already listening, that session is stopped first
  /// and awaited before this one opens the mic, so the native layer never
  /// has two recognition sessions running simultaneously.
  static Future<void> startListening({
    required void Function(String text) onResult,
    required Object owner,
    // No hard-coded default here on purpose: speech_to_text expects the
    // exact locale id string a device's OS reports (BCP-47 style, e.g.
    // "en-US" with a hyphen), not the "en_US" underscore format Dart's
    // own Locale class uses. Getting that string wrong makes the
    // recognizer silently produce nothing, which looked like "it doesn't
    // catch anything I say." Passing null lets the plugin use the
    // device's own current locale, which is always valid.
    String? localeId,
    bool oneShot = false,
  }) async {
    if (!voiceInputEnabled.value || !_speechAvailable) return;

    // Chain onto the lock so overlapping calls run strictly one after
    // another instead of racing each other into `_speech.listen()`.
    final previousLock = _lock;
    final completer = Completer<void>();
    _lock = completer.future;

    try {
      await previousLock;

      // If a session is already open (ours or someone else's), close it
      // fully before opening a new one — never let two `.listen()` calls
      // be in flight at once.
      if (_speech.isListening || isListening.value) {
        try {
          await _speech.stop();
        } catch (_) {}
        isListening.value = false;
        activeOwner.value = null;
      }

      _owner = owner;
      activeOwner.value = owner;
      isListening.value = true;

      try {
        await _speech.listen(
          onResult: (result) {
            // Ignore stray results that arrive after another caller has
            // already taken over the mic.
            if (_owner != owner) return;
            onResult(result.recognizedWords);
            if (result.finalResult) {
              isListening.value = false;
              activeOwner.value = null;
            }
          },
          localeId: localeId,
          // Generous limits: long enough that a full sentence never gets
          // cut off mid-thought, but the caller (VoiceNavFab / mic
          // buttons) can always stop early with a second tap via
          // stopListening(). partialResults keeps the UI able to show
          // live progress; cancelOnError:false means a transient plugin
          // hiccup doesn't silently kill the session.
          listenFor: oneShot ? const Duration(seconds: 20) : null,
          pauseFor: Duration(seconds: oneShot ? 4 : 3),
          partialResults: true,
          cancelOnError: false,
        );
      } catch (e) {
        debugPrint("VoiceService: startListening failed: $e");
        if (_owner == owner) {
          isListening.value = false;
          activeOwner.value = null;
        }
      }
    } finally {
      completer.complete();
    }
  }

  /// Convenience for the accessible voice-navigation mic: listens for a
  /// single short command and resolves with the recognized text once the
  /// user stops talking (or after a short timeout/final result), rather
  /// than requiring the caller to track onResult/finalResult itself.
  static Future<String> listenOnceForCommand({
    required Object owner,
    String? localeId,
  }) async {
    String lastWords = "";

    await startListening(
      owner: owner,
      localeId: localeId,
      oneShot: true,
      onResult: (text) {
        lastWords = text;
      },
    );

    // Wait for this owner's session to end (finalResult fired, it was
    // stopped, or it timed out) rather than depending solely on a
    // callback, since some platforms don't always mark a short command
    // as a "final" result.
    while (activeOwner.value == owner) {
      await Future.delayed(const Duration(milliseconds: 150));
    }

    return lastWords;
  }

  static Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    isListening.value = false;
    activeOwner.value = null;
    _owner = null;
  }
}
