import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/budget_item.dart';
import '../models/user_budget.dart';
import '../utils/id_generator.dart';


class GeminiBudgetService {


  static final String apiKey =
      dotenv.env['GEMINI_API_KEY'] ?? "";


  static const String model =
      "gemini-3.5-flash";





  static Future<UserBudget> generateBudget({

    required String purpose,

    required double income,

    required int durationDays,

  }) async {



    if(apiKey.isEmpty){

      throw Exception(
        "Gemini API key missing",
      );

    }






    final prompt = """

You are Charlie AI.

Charlie is a university student financial advisor in Uganda.

Create a realistic student budget.

Purpose:
$purpose


Available Income:
UGX $income


Duration:
$durationDays days


Rules:

1. Only include expenses related to the purpose.

2. Prioritize important needs first.

3. Avoid duplicate items.

4. Use realistic Ugandan prices.

5. Allocate all available money.

6. Create between 5 and 10 items.

7. Every item must contain:

name
category
quantity
unit
unitCost
amount


8. amount must equal:

quantity × unitCost


Return JSON only.


Format:

{
 "items":[
  {
   "name":"",
   "category":"",
   "quantity":1,
   "unit":"",
   "unitCost":0,
   "amount":0
  }
 ]
}

""";






    final generativeModel = GenerativeModel(

      model: model,

      apiKey: apiKey,

      generationConfig:

      GenerationConfig(

        temperature:0.2,

        responseMimeType:
        "application/json",

      ),

    );







    final response =
    await generativeModel.generateContent(

      [

        Content.text(prompt),

      ],

    );







    if(response.text == null ||
        response.text!.trim().isEmpty){


      throw Exception(
        "Gemini returned no response.",
      );


    }







    final decoded =
    jsonDecode(

      cleanJson(
          response.text!
      ),

    );







    List<BudgetItem> items=[];






    for(final item in decoded["items"] ?? []){


      double quantity =

      (item["quantity"] as num?)
          ?.toDouble()
          ??
          1;



      if(quantity <=0){

        quantity =1;

      }






      double unitCost =

      (item["unitCost"] as num?)
          ?.toDouble()
          ??
          0;






      double amount =

      (item["amount"] as num?)
          ?.toDouble()
          ??
          0;







      if(unitCost <=0 &&
          amount >0){

        unitCost =
            amount / quantity;

      }






      if(amount <=0){

        amount =
            quantity * unitCost;

      }






      if(amount <=0){

        continue;

      }







      items.add(


        BudgetItem(

          id:

          IdGenerator.next(),


          name:

          item["name"]
              ?.toString()
              ??
              "Budget Item",



          category:

          item["category"]
              ?.toString()
              ??
              "Other",



          quantity:

          quantity,



          unit:

          item["unit"]
              ?.toString()
              ??
              "item",



          unitCost:

          unitCost,



          allocatedAmount:

          amount,



          spentAmount:

          0,



          isAI:

          true,

        ),


      );

    }







    if(items.isEmpty){


      throw Exception(
        "AI generated an empty budget.",
      );


    }







    items =
        removeDuplicates(items);







    items =
        validateItems(items);







    redistributeMoney(

      items,

      income,

    );







    return UserBudget(


      id:

      IdGenerator.next(),



      purpose:

      purpose,



      totalIncome:

      income,



      startDate:

      DateTime.now(),



      endDate:

      DateTime.now().add(

        Duration(

          days:durationDays,

        ),

      ),



      items:

      items,



      isAI:

      true,


    );


  }








  static String cleanJson(String text){


    return text

        .replaceAll(
        "```json",
        "",
    )

        .replaceAll(
        "```",
        "",
    )

        .trim();


  }









  static List<BudgetItem> removeDuplicates(

      List<BudgetItem> items

      ){


    final Map<String,BudgetItem> unique={};




    for(final item in items){


      final key =

      "${item.name.toLowerCase()}_${item.category.toLowerCase()}";



      unique[key]=item;


    }




    return unique.values.toList();


  }









  static List<BudgetItem> validateItems(

      List<BudgetItem> items

      ){



    for(final item in items){


      if(item.quantity <=0){

        item.quantity =1;

      }



      if(item.unitCost <0){

        item.unitCost =0;

      }



      item.allocatedAmount =

          item.quantity *
              item.unitCost;



    }



    return items;


  }









  static void redistributeMoney(

      List<BudgetItem> items,

      double income,

      ){



    if(items.isEmpty){

      return;

    }





    double totalAllocated =

    items.fold(

      0,

          (sum,item)=>

      sum + item.allocatedAmount,

    );






    double difference =

        income-totalAllocated;







    if(difference.abs()<1){

      return;

    }







    BudgetItem flexibleItem =

    items.last;






    double newAmount =

        flexibleItem.allocatedAmount
            +
            difference;







    if(newAmount <0){

      newAmount =0;

    }







    flexibleItem.allocatedAmount =

        newAmount;






    flexibleItem.unitCost =

        flexibleItem.quantity <=0

            ?

        newAmount

            :

        newAmount /
            flexibleItem.quantity;



  }



}