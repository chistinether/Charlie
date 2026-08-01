import 'package:flutter/material.dart';
import '../features/add_income_screen.dart';
import '../features/add_budget_screen.dart';
import '../features/documents_screen.dart';
import '../features/add_expense_screen.dart';
import '../../widgets/budget_summary_dialog.dart';
import '../../widgets/financial_insight_dialog.dart';
import '../features/manual_budget_table_screen.dart';
import '../../models/test_users.dart';
import '../../services/budget_analyzer_service.dart';

class HomePage extends StatefulWidget {
  final TestUser user;
  final VoidCallback onUpdated;

  const HomePage({
    super.key,
    required this.user,
    required this.onUpdated,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool summaryShown = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBudgetSummary();
    });
  }

  void showBudgetSummary() {
    if (summaryShown) {
      return;
    }

    summaryShown = true;

    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        showDialog(
          context: context,
          builder: (context) {
            return BudgetSummaryDialog(
              user: widget.user,
            );
          },
        );
      },
    );
  }

  void refreshHome() {
    setState(() {});
    widget.onUpdated();
  }

  void showFinancialInsight() {
    Future.delayed(
      const Duration(milliseconds: 300),
      () {
        showDialog(
          context: context,
          builder: (context) {
            return FinancialInsightDialog(
              user: widget.user,
            );
          },
        );
      },
    );
  }

  // Picks a greeting (and matching emoji) based on the device's current
  // time of day, instead of always saying "Good Morning".
  String get greeting {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return "Good Morning 👋";
    }

    if (hour >= 12 && hour < 17) {
      return "Good Afternoon ☀️";
    }

    if (hour >= 17 && hour < 21) {
      return "Good Evening 🌆";
    }

    return "Good Night 🌙";
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: const Text(
          "Charlie",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications,
              color: Colors.white,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Current Balance",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "UGX ${user.balance.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: buildSmallCard(
                    "Income",
                    "UGX ${user.income.toStringAsFixed(0)}",
                    Icons.arrow_downward,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: buildSmallCard(
                    "Expenses",
                    "UGX ${user.expenses.toStringAsFixed(0)}",
                    Icons.arrow_upward,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              children: [
                actionCard(
                  context,
                  Icons.add_circle,
                  "Add Expense",
                  Colors.red,
                  AddExpenseScreen(
                    user: user,
                    onUpdated: refreshHome,
                  ),
                ),
                actionCard(
                  context,
                  Icons.attach_money,
                  "Add Income",
                  Colors.green,
                  AddIncomeScreen(
                    user: user,
                    onUpdated: refreshHome,
                  ),
                ),
                actionCard(
                  context,
                  Icons.account_balance_wallet,
                  "Budget",
                  Colors.orange,
                  user.budget == null
                      ? AddBudgetScreen(user: user)
                      : ManualBudgetTableScreen(
                          user: user,
                          budget: user.budget!,
                        ),
                ),
                actionCard(
                  context,
                  Icons.receipt_long,
                  "Documents",
                  Colors.blue,
                  DocumentsScreen(userEmail: user.email),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              "Current Budget",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            user.budget == null
                ? const Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.account_balance_wallet,
                        color: Colors.orange,
                      ),
                      title: Text(
                        "No budget created yet",
                      ),
                      subtitle: Text(
                        "Create a budget to start tracking your money",
                      ),
                    ),
                  )
                : Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.budget!.purpose,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Income: UGX ${user.budget!.totalIncome.toStringAsFixed(0)}",
                          ),
                          Text(
                            "Allocated: UGX ${user.budget!.totalAllocated.toStringAsFixed(0)}",
                          ),
                          Text(
                            "Spent: UGX ${user.budget!.totalSpent.toStringAsFixed(0)}",
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                user.budget!.status == "Safe"
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color: user.budget!.status == "Safe"
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.budget!.status,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            BudgetAnalyzerService.analyze(user.budget!),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 30),
            const Text(
              "Recent Transactions",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            user.transactions.isEmpty
                ? const Card(
                    child: ListTile(
                      title: Text("No transactions yet"),
                    ),
                  )
                : Column(
                    children: user.transactions.reversed.map((transaction) {
                      return Card(
                        child: ListTile(
                          title: Text(transaction.title),
                          subtitle: Text(transaction.category),
                          trailing: Text(
                            transaction.isIncome
                                ? "+ UGX ${transaction.amount.toStringAsFixed(0)}"
                                : "- UGX ${transaction.amount.toStringAsFixed(0)}",
                            style: TextStyle(
                              color: transaction.isIncome
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget buildSmallCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(title),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget actionCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    Widget page,
  ) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => page,
          ),
        );

        refreshHome();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(.15),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(title),
          ],
        ),
      ),
    );
  }
}