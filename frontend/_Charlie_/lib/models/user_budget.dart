import 'budget_item.dart';
import '../utils/id_generator.dart';


class UserBudget {


  String id;

  String purpose;

  double totalIncome;

  DateTime startDate;

  DateTime endDate;

  List<BudgetItem> items;

  bool isAI;



  UserBudget({

    required this.id,

    required this.purpose,

    required this.totalIncome,

    required this.startDate,

    required this.endDate,

    required this.items,

    this.isAI = false,

  });






  // ==============================
  // BASIC CALCULATIONS
  // ==============================


  double get totalAllocated {

    return items.fold(

      0,

      (sum,item)=> sum + item.allocatedAmount,

    );

  }




  double get totalSpent {

    return items.fold(

      0,

      (sum,item)=> sum + item.spentAmount,

    );

  }




  double get remainingIncome {

    final remaining =
        totalIncome - totalAllocated;

    return remaining < 0 ? 0 : remaining;

  }




  double get spendingPercentage {

    if(totalIncome <= 0){

      return 0;

    }

    return (totalSpent / totalIncome) * 100;

  }




  double get allocationPercentage {

    if(totalIncome <=0){

      return 0;

    }


    return (totalAllocated / totalIncome) * 100;

  }





  bool get overBudget {

    return totalAllocated > totalIncome;

  }





  bool get hasExceededItems {

    return items.any(

      (item)=> item.isExceeded,

    );

  }





  bool get isNearLimit {

    return totalAllocated >= totalIncome * 0.8;

  }





  bool get hasWarnings {

    return items.any(

      (item)=> item.isNearLimit,

    );

  }





  // ==============================
  // AI BUDGET INTELLIGENCE
  // ==============================


  double get averageCategoryAmount {


    if(items.isEmpty){

      return 0;

    }


    return totalAllocated / items.length;

  }




  bool get isBalanced {


    if(items.isEmpty){

      return false;

    }


    return allocationPercentage >=95 &&
        allocationPercentage <=105;

  }





  String get budgetStatus {


    if(overBudget){

      return "Exceeded";

    }


    if(hasExceededItems){

      return "Some expenses exceeded";

    }


    if(hasWarnings){

      return "Almost finished";

    }


    return "Healthy";

  }






  String get budgetHealth {


    if(overBudget){

      return
      "Your planned expenses are higher than your available income.";

    }


    if(!isBalanced){

      return
      "Your money allocation needs some adjustment.";

    }


    if(hasWarnings){

      return
      "Some categories are taking a large part of your budget.";

    }


    return
    "Your budget distribution looks healthy.";

  }







  String get highestExpenseCategory {


    if(items.isEmpty){

      return "None";

    }



    BudgetItem highest = items.first;



    for(final item in items){

      if(item.allocatedAmount >
          highest.allocatedAmount){

        highest = item;

      }

    }


    return highest.name;

  }







  String get aiAdvice {


    if(overBudget){

      return
      "Charlie recommends reducing some expenses because your budget exceeds your available money.";

    }



    if(isPacedToRunOutEarly){

      return paceMessage;

    }




    if(hasWarnings){

      return
      "Charlie noticed that $highestExpenseCategory consumes a large portion of your budget. Review this category carefully.";

    }




    return
    "Your budget looks realistic. Continue tracking your spending.";

  }







  // ==============================
  // SPENDING PACE ANALYSIS
  // ==============================



  int get totalDays {


    final days =
    endDate.difference(startDate).inDays;


    return days < 1 ? 1 : days;

  }






  int get daysElapsed {


    final elapsed =
    DateTime.now()
        .difference(startDate)
        .inDays;



    if(elapsed <1){

      return 1;

    }



    if(elapsed > totalDays){

      return totalDays;

    }


    return elapsed;

  }






  double get actualDailyRate {


    return totalSpent / daysElapsed;

  }







  int get projectedDaysTotal {


    if(actualDailyRate <=0){

      return totalDays;

    }


    return
    (totalIncome / actualDailyRate)
        .round();


  }







  DateTime get projectedRunOutDate {


    return startDate.add(

      Duration(

        days: projectedDaysTotal,

      ),

    );

  }






  int get daysShort {


    return totalDays - projectedDaysTotal;

  }






  bool get isPacedToRunOutEarly {


    return daysShort >0;

  }







  static const List<String> _monthNames = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
  ];

  String _formatDate(DateTime date) {
    return "${date.day} ${_monthNames[date.month - 1]} ${date.year}";
  }

  // How many days from *now* until money runs out at the current pace,
  // used to phrase the warning in plain terms ("in about 2 weeks")
  // instead of only a calendar date.
  int get daysUntilRunOut {

    final days = projectedRunOutDate.difference(DateTime.now()).inDays;

    return days < 0 ? 0 : days;

  }

  String _roughDuration(int days) {

    if (days <= 0) {
      return "any day now";
    }

    if (days == 1) {
      return "1 day";
    }

    if (days < 14) {
      return "$days days";
    }

    final weeks = (days / 7).round();

    return "about $weeks week${weeks == 1 ? '' : 's'}";

  }

  String get paceMessage {


    if(!isPacedToRunOutEarly){

      return
      "I have inspected your budget and you are spending at a sustainable "
      "pace. If you keep it up, I suggest spending around "
      "UGX ${recommendedDailySpend.toStringAsFixed(0)} daily for the rest "
      "of this period — that way you won't run out of funds, and you'll "
      "likely have more left over to put into savings.";

    }



    return

    "I have inspected your budget, and if you continue spending like this, "
        "you will run out of funds in ${_roughDuration(daysUntilRunOut)} "
        "(around ${_formatDate(projectedRunOutDate)}, "
        "$daysShort day${daysShort == 1 ? '' : 's'} earlier than planned). "
        "I suggest spending no more than UGX "
        "${recommendedDailySpend.toStringAsFixed(0)} daily from now on — "
        "in so doing you won't run out of funds before the period ends, "
        "and you'll have more room to save.";

  }







  int get daysRemaining {

    final now = DateTime.now();

    // Budget period has already ended.
    if(!endDate.isAfter(now)){

      return 0;

    }

    // Round UP (ceiling) instead of truncating, so a period that still
    // has any time left today always counts as at least 1 day
    // remaining. Using .inDays (floor) here caused a freshly generated
    // budget to show "0 days remaining" whenever less than a full 24
    // hours had passed since it was created, which in turn made the
    // recommended daily spend show as UGX 0.
    final remainingMinutes =
    endDate.difference(now).inMinutes;

    final days =
    (remainingMinutes / (24 * 60)).ceil();

    return days <1 ?1:days;

  }






  double get recommendedDailySpend {


    if(daysRemaining <=0){

      return 0;

    }



    final remaining =
    totalIncome-totalSpent;



    return remaining <=0
        ?0
        :remaining/daysRemaining;


  }

// ==============================
// COMPATIBILITY STATUS GETTER
// ==============================

String get status {

  if(overBudget){

    return "Exceeded";

  }


  if(hasExceededItems){

    return "Exceeded";

  }


  if(isPacedToRunOutEarly){

    return "Off Pace";

  }


  if(hasWarnings){

    return "Warning";

  }


  return "Safe";

}





  // ==============================
  // JSON SUPPORT
  // ==============================


  Map<String,dynamic> toJson(){


    return {


      "id":id,

      "purpose":purpose,

      "totalIncome":totalIncome,


      "startDate":
      startDate.toIso8601String(),


      "endDate":
      endDate.toIso8601String(),


      "isAI":isAI,


      "items":
      items.map(

            (item)=>item.toJson(),

      ).toList(),


    };


  }








  factory UserBudget.fromJson(

      Map<String,dynamic> json

      ){


    return UserBudget(


      id:
      json["id"]?.toString() ??
          IdGenerator.next(),




      purpose:
      json["purpose"]?.toString() ??
          "General Budget",




      totalIncome:

      double.tryParse(

        json["totalIncome"]
            .toString(),

      ) ??0,




      startDate:

      DateTime.tryParse(

        json["startDate"]
            .toString(),

      ) ?? DateTime.now(),




      endDate:

      DateTime.tryParse(

        json["endDate"]
            .toString(),

      ) ??
          DateTime.now()
              .add(
            const Duration(days:30),
          ),




      isAI:

      json["isAI"] ?? false,




      items:

      (json["items"] as List? ?? [])

          .map(

              (item)=>

              BudgetItem.fromJson(item)

      )

          .toList(),


    );


  }







  void checkBudget(){


    for(var item in items){


      if(item.allocatedAmount <0){

        item.allocatedAmount =0;

      }


    }


  }







  UserBudget copyWith({


    String? id,

    String? purpose,

    double? totalIncome,

    DateTime? startDate,

    DateTime? endDate,

    List<BudgetItem>? items,

    bool? isAI,


  }){


    return UserBudget(


      id:id ?? this.id,


      purpose:
      purpose ?? this.purpose,


      totalIncome:
      totalIncome ?? this.totalIncome,


      startDate:
      startDate ?? this.startDate,


      endDate:
      endDate ?? this.endDate,


      items:
      items ?? this.items,


      isAI:
      isAI ?? this.isAI,


    );


  }


}