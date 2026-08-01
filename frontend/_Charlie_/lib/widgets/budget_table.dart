import 'package:flutter/material.dart';

import '../models/user_budget.dart';
import '../models/budget_item.dart';
import '../models/test_users.dart';
import '../utils/id_generator.dart';
import '../services/firebase_service.dart';
import '../services/charlie_budget_advisor.dart';
import 'speak_button.dart';



class BudgetTable extends StatefulWidget {


  final UserBudget budget;

  final TestUser user;

  final VoidCallback? onUpdated;



  const BudgetTable({

    super.key,

    required this.budget,

    required this.user,

    this.onUpdated,

  });



  @override
  State<BudgetTable> createState() =>
      _BudgetTableState();

}









class _BudgetTableState extends State<BudgetTable> {
 String aiMessage =
     "Charlie is monitoring your budget...";



 void addNewRow() {

   setState(() {

     widget.budget.items.add(

       BudgetItem(

         id: IdGenerator.next(),

         name: "",

         category: "",

         quantity: 1,

         unit: "Item",

         unitCost: 0,

         allocatedAmount: 0,

         spentAmount: 0,

         isAI: false,

       ),

     );

     updateCharlieAdvice();

   });

   widget.onUpdated?.call();
   _persistBudget();

 }

 void deleteItem(int index) {
   setState(() {
     widget.budget.items.removeAt(index);
     updateCharlieAdvice();
   });
   widget.onUpdated?.call();
   _persistBudget();
 }

 Future<void> _persistBudget() async {
   try {
     await FirebaseService.saveBudget(widget.budget);
   } catch (e) {
     debugPrint("Could not save budget: $e");
   }
 }

 Future<void> _syncTotals() async {
   try {
     await FirebaseService.syncTotals(
       balance: widget.user.balance,
       income: widget.user.income,
       expenses: widget.user.expenses,
     );
   } catch (e) {
     debugPrint("Could not sync totals: $e");
   }
 }

 void updateCharlieAdvice() {

   if (widget.budget.items.isEmpty) {
     aiMessage = "Start by adding your first budget item.";
     return;
   }

   if (widget.budget.overBudget) {
     aiMessage =
         "⚠ Your planned budget exceeds your income.";
     return;
   }

   if (widget.budget.isPacedToRunOutEarly) {
     aiMessage = widget.budget.paceMessage;
     return;
   }

   final advice = CharlieBudgetAdvisor.generateAdvice(widget.budget);

   if (advice.isEmpty) {
     aiMessage = widget.budget.aiAdvice;
   } else if (advice.length == 1) {
     aiMessage = advice.first;
   } else {
     aiMessage = "${advice[0]}\n\n${advice[1]}";
   }
 }


  void editItemDialog(BudgetItem item){



    final name =
    TextEditingController(
        text:item.name
    );


    final category =
    TextEditingController(
        text:item.category
    );


    final quantity =
    TextEditingController(
        text:item.quantity.toString()
    );


    final cost =
    TextEditingController(
        text:item.unitCost.toString()
    );





    showDialog(


      context:context,


      builder:(context)=>AlertDialog(


        title:
        const Text(
          "Edit Budget Item",
        ),





        content:

        SingleChildScrollView(

          child:Column(

            children:[



              TextField(

                controller:name,

                decoration:
                const InputDecoration(
                    labelText:"Item"
                ),

              ),




              TextField(

                controller:category,

                decoration:
                const InputDecoration(
                    labelText:"Category"
                ),

              ),




              TextField(

                controller:quantity,

                keyboardType:
                TextInputType.number,

                decoration:
                const InputDecoration(
                    labelText:"Quantity"
                ),

              ),





              TextField(

                controller:cost,

                keyboardType:
                TextInputType.number,

                decoration:
                const InputDecoration(
                  labelText:"Unit Cost",
                  prefixText:"UGX ",
                ),

              ),



            ],

          ),

        ),






        actions:[



          TextButton(

            onPressed:
                ()=>Navigator.pop(context),


            child:
            const Text(
              "Cancel",
            ),

          ),





          ElevatedButton(


            onPressed:(){



              setState(() {

                item.name = name.text;

                item.category = category.text;

                item.updateQuantity(
                    double.tryParse(quantity.text) ?? 1);

                item.updateUnitCost(
                    double.tryParse(cost.text) ?? 0);

                updateCharlieAdvice();

              });


              widget.onUpdated?.call();
              _persistBudget();


              Navigator.pop(context);



            },


            child:
            const Text(
              "Save",
            ),

          ),



        ],


      ),



    );


  }









 Widget header(String text) {
   return Container(
     alignment: Alignment.center,
     width: 130,
     padding: const EdgeInsets.symmetric(
       vertical: 14,
       horizontal: 8,
     ),
     decoration: BoxDecoration(
       color: Colors.green.shade700,
       border: Border.all(
         color: Colors.grey.shade400,
       ),
     ),
     child: Text(
       text,
       textAlign: TextAlign.center,
       style: const TextStyle(
         color: Colors.white,
         fontWeight: FontWeight.bold,
         fontSize: 14,
       ),
     ),
   );
 }

 Widget editableCell({
   required String value,
   required Function(String) onChanged,
   TextInputType keyboard = TextInputType.text,
 }) {
   final controller = TextEditingController(text: value);

   controller.selection = TextSelection.fromPosition(
     TextPosition(offset: controller.text.length),
   );

   return SizedBox(
     width: 130,
     child: TextField(
       controller: controller,
       keyboardType: keyboard,
       decoration: const InputDecoration(
         border: InputBorder.none,
         contentPadding: EdgeInsets.symmetric(
           horizontal: 8,
           vertical: 12,
         ),
       ),
       onChanged: onChanged,
     ),
   );
 }


  @override
  Widget build(BuildContext context){



    return Column(


      children:[




        Row(


          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,


          children:[




            Expanded(
              child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children:[

                Text(

                  "Total Budget : UGX ${widget.budget.totalAllocated.toStringAsFixed(0)}",

                  style: const TextStyle(

                    fontWeight: FontWeight.bold,

                    fontSize:16,

                  ),

                ),

                Container(

                  width: double.infinity,

                  margin: const EdgeInsets.only(bottom: 12),

                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(

                    color: Colors.green.shade50,

                    borderRadius: BorderRadius.circular(10),

                    border: Border.all(

                      color: Colors.green,

                    ),

                  ),

                  child: Row(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      const Icon(

                        Icons.smart_toy,

                        color: Colors.green,

                      ),

                      const SizedBox(width: 10),

                      Expanded(

                        child: Text(

                          aiMessage,

                          style: const TextStyle(

                            fontWeight: FontWeight.w500,

                          ),

                        ),

                      ),

                      SpeakButton(text: aiMessage),

                    ],

                  ),

                ),

                const SizedBox(height:4),

                Text(

                  "Income : UGX ${widget.budget.totalIncome.toStringAsFixed(0)}",

                ),

                Text(

                  "Remaining : UGX ${widget.budget.remainingIncome.toStringAsFixed(0)}",

                  style: TextStyle(

                    color: widget.budget.remainingIncome < 0

                        ? Colors.red

                        : Colors.green,

                  ),

                ),

              ],

            ),
            ),





            ElevatedButton.icon(

              onPressed: addNewRow,

              icon: const Icon(Icons.add),

              label: const Text("New Row"),

              style: ElevatedButton.styleFrom(

                backgroundColor: Colors.green,

                foregroundColor: Colors.white,

              ),

            ),


          ],


        ),







        const SizedBox(
          height:15,
        ),







        SingleChildScrollView(


          scrollDirection:
          Axis.horizontal,



          child:

            DataTable(



              border:

                TableBorder.all(

                  color:
                  Colors.grey,

                ),





                columns:[



                  DataColumn(
                      label:
                      header("Item")
                  ),


                  DataColumn(
                      label:
                      header("Category")
                  ),



                  DataColumn(
                      label:
                      header("Qty")
                  ),



                  DataColumn(
                      label:
                      header("Unit")
                  ),




                  DataColumn(
                      label:
                      header("Unit Cost")
                  ),




                  DataColumn(
                      label:
                      header("Total")
                  ),




                  DataColumn(
                      label:
                      header("Spent")
                  ),

                  DataColumn(
                    label: header("Status"),
                  ),


                  DataColumn(
                      label:
                      header("Action")
                  ),



                ],







                rows:



                List.generate(


                  widget.budget.items.length,


                      (index){



                    final item =
                    widget.budget.items[index];





                    return DataRow(



                      cells: [

                        //================ ITEM ===================

                        DataCell(

                          editableCell(

                            value: item.name,

                            onChanged: (value){

                              item.name = value;

                              widget.onUpdated?.call();
                              _persistBudget();

                            },

                          ),

                        ),



                        //================ CATEGORY ===================

                        DataCell(

                          editableCell(

                            value: item.category,

                            onChanged: (value){

                              item.category = value;

                              widget.onUpdated?.call();
                              _persistBudget();

                            },

                          ),

                        ),



                        //================ QUANTITY ===================

                        DataCell(

                          editableCell(

                            value: item.quantity.toString(),

                            keyboard: TextInputType.number,

                            onChanged: (value){

                              item.updateQuantity(

                                double.tryParse(value) ?? 0,

                              );



                              setState(() {

                                updateCharlieAdvice();

                              });

                              widget.onUpdated?.call();
                              _persistBudget();

                            },

                          ),

                        ),



                        //================ UNIT ===================

                        DataCell(

                          editableCell(

                            value: item.unit,

                            onChanged: (value){

                              item.unit = value;

                              widget.onUpdated?.call();
                              _persistBudget();

                            },

                          ),

                        ),



                        //================ UNIT COST ===================

                        DataCell(

                          editableCell(

                            value: item.unitCost.toString(),

                            keyboard: TextInputType.number,

                            onChanged: (value){

                              item.updateUnitCost(

                                double.tryParse(value) ?? 0,

                              );



                              setState(() {

                                updateCharlieAdvice();

                              });

                              widget.onUpdated?.call();
                              _persistBudget();

                            },

                          ),

                        ),
                        //================ TOTAL ===================

                        DataCell(

                          Container(

                            width: 130,

                            alignment: Alignment.centerRight,

                            padding: const EdgeInsets.symmetric(horizontal: 8),

                            child: Text(

                              "UGX ${item.allocatedAmount.toStringAsFixed(0)}",

                              style: const TextStyle(

                                fontWeight: FontWeight.bold,

                              ),

                            ),

                          ),

                        ),



                        //================ SPENT ===================

                        DataCell(

                          editableCell(

                            value: item.spentAmount.toString(),

                            keyboard: TextInputType.number,

                            onChanged: (value){

                              final newSpent = double.tryParse(value) ?? 0;
                              final delta = newSpent - item.spentAmount;

                              item.spentAmount = newSpent;

                              if (delta != 0) {
                                widget.user.expenses += delta;
                                widget.user.balance -= delta;

                                widget.user.transactions.add(
                                  TransactionModel(
                                    title: item.name.isEmpty ? "Budget item" : item.name,
                                    category: item.category,
                                    amount: delta.abs(),
                                    isIncome: delta < 0,
                                    date: DateTime.now(),
                                  ),
                                );

                                _syncTotals();
                              }



                             setState(() {

                               updateCharlieAdvice();

                             });

                              widget.onUpdated?.call();
                              _persistBudget();

                            },

                          ),

                        ),



                        //================ STATUS ===================

                        DataCell(

                          Container(

                            width:130,

                            alignment:Alignment.center,

                            child: Text(

                              item.status,

                              style: TextStyle(

                                fontWeight: FontWeight.bold,

                                color:

                                item.isExceeded

                                    ? Colors.red

                                    : item.isNearLimit

                                        ? Colors.orange

                                        : Colors.green,

                              ),

                            ),

                          ),

                        ),



                        //================ EDIT / DELETE ===================

                        DataCell(

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: "Edit",
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: (){
                                  editItemDialog(item);
                                },
                              ),
                              IconButton(
                            tooltip: "Delete",

                            icon: const Icon(

                              Icons.delete,

                              color: Colors.red,

                            ),

                            onPressed: (){

                              deleteItem(index);

                            },

                              ),
                            ],
                          ),

                        ),

                      ],


                    );


                  },


                ),




              ),






          ),






      ],


    );


  }



}