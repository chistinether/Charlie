import 'package:flutter/material.dart';

import '../models/test_users.dart';
import '../models/user_budget.dart';
import '../services/gemini_insight_service.dart';

class BudgetSummaryDialog extends StatefulWidget {
  final TestUser user;

  const BudgetSummaryDialog({
    super.key,
    required this.user,
  });

  @override
  State<BudgetSummaryDialog> createState() =>
      _BudgetSummaryDialogState();
}

class _BudgetSummaryDialogState
    extends State<BudgetSummaryDialog> {
  String? aiInsight;

  bool loadingInsight = true;

  @override
  void initState() {
    super.initState();
    loadAIInsight();
  }

  Future<void> loadAIInsight() async {
    try {
      aiInsight =
          await GeminiInsightService.generateHomeInsight(
        widget.user,
      );
    } catch (e) {
      aiInsight =
          "Charlie AI couldn't generate advice right now.\n\n"
          "Please check your internet connection and try again later.";
    }

    if (!mounted) return;

    setState(() {
      loadingInsight = false;
    });
  }

  // Varied, proportional things Charlie can suggest when spending is
  // genuinely healthy — not limited to this list, since the AI section
  // below generates its own fresh idea every time too. This pool just
  // keeps the instant, non-AI banner from repeating the same line.
  static const List<String> _modestTreatIdeas = [
    "Great job! Your finances are healthy. It's a fair time to restock your groceries or grab a small treat.",
    "Your spending looks solid. You've got a little room to pick up something small you've been needing.",
    "Nice work staying on budget! Consider topping up your groceries or treating yourself to something small.",
    "You're managing money well. A small, reasonable treat won't hurt your balance right now.",
  ];

  static const List<String> _comfortableTreatIdeas = [
    "Excellent! Your finances are healthy with good room to spare — maybe grab that accessory or item you've had your eye on.",
    "Great job! You're comfortably within budget, so a bit of fun spending — new stuff, accessories, or groceries — is fair game.",
    "Your budget is in great shape. Enjoy some of that healthy margin on something fun, and maybe tuck a bit extra into savings too.",
    "Well managed! With this much breathing room, treat yourself to something you've been wanting, or top up your savings a little.",
  ];

  // Deterministic per-day pick so the banner doesn't change every time the
  // dialog rebuilds, but still varies from day to day.
  String _pickDaily(List<String> options) {
    final seed = DateTime.now().day + widget.user.email.hashCode;
    return options[seed.abs() % options.length];
  }

  String generateSuggestion() {
    final user = widget.user;

    if (user.budget != null) {
      UserBudget budget = user.budget!;

      if (budget.overBudget) {
        return "You have exceeded your budget. Reduce unnecessary expenses and review your spending.";
      }

      if (budget.hasExceededItems) {
        return "Some categories have exceeded their limits. Consider adjusting your allocations.";
      }

      if (budget.hasWarnings) {
        return "You are close to your spending limits. Spend carefully for the remaining period.";
      }

      if (budget.isPacedToRunOutEarly) {
        return "You're spending faster than planned. Slow down a little to stay on track.";
      }
    }

    if (user.income <= 0) {
      return "Add your income so Charlie can judge how healthy your spending is.";
    }

    final spendRatio = user.expenses / user.income;

    if (spendRatio > 0.7) {
      return "Your expenses are high compared to income. Try saving more this month.";
    }

    // Genuinely healthy from here — vary the reward suggestion based on
    // how much margin the student actually has.
    final remainingRatio = 1 - spendRatio;

    if (remainingRatio >= 0.4) {
      return _pickDaily(_comfortableTreatIdeas);
    }

    return _pickDaily(_modestTreatIdeas);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
      title: Row(
        children: const [
          Icon(
            Icons.smart_toy,
            color: Color(0xFF2E7D32),
          ),
          SizedBox(width: 10),
          Text("Charlie Summary"),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Welcome back ${widget.user.name} 👋",
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 17,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              "Balance: UGX ${widget.user.balance.toStringAsFixed(0)}",
            ),

            Text(
              "Income: UGX ${widget.user.income.toStringAsFixed(0)}",
            ),

            Text(
              "Expenses: UGX ${widget.user.expenses.toStringAsFixed(0)}",
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green
                    .withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(
                        12),
              ),
              child: Text(
                generateSuggestion(),
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "🤖 Charlie AI Analysis",
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            loadingInsight
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets
                            .all(15),
                    decoration:
                        BoxDecoration(
                      color: Colors.blue
                          .shade50,
                      borderRadius:
                          BorderRadius
                              .circular(
                                  12),
                    ),
                    child: Text(
                      aiInsight ??
                          "No advice available.",
                      style:
                          const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child:
              const Text("Continue"),
        ),
      ],
    );
  }
}