import '../models/test_users.dart';
import '../models/budget_model.dart';

class BudgetChecker {
  static List<String> checkBudgets(TestUser user) {
    List<String> warnings = [];

    for (var budget in user.budgets) {
      if (budget.isExpired) {
        warnings.add(
          "${budget.category} budget has expired. Create a new budget.",
        );
      } else {
        final daysLeft = budget.expiryDate.difference(DateTime.now()).inDays;

        if (daysLeft <= 5) {
          warnings.add(
            "${budget.category} budget expires in $daysLeft days.",
          );
        }

        // NEW: pace / burn-rate warning
        if (budget.isPacedToRunOutEarly) {
          warnings.add(budget.paceMessage);
        }
      }
    }

    return warnings;
  }

  /// Call this specifically after adding a new expense, for ONE budget,
  /// to show an immediate popup rather than waiting for the next full check.
  static String? checkSingleBudgetPace(BudgetModel budget) {
    if (budget.isPacedToRunOutEarly) {
      return budget.paceMessage;
    }
    return null;
  }
}