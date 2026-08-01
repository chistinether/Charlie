import 'package:flutter/material.dart';
import '../../models/test_users.dart';
import '../../services/firebase_service.dart';
import '../../widgets/voice_mic_button.dart';

class AddExpenseScreen extends StatefulWidget {
  final TestUser user;
  final VoidCallback onUpdated;

  const AddExpenseScreen({
    super.key,
    required this.user,
    required this.onUpdated,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String selectedCategory = "Food";

  final List<String> categories = [
    "Food",
    "Shopping",
    "Entertainment",
    "Health",
    "Education",
    "Other",
  ];

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void updateBudgetSpent(String category, double amount) {
    final budget = widget.user.budget;

    if (budget == null) {
      return;
    }

    for (var item in budget.items) {
      if (item.category == category) {
        item.spentAmount += amount;
      }
    }
  }

Future<bool> confirmIfOverAdvised(double amount) async {
    final budget = widget.user.budget;
    if (budget == null) return true;

    final rec = budget.recommendedDailySpend;
    if (rec <= 0 || amount <= rec) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Above your daily budget"),
        content: Text(
          "Your recommended daily spending is "
          "UGX ${rec.toStringAsFixed(0)}, but this expense is "
          "UGX ${amount.toStringAsFixed(0)}. Are you sure you want to "
          "continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, continue"),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> saveExpense()async {
    if (titleController.text.trim().isEmpty ||
        amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    double? amount = double.tryParse(amountController.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid amount")),
      );
      return;
    }
final proceed = await confirmIfOverAdvised(amount);
    if (!proceed) {
      return;
    }
    widget.user.expenses += amount;
    widget.user.balance -= amount;

    widget.user.transactions.add(
      TransactionModel(
        title: titleController.text.trim(),
        category: selectedCategory,
        amount: amount,
        isIncome: false,
        date: DateTime.now(),
      ),
    );

    updateBudgetSpent(selectedCategory, amount);

    final expenseTransaction = TransactionModel(
      title: titleController.text.trim(),
      category: selectedCategory,
      amount: amount,
      isIncome: false,
      date: DateTime.now(),
    );

    try {
      await FirebaseService.addTransaction(expenseTransaction);
      final budgetToSave = widget.user.budget;
      if (budgetToSave != null) {
        await FirebaseService.saveBudget(budgetToSave);
      }
    } catch (e) {
      debugPrint("Could not save expense: $e");
    }

    widget.onUpdated();

    final budget = widget.user.budget;
    final isOffPace = budget != null && budget.isPacedToRunOutEarly;

    if (isOffPace) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("⚠️ Budget Pace Warning"),
          content: Text(budget.paceMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK, GOT IT"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Expense added successfully")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Add Expense"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Expense Title",
                prefixIcon: const Icon(Icons.receipt),
                suffixIcon: VoiceMicButton(controller: titleController),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Amount (UGX)",
                prefixIcon: const Icon(Icons.money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Notes (Optional)",
                prefixIcon: const Icon(Icons.note),
                suffixIcon: VoiceMicButton(controller: notesController),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "SAVE EXPENSE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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