import '../models/user_budget.dart';
import '../models/budget_item.dart';
import '../models/ai_recommendation.dart';



class BudgetAIEngine {



  static List<AIRecommendation> analyze(

      UserBudget budget,

      ){

    final recommendations =
    <AIRecommendation>[];



    //------------------------------------------------
    // 1. Check total allocation
    //------------------------------------------------


    if(budget.overBudget){


      recommendations.add(

        AIRecommendation(

          title:
          "Budget exceeds your income",

          message:

          "Your planned expenses are UGX "
              "${(budget.totalAllocated -
              budget.totalIncome)
              .toInt()} higher than your available money. "
              "Consider reducing some categories.",


          category:
          "Overall Budget",


          type:
          RecommendationType.warning,


        ),

      );


    }




    //------------------------------------------------
    // 2. Category analysis
    //------------------------------------------------


    for(final item in budget.items){



      final percentage =

      budget.totalIncome == 0

          ? 0

          :

      (item.allocatedAmount /
          budget.totalIncome) * 100;





      if(percentage >=30){


        recommendations.add(

          AIRecommendation(

            title:
            "${item.name} takes a large share",

            message:

            "${item.name} uses "
                "${percentage.toInt()}% of your income. "
                "Charlie recommends reviewing this category "
                "to maintain balance.",


            category:
            item.category,


            type:
            RecommendationType.suggestion,


          ),

        );


      }



    }





    //------------------------------------------------
    // 3. Missing important student categories
    //------------------------------------------------


    final categories =

    budget.items

        .map(

            (e)=>e.category.toLowerCase()

    )

        .toList();






    final importantCategories = [

      "food",

      "transport",

      "emergency",

      "education",

      "communication",

    ];






    for(final category in importantCategories){



      if(!categories.contains(category)){


        recommendations.add(

          AIRecommendation(

            title:
            "Missing $category budget",

            message:

            "Charlie noticed that your budget does not "
                "include a $category allocation. "
                "Adding one may make your budget more realistic.",


            category:
            category,


            type:
            RecommendationType.improvement,


          ),

        );



      }


    }






    //------------------------------------------------
    // 4. Spending pace prediction
    //------------------------------------------------


    if(budget.isPacedToRunOutEarly){



      recommendations.add(

        AIRecommendation(

          title:
          "Your spending pace is high",

          message:

          "At your current spending rate, "
              "your money may finish "
              "${budget.daysShort} days early. "
              "Try keeping daily spending near UGX "
              "${budget.recommendedDailySpend.toInt()}.",


          category:
          "Spending Pattern",


          type:
          RecommendationType.warning,


        ),

      );


    }







    //------------------------------------------------
    // 5. Positive reinforcement
    //------------------------------------------------



    if(recommendations.isEmpty){


      recommendations.add(

        AIRecommendation(

          title:
          "Your budget looks healthy",

          message:

          "Charlie found a balanced budget. "
              "Continue tracking expenses to improve accuracy.",


          category:
          "Overall",


          type:
          RecommendationType.positive,


        ),

      );


    }





    return recommendations;


  }



}