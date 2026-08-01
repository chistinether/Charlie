import 'package:flutter/material.dart';
import '../../models/test_users.dart';
import '../../services/firebase_service.dart';
import '../../widgets/voice_mic_button.dart';


class AddIncomeScreen extends StatefulWidget {

  final TestUser user;
  final VoidCallback onUpdated;


  const AddIncomeScreen({
    super.key,
    required this.user,
    required this.onUpdated,
  });


  @override
  State<AddIncomeScreen> createState() =>
      _AddIncomeScreenState();
}




class _AddIncomeScreenState extends State<AddIncomeScreen> {


  final TextEditingController amountController =
      TextEditingController();


  final TextEditingController descriptionController =
      TextEditingController();



  String? selectedSource;



  final List<String> incomeSources = [

    "Allowance",
    "Salary",
    "Business",
    "Scholarship",
    "Parents",
    "Other",

  ];




  @override
  void dispose(){

    amountController.dispose();

    descriptionController.dispose();

    super.dispose();

  }





  Future<void> saveIncome() async {


    if(amountController.text.trim().isEmpty ||
        selectedSource == null){


      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content: Text(
            "Please enter income amount and source",
          ),
        ),

      );


      return;

    }





    double? amount =
        double.tryParse(amountController.text.trim());



    if(amount == null || amount <= 0){


      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content: Text(
            "Enter a valid amount",
          ),
        ),

      );


      return;

    }





    // Update financial information

    widget.user.income += amount;

    widget.user.balance += amount;






    // Add income transaction

    widget.user.transactions.add(

      TransactionModel(

        title:

        selectedSource! +

            (descriptionController.text.trim().isNotEmpty

                ? " - ${descriptionController.text.trim()}"

                : ""),


        category: "Income",


        amount: amount,


        isIncome: true,


        date: DateTime.now(),

      ),

    );







    try {
      await FirebaseService.addTransaction(
        TransactionModel(
          title: selectedSource! +
              (descriptionController.text.trim().isNotEmpty
                  ? " - ${descriptionController.text.trim()}"
                  : ""),
          category: "Income",
          amount: amount,
          isIncome: true,
          date: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint("Could not save income: $e");
    }

    widget.onUpdated();






    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(

        content: Text(
          "Income added successfully",
        ),

      ),

    );





    Navigator.pop(context);


  }







  @override
  Widget build(BuildContext context){


    return Scaffold(


      backgroundColor:
      const Color(0xFFF5F7FA),




      appBar: AppBar(


        title:
        const Text(
          "Add Income",
        ),


        backgroundColor:
        const Color(0xFF2E7D32),


        foregroundColor:
        Colors.white,


      ),







      body: SingleChildScrollView(


        padding:
        const EdgeInsets.all(20),




        child: Column(


          children: [






            const Icon(

              Icons.account_balance_wallet,

              size:80,

              color: Color(0xFF2E7D32),

            ),






            const SizedBox(height:25),






            TextField(


              controller: amountController,


              keyboardType:
              TextInputType.number,



              decoration: InputDecoration(


                labelText:
                "Income Amount (UGX)",


                prefixIcon:
                const Icon(Icons.money),


                border:
                OutlineInputBorder(

                  borderRadius:
                  BorderRadius.circular(15),

                ),

              ),

            ),







            const SizedBox(height:20),







            DropdownButtonFormField<String>(


              initialValue: selectedSource,


              decoration: InputDecoration(


                labelText:
                "Income Source",


                prefixIcon:
                const Icon(Icons.category),


                border:
                OutlineInputBorder(

                  borderRadius:
                  BorderRadius.circular(15),

                ),

              ),





              items:

              incomeSources.map((source){


                return DropdownMenuItem<String>(


                  value: source,


                  child:
                  Text(source),


                );


              }).toList(),






              onChanged:(value){


                setState((){


                  selectedSource = value;


                });


              },


            ),








            const SizedBox(height:20),







            TextField(


              controller: descriptionController,


              maxLines:3,



              decoration: InputDecoration(


                labelText:
                "Description (Optional)",


                prefixIcon:
                const Icon(Icons.notes),


                suffixIcon:
                VoiceMicButton(controller: descriptionController),


                border:
                OutlineInputBorder(

                  borderRadius:
                  BorderRadius.circular(15),

                ),


              ),


            ),







            const SizedBox(height:35),







            SizedBox(


              width:
              double.infinity,


              height:
              55,



              child: ElevatedButton(


                onPressed:
                saveIncome,



                style:
                ElevatedButton.styleFrom(


                  backgroundColor:
                  const Color(0xFF2E7D32),



                  shape:
                  RoundedRectangleBorder(

                    borderRadius:
                    BorderRadius.circular(15),

                  ),

                ),





                child:
                const Text(


                  "SAVE INCOME",


                  style:
                  TextStyle(

                    color: Colors.white,

                    fontSize:18,

                    fontWeight:
                    FontWeight.bold,

                  ),


                ),


              ),


            )



          ],


        ),


      ),


    );


  }


}