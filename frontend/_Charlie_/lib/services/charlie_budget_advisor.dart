import '../models/user_budget.dart';
import '../models/budget_item.dart';

class CharlieBudgetAdvisor {
  static List<String> generateAdvice(UserBudget budget) {
    final List<String> advice = [];

    final double income = budget.totalIncome;
    final double allocated = budget.totalAllocated;

    if (income <= 0) {
      return [
        "Charlie needs your income before it can analyse your budget."
      ];
    }

    // ==========================
    // Overall Budget Health
    // ==========================

    if (allocated > income) {
      advice.add(
        "Your budget exceeds your income by UGX ${(allocated - income).toInt()}. Consider reducing some expenses before saving.",
      );
    } else {
      final remaining = income - allocated;

      if (remaining > income * 0.30) {
        advice.add(
          "You still have UGX ${remaining.toInt()} unallocated. Consider assigning part of it to savings, investments or an emergency fund.",
        );
      }
    }

    // ==========================
    // Category Totals
    // ==========================

    double food = 0;
    double transport = 0;
    double education = 0;
    double entertainment = 0;
    double savings = 0;
    double emergency = 0;

    int subscriptions = 0;

    for (final BudgetItem item in budget.items) {
      final category = item.category.toLowerCase();
      final name = item.name.toLowerCase();

      if (category.contains("food")) {
        food += item.allocatedAmount;
      }

      if (category.contains("transport")) {
        transport += item.allocatedAmount;
      }

      if (category.contains("education") ||
          category.contains("tuition") ||
          category.contains("school")) {
        education += item.allocatedAmount;
      }

      if (category.contains("entertainment")) {
        entertainment += item.allocatedAmount;
      }

      if (category.contains("saving")) {
        savings += item.allocatedAmount;
      }

      if (category.contains("emergency")) {
        emergency += item.allocatedAmount;
      }

      if (name.contains("netflix") ||
          name.contains("spotify") ||
          name.contains("dstv") ||
          name.contains("showmax") ||
          name.contains("youtube premium")) {
        subscriptions++;
      }
    }

    // ==========================
    // Food
    // ==========================

    if (food > income * 0.30) {
      advice.add(
        "Food takes more than 30% of your income. Charlie suggests reviewing grocery and dining expenses.",
      );
    }

    if (food > 0 && food < income * 0.05) {
      advice.add(
        "Your food allocation looks quite low. Make sure it is enough for the entire budgeting period.",
      );
    }

    // ==========================
    // Transport
    // ==========================

    if (transport > income * 0.20) {
      advice.add(
        "Transport costs are consuming over 20% of your income. Consider cheaper commuting options if possible.",
      );
    }

    // ==========================
    // Entertainment
    // ==========================

    if (entertainment > education && education > 0) {
      advice.add(
        "Entertainment spending is higher than education spending. Charlie recommends reviewing your priorities.",
      );
    }

    // ==========================
    // Savings
    // ==========================

    if (savings == 0) {
      advice.add(
        "You haven't allocated anything to savings. Even a small monthly saving builds long-term financial security.",
      );
    }

    // ==========================
    // Emergency Fund
    // ==========================

    if (emergency == 0) {
      advice.add(
        "Consider creating an Emergency Fund category to prepare for unexpected expenses.",
      );
    }

    // ==========================
    // Streaming Services
    // ==========================

    if (subscriptions >= 3) {
      advice.add(
        "Charlie noticed multiple subscription services. Review whether you actively use all of them.",
      );
    }

    // ==========================
    // Tiny Categories
    // ==========================

    for (final BudgetItem item in budget.items) {
      if (item.allocatedAmount > 0 &&
          item.allocatedAmount < income * 0.01) {
        advice.add(
          "\"${item.name}\" has a very small allocation. Verify that this amount is realistic.",
        );
      }
    }

    // ==========================
    // Positive Feedback
    // ==========================

    if (advice.isEmpty) {
      advice.add(
        "Excellent work! Your budget is balanced, includes the important categories and fits within your income.",
      );

      advice.add(
        "Charlie recommends tracking your actual spending regularly so your budget remains accurate throughout the month.",
      );
    }

    return advice;
  }
}