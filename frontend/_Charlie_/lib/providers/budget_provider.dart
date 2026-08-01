import 'package:flutter/material.dart';

import '../models/user_budget.dart';
import '../models/budget_item.dart';
import '../models/test_users.dart';
import '../services/budget_analyzer_service.dart';
import '../utils/id_generator.dart';


class BudgetProvider extends ChangeNotifier {


  UserBudget? _currentBudget;


  final List<UserBudget> _budgetHistory = [];



  UserBudget? get currentBudget =>
      _currentBudget;



  List<UserBudget> get budgetHistory =>
      List.unmodifiable(_budgetHistory);





  // ================================
  // CREATE / SET ACTIVE BUDGET
  // ================================


  void setBudget(UserBudget budget) {


    _currentBudget = budget;


    notifyListeners();


  }







  void createBudget(UserBudget budget) {


    _currentBudget = budget;


    notifyListeners();


  }







  // ================================
  // ADD BUDGET ITEM
  // ================================


  bool addItem(BudgetItem item) {



    if(_currentBudget == null){

      return false;

    }



    if(item.allocatedAmount < 0){

      return false;

    }






    if(
    _currentBudget!.totalAllocated +
        item.allocatedAmount >
        _currentBudget!.totalIncome
    ){

      return false;

    }






    _currentBudget!.items.add(item);



    notifyListeners();



    return true;


  }









  // ================================
  // RECORD EXPENSE
  // ================================


  bool addExpense({

    required BudgetItem item,

    required double amount,

    TestUser? user,

  }) {



    if(_currentBudget == null){

      return false;

    }



    if(amount <= 0){

      return false;

    }





    if(
    !_currentBudget!.items.contains(item)
    ){

      return false;

    }







    if(amount > item.remaining){

      return false;

    }







    item.spentAmount += amount;







    if(user != null){



      user.expenses += amount;


      user.balance -= amount;





      user.transactions.add(



        TransactionModel(


          title: item.name,


          category: item.category,


          amount: amount,


          isIncome: false,


          date: DateTime.now(),


        ),


      );



    }







    notifyListeners();




    return true;



  }









  // ================================
  // REMOVE ITEM
  // ================================


  void removeItem(BudgetItem item){



    if(_currentBudget == null){

      return;

    }





    _currentBudget!.items.remove(item);



    notifyListeners();



  }









  // ================================
  // AI ANALYSIS
  // ================================


  String getBudgetAdvice(){



    if(_currentBudget == null){

      return "Create a budget first.";

    }




    return BudgetAnalyzerService.analyze(

      _currentBudget!,

    );



  }









  // ================================
  // RECYCLE BUDGET
  // ================================


  UserBudget? recycleBudget(){



    if(_currentBudget == null){

      return null;

    }






    final oldBudget = _currentBudget!;





    _budgetHistory.add(oldBudget);








    final recycledItems =

    oldBudget.items.map(



            (item){



          return item.copyWith(



            id:

            IdGenerator.next(),



            spentAmount:0,



          );



        }



    ).toList();










    final duration =

    oldBudget.endDate
        .difference(
      oldBudget.startDate,
    );








    final newBudget = UserBudget(



      id:

      IdGenerator.next(),





      purpose:

      oldBudget.purpose,





      totalIncome:

      oldBudget.totalIncome,





      startDate:

      DateTime.now(),





      endDate:

      DateTime.now()
          .add(duration),





      items:

      recycledItems,





      isAI:

      oldBudget.isAI,



    );








    _currentBudget = newBudget;





    notifyListeners();






    return newBudget;



  }









  // ================================
  // DELETE CURRENT BUDGET
  // ================================


  void clearBudget(){



    if(_currentBudget != null){



      _budgetHistory.add(

        _currentBudget!,

      );



    }






    _currentBudget = null;




    notifyListeners();



  }









  // ================================
  // RESET SPENDING
  // ================================


  void resetSpending(){



    if(_currentBudget == null){

      return;

    }







    for(var item in _currentBudget!.items){



      item.spentAmount = 0;



    }







    notifyListeners();



  }



}