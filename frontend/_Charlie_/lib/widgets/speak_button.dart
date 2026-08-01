import 'package:flutter/material.dart';

import '../services/voice_service.dart';

/// A small icon button that reads [text] aloud in Charlie's chosen voice.
/// Drop this next to any piece of AI advice or on-screen text that's worth
/// hearing read out loud.
class SpeakButton extends StatelessWidget {
  final String text;
  final Color color;

  const SpeakButton({
    super.key,
    required this.text,
    this.color = const Color(0xFF2E7D32),
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: VoiceService.voiceOutputEnabled,
      builder: (context, outputEnabled, child) {
        if (!outputEnabled) return const SizedBox();

        return ValueListenableBuilder<bool>(
          valueListenable: VoiceService.isSpeaking,
          builder: (context, speaking, child) {
            return IconButton(
              tooltip: speaking ? "Stop" : "Listen",
              icon: Icon(
                speaking ? Icons.stop_circle : Icons.volume_up,
                color: color,
              ),
              onPressed: () {
                if (speaking) {
                  VoiceService.stop();
                } else {
                  VoiceService.speak(text);
                }
              },
            );
          },
        );
      },
    );
  }
}
