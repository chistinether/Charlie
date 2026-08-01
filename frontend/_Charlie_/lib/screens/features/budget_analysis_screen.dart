import 'package:flutter/material.dart';

import '../../models/test_users.dart';
import '../../services/gemini_budget_trend_service.dart';

class BudgetAnalysisScreen extends StatefulWidget {
  final TestUser user;

  const BudgetAnalysisScreen({
    super.key,
    required this.user,
  });

  @override
  State<BudgetAnalysisScreen> createState() => _BudgetAnalysisScreenState();
}

class _BudgetAnalysisScreenState extends State<BudgetAnalysisScreen> {
  bool loading = true;
  String? errorMessage;
  BudgetTrendAnalysis? analysis;

  @override
  void initState() {
    super.initState();
    loadAnalysis();
  }

  Future<void> loadAnalysis() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final result = await GeminiBudgetTrendService.analyzeUser(widget.user);

      if (!mounted) return;

      setState(() {
        analysis = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            "Charlie couldn't complete the deep analysis right now. "
            "Please check your connection and try again.";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    double totalSpent = 0;

    for (var transaction in user.transactions) {
      if (!transaction.isIncome) {
        totalSpent += transaction.amount;
      }
    }

    double remaining = user.income - totalSpent;

    bool exceeded = remaining < 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text(
          "Budget Analysis",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loading ? null : loadAnalysis,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Refresh analysis",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadAnalysis,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${user.name}'s Spending Analysis",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              analysisCard(
                "Monthly Income",
                user.income,
                Icons.account_balance_wallet,
                Colors.green,
              ),
              analysisCard(
                "Amount Spent",
                totalSpent,
                Icons.money_off,
                Colors.red,
              ),
              analysisCard(
                "Remaining Balance",
                remaining,
                Icons.savings,
                exceeded ? Colors.red : Colors.blue,
              ),
              const SizedBox(height: 15),
              Text(
                exceeded ? "⚠ Budget Exceeded" : "✓ Spending is Healthy",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: exceeded ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: const [
                  Icon(Icons.smart_toy, color: Color(0xFF2E7D32)),
                  SizedBox(width: 8),
                  Text(
                    "Charlie's In-Depth Analysis",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Based on your most recent income and expense activity.",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 15),
              buildAnalysisBody(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAnalysisBody() {
    if (loading) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Padding(
          padding: EdgeInsets.all(30),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF2E7D32),
                ),
                SizedBox(height: 16),
                Text(
                  "Charlie is analysing your trends and the current "
                  "market...",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    "Analysis unavailable",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(errorMessage!),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: loadAnalysis,
                icon: const Icon(Icons.refresh),
                label: const Text("Try Again"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final result = analysis;

    if (result == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionCard(
          title: "Your Current Trend",
          icon: Icons.timeline,
          color: const Color(0xFF2E7D32),
          child: Text(result.trendSummary, style: bodyStyle),
        ),
        const SizedBox(height: 16),
        sectionCard(
          title: "Where You're Headed",
          icon: Icons.trending_up,
          color: Colors.deepPurple,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result.projection, style: bodyStyle),
              const SizedBox(height: 12),
              riskBadge(result.riskLevel),
            ],
          ),
        ),
        const SizedBox(height: 16),
        sectionCard(
          title: "What To Do Next",
          icon: Icons.checklist,
          color: Colors.blue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: result.advice.map((tip) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.arrow_right,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Expanded(child: Text(tip, style: bodyStyle)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        sectionCard(
          title: "Market Outlook",
          icon: Icons.public,
          color: Colors.orange.shade800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              marketRow(Icons.restaurant, "Food", result.marketOutlook.food),
              const SizedBox(height: 12),
              marketRow(
                Icons.directions_bus,
                "Transport",
                result.marketOutlook.transport,
              ),
              const SizedBox(height: 12),
              marketRow(
                Icons.bolt,
                "Utilities",
                result.marketOutlook.utilities,
              ),
              const SizedBox(height: 12),
              marketRow(
                Icons.menu_book,
                "Scholastic Materials",
                result.marketOutlook.scholasticMaterials,
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 6),
              Text(
                "Overall",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(result.marketOutlook.overall, style: bodyStyle),
            ],
          ),
        ),
      ],
    );
  }

  Widget marketRow(IconData icon, String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: Colors.orange.shade800),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(text, style: bodyStyle),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle get bodyStyle => const TextStyle(fontSize: 15, height: 1.5);

  Widget riskBadge(String riskLevel) {
    Color color;

    switch (riskLevel.toLowerCase()) {
      case "low":
        color = Colors.green;
        break;
      case "medium":
        color = Colors.orange;
        break;
      case "high":
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        "Risk Level: $riskLevel",
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget analysisCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(
          "UGX ${amount.toStringAsFixed(0)}",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}