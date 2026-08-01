import '../models/user_budget.dart';
import '../models/budget_item.dart';
import '../utils/id_generator.dart';



class BudgetRecycleService {



  static UserBudget recycleBudget(
      UserBudget oldBudget,
      double newIncome,
      ){




    final List<BudgetItem> recycledItems = [];




    final incomeRatio =
        newIncome / oldBudget.totalIncome;





    for(final item in oldBudget.items){



      recycledItems.add(


        item.copyWith(


          id:
          IdGenerator.next(),



          spentAmount:
          0,



          allocatedAmount:
          item.allocatedAmount *
              incomeRatio,



          isAI:
          false,


        ),


      );


    }







    return UserBudget(


      id:

      IdGenerator.next(),




      purpose:

      "${oldBudget.purpose} (Recycled)",




      totalIncome:

      newIncome,




      startDate:

      DateTime.now(),




      endDate:

      DateTime.now()
          .add(
        const Duration(
            days:30
        ),
      ),




      items:

      recycledItems,




      isAI:false,


    );


  }








  static List<String> analyzeRecycle(
      UserBudget budget,
      ){



    List<String> suggestions=[];




    for(final item in budget.items){





      if(item.spentAmount <
          item.allocatedAmount *0.5){



        suggestions.add(

          "${item.name} was underused previously. "
              "Charlie suggests reducing this allocation.",

        );


      }






      if(item.spentAmount >
          item.allocatedAmount *0.9){



        suggestions.add(

          "${item.name} was almost fully used. "
              "Keeping this amount is recommended.",

        );


      }



    }




    if(suggestions.isEmpty){


      suggestions.add(

        "Your previous budget appears stable. "
            "Charlie recommends continuing with similar allocations.",

      );


    }





    return suggestions;



  }




}