import 'package:flutter/material.dart';

import '../../models/test_users.dart';

import '../features/ai_budget_screen.dart';
import '../features/manual_budget_screen.dart';
import '../features/budget_analysis_screen.dart';



class BudgetsPage extends StatelessWidget {


  final TestUser user;



  const BudgetsPage({

    super.key,

    required this.user,

  });





  @override
  Widget build(BuildContext context) {



    final Map<String, double> budgets = {

      "Food": user.income * 0.15,

      "Shopping": user.income * 0.15,

      "Entertainment": user.income * 0.05,

      "Outing": user.income * 0.10,

      "Miscellaneous": user.income * 0.05,

    };






    return Scaffold(


      backgroundColor:
      const Color(0xFFF5F7FA),



      appBar: AppBar(


        backgroundColor:
        const Color(0xFF2E7D32),


        title: const Text(

          "Budgets",

          style: TextStyle(

            color: Colors.white,

            fontWeight: FontWeight.bold,

          ),

        ),


      ),





      body: SingleChildScrollView(


        padding:
        const EdgeInsets.all(16),



        child: Column(


          crossAxisAlignment:
          CrossAxisAlignment.start,



          children: [



            Text(


              "${user.name}'s Budget Planner",


              style: const TextStyle(


                fontSize:26,


                fontWeight:FontWeight.bold,


              ),


            ),





            const SizedBox(height:8),





            const Text(


              "Manage your spending wisely.",


              style: TextStyle(


                color:Colors.grey,


                fontSize:16,


              ),


            ),





            const SizedBox(height:25),





            // NEW BUDGET OPTIONS

            Row(

              children: [


                Expanded(

                  child: ElevatedButton.icon(

                    onPressed: (){


                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder: (context)=>

                              AIBudgetScreen(

                                user:user,

                              ),

                        ),

                      );


                    },


                    icon: const Icon(

                      Icons.auto_awesome,

                    ),


                    label: const Text(

                      "AI Budget",

                    ),


                    style: ElevatedButton.styleFrom(

                      backgroundColor:

                      const Color(0xFF2E7D32),


                      foregroundColor:

                      Colors.white,

                    ),

                  ),

                ),



                const SizedBox(width:10),



                Expanded(

                  child: ElevatedButton.icon(

                    onPressed: (){


                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder: (context)=>

                              ManualBudgetScreen(

                                user:user,

                              ),

                        ),

                      );


                    },


                    icon: const Icon(

                      Icons.edit,

                    ),


                    label: const Text(

                      "Manual",

                    ),


                    style: ElevatedButton.styleFrom(

                      backgroundColor:

                      Colors.orange,


                      foregroundColor:

                      Colors.white,

                    ),

                  ),

                ),


              ],

            ),





            const SizedBox(height:12),





            SizedBox(

              width:double.infinity,


              child: ElevatedButton.icon(

                onPressed: (){


                  Navigator.push(

                    context,

                    MaterialPageRoute(

                      builder: (context)=>

                          BudgetAnalysisScreen(

                            user:user,

                          ),

                    ),

                  );


                },


                icon: const Icon(

                  Icons.analytics,

                ),


                label: const Text(

                  "Analyse Spending",

                ),


                style: ElevatedButton.styleFrom(

                  backgroundColor:

                  Colors.blue,


                  foregroundColor:

                  Colors.white,

                ),

              ),

            ),





            const SizedBox(height:30),






            Container(


              width:double.infinity,


              padding:
              const EdgeInsets.all(20),



              decoration:BoxDecoration(



                color:
                const Color(0xFF2E7D32),



                borderRadius:
                BorderRadius.circular(20),


              ),





              child:Column(



                crossAxisAlignment:
                CrossAxisAlignment.start,



                children:[



                  const Icon(


                    Icons.auto_graph,


                    color:Colors.white,


                    size:40,


                  ),





                  const SizedBox(height:15),





                  const Text(



                    "Automatic Budget",



                    style:TextStyle(



                      color:Colors.white,



                      fontSize:22,



                      fontWeight:FontWeight.bold,



                    ),


                  ),





                  const SizedBox(height:10),





                  Text(



                    "Charlie created this budget using your income of UGX ${user.income.toStringAsFixed(0)}.",



                    style:const TextStyle(



                      color:Colors.white70,



                    ),


                  ),



                ],


              ),


            ),





            const SizedBox(height:30),





            const Text(


              "My Budgets",



              style:TextStyle(



                fontSize:22,


                fontWeight:FontWeight.bold,


              ),


            ),





            const SizedBox(height:20),





            ...budgets.entries.map((entry){



              final spent =

              calculateSpent(entry.key);





              return buildBudgetCard(



                entry.key,



                getIcon(entry.key),



                entry.value,



                spent,



                getColor(entry.key),



              );


            }),





            const SizedBox(height:30),





            const Text(


              "Budget Tips",


              style:TextStyle(


                fontSize:22,


                fontWeight:FontWeight.bold,


              ),


            ),





            const SizedBox(height:15),





            Card(



              shape:RoundedRectangleBorder(



                borderRadius:

                BorderRadius.circular(15),


              ),





              child:

              const Padding(



                padding:

                EdgeInsets.all(18),





                child:Text(



                  "Monitor your expenses regularly to avoid exceeding your monthly budget limits.",


                ),


              ),


            ),



          ],


        ),


      ),


    );


  }







  double calculateSpent(String category){



    double total = 0;



    for(var transaction in user.transactions){



      if(!transaction.isIncome &&

          transaction.category == category){



        total += transaction.amount;



      }


    }



    return total;


  }







  Widget buildBudgetCard(



      String title,



      IconData icon,



      double limit,



      double spent,



      Color color,



      ){



    double progress = 0;



    if(limit > 0){


      progress = spent / limit;


    }



    if(progress > 1){


      progress = 1;


    }






    return Card(



      margin:

      const EdgeInsets.only(bottom:18),




      shape:RoundedRectangleBorder(



        borderRadius:

        BorderRadius.circular(18),


      ),






      child:Padding(



        padding:

        const EdgeInsets.all(18),





        child:Column(



          children:[





            Row(



              children:[





                CircleAvatar(



                  backgroundColor:

                  color.withValues(alpha:0.15),



                  child:Icon(



                    icon,



                    color:color,



                  ),


                ),





                const SizedBox(width:15),





                Expanded(



                  child:Text(



                    title,



                    style:const TextStyle(



                      fontSize:18,


                      fontWeight:FontWeight.bold,


                    ),



                  ),


                ),


              ],


            ),





            const SizedBox(height:15),





            LinearProgressIndicator(



              value:progress,



              color:color,



              minHeight:8,



              backgroundColor:

              Colors.grey.shade300,


            ),





            const SizedBox(height:12),






            Row(



              mainAxisAlignment:

              MainAxisAlignment.spaceBetween,




              children:[





                Text(



                  "Limit: UGX ${limit.toInt()}",



                ),






                Text(



                  "Spent: UGX ${spent.toInt()}",



                  style:TextStyle(



                    color:color,



                    fontWeight:

                    FontWeight.bold,


                  ),


                ),


              ],


            ),





            const SizedBox(height:10),





            Align(



              alignment:

              Alignment.centerLeft,




              child:Text(



                "Remaining: UGX ${(limit-spent).toInt()}",



                style:

                const TextStyle(



                  color:Colors.green,



                  fontWeight:FontWeight.bold,


                ),


              ),


            ),



          ],


        ),


      ),


    );


  }







  IconData getIcon(String category){

    switch(category){

      case "Food":
        return Icons.fastfood;


      case "Shopping":
        return Icons.shopping_bag;


      case "Entertainment":
        return Icons.movie;


      case "Outing":
        return Icons.directions_walk;


      case "Miscellaneous":
        return Icons.more_horiz;


      default:
        return Icons.money;

    }

  }






  Color getColor(String category){

    switch(category){

      case "Food":
        return Colors.orange;


      case "Shopping":
        return Colors.purple;


      case "Entertainment":
        return Colors.red;


      case "Outing":
        return Colors.blue;


      case "Miscellaneous":
        return Colors.green;


      default:
        return Colors.grey;

    }

  }


}