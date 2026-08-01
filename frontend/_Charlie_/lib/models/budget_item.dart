import '../utils/id_generator.dart';

class BudgetItem {

  String id;

  String name;

  String category;


  double quantity;

  String unit;

  double unitCost;


  double allocatedAmount;

  double spentAmount;


  bool isAI;



  BudgetItem({

    required this.id,

    required this.name,

    required this.category,

    required this.quantity,

    required this.unit,

    required this.unitCost,

    double? allocatedAmount,

    required this.spentAmount,

    this.isAI = false,

  }) : allocatedAmount =
            allocatedAmount ?? (quantity * unitCost);



  // ==============================
  // CALCULATIONS
  // ==============================


  double get calculatedAmount {

    return quantity * unitCost;

  }




  void recalculate(){

    allocatedAmount =
        quantity * unitCost;

  }





  double get remaining {

    final value =
        allocatedAmount - spentAmount;


    return value < 0 ? 0 : value;

  }





  double get progress {


    if(allocatedAmount <=0){

      return 0;

    }


    return
    (spentAmount / allocatedAmount)
        .clamp(0.0,1.0);

  }





  double get percentageUsed {

    return progress * 100;

  }







  bool get isExceeded {


    return spentAmount >
        allocatedAmount;

  }







  bool get isFinished {


    return allocatedAmount >0 &&
        spentAmount >= allocatedAmount &&
        !isExceeded;

  }







  bool get isNearLimit {


    return progress >=0.80 &&
        !isExceeded &&
        !isFinished;

  }







  String get status {


    if(isExceeded){

      return "Exceeded";

    }


    if(isFinished){

      return "Finished";

    }


    if(isNearLimit){

      return "Almost finished";

    }


    return "Safe";

  }








  // ==============================
  // EDIT HELPERS
  // ==============================



  void updateQuantity(double value){

    quantity =
        value <0 ? 0:value;


    recalculate();

  }






  void updateUnitCost(double value){

    unitCost =
        value <0 ?0:value;


    recalculate();

  }







  String get formattedAmount {


    return
    "UGX ${allocatedAmount.toInt()}";

  }







  // ==============================
  // JSON
  // ==============================



  Map<String,dynamic> toJson(){


    return {


      "id":id,


      "name":name,


      "category":category,


      "quantity":quantity,


      "unit":unit,


      "unitCost":unitCost,


      "allocatedAmount":allocatedAmount,


      "spentAmount":spentAmount,


      "isAI":isAI,


    };


  }








  factory BudgetItem.fromJson(
      Map<String,dynamic> json){


    return BudgetItem(


      id:
      json["id"]?.toString() ??
          IdGenerator.next(),




      name:
      json["name"]?.toString() ??
          "Unnamed Item",




      category:
      json["category"]?.toString() ??
          "Other",




      quantity:
      _parseDouble(
          json["quantity"],
          1,
      ),




      unit:
      json["unit"]?.toString() ??
          "item",




      unitCost:
      _parseDouble(
          json["unitCost"],
          0,
      ),




      allocatedAmount:
      _parseNullableDouble(
          json["allocatedAmount"],
      ),




      spentAmount:
      _parseDouble(
          json["spentAmount"],
          0,
      ),




      isAI:
      json["isAI"] ?? false,


    );


  }








  // ==============================
  // COPY SUPPORT
  // ==============================



  BudgetItem copyWith({


    String? id,

    String? name,

    String? category,

    double? quantity,

    String? unit,

    double? unitCost,

    double? allocatedAmount,

    double? spentAmount,

    bool? isAI,


  }){


    return BudgetItem(


      id:
      id ?? this.id,


      name:
      name ?? this.name,


      category:
      category ?? this.category,



      quantity:
      quantity ?? this.quantity,



      unit:
      unit ?? this.unit,



      unitCost:
      unitCost ?? this.unitCost,



      allocatedAmount:
      allocatedAmount ?? this.allocatedAmount,



      spentAmount:
      spentAmount ?? this.spentAmount,



      isAI:
      isAI ?? this.isAI,


    );


  }







  // ==============================
  // SAFE PARSERS
  // ==============================



  static double _parseDouble(
      dynamic value,
      double fallback){

    if(value == null){

      return fallback;

    }


    if(value is num){

      return value.toDouble();

    }


    return double.tryParse(
        value.toString()
    ) ?? fallback;

  }







  static double? _parseNullableDouble(
      dynamic value){


    if(value == null){

      return null;

    }


    if(value is num){

      return value.toDouble();

    }


    return double.tryParse(
        value.toString()
    );


  }


}