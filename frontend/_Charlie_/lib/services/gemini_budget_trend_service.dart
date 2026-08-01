import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/test_users.dart';

/// A market outlook broken down by the specific categories that matter
/// most to a student's budget, each one grounded in what the student is
/// actually spending in that area — rather than one generic paragraph.
class MarketOutlook {
  final String food;
  final String transport;
  final String utilities;
  final String scholasticMaterials;
  final String overall;

  MarketOutlook({
    required this.food,
    required this.transport,
    required this.utilities,
    required this.scholasticMaterials,
    required this.overall,
  });

  factory MarketOutlook.fromJson(Map<String, dynamic>? json) {
    final map = json ?? {};

    return MarketOutlook(
      food: map["food"]?.toString() ?? "No food market insight available.",
      transport: map["transport"]?.toString() ??
          "No transport market insight available.",
      utilities: map["utilities"]?.toString() ??
          "No utilities market insight available.",
      scholasticMaterials: map["scholasticMaterials"]?.toString() ??
          "No scholastic materials market insight available.",
      overall:
          map["overall"]?.toString() ?? "No overall market summary available.",
    );
  }

  factory MarketOutlook.unavailable() {
    const unavailable = "Unavailable right now — please retry.";

    return MarketOutlook(
      food: unavailable,
      transport: unavailable,
      utilities: unavailable,
      scholasticMaterials: unavailable,
      overall: "Market insight isn't available right now. Please retry shortly.",
    );
  }
}

/// Structured result of Charlie's in-depth budget trend analysis, used by
/// the Budget Analysis screen.
class BudgetTrendAnalysis {
  final String trendSummary;
  final String projection;
  final String riskLevel;
  final List<String> advice;
  final MarketOutlook marketOutlook;
  final bool isHealthy;

  BudgetTrendAnalysis({
    required this.trendSummary,
    required this.projection,
    required this.riskLevel,
    required this.advice,
    required this.marketOutlook,
    required this.isHealthy,
  });

  factory BudgetTrendAnalysis.fallback([String reason = ""]) {
    return BudgetTrendAnalysis(
      trendSummary: reason.isEmpty
          ? "Charlie couldn't reach the analysis engine right now."
          : "Charlie couldn't complete the analysis right now ($reason).",
      projection:
          "Please check your internet connection and try again in a moment.",
      riskLevel: "Unknown",
      advice: const [
        "Keep recording every expense and income entry so Charlie has enough data to work with.",
        "Try running this analysis again once you're back online.",
      ],
      marketOutlook: MarketOutlook.unavailable(),
      isHealthy: false,
    );
  }
}

class GeminiBudgetTrendService {
  static final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

  static const String model = "gemini-3.5-flash";

  static String get apiUrl =>
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent";

  // Keyword groups used to roll the student's own transaction categories
  // up into the four buckets the market outlook reports on, so the AI is
  // given a concrete UGX figure per bucket instead of guessing.
  static const List<String> _foodKeywords = [
    "food",
    "grocer",
    "meal",
    "lunch",
    "dinner",
    "breakfast",
    "snack",
  ];

  static const List<String> _transportKeywords = [
    "transport",
    "fare",
    "fuel",
    "boda",
    "taxi",
    "uber",
    "bolt",
  ];

  static const List<String> _utilitiesKeywords = [
    "utilit",
    "electric",
    "power",
    "water",
    "rent",
    "internet",
    "airtime",
    "data",
    "wifi",
  ];

  static const List<String> _scholasticKeywords = [
    "scholastic",
    "school",
    "tuition",
    "book",
    "stationery",
    "education",
    "course",
    "handout",
    "printing",
  ];

  static double _bucketSum(
    Map<String, double> categoryTotals,
    List<String> keywords,
  ) {
    double sum = 0;

    categoryTotals.forEach((category, amount) {
      final lower = category.toLowerCase();

      if (keywords.any((keyword) => lower.contains(keyword))) {
        sum += amount;
      }
    });

    return sum;
  }

  /// Analyses [user]'s transaction history (weighted toward the most
  /// recent activity) plus their active budget, if any, and returns
  /// Charlie's read on their current trend, where it's headed, in-depth
  /// advice, and a category-by-category market outlook.
  static Future<BudgetTrendAnalysis> analyzeUser(TestUser user) async {
    if (apiKey.isEmpty) {
      throw Exception("Gemini API key missing");
    }

    final sortedTransactions = [...user.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    double totalIncome = 0;
    double totalExpense = 0;

    final Map<String, double> categoryTotals = {};

    final now = DateTime.now();
    double last30Spend = 0;
    double prev30Spend = 0;

    for (final t in sortedTransactions) {
      if (t.isIncome) {
        totalIncome += t.amount;
        continue;
      }

      totalExpense += t.amount;
      categoryTotals[t.category] =
          (categoryTotals[t.category] ?? 0) + t.amount;

      final daysAgo = now.difference(t.date).inDays;

      if (daysAgo <= 30) {
        last30Spend += t.amount;
      } else if (daysAgo <= 60) {
        prev30Spend += t.amount;
      }
    }

    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategoriesText = topCategories
        .take(5)
        .map((e) => "- ${e.key}: UGX ${e.value.toInt()}")
        .join("\n");

    final recentTransactionsText = sortedTransactions.take(15).map((t) {
      final daysAgo = now.difference(t.date).inDays;
      final when = daysAgo <= 0 ? "today" : "$daysAgo day(s) ago";
      return "- ${t.title} (${t.category}), UGX ${t.amount.toInt()}, "
          "${t.isIncome ? "Income" : "Expense"}, $when";
    }).join("\n");

    String trendDirection =
        "Not enough historical data yet to compare recent periods.";

    if (prev30Spend > 0) {
      final change = ((last30Spend - prev30Spend) / prev30Spend) * 100;

      if (change > 5) {
        trendDirection =
            "Spending is UP about ${change.toStringAsFixed(0)}% versus the "
            "previous 30 days.";
      } else if (change < -5) {
        trendDirection =
            "Spending is DOWN about ${change.abs().toStringAsFixed(0)}% "
            "versus the previous 30 days.";
      } else {
        trendDirection =
            "Spending has stayed roughly stable over the last 30 days.";
      }
    }

    String budgetContext = "The student has not created a formal budget yet.";

    if (user.budget != null) {
      final b = user.budget!;
      budgetContext = """
Active budget purpose: ${b.purpose}
Budget status: ${b.status}
Allocated: UGX ${b.totalAllocated.toInt()} of UGX ${b.totalIncome.toInt()}
Spent so far: UGX ${b.totalSpent.toInt()}
Spending pace: ${b.paceMessage}
""";
    }

    // Roll the student's own categories up into the four buckets the
    // market outlook has to speak to directly.
    final foodSpend = _bucketSum(categoryTotals, _foodKeywords);
    final transportSpend = _bucketSum(categoryTotals, _transportKeywords);
    final utilitiesSpend = _bucketSum(categoryTotals, _utilitiesKeywords);
    final scholasticSpend = _bucketSum(categoryTotals, _scholasticKeywords);

    String bucketLine(String label, double amount) {
      return amount > 0
          ? "$label: UGX ${amount.toInt()} recorded so far"
          : "$label: no recorded spending yet in this category";
    }

    final bucketBreakdown = [
      bucketLine("Food", foodSpend),
      bucketLine("Transport", transportSpend),
      bucketLine("Utilities (electricity, water, rent, airtime/data)",
          utilitiesSpend),
      bucketLine("Scholastic materials (books, stationery, tuition-related)",
          scholasticSpend),
    ].join("\n");

    final prompt = """
You are Charlie AI, an intelligent financial advisor built into a budgeting
app for Ugandan university students.

Analyse this student's CURRENT financial situation. Always weigh the most
recent transactions more heavily than older ones when judging their present
habits — you are told how many days ago each transaction happened.

Total income recorded: UGX ${totalIncome.toInt()}
Total expenses recorded: UGX ${totalExpense.toInt()}
Current balance: UGX ${user.balance.toInt()}

Recent spending trend: $trendDirection

Top spending categories:
${topCategoriesText.isEmpty ? "No expense data yet" : topCategoriesText}

The student's spending broken into the four areas the market outlook must
address:
$bucketBreakdown

Most recent transactions (most recent first):
${recentTransactionsText.isEmpty ? "No transactions recorded yet" : recentTransactionsText}

Budget context:
$budgetContext

Your tasks:
1. Describe the student's CURRENT trend of financial management honestly
   but encouragingly.
2. Project realistically where this habit is likely to lead them over the
   coming weeks/months if nothing changes (e.g. running low on funds,
   building healthy savings, drifting into financial strain, etc).
3. Give in-depth, practical advice on what the student should do next —
   at least 4 concrete, specific suggestions grounded in what you see in
   their data, not generic platitudes.
4. Produce a market outlook broken into exactly these four areas, each one
   grounded in the amount you were given above for that area (not a vague
   paragraph — be direct about the price/inflation direction AND what it
   practically means for this specific student):
   - food: current direction of food/grocery prices in Uganda, and what it
     means given the student's own food spending figure above.
   - transport: current direction of fuel/fare prices, and what it means
     given the student's own transport spending figure above.
   - utilities: current direction of electricity, water, rent, and
     airtime/data costs, and what it means given the student's own
     utilities spending figure above.
   - scholasticMaterials: current direction of the cost of books,
     stationery, and other tuition-related materials, and what it means
     given the student's own scholastic spending figure above.
   Each of the four must end with one direct, practical implication (e.g.
   "budget roughly X% more for this" or "this cost has been stable, no
   change needed"). Then write one "overall" sentence tying all four
   together. State plainly that this is general economic context based on
   broad, well-known trends, not a live market feed — do not imply it is
   real-time data.
5. Decide whether the student's overall spending pattern is currently
   healthy and sustainable (true) or not (false).

Respond ONLY with strict JSON, no markdown fences, no commentary outside
the JSON, in exactly this shape:

{
"trendSummary": "...",
"projection": "...",
"riskLevel": "Low" | "Medium" | "High",
"advice": ["...", "...", "...", "..."],
"marketOutlook": {
  "food": "...",
  "transport": "...",
  "utilities": "...",
  "scholasticMaterials": "...",
  "overall": "..."
},
"isHealthy": true | false
}

Keep each string concise but substantive (2-3 sentences each), and keep the
whole response under 420 words.
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
          "temperature": 0.4,
          "responseMimeType": "application/json",
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Gemini Error: ${response.body}");
    }

    final data = jsonDecode(response.body);

    String result = data["candidates"][0]["content"]["parts"][0]["text"];

    result = result.replaceAll("```json", "").replaceAll("```", "").trim();

    final parsed = jsonDecode(result);

    return BudgetTrendAnalysis(
      trendSummary:
          parsed["trendSummary"]?.toString() ?? "No trend summary available.",
      projection:
          parsed["projection"]?.toString() ?? "No projection available.",
      riskLevel: parsed["riskLevel"]?.toString() ?? "Unknown",
      advice: (parsed["advice"] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      marketOutlook:
          MarketOutlook.fromJson(parsed["marketOutlook"] as Map<String, dynamic>?),
      isHealthy: parsed["isHealthy"] == true,
    );
  }
}