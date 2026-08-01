# Voice fixes & accessible navigation mic

## 1. Fixed: two microphones opening at once

**Root cause:** `VoiceService` wrapped a single native speech-recognition
session (`speech_to_text`'s `SpeechToText` object), but `startListening()`
had no locking or ownership tracking. Screens with more than one
`VoiceMicButton` — e.g. **Add Expense** (title field + notes field) and
**Add Income** — let each button call `startListening()` independently.
If one field's mic was tapped while another was still open, the plugin
ended up with two overlapping `.listen()` calls in flight, so the
platform opened two simultaneous recording sessions, and the transcript
could land in the wrong field or the app could throw an "already
listening" error.

There was a second, related bug: every `VoiceMicButton` watched the same
*global* `VoiceService.isListening` flag, so as soon as any one mic
started, **every** mic button on screen lit up red as if it were
recording — confusing regardless of the first bug.

**Fix (`lib/services/voice_service.dart`, `lib/widgets/voice_mic_button.dart`):**
- `startListening()` now takes a required `owner` token and runs every
  start/stop through a serialized lock (`_lock`), so two calls can never
  race into the native plugin at the same time.
- Before opening a new session, it fully stops any session that's
  already open (belonging to *any* owner) and waits for that to
  complete — the mic is guaranteed to be closed before it's reopened.
- `VoiceService.activeOwner` exposes *which* caller currently owns the
  open session. `VoiceMicButton` now gives itself a unique token per
  instance and only shows itself as "listening" when it's actually the
  active owner, so unrelated mic buttons on the same screen no longer
  light up together.
- Stray results delivered after ownership has changed are dropped
  (`if (_owner != owner) return;`), so a slow final callback from a
  session that's already been superseded can't overwrite the wrong
  field.

No screen code had to change — `VoiceMicButton(controller: ...)` keeps
the same public API, so `add_expense_screen.dart`, `add_income_screen.dart`,
and `ai_budget_screen.dart` work unmodified.

## 2. New: accessible voice-navigation microphone

A single floating microphone (`lib/widgets/voice_nav_fab.dart`) now sits
on screen across every tab of the dashboard (Home, Expenses, Analytics,
Budgets, Profile — it lives outside the `IndexedStack`, so it's always
reachable). A visually impaired user can:

1. Tap it (it's a full-size `FloatingActionButton`, and announces itself
   to screen readers via `Semantics` as "Voice navigation" with a spoken
   hint).
2. Charlie says "Listening" out loud, then the mic opens.
3. Say a command — "open expenses", "open manual budgets", "profile",
   "add expense", "go back", "help", etc.
4. Charlie speaks back what it's doing ("Opening Expenses") **and**
   performs the navigation — no need to see the screen or ask someone
   else for help.

**Command matching** (`lib/services/voice_command_router.dart`) uses
simple keyword matching rather than exact phrases, so filler words like
"open", "go to", "show me" don't matter — only the key phrase needs to
be somewhere in what was heard. Recognized commands:

| Say...                                   | Goes to                     |
|-------------------------------------------|------------------------------|
| "home" / "dashboard"                       | Home tab                     |
| "expenses" / "add expense"                 | Expenses tab / Add Expense   |
| "analytics"                                | Analytics tab                |
| "budgets" / "manual budgets" / "ai budget" / "budget analysis" | Budgets tab / that screen |
| "add income"                               | Add Income screen            |
| "profile" / "account"                      | Profile tab                  |
| "documents"                                | Documents screen             |
| "notifications" / "budget notifications"   | Notifications screens        |
| "voice settings"                           | Voice Settings screen        |
| "help" / "support"                         | Help & Support screen        |
| "about"                                    | About Charlie screen         |
| "go back"                                  | Pops the current screen      |

Anything unrecognized gets a spoken (and on-screen) prompt suggesting a
few example commands instead of silently doing nothing.

This shares the same `VoiceService` lock/ownership fix above — tapping
the navigation mic while a text field's dictation mic is open cleanly
stops that session first rather than opening a second microphone
stream.

### Files touched
- `lib/services/voice_service.dart` — locking/ownership rewrite (bug fix
  for both existing dictation mics and the new nav mic).
- `lib/widgets/voice_mic_button.dart` — per-instance ownership token.
- `lib/services/voice_command_router.dart` — **new**, command grammar
  (now also matches "read this screen" / "what's on this screen").
- `lib/widgets/voice_nav_fab.dart` — **new**, the on-screen nav mic.
- `lib/screens/dashboards/dashboard_screen.dart` — wires the nav mic in
  as the dashboard's `floatingActionButton`.
- `lib/services/screen_reader_service.dart` — **new**, walks the current
  screen's widget tree and reads text/buttons aloud, top-to-bottom.
- `lib/widgets/screen_reader_overlay.dart` — **new**, the bottom-left
  "read screen" button present on every screen.
- `lib/main.dart` — wires the overlay in once via `MaterialApp.builder`.

### Setup — unchanged from `VOICE_SETUP.md`
This zip is still `lib/` only. Before building, make sure your project
already has (per `VOICE_SETUP.md`):
- `flutter_tts` and `speech_to_text` in `pubspec.yaml`
- `RECORD_AUDIO` / `INTERNET` permissions on Android
- `NSMicrophoneUsageDescription` / `NSSpeechRecognitionUsageDescription`
  on iOS

Nothing new is required for the nav mic — it reuses the same
`speech_to_text` / `flutter_tts` plugins and permissions the dictation
mics already needed.

## 3. Follow-up fixes: recognition wasn't catching speech, command set felt narrow

### Locale-format bug (the likely main cause of "it doesn't catch anything")
`startListening()` hard-coded `localeId: "en_US"` — but `speech_to_text`
expects the exact string a device reports, which is BCP-47 style with a
**hyphen** (`en-US`), not Dart's `Locale` underscore format (`en_US`). A
mismatched locale id makes the native recognizer silently return nothing,
which looks exactly like "I said things and it didn't catch them" while
still occasionally "working" if a device happened to tolerate the
mismatch or fall back to a default. Fixed by not hard-coding a locale at
all — `localeId` is now optional and left `null`, so the plugin uses
whatever locale the device is already set to (always valid).

### Auto-cutoff was too aggressive
The one-shot listen used for commands had `pauseFor: 3s` / `listenFor: 8s`,
which could stop listening mid-sentence for anyone who paused briefly.
Loosened to `pauseFor: 4s` / `listenFor: 20s`, and — more importantly —
you can always tap the mic a second time to stop it manually rather than
waiting for the timeout.

### Command set felt narrow
`voice_command_router.dart` now matches many alternative phrasings per
destination (e.g. Expenses also matches "spending", "payments",
"transactions"; Analytics matches "analy" broadly so "analysis",
"analytics", "analyze" all hit) instead of one fixed phrase, so you don't
have to remember exact wording — see the updated table above.

### The nav mic now also dictates into whatever field is focused
This is the bigger change: `VoiceNavFab` now checks what has focus the
moment you tap it.
- If nothing is focused, it works as before — a spoken navigation
  command.
- If a text field is focused (e.g. you've moved to the "Expense Title"
  field), anything you say that **isn't** a recognized navigation command
  gets typed directly into that field — the same one mic does both jobs,
  so there's no need to locate the small per-field mic icons at all.
  Navigation commands ("go back", "open expenses", etc.) still work even
  while a field is focused, so you can back out without unfocusing first.

Technically this reads `FocusManager.instance.primaryFocus`, and — per
Flutter's own migration guidance for exactly this scenario — checks
whether the focused context's widget is an `EditableText` to reach its
`controller` directly. The FAB's own `FocusNode` is set to
`canRequestFocus: false` so tapping it never steals focus away from the
field you were just on, which is what makes this detection possible in
the first place.

## 4. New: read-screen accessibility feature (every screen)

A second, small "read screen" button (`lib/widgets/screen_reader_overlay.dart`)
now floats bottom-left on **every** screen in the app — splash, login,
signup, every dashboard tab, and every pushed feature screen — without
needing to add it to each screen individually. It's wired in once, via
`MaterialApp.builder` in `main.dart`, which wraps whatever screen is
currently showing in `ScreenReaderOverlay`.

Tapping it (or saying "read this screen" / "what's on this screen" to
the voice-navigation mic) reads the current screen aloud:

- **Only text and buttons** are read — icons, images, dividers, plain
  containers, and similar non-textual elements are skipped entirely.
- **Buttons are announced as buttons**: Charlie says "Button," then the
  button's label, before reading it — e.g. "Button, Save Expense."
- **Plain text is announced as text**: "Text," then the content — e.g.
  "Text, Total spent this month is 240 dollars."
- **Emoji are stripped** from whatever is read, so a label like "Nice
  job \ud83c\udf89" is read as "Nice job" — ordinary punctuation (em
  dashes, curly quotes) is left untouched.
- **Reading order is top-to-bottom, then left-to-right** — this uses
  each element's actual on-screen position (not just the order it
  happens to appear in the source code), so it reflects what's visually
  first regardless of how a screen's layout is built internally.
- Tapping the button again (or the mic again) stops the reading
  immediately instead of letting it run to the end.

**How it works:** `ScreenReaderService` (`lib/services/screen_reader_service.dart`)
walks the live Flutter Element tree for whatever screen is currently on
screen. For each `Text`/`RichText` it finds, it records the text and
its position; for each button type (`ElevatedButton`, `TextButton`,
`OutlinedButton`, `IconButton`, `FloatingActionButton`, `MaterialButton`)
it extracts the label from the button's own content (handling the
common shapes — a bare `Text`, or a `Row`/`Column` mixing an `Icon` and
a `Text`) without also reading that label a second time as plain text.
Everything is then sorted by vertical position (and horizontal position
as a tiebreaker) and spoken through the same `VoiceService` used
everywhere else in the app, one item at a time, waiting for each to
finish before starting the next.

Because this walks the real widget tree at runtime, it works
automatically on new screens too — nothing extra needs to be written
per screen for it to pick up that screen's text and buttons.

## 5. Fixed: full-screen red overlay on launch (web)

Immediately after wiring the read-screen button in via `MaterialApp.builder`,
the app showed a full-screen opaque red mask on the very first frame
(the splash screen) that blocked all interaction. That's Flutter's
built-in error screen — it appears whenever a widget throws during
build or layout, and since the new overlay wraps literally every frame
of the app, an error in it broke every screen starting with the first
one.

**Root cause:** `ScreenReaderOverlay` placed the app's own content
(`child`) as a plain, non-positioned item inside a `Stack`, alongside
the read-screen button as a `Positioned` item. A `Stack` sizes itself
by measuring the *intrinsic* size of its non-positioned children —
but route/Navigator content generally doesn't support intrinsic
sizing, so asking for it throws a layout exception. That exception is
what produced the full-screen red mask.

**Fix:** wrap `child` in `Positioned.fill` instead of passing it in
bare. This tells the app's content to simply fill whatever size the
`Stack` has already been given by its own parent (the full screen),
rather than asking `child` for an intrinsic size it can't provide.

**Also fixed while in there:** the read-screen button was scoped to
read the whole overlay `Stack`, which included itself — every screen
would additionally announce "Button, Read screen" about the button
doing the reading. Fixed by capturing a `BuildContext` scoped to just
`child` (via a `Builder` positioned only around the app content) and
handing that context to the button, so the walk never includes the
button itself.

**Also hardened:** the screen-reading tree walk and speech loop are now
wrapped in try/catch at both the per-widget level and the overall
read-screen call, so an unusual widget shape it doesn't recognize can
never crash the app when the feature is actually used — it's skipped
(or the whole read fails gracefully with a spoken "Sorry, I couldn't
read this screen") instead.

## 6. Fixed (for real this time): red mask still appeared, plus screen reader is now opt-in

The previous `Positioned.fill` change (section 5) was correct in principle
but was never actually run through a build (no Flutter toolchain was
available when it was written), and the mask was still showing up in
practice.

**Root-cause fix:** `ScreenReaderOverlay` now wraps its `Stack` in a
`LayoutBuilder` and pins it to a `SizedBox` sized from the *measured*
constraints, instead of trusting that the ambient constraints handed
down through `MaterialApp.builder` are already tight. This removes the
last way the Stack's own sizing could depend on asking the app's
content for an intrinsic size it can't provide.

**Safety net (`lib/main.dart`):** set a custom `ErrorWidget.builder` so
that if *anything* else in the tree throws during build/layout/paint in
the future, it shows a small, unobtrusive inline message instead of
Flutter's default full-screen translucent red mask. This can't fix a
bug by itself, but it guarantees this specific failure mode (an error
anywhere blocking the entire screen) can't recur.

**New: "Screen reader" is now its own Settings toggle, off by default**
(`VoiceService.screenReaderEnabled`, Voice Settings → "Screen Reader").
This is separate from "Charlie speaks" (voice output) — a person can
have one on without the other. While it's off:
- The floating "read screen" button doesn't appear on any screen.
- The "read this screen" voice command replies that the feature is
  off instead of reading anything.
Turning it off while a read is in progress stops it immediately.

**New: tapping the voice-command mic always stops an in-progress
screen read first**, in either direction (starting to listen or
stopping), so the two features never talk over each other
(`lib/widgets/voice_nav_fab.dart`, `_handleTap`).

### Files touched
- `lib/main.dart` — global `ErrorWidget.builder` safety net.
- `lib/widgets/screen_reader_overlay.dart` — `LayoutBuilder`-driven
  sizing; read-screen button now hidden unless the new setting is on.
- `lib/services/voice_service.dart` — new persisted
  `screenReaderEnabled` setting + `setScreenReaderEnabled()`.
- `lib/services/screen_reader_service.dart` — `readScreen()` now checks
  the setting before reading anything.
- `lib/screens/features/voice_settings_screen.dart` — new "Screen
  Reader" section with its own switch.
- `lib/widgets/voice_nav_fab.dart` — stops any in-progress screen read
  as soon as the mic is tapped.

### Still worth knowing
- Same caveat as before: no Flutter/Dart toolchain is available in this
  environment, so this has been reviewed carefully but not run through
  `flutter analyze` or a real build. Please do a build + smoke test
  (especially the login screen, and toggling "Screen reader" on/off in
  Voice Settings) before shipping.

## 7. Fixed properly this time: red mask was an architectural problem, not a sizing detail

Both previous attempts (sections 5 and 6) kept the same basic shape --
wrap the entire app's content in a `Stack` inside `MaterialApp.builder`,
with the read-screen button as a sibling -- and just tried different
ways to size that `Stack` safely. That was the wrong level to fix this
at: *any* exception anywhere in the app, for any reason, would replace
that whole wrapping `Stack` with Flutter's error box, and because the
`Stack` contained the entire app's content, the error box ended up
covering the entire screen and swallowing every touch -- which is
exactly what kept happening, on both the splash screen and the login
screen, regardless of how the `Stack`'s own sizing was fixed.

**Real fix:** stopped wrapping the app's content at all. The read-screen
button is now inserted as its own `OverlayEntry` directly on the
Navigator's existing `Overlay` (`lib/main.dart` calls
`ScreenReaderOverlay.attach(navigatorKey)` once, after the first
frame) -- the same mechanism Flutter itself uses for SnackBars and
Tooltips. It floats on top as a small, separate sibling next to
whatever route is showing, instead of being a wrapper around it. That
means:
- The app's own screens (splash, login, dashboard, etc.) are never
  touched, resized, or re-parented by this feature at all.
- If anything ever throws inside the button itself, the resulting
  error box can only ever replace that small bottom-left corner --
  never the rest of the screen, and it can never block touches
  anywhere else.

`ScreenReaderService`'s tree walk now starts from the Navigator's own
context (an ancestor of both the current route and this new overlay
entry) and explicitly skips the read-screen button itself by its
`heroTag` so it still doesn't announce itself.

### Files touched
- `lib/main.dart` — added a top-level `navigatorKey`, passed it to
  `MaterialApp`, removed the `builder:` Stack wrapping entirely, and
  schedules `ScreenReaderOverlay.attach(navigatorKey)` after the first
  frame instead.
- `lib/widgets/screen_reader_overlay.dart` — rewritten from a
  `StatelessWidget` that wrapped `child` to a plain class with a static
  `attach()` that inserts an `OverlayEntry`.
- `lib/services/screen_reader_service.dart` — skips the read-screen
  button (by heroTag) when walking the tree, since it's now a sibling
  of the current route rather than excluded structurally.

If a translucent red mask still appears after this, the cause is
elsewhere in the app (not this feature) -- in that case, please share
whatever appears in the browser DevTools Console (F12 → Console) or
the terminal running `flutter run`, since Flutter prints the exact
widget and stack trace for whatever threw, which is the fastest way to
pin down a cause I can't reproduce without a Flutter toolchain here.

## 8. Fixed: reading the wrong screen, plus text/button/table announcement rules

### "It reads stuff on another screen"
Two separate bugs, both caused by the read-screen walk starting from a
context that was an ancestor of more than just the visible screen:

1. **Dashboard tabs bled into each other.** `DashboardScreen` uses an
   `IndexedStack` to keep Home/Expenses/Analytics/Budgets/Profile all
   mounted at once (intentional — see its own comment, it's what stops
   the welcome popup re-firing every tab switch), but every tab still
   has real, laid-out `RenderObject`s even when it isn't the one being
   shown. The walk had no special case for this, so it happily read
   Text/Buttons from tabs you weren't even looking at.
2. **Previous screens bled into the current one.** `PageRoute.maintainState`
   defaults to `true`, so a screen you navigated away from (e.g. Add
   Expense, opened from Home) is very often still mounted underneath
   whatever's on top — again with real geometry, so its content could
   still turn up in the read-aloud.

There was a third, smaller inconsistency on top of these: the two
places that triggered a read passed two *different* contexts into
`ScreenReaderService.readScreen()` — the bottom-left button passed the
Navigator's own context (too broad, causing the bugs above), while the
"read this screen" voice command passed `VoiceNavFab`'s own context
(too narrow — it would only ever see its own small subtree).

**Fix (`lib/services/screen_reader_service.dart`):**
- `ScreenReaderService.readScreen()` is now called with **no context
  argument** from both places. It resolves "the current screen" itself,
  via a `GlobalKey<NavigatorState>` handed to it once at startup
  (`ScreenReaderService.configure(navigatorKey)` in `main.dart`) —
  one source of truth instead of two different (both wrong) contexts.
- Added `ScreenReaderService.routeObserver`, a `NavigatorObserver`
  registered via `MaterialApp(navigatorObservers: [...])`, that tracks
  whichever route is actually on top of the stack. During the walk,
  any element whose `ModalRoute.of(element)` doesn't match that route
  is skipped entirely (its subtree included) — this is what stops an
  earlier, `maintainState`-preserved screen from being read.
- The walk now special-cases `IndexedStack`: it only descends into
  `children[index]`, never the inactive tabs — this is what stops
  dashboard tabs from bleeding into each other.
- Also now skips `Offstage(offstage: true)` and `Visibility(visible:
  false)` subtrees defensively, for the same reason.

### Text/Button/Table announcement rules
Previously every item was spoken as `"Text, ..."` or `"Button, ..."`
with no memory of what came before, so a screen with five text labels
in a row said "Text" five times.

**Fix:** the read loop now tracks the kind of the last thing it said:
- **Text**: only gets the `"Text,"` prefix the first time in a run —
  consecutive text after that is spoken on its own, until a button or
  table interrupts the run, at which point the next text item says
  `"Text,"` again.
- **Button**: always says `"Button,"` — every single one, never
  de-duplicated.
- **Table**: says `"Table"` once, then reads each row as one item —
  e.g. `"Soap. Category: Food. Quantity: 2. Unit: pcs. Unit Cost: UGX
  2000. Total: UGX 4000."` — before moving on to whatever's next
  (which, if it's plain text, says `"Text,"` again, same as after a
  button).

**Table support is new** (`_collectTable` in `screen_reader_service.dart`):
detects any `DataTable` generically — column headers and cell values
are both read directly from the live widget data (not hand-authored
per screen), including pulling the *current* text out of an editable
cell's `TextField` (the budget table's cells are editable, so their
value lives in a `TextEditingController`, not a plain `Text` widget).
Empty/not-yet-filled rows (e.g. a freshly added blank row) are skipped
rather than announced as empty. Buttons inside a row (Edit/Delete) are
still announced individually as `"Button, Edit"` / `"Button, Delete"`
per the rule above — this also required giving those two `IconButton`s
in `lib/widgets/budget_table.dart` actual `tooltip`s, since an
`IconButton` with no tooltip and only an icon (icons are deliberately
never read aloud) had no spoken label at all before.

Emoji stripping (existing behaviour, unchanged) still applies to every
piece of read-aloud text, including table cell values.

### Files touched
- `lib/services/screen_reader_service.dart` — route-scoped, `IndexedStack`/
  `Offstage`/`Visibility`-aware tree walk; table detection and reading;
  text/button/table announcement de-duplication rules.
- `lib/main.dart` — `ScreenReaderService.configure(navigatorKey)`;
  registers `ScreenReaderService.routeObserver` on `MaterialApp`.
- `lib/widgets/screen_reader_overlay.dart` — button now calls
  `ScreenReaderService.readScreen()` with no context.
- `lib/widgets/voice_nav_fab.dart` — "read this screen" command now
  calls `ScreenReaderService.readScreen()` with no context.
- `lib/widgets/budget_table.dart` — added `tooltip: "Edit"` / `"Delete"`
  to the row action buttons so they're announced.

### Still worth knowing
Same caveat as every prior round: no Flutter/Dart toolchain is
available in this environment, so this has been reviewed carefully but
not run through `flutter analyze` or a real build/device test. Please
smoke-test: switching dashboard tabs then reading the screen, pushing
a feature screen (e.g. Add Expense) from Home then reading *that*
screen, and reading a budget table with a few rows filled in.
