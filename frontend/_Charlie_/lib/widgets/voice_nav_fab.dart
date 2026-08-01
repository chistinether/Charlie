import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/test_users.dart';
import '../services/screen_reader_service.dart';
import '../services/voice_command_router.dart';
import '../services/voice_service.dart';

/// A single always-on-screen microphone that lets a visually impaired user
/// operate the whole app by voice.
///
/// It works in two modes, decided automatically by what has focus the
/// moment you tap it — no separate mode switch to remember:
///
///  * **No text field focused** — whatever you say is treated as a
///    navigation command: "open expenses", "open manual budgets",
///    "profile", "add expense", "go back", and so on. Charlie speaks back
///    what it's doing.
///  * **A text field is focused** (e.g. you've tabbed/swiped to the
///    "Expense Title" field with a screen reader) — anything that isn't
///    itself a recognized navigation command is typed straight into that
///    field, exactly like the little per-field mic icons already do. That
///    means a blind user never has to hunt for those small icons — this
///    one mic does both jobs depending on where they already are.
///
/// Drop this once in [DashboardScreen] (it stays on screen across every
/// tab because it lives outside the IndexedStack body).
///
/// Shares [VoiceService]'s single listening session with every
/// [VoiceMicButton] in the app (same lock/ownership model), so tapping
/// this while a text field's own dictation mic is already open cleanly
/// stops that session first instead of opening a second microphone
/// stream.
class VoiceNavFab extends StatefulWidget {
  final TestUser user;

  /// Called after any action that changes the user's data (add expense /
  /// add income), mirroring the `onUpdated` callback the rest of the app
  /// already uses to refresh the dashboard.
  final VoidCallback onDataChanged;

  /// Switches the dashboard's bottom-nav tab (Home/Expenses/Analytics/
  /// Budgets/Profile) — see [DashboardTabs].
  final ValueChanged<int> onSwitchTab;

  const VoiceNavFab({
    super.key,
    required this.user,
    required this.onDataChanged,
    required this.onSwitchTab,
  });

  @override
  State<VoiceNavFab> createState() => _VoiceNavFabState();
}

class _VoiceNavFabState extends State<VoiceNavFab> {
  final Object _owner = Object();

  // canRequestFocus: false is the key line here — without it, tapping
  // this FloatingActionButton would itself grab keyboard focus and steal
  // it away from whatever TextField the user was just on, making it
  // impossible to ever detect "they were dictating into a field" by the
  // time onPressed runs.
  final FocusNode _fabFocusNode = FocusNode(
    canRequestFocus: false,
    skipTraversal: true,
  );

  bool _busy = false;

  @override
  void dispose() {
    _fabFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Object?>(
      valueListenable: VoiceService.activeOwner,
      builder: (context, activeOwner, child) {
        final listening = activeOwner == _owner;
        return Semantics(
          button: true,
          label: "Voice navigation",
          hint: listening
              ? "Listening. Say a command, or speak to fill in the "
                  "field you're on. Tap again to stop."
              : "Double tap, then say a command like open expenses, "
                  "open manual budgets, or profile. If a field is "
                  "selected, speaking fills it in instead.",
          child: FloatingActionButton(
            heroTag: "voice_nav_fab",
            focusNode: _fabFocusNode,
            backgroundColor:
                listening ? Colors.red : const Color(0xFF2E7D32),
            tooltip: "Voice navigation",
            onPressed: _busy ? null : () => _handleTap(listening),
            child: Icon(
              listening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleTap(bool listening) async {
    // Tapping the voice-command mic always interrupts a screen read in
    // progress first, so the two features never speak over each other.
    if (ScreenReaderService.isReading.value) {
      await ScreenReaderService.stop();
    }

    if (listening) {
      await VoiceService.stopListening();
      return;
    }

    if (!VoiceService.voiceInputEnabled.value) {
      _notify(
        "Voice input is turned off. Enable it in Voice Settings to use "
        "voice navigation.",
      );
      return;
    }

    if (!VoiceService.speechInputAvailable) {
      _notify(
        "Voice input isn't available on this device. Check microphone "
        "permissions.",
      );
      return;
    }

    // Capture the currently-focused field's controller, if any, BEFORE
    // anything else runs — this is what lets the same mic double as
    // field dictation. Because _fabFocusNode can't request focus,
    // tapping this button hasn't disturbed whatever had focus a moment
    // ago, so primaryFocus still points at the user's text field (if
    // any) rather than at this button.
    //
    // When a TextField/TextFormField has focus, its FocusNode is
    // attached to a dedicated Focus widget rendered by the framework's
    // own EditableText — so the currently-focused context's widget IS
    // that EditableText, and reading its `controller` directly is the
    // approach Flutter's own docs recommend for "update the text of the
    // currently focused field".
    final focusedWidget = FocusManager.instance.primaryFocus?.context?.widget;
    final TextEditingController? focusedController =
        focusedWidget is EditableText ? focusedWidget.controller : null;

    setState(() => _busy = true);
    HapticFeedback.mediumImpact();

    try {
      await VoiceService.speakAndWait("Listening");
      final heard = await VoiceService.listenOnceForCommand(owner: _owner);

      if (!mounted) return;

      if (heard.trim().isEmpty) {
        await VoiceService.speak(
          "I didn't hear anything. Please try again.",
        );
        return;
      }

      final result = VoiceCommandRouter.resolve(
        heard,
        user: widget.user,
        onDataChanged: widget.onDataChanged,
      );

      // If what was said isn't a recognized navigation command AND a
      // text field is currently focused, treat it as dictation into
      // that field instead of just saying "I didn't understand" — this
      // is the behavior that makes the single mic double as every
      // field's mic too.
      if (result.kind == VoiceCommandKind.unrecognized &&
          focusedController != null) {
        _fillFocusedField(focusedController, heard);
        await VoiceService.speak("Set to $heard");
        return;
      }

      switch (result.kind) {
        case VoiceCommandKind.switchTab:
          widget.onSwitchTab(result.tabIndex!);
          break;
        case VoiceCommandKind.pushScreen:
          Navigator.of(context).push(
            MaterialPageRoute(builder: result.screenBuilder!),
          );
          break;
        case VoiceCommandKind.goBack:
          Navigator.of(context).maybePop();
          break;
        case VoiceCommandKind.readScreen:
          // ScreenReaderService resolves "the current screen" itself
          // now, so this FAB's own (much narrower) context is no longer
          // passed in — see screen_reader_service.dart. The read itself
          // speaks each item as it goes, so there's no separate
          // confirmation line to say afterward — just kick it off and
          // return.
          ScreenReaderService.readScreen();
          return;
        case VoiceCommandKind.unrecognized:
          break;
      }

      await VoiceService.speak(result.spokenReply);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fillFocusedField(TextEditingController controller, String text) {
    controller.text = text;
    controller.selection = TextSelection.collapsed(offset: text.length);
  }

  void _notify(String message) {
    VoiceService.speak(message);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
