import 'package:flutter/material.dart';

import '../models/test_users.dart';

import '../screens/features/about_charlie_screen.dart';
import '../screens/features/add_expense_screen.dart';
import '../screens/features/add_income_screen.dart';
import '../screens/features/ai_budget_screen.dart';
import '../screens/features/budget_analysis_screen.dart';
import '../screens/features/budget_notification_screen.dart';
import '../screens/features/documents_screen.dart';
import '../screens/features/help_and_support_screen.dart';
import '../screens/features/manual_budget_screen.dart';
import '../screens/features/notifications_screen.dart';
import '../screens/features/voice_settings_screen.dart';

/// What a spoken command should do: switch the bottom-nav tab, push a
/// feature screen, pop back, read the current screen aloud, or none of
/// the above.
enum VoiceCommandKind { switchTab, pushScreen, goBack, readScreen, unrecognized }

class VoiceCommandResult {
  final VoiceCommandKind kind;

  /// Set when [kind] is [VoiceCommandKind.switchTab].
  final int? tabIndex;

  /// Set when [kind] is [VoiceCommandKind.pushScreen].
  final WidgetBuilder? screenBuilder;

  /// What Charlie should say back to confirm the action (or explain that
  /// the command wasn't understood). Spoken by the caller via
  /// VoiceService.speak so the person gets audible confirmation without
  /// having to look at the screen.
  final String spokenReply;

  const VoiceCommandResult._({
    required this.kind,
    required this.spokenReply,
    this.tabIndex,
    this.screenBuilder,
  });

  factory VoiceCommandResult.tab(int index, String label) =>
      VoiceCommandResult._(
        kind: VoiceCommandKind.switchTab,
        tabIndex: index,
        spokenReply: "Opening $label",
      );

  factory VoiceCommandResult.push(WidgetBuilder builder, String label) =>
      VoiceCommandResult._(
        kind: VoiceCommandKind.pushScreen,
        screenBuilder: builder,
        spokenReply: "Opening $label",
      );

  factory VoiceCommandResult.back() => const VoiceCommandResult._(
        kind: VoiceCommandKind.goBack,
        spokenReply: "Going back",
      );

  factory VoiceCommandResult.readScreen() => const VoiceCommandResult._(
        kind: VoiceCommandKind.readScreen,
        spokenReply: "",
      );

  factory VoiceCommandResult.unrecognized(String heard) =>
      VoiceCommandResult._(
        kind: VoiceCommandKind.unrecognized,
        spokenReply: heard.trim().isEmpty
            ? "Sorry, I didn't catch that. You can say things like, "
                "open expenses, open manual budgets, or profile."
            : "Sorry, I didn't understand \"$heard\". You can say things "
                "like, open expenses, open manual budgets, or profile.",
      );
}

/// Bottom-nav tab indices, mirrored from [DashboardScreen]'s `loadPages()`
/// order (Home, Expenses, Analytics, Budgets, Profile).
class DashboardTabs {
  static const home = 0;
  static const expenses = 1;
  static const analytics = 2;
  static const budgets = 3;
  static const profile = 4;
}

/// Matches free-form recognized speech against the set of voice commands
/// Charlie understands, and returns what to do about it.
///
/// Matching is deliberately simple keyword/contains matching rather than
/// requiring an exact phrase — a visually impaired user shouldn't have to
/// memorize precise wording. Filler words like "open", "go to", "show me"
/// are effectively ignored since we just look for the key phrase anywhere
/// in the sentence. More specific phrases (e.g. "manual budget") are
/// checked before their more general counterpart ("budget") so "open
/// manual budgets" doesn't get matched as just the Budgets tab.
class VoiceCommandRouter {
  VoiceCommandRouter._();

  static VoiceCommandResult resolve(
    String heard, {
    required TestUser user,
    required VoidCallback onDataChanged,
  }) {
    final text = " ${heard.toLowerCase().trim()} ";
    if (text.trim().isEmpty) return VoiceCommandResult.unrecognized(heard);

    // True if ANY of [phrases] appears anywhere in what was heard. Every
    // phrase list below is deliberately generous — filler words like
    // "open", "go to", "show me", "take me to", "I want to" are never
    // required, and each destination has several ways to say it, so the
    // user doesn't have to remember one exact wording.
    bool hasAny(List<String> phrases) => phrases.any(text.contains);

    // ---- Explicit navigation control ----
    if (hasAny(["go back", "previous screen", "back button", " back "])) {
      return VoiceCommandResult.back();
    }
    if (hasAny([
      "read this screen",
      "read the screen",
      "read screen",
      "what's on this screen",
      "what is on this screen",
      "what's on the screen",
      "read this page",
      "read out",
    ])) {
      return VoiceCommandResult.readScreen();
    }

    // ---- Specific feature screens (checked before their broader tab,
    // so e.g. "manual budgets" doesn't just fall through to the plain
    // Budgets tab) ----
    if (hasAny(["manual budget", "manual budgeting", "create my own budget"])) {
      return VoiceCommandResult.push(
        (_) => ManualBudgetScreen(user: user),
        "Manual Budgets",
      );
    }
    if (hasAny(["ai budget", "a i budget", "smart budget", "automatic budget", "generate a budget"])) {
      return VoiceCommandResult.push(
        (_) => AIBudgetScreen(user: user),
        "AI Budget",
      );
    }
    if (hasAny(["budget analysis", "analyze my budget", "budget trend", "budget breakdown"])) {
      return VoiceCommandResult.push(
        (_) => BudgetAnalysisScreen(user: user),
        "Budget Analysis",
      );
    }
    if (hasAny(["add expense", "new expense", "log expense", "record expense", "enter an expense"])) {
      return VoiceCommandResult.push(
        (_) => AddExpenseScreen(user: user, onUpdated: onDataChanged),
        "Add Expense",
      );
    }
    if (hasAny(["add income", "new income", "log income", "record income", "enter income"])) {
      return VoiceCommandResult.push(
        (_) => AddIncomeScreen(user: user, onUpdated: onDataChanged),
        "Add Income",
      );
    }
    if (hasAny(["document", "my files", "receipts"])) {
      return VoiceCommandResult.push(
        (_) => DocumentsScreen(userEmail: user.email),
        "Documents",
      );
    }
    if (hasAny(["budget notification", "budget alert", "budget reminder"])) {
      return VoiceCommandResult.push(
        (_) => BudgetNotificationsScreen(user: user),
        "Budget Notifications",
      );
    }
    if (hasAny(["notification", "alert"])) {
      return VoiceCommandResult.push(
        (_) => const NotificationsScreen(),
        "Notifications",
      );
    }
    if (hasAny(["voice setting", "change my voice", "speech setting", "speaking rate"])) {
      return VoiceCommandResult.push(
        (_) => const VoiceSettingsScreen(),
        "Voice Settings",
      );
    }
    if (hasAny(["help", "support", "i'm stuck", "how do i", "assist me"])) {
      return VoiceCommandResult.push(
        (_) => const HelpSupportScreen(),
        "Help and Support",
      );
    }
    if (hasAny(["about", "who made this", "what is charlie", "what is this app"])) {
      return VoiceCommandResult.push(
        (_) => const AboutCharlieScreen(),
        "About Charlie",
      );
    }

    // ---- Bottom-nav tabs (broad matches, checked last) ----
    if (hasAny(["profile", "account", "my details", "my info", "settings"])) {
      return VoiceCommandResult.tab(DashboardTabs.profile, "Profile");
    }
    if (hasAny(["expense", "spending", "spendings", "payments", "transaction", "purchases"])) {
      return VoiceCommandResult.tab(DashboardTabs.expenses, "Expenses");
    }
    if (hasAny(["analy", "insight", "chart", "report", "summary", "overview of my spending"])) {
      // "analy" deliberately broad — matches analytics, analysis,
      // analyze, analyzer, etc.
      return VoiceCommandResult.tab(DashboardTabs.analytics, "Analytics");
    }
    if (hasAny(["budget", "budgeting", "money plan"])) {
      return VoiceCommandResult.tab(DashboardTabs.budgets, "Budgets");
    }
    if (hasAny(["home", "dashboard", "main screen", "main menu", "start screen"])) {
      return VoiceCommandResult.tab(DashboardTabs.home, "Home");
    }

    return VoiceCommandResult.unrecognized(heard);
  }
}
