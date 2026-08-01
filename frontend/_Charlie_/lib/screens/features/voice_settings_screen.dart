import 'package:flutter/material.dart';

import '../../services/screen_reader_service.dart';
import '../../services/voice_service.dart';

class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  static const _green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text("Voice Settings"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Voice Output",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Let Charlie read advice and insights out loud.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: VoiceService.voiceOutputEnabled,
              builder: (context, enabled, child) {
                return SwitchListTile(
                  activeColor: _green,
                  title: const Text("Charlie speaks"),
                  subtitle: const Text("Read advice aloud"),
                  value: enabled,
                  onChanged: (value) {
                    VoiceService.setVoiceOutputEnabled(value);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            "Voice Input",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Speak instead of typing on supported fields (look for the mic icon).",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: VoiceService.voiceInputEnabled,
              builder: (context, enabled, child) {
                return SwitchListTile(
                  activeColor: _green,
                  title: const Text("Voice input"),
                  subtitle: Text(
                    VoiceService.speechInputAvailable
                        ? "Dictate into text fields"
                        : "Not available on this device",
                  ),
                  value: enabled && VoiceService.speechInputAvailable,
                  onChanged: VoiceService.speechInputAvailable
                      ? (value) => VoiceService.setVoiceInputEnabled(value)
                      : null,
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            "Screen Reader",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Have Charlie read this screen's text and buttons aloud, "
            "top to bottom, using the floating button in the corner of "
            "every screen (or by saying \"read this screen\").",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: VoiceService.screenReaderEnabled,
              builder: (context, enabled, child) {
                return SwitchListTile(
                  activeColor: _green,
                  title: const Text("Screen reader"),
                  subtitle: const Text("Read screen contents aloud"),
                  value: enabled,
                  onChanged: (value) {
                    VoiceService.setScreenReaderEnabled(value);
                    if (!value) ScreenReaderService.stop();
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            "Speech Rate",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ValueListenableBuilder<double>(
            valueListenable: VoiceService.speechRate,
            builder: (context, rate, child) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.slow_motion_video, color: _green),
                      Expanded(
                        child: Slider(
                          activeColor: _green,
                          value: rate.clamp(0.1, 1.0),
                          min: 0.1,
                          max: 1.0,
                          divisions: 18,
                          label: rate.toStringAsFixed(2),
                          onChanged: (value) {
                            VoiceService.setSpeechRate(value);
                          },
                        ),
                      ),
                      const Icon(Icons.fast_forward, color: _green),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Choose a Voice",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: VoiceService.isSpeaking,
                builder: (context, speaking, child) {
                  return TextButton.icon(
                    onPressed: () {
                      if (speaking) {
                        VoiceService.stop();
                      } else {
                        VoiceService.speak(
                          "Hi, I'm Charlie, your budget advisor. This is what I sound like.",
                        );
                      }
                    },
                    icon: Icon(speaking ? Icons.stop : Icons.play_arrow),
                    label: Text(speaking ? "Stop" : "Test current voice"),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (VoiceService.availableVoices.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "No selectable voices were found on this device. "
                  "Charlie will use the system default voice.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ValueListenableBuilder<Map<String, String>?>(
              valueListenable: VoiceService.selectedVoice,
              builder: (context, selected, child) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: VoiceService.availableVoices.map((voice) {
                      final isSelected = selected != null &&
                          selected["name"] == voice["name"] &&
                          selected["locale"] == voice["locale"];

                      return RadioListTile<String>(
                        activeColor: _green,
                        title: Text(voice["name"] ?? "Unknown voice"),
                        subtitle: Text(voice["locale"] ?? ""),
                        value: voice["name"] ?? "",
                        groupValue: isSelected ? voice["name"] : null,
                        onChanged: (_) {
                          VoiceService.setVoice(voice);
                          VoiceService.speak("This is Charlie's voice.");
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
