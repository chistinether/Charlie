import 'package:flutter/material.dart';

import '../services/voice_service.dart';

/// A small mic icon meant to be dropped in as a TextField's [suffixIcon]
/// (or anywhere else) to let the user dictate into [controller] instead
/// of typing.
///
/// Usage:
/// ```dart
/// TextField(
///   controller: titleController,
///   decoration: InputDecoration(
///     labelText: "Expense Title",
///     suffixIcon: VoiceMicButton(controller: titleController),
///   ),
/// )
/// ```
///
/// Screens like Add Expense have more than one of these on screen at once
/// (title + notes). Each button owns a unique token and only shows itself
/// as "listening" when it is actually the one [VoiceService] is recording
/// for — so tapping the notes field's mic can never make the title field's
/// mic light up too, and only one mic session is ever open at a time.
class VoiceMicButton extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onResult;
  final Color activeColor;
  final Color idleColor;

  const VoiceMicButton({
    super.key,
    required this.controller,
    this.onResult,
    this.activeColor = Colors.red,
    this.idleColor = const Color(0xFF2E7D32),
  });

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton> {
  // Unique per-instance owner token, so VoiceService can tell this button
  // apart from any other mic button (or the voice-navigation FAB) that
  // might try to use the mic around the same time.
  final Object _owner = Object();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: VoiceService.voiceInputEnabled,
      builder: (context, inputEnabled, child) {
        if (!inputEnabled) return const SizedBox();

        return ValueListenableBuilder<Object?>(
          valueListenable: VoiceService.activeOwner,
          builder: (context, activeOwner, child) {
            final listening = activeOwner == _owner;
            return Semantics(
              button: true,
              label: listening
                  ? "Stop dictating"
                  : "Dictate this field by voice",
              child: IconButton(
                tooltip: listening ? "Stop listening" : "Speak",
                icon: Icon(
                  listening ? Icons.mic : Icons.mic_none,
                  color: listening ? widget.activeColor : widget.idleColor,
                ),
                onPressed: () => _handleTap(context, listening),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleTap(BuildContext context, bool listening) async {
    if (listening) {
      await VoiceService.stopListening();
      return;
    }

    if (!VoiceService.speechInputAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Voice input isn't available on this device. Check microphone permissions.",
          ),
        ),
      );
      return;
    }

    await VoiceService.startListening(
      owner: _owner,
      onResult: (text) {
        widget.controller.text = text;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length),
        );
        widget.onResult?.call();
      },
    );
  }
}
