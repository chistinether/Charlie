import '../models/user_budget.dart';
import '../models/budget_item.dart';


class BudgetAnalyzerService {


  static String analyze(UserBudget budget) {


    final double spent = budget.totalSpent;

    final double remaining =
        budget.totalIncome - spent;



    final double safeRemaining =
        remaining < 0 ? 0 : remaining;



    // ===============================
    // 1. Critical overspending
    // ===============================

    if(spent > budget.totalIncome){


      final double exceeded =
          spent - budget.totalIncome;



      return
      "🚨 FINAL WARNING: You have exceeded your total income by "
          "UGX ${exceeded.toInt()}. "
          "Your spending is higher than your available money. "
          "Reduce unnecessary expenses immediately.";


    }







    // ===============================
    // 2. Budget allocation problem
    // ===============================

    if(budget.overBudget){


      return
      "⚠️ Your planned allocations are higher than your income. "
          "Reduce some categories before continuing.";


    }







    // ===============================
    // 3. Spending pace prediction
    // ===============================

    if(budget.isPacedToRunOutEarly){


      return
      "⚠️ Spending pace warning: At your current rate, "
          "your money may finish "
          "${budget.daysShort} day"
          "${budget.daysShort == 1 ? '' : 's'} early. "
          "Try limiting daily spending to about "
          "UGX ${budget.recommendedDailySpend.toStringAsFixed(0)} "
          "for the remaining period.";


    }







    // ===============================
    // 4. Category overspending
    // ===============================

    for(BudgetItem item in budget.items){


      if(item.isExceeded){


        final double difference =
            item.spentAmount -
                item.allocatedAmount;



        return
        "🚨 ${item.name} has exceeded its budget by "
            "UGX ${difference.toInt()}. "
            "Consider reducing spending in this category.";


      }


    }








    // ===============================
    // 5. Category near limit
    // ===============================

    for(BudgetItem item in budget.items){


      if(item.isNearLimit){


        return
        "⚠️ ${item.name} is almost finished. "
            "You have used "
            "${item.percentageUsed.toInt()}% of this category. "
            "Spend carefully.";


      }


    }








    // ===============================
    // 6. Low remaining money
    // ===============================


    final double remainingPercentage =
        budget.totalIncome > 0
            ? safeRemaining / budget.totalIncome
            : 0;



    if(remainingPercentage <= 0.10){


      return
      "Your remaining balance is low. "
          "Only UGX ${safeRemaining.toInt()} is available. "
          "Charlie recommends avoiding unnecessary purchases "
          "until your next income period.";


    }








    // ===============================
    // 7. Highest spending category
    // ===============================


    if(budget.items.isNotEmpty){


      final BudgetItem biggest =
      budget.items.reduce(

              (a,b)=>

          a.spentAmount > b.spentAmount
              ? a
              : b

      );



      if(biggest.spentAmount > 0){


        return
        "Your budget is healthy. "
            "Your highest spending area is "
            "${biggest.name} with UGX "
            "${biggest.spentAmount.toInt()} spent. "
            "You can safely spend around "
            "UGX ${budget.recommendedDailySpend.toStringAsFixed(0)} "
            "per day to stay on track.";


      }


    }








    // ===============================
    // 8. Saving opportunity
    // ===============================


    final bool hasSavingsAllocation = budget.items.any(
      (item) =>
          item.category.toLowerCase().contains("saving") &&
          item.allocatedAmount > 0,
    );

    final double unallocated =
        budget.totalIncome - budget.totalAllocated;

    final double safeUnallocated =
        unallocated < 0 ? 0 : unallocated;

    final double unallocatedPercentage =
        budget.totalIncome > 0
            ? safeUnallocated / budget.totalIncome
            : 0;

    if(!hasSavingsAllocation && unallocatedPercentage >= 0.30){


      return
      "Your budget is in a good position. "
          "You still have UGX ${safeUnallocated.toInt()} unallocated. "
          "Consider assigning part of it to a savings category or "
          "an important goal.";


    }








    // ===============================
    // 9. Default advice
    // ===============================


    return
    "Your budget is healthy. "
        "Continue recording expenses so Charlie can provide "
        "more personalized financial advice.";


  }


}