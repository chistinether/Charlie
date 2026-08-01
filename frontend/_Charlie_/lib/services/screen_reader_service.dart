import 'package:flutter/material.dart';

import 'voice_service.dart';

/// Reads the current screen aloud: every plain-text label, every button's
/// label, and every table's rows, in visual top-to-bottom (then
/// left-to-right) order, skipping everything else — icons, images,
/// emojis, dividers, plain containers, and so on.
///
/// Announcement rules:
///  * A run of consecutive plain text is only prefixed with "Text," the
///    first time — after that it's spoken on its own until something
///    else (a button or a table) interrupts the run, at which point the
///    next text item gets the "Text," prefix again.
///  * Every button always says "Button," — never de-duplicated.
///  * A table says "Table" once, then each row is read as one item —
///    its first cell (e.g. an item's name) followed by its other
///    non-empty cells labelled with that column's header (e.g.
///    "Soap. Category: Food. Quantity: 2. Unit Cost: UGX 2000.").
///
/// This walks the live Element tree rather than requiring every screen
/// to hand-author a script, so it works the same way on every screen —
/// including ones added later — without per-screen wiring.
class ScreenReaderService {
  ScreenReaderService._();

  static final ValueNotifier<bool> isReading = ValueNotifier(false);

  // Bumped on every stop/restart; a running read loop compares its own
  // captured token against this to know whether it's been superseded or
  // cancelled, so tapping the button again cleanly interrupts a read in
  // progress instead of queuing a second one on top of it.
  static int _token = 0;

  // ---------------- Navigator / route wiring ----------------

  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Tracks whichever route currently sits on top of the navigation
  /// stack. Register once via
  /// `MaterialApp(navigatorObservers: [ScreenReaderService.routeObserver])`.
  ///
  /// This is the fix for "it reads stuff from another screen": Flutter's
  /// [PageRoute.maintainState] defaults to true, so a screen you've
  /// navigated away from is very often still mounted (with real,
  /// positioned RenderObjects) underneath the one you're looking at —
  /// without this, its text/buttons would still turn up in the walk.
  static final _TopRouteObserver routeObserver = _TopRouteObserver();

  /// Call once (e.g. in `main()`) so the service knows where to find
  /// "the current screen" without every caller needing to hand it a
  /// BuildContext of its own — passing the wrong context (too broad, or
  /// scoped to just a single small widget) was the root cause of both
  /// the over-reading and under-reading bugs seen before.
  static void configure(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Reads everything on the screen the user is actually looking at. If
  /// a read is already in progress, calling this again stops it instead
  /// (acts as a toggle). [context] is only used as a fallback if the
  /// service hasn't been [configure]d yet.
  static Future<void> readScreen([BuildContext? context]) async {
    if (isReading.value) {
      await stop();
      return;
    }

    if (!VoiceService.screenReaderEnabled.value) {
      await VoiceService.speak(
        "Screen reading is turned off. Enable it in Voice Settings first.",
      );
      return;
    }

    final root = _navigatorKey?.currentContext ?? context;
    if (root == null) {
      await VoiceService.speak("Sorry, I couldn't read this screen.");
      return;
    }

    List<_ReadableItem> items;
    try {
      items = _collect(root);
    } catch (e, st) {
      // The tree walk touches widget internals via type checks; if some
      // widget shape we didn't anticipate trips it up, fail quietly
      // rather than crashing the screen the user is trying to have
      // read to them.
      debugPrint("ScreenReaderService: failed to read screen: $e\n$st");
      await VoiceService.speak(
        "Sorry, I couldn't read this screen.",
      );
      return;
    }

    if (items.isEmpty) {
      await VoiceService.speak("Nothing to read on this screen.");
      return;
    }

    final myToken = ++_token;
    isReading.value = true;
    await VoiceService.stop();

    try {
      // Tracks the kind of the last item spoken so plain text only gets
      // its "Text," prefix once per consecutive run (see class doc).
      _ItemKind? lastKind;

      for (final item in items) {
        if (_token != myToken) break; // stopped or superseded mid-read

        switch (item.kind) {
          case _ItemKind.text:
            final phrase = lastKind == _ItemKind.text
                ? item.label
                : "Text, ${item.label}";
            await VoiceService.speakAndWait(phrase);
            lastKind = _ItemKind.text;
            break;

          case _ItemKind.button:
            await VoiceService.speakAndWait("Button, ${item.label}");
            lastKind = _ItemKind.button;
            break;

          case _ItemKind.tableStart:
            await VoiceService.speakAndWait("Table");
            lastKind = _ItemKind.tableStart;
            break;

          case _ItemKind.tableRow:
            await VoiceService.speakAndWait(item.label);
            // Stays "not text" so plain text resuming after the table
            // announces "Text," again, same as coming from a button.
            lastKind = _ItemKind.tableRow;
            break;
        }
      }
    } catch (e, st) {
      debugPrint("ScreenReaderService: error while reading: $e\n$st");
    }

    if (_token == myToken) isReading.value = false;
  }

  static Future<void> stop() async {
    _token++;
    isReading.value = false;
    await VoiceService.stop();
  }

  // ---------------- Widget-tree walk ----------------

  static List<_ReadableItem> _collect(BuildContext context) {
    final items = <_ReadableItem>[];
    final activeRoute = routeObserver.current;

    void visit(Element element) {
      try {
        final widget = element.widget;

        // The read-screen button lives in its own OverlayEntry, as a
        // sibling of the current route rather than a descendant of it
        // -- but both hang off the same Navigator context this walk
        // starts from, so without this check the button would end up
        // announcing itself ("Button, Read screen") on every screen.
        if (widget is FloatingActionButton &&
            widget.heroTag == "screen_reader_fab") {
          return;
        }

        // Skip anything that belongs to a route other than the one
        // currently on top. `maintainState` (default true on PageRoute)
        // keeps a screen you've navigated away from mounted in the tree
        // -- this is what stopped it from bleeding into the read-aloud.
        // Elements that aren't inside any route yet (e.g. the Overlay
        // itself, above every route) return null here and are left
        // alone so the walk can still get down into the active route.
        final elementRoute = ModalRoute.of(element);
        if (elementRoute != null && elementRoute != activeRoute) {
          return;
        }

        // IndexedStack (used by the dashboard's tab bar) keeps every
        // tab's widget mounted and laid out at once, only painting the
        // selected one -- so only walk that one child, or every tab's
        // content would be read regardless of which tab is showing.
        if (widget is IndexedStack) {
          final index = widget.index ?? 0;
          final total = widget.children.length;
          if (index >= 0 && index < total) {
            // Match by position, not object identity -- IndexedStack's
            // real per-tab children are always in the same order as
            // widget.children, so this is guaranteed correct, unlike
            // comparing `child.widget` against a captured widget
            // instance (which silently matches nothing -- and reads
            // nothing from the whole tab -- if the two ever fall out
            // of sync).
            //
            // IndexedStack's own Element does NOT directly own one
            // child Element per tab -- it has a single child Element
            // (an internal `_RawIndexedStack` render object wrapper)
            // that in turn owns the real per-tab Elements one level
            // further down. Walking `element.visitChildren` directly
            // only ever finds that one wrapper, so a position counter
            // starting at 0 never advances past 0 -- every tab except
            // index 0 fails to match, and index 0 only "worked" by
            // coincidence (0 == 0) while actually visiting the wrapper
            // rather than the tab itself. Descend through single-child
            // wrappers until we reach the Element that actually has
            // one child per tab, then index into that.
            Element? host = element;
            var depth = 0;
            while (host != null && depth < 5) {
              final children = <Element>[];
              host.visitChildren(children.add);
              if (children.length == total) {
                visit(children[index]);
                host = null;
                break;
              } else if (children.length == 1) {
                host = children.first;
                depth++;
              } else {
                debugPrint(
                  "ScreenReaderService: IndexedStack -- could not locate "
                  "per-tab host element (got ${children.length} children "
                  "at depth $depth, expected $total)",
                );
                host = null;
              }
            }
          }
          return;
        }

        // Offstage / invisible content shouldn't be read either.
        if (widget is Offstage) {
          if (widget.offstage) return;
        } else if (widget is Visibility) {
          if (!widget.visible) return;
        }

        // Tables get special handling: announce "Table" once, then read
        // each row as its own item (see class doc).
        if (widget is DataTable) {
          _collectTable(widget, element, items);
          return;
        }

        if (widget is Text || widget is RichText) {
          final raw = widget is Text
              ? (widget.data ?? widget.textSpan?.toPlainText() ?? "")
              : (widget as RichText).text.toPlainText();
          final cleaned = _sanitize(raw);
          if (cleaned.isNotEmpty) {
            final pos = _globalPosition(element);
            if (pos != null) {
              items.add(_ReadableItem(
                kind: _ItemKind.text,
                label: cleaned,
                y: pos.dy,
                x: pos.dx,
              ));
            }
          }
          // A Text has nothing meaningful below it — stop here.
          return;
        }

        final buttonLabel = _buttonLabelIfAny(widget);
        if (buttonLabel != null) {
          final cleaned = _sanitize(buttonLabel);
          if (cleaned.isNotEmpty) {
            final pos = _globalPosition(element);
            if (pos != null) {
              items.add(_ReadableItem(
                kind: _ItemKind.button,
                label: cleaned,
                y: pos.dy,
                x: pos.dx,
              ));
            }
          }
          // Don't also read the button's internal label as a second,
          // separate "Text" item.
          return;
        }
      } catch (e) {
        // One unusual widget shouldn't stop the rest of the screen
        // from being collected — skip it and keep walking.
        debugPrint("ScreenReaderService: skipped a widget: $e");
      }

      // NOTE: this recursive call was previously OUTSIDE the try/catch
      // above. That meant an exception thrown anywhere further down in
      // the tree (in a *descendant's* recursive `visit` call) would
      // propagate all the way up through every ancestor's call to
      // `element.visitChildren(visit)` here -- none of which catch it at
      // this point -- unwinding out of `_collect()` entirely and
      // discarding every item collected so far anywhere in the walk, not
      // just the problematic subtree. Wrapping it too means a bad
      // subtree only loses its own content instead of everything.
      try {
        element.visitChildren(visit);
      } catch (e) {
        debugPrint("ScreenReaderService: skipped a subtree: $e");
      }
    }

    context.visitChildElements(visit);

    items.sort((a, b) {
      final byRow = a.y.compareTo(b.y);
      return byRow != 0 ? byRow : a.x.compareTo(b.x);
    });

    return items;
  }

  // ---------------- Table extraction ----------------

  /// Reads a [DataTable] as "Table" once, followed by one spoken item per
  /// row: its first cell's value (the row's "name"), then each other
  /// non-empty cell labelled with its column header. Works for any
  /// DataTable, not just a specific screen's — column headers and cell
  /// values are both pulled generically from the live widget data.
  static void _collectTable(
    DataTable table,
    Element tableElement,
    List<_ReadableItem> items,
  ) {
    final anchor = _globalPosition(tableElement);
    if (anchor == null) return;

    final headers =
        table.columns.map((c) => _extractLabel(c.label)?.trim()).toList();

    items.add(_ReadableItem(
      kind: _ItemKind.tableStart,
      label: "Table",
      y: anchor.dy,
      x: anchor.dx,
    ));

    // Tiny, strictly-increasing offsets keep every row (and any buttons
    // found inside it) sorted immediately after "Table" and in row
    // order, without needing each row's own RenderObject position.
    double y = anchor.dy;

    for (final row in table.rows) {
      final cellValues =
          row.cells.map((cell) => _extractLabel(cell.child)).toList();

      final rawName = cellValues.isNotEmpty ? cellValues.first?.trim() : null;
      final name = rawName == null ? "" : _sanitize(rawName);

      final parts = <String>[];
      for (var i = 1; i < cellValues.length; i++) {
        final rawValue = cellValues[i]?.trim();
        if (rawValue == null || rawValue.isEmpty) continue;
        final value = _sanitize(rawValue);
        if (value.isEmpty) continue;

        final header = i < headers.length ? headers[i] : null;
        parts.add(
          header == null || header.isEmpty ? value : "$header: $value",
        );
      }

      // Skip fully-empty rows (e.g. a freshly added, not-yet-filled-in
      // row) rather than reading out nothing useful.
      if (name.isEmpty && parts.isEmpty) continue;

      y += 0.01;

      final spokenName = name.isEmpty ? "Row" : name;
      final body = parts.join(". ");

      items.add(_ReadableItem(
        kind: _ItemKind.tableRow,
        label: body.isEmpty ? spokenName : "$spokenName. $body.",
        y: y,
        x: anchor.dx,
      ));

      // Buttons inside a row (e.g. Edit / Delete) still always announce
      // as "Button, ..." — collected here since the table subtree is
      // handled directly from widget data rather than the normal walk.
      for (final cell in row.cells) {
        final buttonLabels = <String>[];
        _collectButtonLabels(cell.child, buttonLabels);
        for (final label in buttonLabels) {
          y += 0.001;
          items.add(_ReadableItem(
            kind: _ItemKind.button,
            label: label,
            y: y,
            x: anchor.dx,
          ));
        }
      }
    }
  }

  static void _collectButtonLabels(Widget? widget, List<String> out) {
    if (widget == null) return;

    final label = _buttonLabelIfAny(widget);
    if (label != null) {
      final cleaned = _sanitize(label);
      if (cleaned.isNotEmpty) out.add(cleaned);
      return;
    }

    if (widget is Padding) return _collectButtonLabels(widget.child, out);
    if (widget is Center) return _collectButtonLabels(widget.child, out);
    if (widget is Align) return _collectButtonLabels(widget.child, out);
    if (widget is SizedBox) return _collectButtonLabels(widget.child, out);
    if (widget is Container) return _collectButtonLabels(widget.child, out);
    if (widget is DefaultTextStyle) {
      return _collectButtonLabels(widget.child, out);
    }
    if (widget is Row) {
      for (final c in widget.children) {
        _collectButtonLabels(c, out);
      }
      return;
    }
    if (widget is Column) {
      for (final c in widget.children) {
        _collectButtonLabels(c, out);
      }
      return;
    }
    if (widget is Wrap) {
      for (final c in widget.children) {
        _collectButtonLabels(c, out);
      }
      return;
    }
    if (widget is Flex) {
      for (final c in widget.children) {
        _collectButtonLabels(c, out);
      }
      return;
    }
  }

  static Offset? _globalPosition(Element element) {
    final renderObject = element.findRenderObject();
    if (renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize) {
      try {
        return renderObject.localToGlobal(Offset.zero);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // ---------------- Button label extraction ----------------

  static String? _buttonLabelIfAny(Widget widget) {
    if (widget is ButtonStyleButton) {
      // Covers ElevatedButton, TextButton, OutlinedButton.
      return _extractLabel(widget.child);
    }
    if (widget is IconButton) {
      return widget.tooltip ?? _extractLabel(widget.icon);
    }
    if (widget is FloatingActionButton) {
      return widget.tooltip ?? _extractLabel(widget.child);
    }
    if (widget is MaterialButton) {
      return _extractLabel(widget.child);
    }
    return null;
  }

  /// Looks for a spoken label/value inside a widget subtree — handles
  /// the common shapes (a bare Text, an editable TextField's current
  /// text, or Text alongside an icon inside a Row/Column, wrapped in
  /// Padding/Center/Container/etc.) without needing every screen or
  /// table to structure its content a particular way. Deliberately does
  /// NOT descend into Icon — icons (including emoji used as icons) are
  /// never read. Also used to read DataTable column headers and cell
  /// values generically.
  static String? _extractLabel(Widget? widget) {
    if (widget == null) return null;
    if (widget is Text) return widget.data ?? widget.textSpan?.toPlainText();
    if (widget is RichText) return widget.text.toPlainText();
    if (widget is TextField) return widget.controller?.text;
    if (widget is EditableText) return widget.controller.text;
    if (widget is Icon) return null;
    if (widget is Padding) return _extractLabel(widget.child);
    if (widget is Center) return _extractLabel(widget.child);
    if (widget is Align) return _extractLabel(widget.child);
    if (widget is SizedBox) return _extractLabel(widget.child);
    if (widget is Container) return _extractLabel(widget.child);
    if (widget is DefaultTextStyle) return _extractLabel(widget.child);
    if (widget is Row) return _firstLabelIn(widget.children);
    if (widget is Column) return _firstLabelIn(widget.children);
    if (widget is Wrap) return _firstLabelIn(widget.children);
    if (widget is Flex) return _firstLabelIn(widget.children);
    return null;
  }

  static String? _firstLabelIn(List<Widget> children) {
    for (final child in children) {
      final label = _extractLabel(child);
      if (label != null && label.trim().isNotEmpty) return label;
    }
    return null;
  }

  // ---------------- Text cleanup ----------------

  // Emoji / pictograph / symbol blocks — deliberately narrow (does NOT
  // include the general punctuation block) so ordinary punctuation like
  // em dashes and curly quotes in real sentences is left alone.
  static final RegExp _emojiPattern = RegExp(
    r'[\u{1F1E6}-\u{1F1FF}\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{200D}]',
    unicode: true,
  );

  static String _sanitize(String text) {
    final withoutEmoji = text.replaceAll(_emojiPattern, " ");
    return withoutEmoji.replaceAll(RegExp(r"\s+"), " ").trim();
  }
}

/// Tracks whichever route is currently on top of the Navigator's stack.
/// See [ScreenReaderService.routeObserver] for why this matters.
class _TopRouteObserver extends NavigatorObserver {
  Route<dynamic>? _current;

  Route<dynamic>? get current => _current;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _current = route;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Only meaningful if the route being popped is the one we think is
    // on top -- should always be true for a normal back navigation,
    // but guard it anyway so a stray notification can't move `current`
    // to the wrong place.
    if (_current == route) {
      _current = previousRoute;
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // didRemove also fires for routes well below the top of the stack
    // -- most notably, pushReplacement() pushes the new route (firing
    // didPush, which correctly updates `current`) and only *afterwards*
    // removes the old route it replaced. That old route's `previousRoute`
    // is whatever was below *it*, not the new top -- so blindly doing
    // `_current = previousRoute` here would stomp the just-pushed route
    // back to something stale (e.g. null, right after login ->
    // Dashboard), which is exactly what made the read-aloud walk think
    // no screen was current. Only actually update `current` if the
    // route being removed is the one we're currently tracking.
    if (_current == route) {
      _current = previousRoute;
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    // Same guard as above: only treat this as changing what's current
    // if it's actually replacing the tracked current route (or nothing
    // has been tracked yet).
    if (newRoute != null && (_current == oldRoute || _current == null)) {
      _current = newRoute;
    }
  }
}

enum _ItemKind { text, button, tableStart, tableRow }

class _ReadableItem {
  final String label;
  final _ItemKind kind;
  final double y;
  final double x;

  _ReadableItem({
    required this.label,
    required this.kind,
    required this.y,
    required this.x,
  });
}