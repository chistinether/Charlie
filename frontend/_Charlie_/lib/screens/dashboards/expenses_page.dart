import 'package:flutter/material.dart';

import '../../models/test_users.dart';
import '../features/add_expense_screen.dart';



class ExpensesPage extends StatefulWidget {


  final TestUser user;

  final VoidCallback onUpdated;



  const ExpensesPage({

    super.key,

    required this.user,

    required this.onUpdated,

  });



  @override
  State<ExpensesPage> createState() =>
      _ExpensesPageState();

}







class _ExpensesPageState extends State<ExpensesPage> {



  final TextEditingController searchController =
      TextEditingController();



  String searchText = "";







  @override
  void dispose(){

    searchController.dispose();

    super.dispose();

  }









  Future<void> openAddExpense() async {


    await Navigator.push(


      context,


      MaterialPageRoute(


        builder:(context)=>AddExpenseScreen(


          user:widget.user,


          onUpdated:widget.onUpdated,


        ),


      ),


    );



    setState(() {});


  }









  @override
  Widget build(BuildContext context){



    final expenses =
    widget.user.transactions.where((transaction){



      return !transaction.isIncome &&

          transaction.title
              .toLowerCase()
              .contains(
              searchText.toLowerCase()
          );



    }).toList();







    return Scaffold(



      backgroundColor:
      const Color(0xFFF5F7FA),






      appBar:AppBar(



        backgroundColor:
        const Color(0xFF2E7D32),



        title:const Text(



          "My Expenses",



          style:TextStyle(


            color:Colors.white,


            fontWeight:
            FontWeight.bold,


          ),


        ),


      ),







      floatingActionButton:FloatingActionButton(



        backgroundColor:
        const Color(0xFF2E7D32),



        onPressed:
        openAddExpense,



        child:const Icon(



          Icons.add,



          color:Colors.white,


        ),



      ),








      body:Padding(



        padding:
        const EdgeInsets.all(16),



        child:Column(



          children:[




            TextField(



              controller:
              searchController,



              onChanged:(value){



                setState((){


                  searchText=value;


                });



              },



              decoration:InputDecoration(



                hintText:
                "Search expenses...",



                prefixIcon:
                const Icon(Icons.search),



                filled:true,



                fillColor:
                Colors.white,



                border:OutlineInputBorder(



                  borderRadius:
                  BorderRadius.circular(15),



                  borderSide:
                  BorderSide.none,


                ),


              ),


            ),







            const SizedBox(height:20),







            Expanded(



              child:expenses.isEmpty



                  ? const Center(



                child:Text(



                  "No expenses found",



                  style:TextStyle(



                    color:
                    Colors.grey,



                    fontSize:18,


                  ),



                ),


              )



                  :ListView.builder(



                itemCount:
                expenses.length,



                itemBuilder:(context,index){



                  final expense =
                  expenses[index];




                  return ExpenseCard(



                    title:
                    expense.title,



                    amount:
                    "- UGX ${expense.amount.toStringAsFixed(0)}",



                    color:
                    Colors.red,


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









class ExpenseCard extends StatelessWidget {



  final String title;


  final String amount;


  final Color color;






  const ExpenseCard({


    super.key,


    required this.title,


    required this.amount,


    required this.color,


  });








  @override
  Widget build(BuildContext context){



    return Card(



      margin:
      const EdgeInsets.only(bottom:15),




      child:ListTile(




        leading:CircleAvatar(



          backgroundColor:
          color.withOpacity(0.15),



          child:Icon(



            Icons.money_off,



            color:color,


          ),


        ),








        title:Text(



          title,



          style:const TextStyle(



            fontWeight:
            FontWeight.bold,


          ),


        ),









        trailing:Text(



          amount,



          style:TextStyle(



            color:color,



            fontWeight:
            FontWeight.bold,


          ),


        ),



      ),



    );



  }


}