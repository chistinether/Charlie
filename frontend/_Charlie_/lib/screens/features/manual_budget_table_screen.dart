import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/test_users.dart';
import '../../models/user_budget.dart';

import '../../widgets/budget_table.dart';
import '../../widgets/speak_button.dart';
import '../../services/budget_analyzer_service.dart';
import '../../services/charlie_budget_advisor.dart';
import '../../services/firebase_service.dart';
import '../../providers/budget_provider.dart';



class ManualBudgetTableScreen extends StatefulWidget {


  final TestUser user;

  final UserBudget budget;



  const ManualBudgetTableScreen({

    super.key,

    required this.user,

    required this.budget,

  });



  @override
  State<ManualBudgetTableScreen> createState() =>
      _ManualBudgetTableScreenState();

}









class _ManualBudgetTableScreenState
    extends State<ManualBudgetTableScreen> {





  double get totalAllocated {


    return widget.budget.items.fold(

      0,

      (sum,item)=>
          sum + item.allocatedAmount,

    );


  }







  double get remaining {


    return widget.budget.totalIncome -
        totalAllocated;


  }







  void showMessage(String message){


    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        content: Text(message),

        behavior:
        SnackBarBehavior.floating,

      ),

    );


  }









  Future<void> recycleBudget() async {

    final provider =
    Provider.of<BudgetProvider>(
      context,
      listen: false,
    );

    provider.setBudget(widget.budget);

    final oldBudget = widget.budget;
    final newBudget = provider.recycleBudget();

    if (newBudget != null) {
      // Keep the user object, provider, and Firebase all pointing at
      // the same budget so nothing appears to "disappear" later.
      widget.user.budget = newBudget;
      widget.user.budgetHistory.add(oldBudget);

      try {
        await FirebaseService.saveBudget(newBudget);
        await FirebaseService.archiveBudget(oldBudget);
      } catch (e) {
        debugPrint("Could not save recycled budget: $e");
      }

      showMessage("Budget recycled successfully");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ManualBudgetTableScreen(
            user: widget.user,
            budget: newBudget,
          ),
        ),
      );
    }
  }









  Future<void> reviewAndSaveBudget() async {
    if (widget.budget.items.isEmpty) {
      showMessage("Add at least one budget item before saving.");
      return;
    }

    final List<String> suggestions = [
      BudgetAnalyzerService.analyze(widget.budget),
      // Always show the daily safe-spending guidance, not only when the
      // user is already off pace. This is what tells them e.g. "spend
      // about UGX X per day and you won't run out before <date>" from
      // the moment they save the budget, not just once they've started
      // overspending.
      widget.budget.paceMessage,
      ...CharlieBudgetAdvisor.generateAdvice(widget.budget),
    ];

    if (!mounted) return;

    final bool? confirmedSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Charlie's Suggestions"),
            SpeakButton(text: suggestions.join(". ")),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Before you save this budget, here's what Charlie "
                "thinks of it:",
              ),
              const SizedBox(height: 12),
              for (final suggestion in suggestions) ...[
                Text(suggestion),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep Editing"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Save Budget"),
          ),
        ],
      ),
    );

    if (confirmedSave != true) {
      return;
    }

    try {
      await FirebaseService.saveBudget(widget.budget);
    } catch (e) {
      debugPrint("Could not save budget: $e");
    }

    if (!mounted) return;

    showMessage("Budget saved successfully");
    Navigator.pop(context);
  }

  Widget aiAdvisorCard(){



    final analysis =
    BudgetAnalyzerService.analyze(

        widget.budget

    );






    final status =
    widget.budget.status;







    Color statusColor = Colors.green;





    if(status == "Exceeded"){


      statusColor = Colors.red;


    }

    else if(status == "Warning"){


      statusColor = Colors.orange;


    }









    return Container(


      width:
      double.infinity,


      padding:
      const EdgeInsets.all(16),



      margin:
      const EdgeInsets.only(

          bottom:15

      ),





      decoration:

      BoxDecoration(

        color:
        Colors.white,


        borderRadius:
        BorderRadius.circular(15),


      ),






      child:

      Column(


        crossAxisAlignment:
        CrossAxisAlignment.start,





        children:[





          Row(


            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,



            children:[




              const Text(

                "Charlie AI Advisor",

                style:

                TextStyle(

                  fontSize:20,

                  fontWeight:
                  FontWeight.bold,

                ),

              ),






              Text(

                status,

                style:

                TextStyle(

                  color:
                  statusColor,

                  fontWeight:
                  FontWeight.bold,

                ),

              ),



            ],


          ),







          const SizedBox(height:12),








          Text(

            analysis,

            style:

            const TextStyle(

              fontWeight:
              FontWeight.w600,

            ),

          ),





          const SizedBox(height:12),






          Text(

            widget.budget.aiAdvice,

            style:

            const TextStyle(

              fontSize:14,

            ),

          ),







        ],


      ),


    );


  }









  Widget summaryCard(){



    return Container(


      width:
      double.infinity,


      padding:
      const EdgeInsets.all(16),




      margin:
      const EdgeInsets.only(

          bottom:15

      ),






      decoration:

      BoxDecoration(

        color:
        Colors.white,


        borderRadius:
        BorderRadius.circular(15),


      ),






      child:

      Column(


        crossAxisAlignment:
        CrossAxisAlignment.start,





        children:[





          const Text(

            "Budget Summary",

            style:

            TextStyle(

              fontSize:20,

              fontWeight:
              FontWeight.bold,

            ),

          ),






          const SizedBox(height:10),








          Text(

            "Income: UGX "
                "${widget.budget.totalIncome.toInt()}",

          ),








          Text(

            "Allocated: UGX "
                "${totalAllocated.toInt()}",

          ),








          Text(

            "Remaining: UGX "
                "${remaining.toInt()}",

          ),







          Text(

            "Budget Health: "
                "${widget.budget.budgetHealth}",

          ),





        ],


      ),


    );


  }









  @override
  Widget build(BuildContext context){



    return Scaffold(






      appBar:

      AppBar(


        title:

        const Text(

            "Manual Budget Table"

        ),




        backgroundColor:

        const Color(0xFF2E7D32),





        actions:[





          IconButton(

            onPressed:
            recycleBudget,



            icon:

            const Icon(

                Icons.refresh

            ),




            tooltip:

            "Recycle Budget",



          ),



        ],



      ),







      body:

      SingleChildScrollView(



        padding:

        const EdgeInsets.all(15),





        child:


        Column(




          children:[




            aiAdvisorCard(),





            summaryCard(),






            BudgetTable(



              budget:

              widget.budget,



              user:

              widget.user,



              onUpdated:


                  (){


                setState((){});


              },


            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: reviewAndSaveBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white, // Text and icon color
                ),
                child: const Text("SAVE BUDGET"),
              ),
            ),







          ],



        ),




      ),







    );


  }


}