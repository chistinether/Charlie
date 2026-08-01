import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/test_users.dart';

class AnalyticsPage extends StatelessWidget {
  final TestUser user;

  const AnalyticsPage({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {

    // Calculate expense category totals.
    //
    // This was previously grouping by `transaction.title` (the free-text
    // label the user types per expense, e.g. "Lunch", "Bus fare") instead
    // of `transaction.category` (the dropdown category, e.g. "Food",
    // "Transport"). Because the title is different for almost every
    // transaction, and especially whenever the user reused the exact same
    // title for every expense they logged, this either fragmented the pie
    // into one sliver per transaction or collapsed it into a single
    // ever-growing slice that was always 100% of itself - which is exactly
    // why the chart looked "stuck" regardless of what was added.
    Map<String, double> categoryExpenses = {};

    for (var transaction in user.transactions) {
      if (!transaction.isIncome) {
        categoryExpenses[transaction.category] =
            (categoryExpenses[transaction.category] ?? 0) +
                transaction.amount;
      }
    }

    // Use the sum of the actual categorized transactions as the
    // denominator, rather than `user.expenses`. `user.expenses` is a
    // separately maintained running total that can drift out of sync with
    // the transaction list (for example, seeded/legacy expense totals that
    // predate individual transaction records), which made the percentages
    // wrong or inconsistent. Basing it on the categorized data guarantees
    // the slices always add up to a consistent, genuinely dynamic 100%.
    double totalExpenses = categoryExpenses.values.fold(
      0,
      (sum, value) => sum + value,
    );

    const List<Color> chartColors = [
      Color(0xFF2E7D32),
      Color(0xFFEF6C00),
      Color(0xFF1565C0),
      Color(0xFFC62828),
      Color(0xFF6A1B9A),
      Color(0xFF00838F),
      Color(0xFFF9A825),
      Color(0xFF4E342E),
    ];

    final categoryEntries = categoryExpenses.entries.toList();

    return Scaffold(

      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(

        backgroundColor: const Color(0xFF2E7D32),

        elevation: 0,

        title: const Text(
          "Analytics",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),


      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,


          children: [


            const Text(
              "Monthly Income vs Expenses",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),


            const SizedBox(height: 20),



            Container(

              height: 300,

              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius:
                BorderRadius.circular(20),

              ),


              child: BarChart(

                BarChartData(

                  alignment:
                  BarChartAlignment.spaceAround,


                  borderData:
                  FlBorderData(show: false),



                  titlesData: FlTitlesData(


                    bottomTitles:
                    AxisTitles(


                      sideTitles:
                      SideTitles(


                        showTitles:true,


                        getTitlesWidget:
                            (value, meta){


                          switch(value.toInt()){


                            case 0:
                              return const Text(
                                  "Income"
                              );


                            case 1:
                              return const Text(
                                  "Expenses"
                              );


                            default:
                              return const Text("");
                          }

                        },


                      ),

                    ),


                  ),



                  barGroups: [


                    BarChartGroupData(

                      x:0,

                      barRods:[

                        BarChartRodData(

                          toY:
                          user.income,

                          width:40,

                          color:
                          Colors.green,

                        ),

                      ],

                    ),



                    BarChartGroupData(

                      x:1,

                      barRods:[

                        BarChartRodData(

                          toY:
                          user.expenses,

                          width:40,

                          color:
                          Colors.red,

                        ),

                      ],

                    ),


                  ],


                ),

              ),

            ),



            const SizedBox(height:30),



            const Text(

              "Expense Categories",

              style:TextStyle(

                fontSize:22,

                fontWeight:
                FontWeight.bold,

              ),

            ),



            const SizedBox(height:20),



            Container(

              height:340,


              padding: const EdgeInsets.all(15),


              decoration:BoxDecoration(

                color:Colors.white,

                borderRadius:
                BorderRadius.circular(20),

              ),



              child: categoryEntries.isEmpty

                  ? const Center(
                child: Text(
                  "No expenses recorded yet",
                ),
              )


                  : Column(
                children: [

                  Expanded(
                    child: PieChart(


                      PieChartData(


                        centerSpaceRadius:45,


                        sections:

                        List.generate(
                          categoryEntries.length,
                          (index) {

                            final entry = categoryEntries[index];

                            double percentage =
                                totalExpenses <= 0
                                    ? 0
                                    : (entry.value /
                                        totalExpenses) *
                                        100;


                            return PieChartSectionData(


                              value:
                              entry.value,


                              title:
                              "${percentage.toStringAsFixed(0)}%",


                              radius:60,


                              color: chartColors[
                                  index % chartColors.length],


                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),

                            );

                          },
                        ),


                      ),

                    ),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: List.generate(
                      categoryEntries.length,
                      (index) {

                        final entry = categoryEntries[index];

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: chartColors[
                                    index % chartColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "${entry.key} (UGX ${entry.value.toStringAsFixed(0)})",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        );

                      },
                    ),
                  ),

                ],
              ),

            ),





            const SizedBox(height:30),




            const Text(

              "AI Financial Suggestions",

              style:TextStyle(

                fontSize:22,

                fontWeight:
                FontWeight.bold,

              ),

            ),




            const SizedBox(height:15),




            Card(

              shape:
              RoundedRectangleBorder(

                borderRadius:
                BorderRadius.circular(15),

              ),


              child:Padding(

                padding:
                const EdgeInsets.all(18),



                child:Column(


                  crossAxisAlignment:
                  CrossAxisAlignment.start,


                  children:[


                    const Text(

                      "Suggestion",

                      style:TextStyle(

                        fontWeight:
                        FontWeight.bold,

                        fontSize:18,

                      ),

                    ),



                    const SizedBox(height:10),



                    Text(

                      user.expenses >
                          user.income * 0.5

                          ?

                      "Your expenses are more than 50% of your income. Consider reducing unnecessary spending."

                          :

                      "Your spending is under control. Keep maintaining your current financial habits.",


                    ),



                    const SizedBox(height:20),



                    const Text(

                      "Current Balance Prediction",

                      style:TextStyle(

                        fontWeight:
                        FontWeight.bold,

                      ),

                    ),



                    const SizedBox(height:8),



                    Text(

                      "Based on your current spending pattern, "
                          "your balance is UGX ${user.balance.toStringAsFixed(0)}.",

                    ),


                  ],


                ),

              ),

            ),



          ],


        ),

      ),

    );

  }

}