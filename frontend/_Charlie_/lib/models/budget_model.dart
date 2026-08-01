class BudgetModel {

  String name;
  String category;

  double amount;
  double spent;

  DateTime createdDate;
  DateTime expiryDate;


  BudgetModel({

    required this.name,

    required this.category,

    required this.amount,

    required this.spent,

    required this.createdDate,

    required this.expiryDate,

  });





  // ===============================
  // Remaining Money
  // ===============================

  double get remaining {

    final value = amount - spent;

    return value < 0 ? 0 : value;

  }






  // ===============================
  // Spending Progress
  // ===============================

  double get progress {

    if(amount <= 0){

      return 0;

    }


    return (spent / amount)
        .clamp(0.0, 1.0);

  }






  // ===============================
  // Percentage Used
  // ===============================

  double get percentageUsed {

    return progress * 100;

  }







  // ===============================
  // Budget Status Checks
  // ===============================


  bool get isExceeded {

    return spent > amount;

  }





  bool get isNearLimit {

    return progress >= 0.8 &&
        !isExceeded;

  }





  bool get isExpired {

    return DateTime.now()
        .isAfter(expiryDate);

  }








  // ===============================
  // Spending Pace Prediction
  // ===============================


  int get totalDays {


    final days =
        expiryDate
            .difference(createdDate)
            .inDays;


    return days <= 0 ? 1 : days;

  }






  int get daysElapsed {


    final days =
        DateTime.now()
            .difference(createdDate)
            .inDays;


    if(days <= 0){

      return 1;

    }


    if(days > totalDays){

      return totalDays;

    }


    return days;

  }







  double get dailySpendingRate {


    return spent / daysElapsed;


  }







  int get projectedDaysTotal {


    if(dailySpendingRate <= 0){

      return totalDays;

    }


    return
        (amount / dailySpendingRate)
            .round();

  }







  int get daysShort {


    return totalDays -
        projectedDaysTotal;

  }







  bool get isPacedToRunOutEarly {


    return daysShort > 0 &&
        !isExpired;

  }







  String get paceMessage {


    if(!isPacedToRunOutEarly){

      return
      "Your spending pace is healthy. "
      "This budget is currently on track.";

    }




    return

    "Your current spending pace may "
    "finish this budget "
    "$daysShort day${daysShort == 1 ? '' : 's'} "
    "earlier than expected. "
    "Consider reducing spending.";

  }


}