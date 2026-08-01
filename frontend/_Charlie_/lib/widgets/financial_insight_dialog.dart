import 'package:flutter/material.dart';

import '../models/test_users.dart';


class FinancialInsightDialog extends StatelessWidget {


  final TestUser user;


  const FinancialInsightDialog({

    super.key,

    required this.user,

  });





  String get spendingMessage {


    if(user.income <= 0){

      return
      "Add your income information so Charlie can analyze your finances.";

    }




    double percentage =

        (user.expenses / user.income) * 100;





    if(percentage >= 90){

      return
      "Your expenses are very high compared to your income. "
          "Try reducing unnecessary spending.";

    }




    if(percentage >= 70){

      return
      "You are using most of your income. "
          "Consider creating a stronger saving plan.";

    }





    if(user.expenses <= user.income * 0.5){

      return
      "Great work! You are keeping your expenses under control.";

    }




    return
    "Your spending is balanced. Keep monitoring your expenses.";

  }









  String get budgetMessage {


    if(user.budget == null){

      return
      "You do not have an active budget. "
          "Create one so Charlie can track your goals.";

    }




    if(user.budget!.overBudget){

      return
      "Warning: Your total spending has exceeded your budget.";

    }




    if(user.budget!.hasExceededItems){

      return
      "Some budget categories have exceeded their limits.";

    }




    if(user.budget!.hasWarnings){

      return
      "Some categories are close to their spending limits.";

    }




    return
    "Your budget is currently healthy.";

  }








  List<String> get suggestions {


    List<String> advice = [];



    if(user.expenses > user.income * 0.7){

      advice.add(
          "Try reducing unnecessary expenses."
      );

    }



    else{

      advice.add(
          "Continue maintaining your current spending habits."
      );

    }






    if(user.budget == null){

      advice.add(
          "Create a budget to improve financial planning."
      );

    }






    if(user.balance > 0){

      advice.add(

          "Consider saving part of your remaining balance."

      );

    }





    return advice;


  }








  @override
  Widget build(BuildContext context) {


    return AlertDialog(


      shape:

      RoundedRectangleBorder(

        borderRadius:

        BorderRadius.circular(20),

      ),





      title:


      Row(

        children:[


          const Icon(

            Icons.auto_awesome,

            color:

            Color(0xFF2E7D32),

          ),



          const SizedBox(width:10),




          const Text(

            "Charlie AI Insight",

          ),


        ],

      ),






      content:


      SingleChildScrollView(


        child:

        Column(


          crossAxisAlignment:

          CrossAxisAlignment.start,



          children:[



            Text(

              "Hello ${user.name} 👋",

              style:

              const TextStyle(

                fontSize:18,

                fontWeight:

                FontWeight.bold,

              ),

            ),




            const SizedBox(height:15),




            const Text(

              "Spending Analysis",

              style:

              TextStyle(

                fontSize:17,

                fontWeight:

                FontWeight.bold,

              ),

            ),





            const SizedBox(height:8),





            Text(

              spendingMessage,

            ),






            const SizedBox(height:20),






            const Text(

              "Budget Analysis",

              style:

              TextStyle(

                fontSize:17,

                fontWeight:

                FontWeight.bold,

              ),

            ),






            const SizedBox(height:8),





            Text(

              budgetMessage,

            ),






            const SizedBox(height:20),






            const Text(

              "Suggestions",

              style:

              TextStyle(

                fontSize:17,

                fontWeight:

                FontWeight.bold,

              ),

            ),






            const SizedBox(height:8),






            ...suggestions.map((item){


              return Padding(


                padding:

                const EdgeInsets.only(bottom:8),


                child:


                Row(

                  crossAxisAlignment:

                  CrossAxisAlignment.start,

                  children:[



                    const Text(

                      "• ",

                      style:

                      TextStyle(

                        fontSize:18,

                      ),

                    ),




                    Expanded(

                      child:

                      Text(item),

                    ),



                  ],


                ),


              );


            }),




          ],


        ),


      ),






      actions:[



        ElevatedButton(


          style:

          ElevatedButton.styleFrom(

            backgroundColor:

            const Color(0xFF2E7D32),

          ),



          onPressed:(){


            Navigator.pop(context);


          },



          child:

          const Text(

            "Continue",

            style:

            TextStyle(

              color:

              Colors.white,

            ),

          ),


        )


      ],



    );


  }


}