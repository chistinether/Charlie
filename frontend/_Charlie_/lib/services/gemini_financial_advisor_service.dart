import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/test_users.dart';


class GeminiFinancialAdvisorService {


  static final String apiKey =
      dotenv.env['GEMINI_API_KEY'] ?? "";


  static const String model =
      "gemini-3.5-flash";


  static String get apiUrl =>
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent";





  static Future<Map<String,dynamic>> analyzeFinance(
      TestUser user
      ) async {



    if(apiKey.isEmpty){

      throw Exception(
          "Gemini API key missing"
      );

    }





    final transactions = user.transactions.map((t){


      return """

Title: ${t.title}
Category: ${t.category}
Amount: ${t.amount}
Type: ${t.isIncome ? "Income" : "Expense"}

""";


    }).join("\n");







    String budgetStatus =
        "No budget created";


    String budgetAdvice =
        "Create a budget to improve your financial planning.";


    String paceInformation =
        "No spending pace information available.";


    double recommendedDailySpend = 0;




    if(user.budget != null){


      budgetStatus =
          user.budget!.status;


      budgetAdvice =
          user.budget!.aiAdvice;


      paceInformation =
          user.budget!.paceMessage;


      recommendedDailySpend =
          user.budget!.recommendedDailySpend;


    }








    final prompt = """

You are Charlie AI, a university student financial advisor.


Analyze this student's financial situation.


Student Income:
UGX ${user.income}


Current Expenses:
UGX ${user.expenses}


Current Balance:
UGX ${user.balance}


Budget Status:
$budgetStatus


Budget Advice:
$budgetAdvice


Spending Pace:
$paceInformation


Recommended Daily Spending:
UGX ${recommendedDailySpend.toInt()}


Transactions:

$transactions



Your job:

1. Identify financial problems.
2. Suggest better spending habits.
3. Give realistic student advice.
4. Keep advice short and practical.


Return JSON only:


{
"summary":"",
"warning":"",
"suggestion":""
}


""";









    final response = await http.post(


      Uri.parse(
          "$apiUrl?key=$apiKey"
      ),



      headers:{


        "Content-Type":
        "application/json"


      },



      body:jsonEncode({


        "contents":[


          {


            "parts":[


              {


                "text":prompt


              }


            ]


          }


        ],




        "generationConfig":{


          "temperature":0.3,


          "responseMimeType":
          "application/json"


        }


      }),


    );








    if(response.statusCode != 200){


      throw Exception(
          "Gemini Error: ${response.body}"
      );


    }








    final data =
    jsonDecode(response.body);






    try{


      String result =


      data["candidates"][0]
      ["content"]
      ["parts"][0]
      ["text"];






      result = result

          .replaceAll(
          "```json",
          ""
      )

          .replaceAll(
          "```",
          ""
      )

          .trim();






      return jsonDecode(result);



    }

    catch(e){


      return {


        "summary":
        "Charlie could not complete the analysis.",


        "warning":
        "Try again later.",


        "suggestion":
        "Continue tracking your expenses."


      };


    }



  }


}