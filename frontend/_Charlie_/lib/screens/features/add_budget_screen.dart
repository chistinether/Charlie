import 'package:flutter/material.dart';

import '../../models/test_users.dart';
import '../../models/user_budget.dart';
import '../../utils/id_generator.dart';
import '../features/manual_budget_table_screen.dart';
import '../../services/firebase_service.dart';
import '../../services/budget_recycle_service.dart';


class AddBudgetScreen extends StatefulWidget {

  final TestUser user;

  const AddBudgetScreen({
    super.key,
    required this.user,
  });


  @override
  State<AddBudgetScreen> createState() =>
      _AddBudgetScreenState();

}



class _AddBudgetScreenState extends State<AddBudgetScreen>{


  final purposeController =
      TextEditingController();


  final incomeController =
      TextEditingController();



  String selectedPeriod = "Monthly";


  final periods = [

    "Weekly",
    "Monthly",
    "Semester",
    "Yearly",

  ];



  @override
  void initState(){

    super.initState();

    incomeController.text =
        widget.user.income.toStringAsFixed(0);

  }



  @override
  void dispose(){

    purposeController.dispose();

    incomeController.dispose();

    super.dispose();

  }




  DateTime getEndDate(){


    switch(selectedPeriod){


      case "Weekly":

        return DateTime.now()
            .add(const Duration(days:7));


      case "Semester":

        return DateTime.now()
            .add(const Duration(days:120));


      case "Yearly":

        return DateTime.now()
            .add(const Duration(days:365));


      default:

        return DateTime.now()
            .add(const Duration(days:30));


    }

  }





  Future<void> createBudget() async {

    double income =
        double.tryParse(
          incomeController.text,
        ) ?? 0;

    if (purposeController.text.trim().isEmpty || income <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter valid budget details"),
        ),
      );
      return;
    }

    UserBudget budget;
    bool useTemplate = false;

    if (widget.user.budgetHistory.isNotEmpty) {
      final previous = widget.user.budgetHistory.last;

      useTemplate = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Use a previous budget?"),
              content: Text(
                "You have a saved budget (\"${previous.purpose}\"). "
                "Would you like Charlie to auto-fill your items from "
                "it, rescaled to your new income?",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Start blank"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Use previous budget"),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (useTemplate) {
      final previous = widget.user.budgetHistory.last;

      budget = BudgetRecycleService.recycleBudget(previous, income);
      budget.purpose = purposeController.text.trim();
      budget.startDate = DateTime.now();
      budget.endDate = getEndDate();
    } else {
      budget = UserBudget(
        id: IdGenerator.next(),
        purpose: purposeController.text.trim(),
        totalIncome: income,
        startDate: DateTime.now(),
        endDate: getEndDate(),
        items: [],
        isAI: false,
      );
    }

    // Archive whatever budget the user had before, so it stays
    // available for future auto-fill / recycle, and is never just
    // silently overwritten.
    if (widget.user.budget != null) {
      final oldBudget = widget.user.budget!;
      widget.user.budgetHistory.add(oldBudget);

      try {
        await FirebaseService.archiveBudget(oldBudget);
      } catch (e) {
        debugPrint("Could not archive previous budget: $e");
      }
    }

    widget.user.budget = budget;

    try {
      await FirebaseService.saveBudget(budget);
    } catch (e) {
      debugPrint("Could not save budget: $e");
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ManualBudgetTableScreen(
          user: widget.user,
          budget: budget,
        ),
      ),
    );
  }






  @override
  Widget build(BuildContext context){


    return Scaffold(


      appBar:AppBar(

        title:
        const Text(
            "Create Manual Budget"
        ),

        backgroundColor:
        const Color(0xFF2E7D32),

      ),




      body:

      Padding(

        padding:
        const EdgeInsets.all(20),


        child:

        Column(


          children:[



            TextField(

              controller:
              purposeController,


              decoration:

              const InputDecoration(

                labelText:
                "Budget Purpose",

                border:
                OutlineInputBorder(),

              ),

            ),



            const SizedBox(height:20),



            TextField(

              controller:
              incomeController,


              keyboardType:
              TextInputType.number,


              decoration:

              const InputDecoration(

                labelText:
                "Available Income",

                prefixText:
                "UGX ",

                border:
                OutlineInputBorder(),

              ),

            ),



            const SizedBox(height:20),



            DropdownButtonFormField<String>(


              value:selectedPeriod,


              items:

              periods.map((e)=>

                  DropdownMenuItem(

                    value:e,

                    child:
                    Text(e),

                  )

              ).toList(),



              onChanged:(value){

                setState((){

                  selectedPeriod=value!;

                });

              },


              decoration:

              const InputDecoration(

                labelText:
                "Duration",

                border:
                OutlineInputBorder(),

              ),


            ),




            const Spacer(),



            SizedBox(

              width:
              double.infinity,


              height:55,


              child:

              ElevatedButton(
                onPressed: createBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white, // Makes the text white
                ),
                child: const Text(
                  "CONTINUE",
                ),
              ),

            )


          ],

        ),

      ),

    );


  }



}