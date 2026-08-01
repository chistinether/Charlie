import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/user_budget.dart';
import '../models/test_users.dart';

class GeminiInsightService {
  static final String apiKey =
      dotenv.env['GEMINI_API_KEY'] ?? "";

  static const String model = "gemini-3.5-flash";

  static String get apiUrl =>
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent";

  /// Generates the short "Charlie AI Analysis" text shown in the home
  /// screen popup. Works whether or not the user has created a formal
  /// budget yet, and — when their spending is genuinely healthy and
  /// sustainable — dynamically suggests a proportional, non-repetitive
  /// way to enjoy some of that healthy margin (not limited to a fixed
  /// list of ideas). When it isn't healthy, it focuses on tightening
  /// advice instead.
  static Future<String> generateHomeInsight(TestUser user) async {
    if (apiKey.isEmpty) {
      throw Exception("Gemini API key missing");
    }

    final recentTransactions = [...user.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    final transactionsText = recentTransactions.take(10).map((t) {
      return "- ${t.title} (${t.category}): UGX ${t.amount.toInt()} "
          "${t.isIncome ? "(Income)" : "(Expense)"}";
    }).join("\n");

    String budgetSection = "The student has not created a formal budget yet.";

    if (user.budget != null) {
      final budget = user.budget!;

      final items = budget.items.map((item) {
        return "- ${item.name}: Allocated UGX ${item.allocatedAmount.toInt()}, "
            "Spent UGX ${item.spentAmount.toInt()}";
      }).join("\n");

      budgetSection = """
Budget purpose: ${budget.purpose}
Budget status: ${budget.status}
Total Allocated: UGX ${budget.totalAllocated.toInt()}
Total Spent: UGX ${budget.totalSpent.toInt()}
Remaining: UGX ${budget.remainingIncome.toInt()}
Spending pace: ${budget.paceMessage}

Budget Categories
$items
""";
    }

    final prompt = """
You are Charlie AI, an intelligent financial advisor designed for
university students in Uganda. You are writing the short message that
appears in a popup the moment the student opens the app.

Student income: UGX ${user.income.toInt()}
Student expenses so far: UGX ${user.expenses.toInt()}
Current balance: UGX ${user.balance.toInt()}

$budgetSection

Recent transactions (most recent first):
${transactionsText.isEmpty ? "No transactions recorded yet" : transactionsText}

First, judge honestly whether the student's spending is currently healthy
and sustainable (comfortably within income, no exceeded categories, not
running out of funds early).

- If it IS healthy and sustainable: congratulate them briefly, then
  suggest ONE proportional, specific way they could enjoy a bit of that
  healthy margin right now. Vary what you suggest each time instead of
  always repeating the same idea — pick whatever fits their data best
  from things like a small treat, restocking groceries, a new accessory
  or item they've needed, saving a bit extra, or something similarly
  low-risk. Keep the suggestion proportional to how much healthy margin
  they actually have.
- If it is NOT healthy and sustainable: skip discretionary spending
  suggestions entirely and instead give a short, specific, encouraging
  tip to help them tighten up.

Respond in this exact format.

Financial Summary:
...

Risk Level:
Low / Medium / High

Overspending:
...

Suggestions:
• ...
• ...
• ...

Motivation:
...

Keep your answer under 180 words.
Do not use Markdown.
""";

    final response = await http.post(
      Uri.parse("$apiUrl?key=$apiKey"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Gemini Error: ${response.body}");
    }

    final body = jsonDecode(response.body);

    return body["candidates"][0]["content"]["parts"][0]["text"];
  }

  static Future<String> generateInsight(
      UserBudget budget) async {

    if (apiKey.isEmpty) {
      throw Exception("Gemini API key missing");
    }

    String items = budget.items.map((item) {
      return
          "- ${item.name}: "
          "Allocated UGX ${item.allocatedAmount.toInt()}, "
          "Spent UGX ${item.spentAmount.toInt()}";
    }).join("\n");

    final prompt = """
    You are Charlie AI.

    You are an intelligent financial advisor designed for university students.

    Analyse the student's financial situation.

    Purpose:
    ${budget.purpose}

    Total Income:
    UGX ${budget.totalIncome.toInt()}

    Total Allocated:
    UGX ${budget.totalAllocated.toInt()}

    Total Spent:
    UGX ${budget.totalSpent.toInt()}

    Remaining:
    UGX ${budget.remainingIncome.toInt()}

    Budget Categories

    $items

    Respond in this exact format.

    Financial Summary:
    ...

    Risk Level:
    Low / Medium / High

    Overspending:
    ...

    Suggestions:
    • ...
    • ...
    • ...

    Motivation:
    ...

    Keep your answer under 180 words.
    Do not use Markdown.
    """;
    final response = await http.post(
      Uri.parse("$apiUrl?key=$apiKey"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": prompt,
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Gemini Error");
    }

    final body = jsonDecode(response.body);

    return body["candidates"][0]["content"]["parts"][0]["text"];
  }
}