import 'package:flutter/material.dart';

import '../../models/test_users.dart';
import '../../services/budget_analyzer_service.dart';



class BudgetNotificationsScreen extends StatelessWidget {


  final TestUser user;



  const BudgetNotificationsScreen({

    super.key,

    required this.user,

  });





  @override
  Widget build(BuildContext context) {


    final messages = [
    BudgetAnalyzerService.analyze(user.budget!)
    ];





    return Scaffold(


      backgroundColor:
      const Color(0xFFF5F7FA),



      appBar: AppBar(


        backgroundColor:
        const Color(0xFF2E7D32),



        title:
        const Text(

          "Budget Insights",

          style:
          TextStyle(

            color:Colors.white,

          ),

        ),

      ),




      body:
      Padding(

        padding:
        const EdgeInsets.all(20),



        child:
        Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,



          children:[



            const Icon(

              Icons.analytics,

              size:60,

              color:
              Color(0xFF2E7D32),

            ),





            const SizedBox(height:20),




            const Text(

              "Charlie Analysis",

              style:
              TextStyle(

                fontSize:26,

                fontWeight:
                FontWeight.bold,

              ),

            ),





            const SizedBox(height:20),





            Expanded(

              child:
              messages.isEmpty


                  ?

              const Center(

                child:
                Text(

                  "No budget data available yet.",

                  style:
                  TextStyle(

                    fontSize:18,

                  ),

                ),

              )



                  :

              ListView.builder(


                itemCount:
                messages.length,



                itemBuilder:
                    (context,index){



                  return Card(



                    margin:
                    const EdgeInsets.only(

                      bottom:15,

                    ),



                    child:
                    ListTile(



                      leading:
                      const CircleAvatar(


                        backgroundColor:
                        Color(0xFF2E7D32),



                        child:
                        Icon(

                          Icons.notifications,

                          color:
                          Colors.white,

                        ),

                      ),





                      title:
                      Text(

                        messages[index],

                      ),



                    ),



                  );


                },

              ),

            ),



          ],


        ),

      ),



    );


  }



}