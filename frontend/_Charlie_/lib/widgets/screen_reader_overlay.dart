import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/screen_reader_service.dart';
import '../services/voice_service.dart';

/// A single floating "read this screen" button that sits on top of
/// whatever screen is currently showing -- splash, login, every
/// dashboard tab, every pushed feature screen -- without needing to be
/// added to each screen individually.
///
/// Unlike the previous implementation, this does NOT wrap the app's own
/// content in a Stack. Instead it inserts itself as a separate
/// [OverlayEntry] directly on the app's [Navigator]/[Overlay] -- the
/// same mechanism Flutter itself uses for SnackBars and Tooltips. That
/// matters: an OverlayEntry is a small, self-contained sibling floating
/// on top of the current route, not a wrapper around it, so if
/// something in it ever throws, the resulting error box can only ever
/// replace this small corner of the screen. It can never again take
/// over or block the rest of the app the way a Stack wrapped around
/// `child` inside `MaterialApp.builder` previously could.
class ScreenReaderOverlay {
  ScreenReaderOverlay._();

  static bool _attached = false;

  /// Call once, after the first frame, with the app's `navigatorKey`
  /// (see main.dart). Safe to call more than once -- only the first
  /// call actually inserts anything.
  static void attach(GlobalKey<NavigatorState> navigatorKey) {
    if (_attached) return;

    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) {
      // Navigator/Overlay not mounted yet -- try again next frame
      // rather than failing silently.
      WidgetsBinding.instance.addPostFrameCallback((_) => attach(navigatorKey));
      return;
    }

    _attached = true;
    overlayState.insert(
      OverlayEntry(
        // opaque: false (the default) is important here -- this entry
        // must never intercept touches outside its own small button,
        // so the rest of the screen underneath stays fully usable.
        builder: (context) => Positioned(
          left: 16,
          bottom: 16,
          child: SafeArea(
            child: ValueListenableBuilder<bool>(
              valueListenable: VoiceService.screenReaderEnabled,
              builder: (context, enabled, _) {
                // Only present when switched on in Settings -- see
                // VoiceSettingsScreen's "Screen reader" toggle.
                if (!enabled) return const SizedBox.shrink();
                return const _ReadScreenButton();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadScreenButton extends StatefulWidget {
  const _ReadScreenButton();

  @override
  State<_ReadScreenButton> createState() => _ReadScreenButtonState();
}

class _ReadScreenButtonState extends State<_ReadScreenButton> {
  // canRequestFocus: false so this never steals focus away from a text
  // field the user is on, same reasoning as VoiceNavFab.
  final FocusNode _focusNode = FocusNode(
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ScreenReaderService.isReading,
      builder: (context, reading, child) {
        return Semantics(
          button: true,
          label: "Read screen",
          hint: reading
              ? "Reading this screen aloud. Double tap to stop."
              : "Double tap to have this screen read aloud, text and "
                  "buttons only, top to bottom.",
          child: FloatingActionButton.small(
            heroTag: "screen_reader_fab",
            focusNode: _focusNode,
            tooltip: "Read screen",
            backgroundColor: reading ? Colors.red : const Color(0xFF2E7D32),
            onPressed: () {
              // ScreenReaderService resolves "the current screen" itself
              // (via the navigatorKey it was configured with in
              // main.dart) and scopes the walk to the route actually on
              // top, so there's no context to pick here — see
              // screen_reader_service.dart.
              HapticFeedback.selectionClick();
              ScreenReaderService.readScreen();
            },
            child: Icon(
              reading ? Icons.stop : Icons.record_voice_over,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
