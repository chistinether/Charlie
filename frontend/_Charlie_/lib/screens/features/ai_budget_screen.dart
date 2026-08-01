import 'package:flutter/material.dart';

import '../../models/test_users.dart';
import '../../models/user_budget.dart';
import '../../models/budget_item.dart';
import '../../utils/id_generator.dart';

import '../../widgets/budget_table.dart';
import '../../widgets/voice_mic_button.dart';
import '../../widgets/speak_button.dart';

import '../../services/gemini_budget_service.dart';

import '../../services/firebase_service.dart';



class AIBudgetScreen extends StatefulWidget {


  final TestUser user;


  const AIBudgetScreen({

    super.key,

    required this.user,

  });



  @override
  State<AIBudgetScreen> createState() =>
      _AIBudgetScreenState();

}




class _AIBudgetScreenState extends State<AIBudgetScreen> {


  final TextEditingController purposeController =
      TextEditingController();


  final TextEditingController incomeController =
      TextEditingController();


  final TextEditingController durationController =
      TextEditingController();



  UserBudget? generatedBudget;


  bool loading = false;

  bool savingBudget = false;




  @override
  void dispose(){


    purposeController.dispose();

    incomeController.dispose();

    durationController.dispose();


    super.dispose();

  }





  void showMessage(String message){


    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(message),

      ),

    );


  }





  Future<void> generateBudget() async {


    if(purposeController.text.trim().isEmpty){


      showMessage(
        "Enter budget purpose",
      );


      return;

    }



    double income =
        incomeController.text.trim().isEmpty

            ?

        widget.user.income

            :

        double.tryParse(
          incomeController.text,
        ) ?? 0;



    int duration =
        int.tryParse(
          durationController.text,
        ) ?? 0;



    if(income <= 0 || duration <= 0){


      showMessage(
        "Enter valid income and duration",
      );


      return;

    }



    setState((){

      loading = true;

    });



    try{


      final budget =
          await GeminiBudgetService.generateBudget(

            purpose:
            purposeController.text.trim(),


            income:
            income,


            durationDays:
            duration,


          );



      setState((){


        generatedBudget = budget;


      });



    }
    catch(e){


      showMessage(
        "AI Error: $e",
      );


    }
    finally{


      setState((){

        loading = false;

      });


    }


  }







  double get totalAllocated{


    if(generatedBudget == null){

      return 0;

    }



    return generatedBudget!.items.fold(

      0,

          (sum,item)=>

      sum + item.allocatedAmount,

    );


  }




  double get remainingAmount{


    if(generatedBudget == null){

      return 0;

    }


    return generatedBudget!.totalIncome -
        totalAllocated;


  }





  double get allocationPercentage{


    if(generatedBudget == null ||
        generatedBudget!.totalIncome <=0){

      return 0;

    }


    return totalAllocated /
        generatedBudget!.totalIncome;


  }
    Future<void> saveBudget() async {


      if(generatedBudget == null){

        return;

      }



      final newBudget = UserBudget(


        id: IdGenerator.next(),



        purpose: generatedBudget!.purpose,



        totalIncome: generatedBudget!.totalIncome,



        startDate: generatedBudget!.startDate,



        endDate: generatedBudget!.endDate,



        items: generatedBudget!.items,



        isAI: true,


      );

      final oldBudget = widget.user.budget;

      setState((){
        savingBudget = true;
      });

      try {
        await FirebaseService.saveBudget(newBudget);

        // Keep a copy of whatever budget this is replacing so it still
        // shows up in "recycle a previous budget" flows later, the same
        // way the manual budget flow archives on recycle.
        if (oldBudget != null) {
          await FirebaseService.archiveBudget(oldBudget);
          widget.user.budgetHistory.add(oldBudget);
        }

        widget.user.budget = newBudget;

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            content: Text(
              "AI Budget saved successfully",
            ),

          ),

        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not save budget: $e")),
        );
      } finally {
        if (mounted) {
          setState((){
            savingBudget = false;
          });
        }
      }

    }









    void editItem(BudgetItem item){



      final nameController =
          TextEditingController(
            text: item.name,
          );



      final categoryController =
          TextEditingController(
            text: item.category,
          );



      final amountController =
          TextEditingController(
            text: item.allocatedAmount
                .toStringAsFixed(0),
          );







      showDialog(

        context: context,

        builder:(context){


          return AlertDialog(


            title:
            const Text(
              "Edit Budget Item",
            ),




            content:

            Column(

              mainAxisSize:
              MainAxisSize.min,


              children:[



                TextField(

                  controller:
                  nameController,


                  decoration:
                  const InputDecoration(

                    labelText:
                    "Item Name",

                  ),

                ),




                TextField(

                  controller:
                  categoryController,


                  decoration:
                  const InputDecoration(

                    labelText:
                    "Category",

                  ),

                ),




                TextField(

                  controller:
                  amountController,


                  keyboardType:
                  TextInputType.number,


                  decoration:
                  const InputDecoration(

                    labelText:
                    "Amount",

                    prefixText:
                    "UGX ",

                  ),

                ),


              ],


            ),





            actions:[



              TextButton(

                onPressed:(){

                  Navigator.pop(context);

                },


                child:
                const Text(
                  "Cancel",
                ),


              ),






              ElevatedButton(

                onPressed:(){


                  setState((){


                    item.name =
                        nameController.text.trim();



                    item.category =
                        categoryController.text.trim();




                    item.allocatedAmount =
                        double.tryParse(
                          amountController.text,
                        )

                            ??

                        item.allocatedAmount;



                    item.unitCost =
                        item.quantity <=0

                            ?

                        item.allocatedAmount

                            :

                        item.allocatedAmount /
                            item.quantity;



                  });



                  Navigator.pop(context);


                },


                child:
                const Text(
                  "Save",
                ),


              ),


            ],


          );


        },


      );


    }









    void addItem(){



      if(generatedBudget == null){

        return;

      }




      setState((){


        generatedBudget!.items.add(


          BudgetItem(

            id: IdGenerator.next(),


            name:
            "New Item",


            category:
            "Other",


            quantity:
            1,


            unit:
            "item",


            unitCost:
            0,


            allocatedAmount:
            0,


            spentAmount:
            0,


            isAI:
            false,


          ),


        );


      });


    }








    void deleteItem(BudgetItem item){



      if(generatedBudget == null){

        return;

      }




      setState((){


        generatedBudget!.items.remove(item);


      });



    }
      Widget aiAdvisorCard(){


        if(generatedBudget == null){

          return const SizedBox();

        }



        final budget = generatedBudget!;




        return Container(


          width:
          double.infinity,


          margin:
          const EdgeInsets.only(
            top:20,
          ),



          padding:
          const EdgeInsets.all(16),




          decoration:
          BoxDecoration(


            color:
            Colors.orange.withValues(
              alpha:0.12,
            ),



            borderRadius:
            BorderRadius.circular(12),


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

                  SpeakButton(
                    text:
                    "${budget.paceMessage} "
                    "Recommended daily spending: UGX ${budget.recommendedDailySpend.toInt()}. "
                    "${budget.isPacedToRunOutEarly ? 'Your current spending pace may finish your money before the budget period ends.' : 'Your spending pace looks healthy.'}",
                  ),

                ],

              ),





              const SizedBox(
                height:12,
              ),





              Text(

                budget.paceMessage,

                style:
                const TextStyle(

                  fontSize:15,

                ),

              ),





              const SizedBox(
                height:12,
              ),





              Text(

                "Recommended daily spending: UGX ${budget.recommendedDailySpend.toInt()}",


                style:
                const TextStyle(

                  fontWeight:
                  FontWeight.bold,

                ),


              ),





              const SizedBox(
                height:12,
              ),





              Text(

                budget.isPacedToRunOutEarly

                    ?

                "⚠️ Your current spending pace may finish your money before the budget period ends."

                    :

                "✅ Your spending pace looks healthy.",



                style:

                TextStyle(


                  color:

                  budget.isPacedToRunOutEarly

                      ?

                  Colors.red

                      :

                  Colors.green,



                  fontWeight:
                  FontWeight.bold,


                ),



              ),



            ],



          ),



        );


      }









      Widget budgetItemCard(BudgetItem item){


        return Card(



          margin:

          const EdgeInsets.only(
            bottom:12,
          ),




          child:

          Padding(



            padding:
            const EdgeInsets.all(15),




            child:

            Column(



              crossAxisAlignment:
              CrossAxisAlignment.start,



              children:[



                Row(



                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,



                  children:[



                    Expanded(



                      child:

                      Text(


                        item.name,


                        style:

                        const TextStyle(

                          fontSize:18,

                          fontWeight:
                          FontWeight.bold,

                        ),


                      ),


                    ),




                    IconButton(

                      onPressed:(){

                        editItem(item);

                      },


                      icon:
                      const Icon(
                        Icons.edit,
                      ),


                    ),





                    IconButton(

                      onPressed:(){

                        deleteItem(item);

                      },


                      icon:

                      const Icon(
                        Icons.delete,
                      ),


                    ),



                  ],



                ),






                Text(


                  item.category,


                  style:

                  const TextStyle(

                    color:
                    Colors.grey,

                  ),



                ),






                const SizedBox(
                  height:10,
                ),






                LinearProgressIndicator(


                  value:

                  item.progress > 1

                      ?

                  1

                      :

                  item.progress,


                ),






                const SizedBox(
                  height:8,
                ),






                Row(



                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,



                  children:[



                    Text(

                      "UGX ${item.spentAmount.toInt()} / ${item.allocatedAmount.toInt()}",


                    ),






                    Text(


                      item.status,


                      style:

                      TextStyle(


                        fontWeight:
                        FontWeight.bold,



                        color:


                        item.isExceeded

                            ?

                        Colors.red

                            :

                        Colors.green,


                      ),


                    ),



                  ],



                ),



              ],



            ),



          ),



        );


      }
        @override
        Widget build(BuildContext context) {


          return Scaffold(


            appBar:

            AppBar(

              title:

              const Text(

                "Charlie AI Budget",

              ),

            ),





            body:

            SingleChildScrollView(


              padding:

              const EdgeInsets.all(20),




              child:

              Column(


                crossAxisAlignment:

                CrossAxisAlignment.start,




                children:[





                  TextField(


                    controller:

                    purposeController,



                    decoration:

                    InputDecoration(


                      labelText:

                      "Budget Purpose",


                      border:

                      const OutlineInputBorder(),


                      suffixIcon:

                      VoiceMicButton(controller: purposeController),


                    ),


                  ),






                  const SizedBox(
                    height:15,
                  ),






                  TextField(


                    controller:

                    incomeController,



                    keyboardType:

                    TextInputType.number,




                    decoration:

                    const InputDecoration(


                      labelText:

                      "Income Amount",


                      prefixText:

                      "UGX ",


                      border:

                      OutlineInputBorder(),


                    ),


                  ),







                  const SizedBox(
                    height:15,
                  ),







                  TextField(


                    controller:

                    durationController,



                    keyboardType:

                    TextInputType.number,




                    decoration:

                    const InputDecoration(


                      labelText:

                      "Duration Days",


                      border:

                      OutlineInputBorder(),


                    ),


                  ),






                  const SizedBox(
                    height:20,
                  ),








                  SizedBox(


                    width:

                    double.infinity,




                    child:

                    ElevatedButton(


                      onPressed:

                      loading

                          ?

                      null

                          :

                      generateBudget,




                      child:

                      loading

                          ?

                      const CircularProgressIndicator()

                          :

                      const Text(

                        "GENERATE AI BUDGET",

                      ),



                    ),



                  ),






                  const SizedBox(
                    height:30,
                  ),







                  if(generatedBudget != null)...[





                    Row(



                      mainAxisAlignment:

                      MainAxisAlignment.spaceBetween,




                      children:[



                        const Text(


                          "AI Generated Budget",



                          style:

                          TextStyle(


                            fontSize:22,


                            fontWeight:

                            FontWeight.bold,


                          ),



                        ),





                        IconButton(



                          onPressed:

                          addItem,



                          icon:

                          const Icon(

                            Icons.add,

                          ),



                        ),



                      ],



                    ),








                    BudgetTable(


                      budget:

                      generatedBudget!,



                      user:

                      widget.user,



                      onUpdated:

                          () => setState((){}),


                    ),







                    const SizedBox(
                      height:20,
                    ),







                    Container(



                      width:

                      double.infinity,




                      padding:

                      const EdgeInsets.all(16),




                      decoration:

                      BoxDecoration(



                        color:

                        Colors.green.withValues(

                          alpha:0.1,

                        ),




                        borderRadius:

                        BorderRadius.circular(12),



                      ),




                      child:

                      Column(



                        crossAxisAlignment:

                        CrossAxisAlignment.start,




                        children:[




                          Text(


                            "Income: UGX ${generatedBudget!.totalIncome.toInt()}",



                            style:

                            const TextStyle(



                              fontSize:18,


                              fontWeight:

                              FontWeight.bold,



                            ),



                          ),






                          const SizedBox(
                            height:10,
                          ),






                          Text(



                            "Allocated: UGX ${totalAllocated.toInt()}",




                            style:

                            const TextStyle(



                              fontSize:17,


                              fontWeight:

                              FontWeight.bold,



                            ),



                          ),






                          const SizedBox(
                            height:10,
                          ),






                          Text(



                            "Remaining: UGX ${remainingAmount.toInt()}",




                            style:

                            TextStyle(



                              fontSize:17,


                              fontWeight:

                              FontWeight.bold,



                              color:

                              remainingAmount < 0

                                  ?

                              Colors.red

                                  :

                              Colors.blue,



                            ),



                          ),






                          const SizedBox(
                            height:15,
                          ),






                          LinearProgressIndicator(



                            value:

                            allocationPercentage > 1

                                ?

                            1

                                :

                            allocationPercentage,



                          ),



                        ],



                      ),



                    ),







                    // Charlie AI Advisor appears ONLY here
                    aiAdvisorCard(),







                    const SizedBox(
                      height:20,
                    ),







                    SizedBox(



                      width:

                      double.infinity,




                      child:

                      ElevatedButton(



                        onPressed:

                        (remainingAmount < 0 || savingBudget)

                            ?

                        null

                            :

                        saveBudget,




                        child:

                        savingBudget
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(

                          "SAVE AI BUDGET",

                        ),



                      ),



                    ),





                  ],





                ],



              ),



            ),



          );

        }


      }