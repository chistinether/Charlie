import 'package:flutter/material.dart';

import '../../models/test_users.dart';
import '../../models/user_budget.dart';
import '../../models/budget_item.dart';
import '../../utils/id_generator.dart';
import 'add_budget_screen.dart';
import 'manual_budget_table_screen.dart';

// Entry point for manual budgeting. Rather than silently jumping straight
// into whatever budget the user currently has active (which could be an
// AI-generated budget they just saved), this screen lets the user choose:
//   1. Create a new budget from scratch (default action), or
//   2. Edit one of their existing saved budgets, which auto-fills the
//      manual budget table with that budget's details for editing.
class ManualBudgetScreen extends StatelessWidget {
  final TestUser user;

  const ManualBudgetScreen({
    super.key,
    required this.user,
  });

  List<UserBudget> get _savedBudgets {
    return [
      if (user.budget != null) user.budget!,
      ...user.budgetHistory,
    ];
  }

  void _createFromScratch(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AddBudgetScreen(user: user),
      ),
    );
  }

  void _editExistingBudget(BuildContext context, UserBudget original) {
    // Work on a copy so editing doesn't mutate the saved budget (or its
    // items, since BudgetItem is mutable) until the user explicitly saves.
    final editableBudget = original.copyWith(
      id: IdGenerator.next(),
      items: original.items
          .map(
            (item) => item.copyWith(),
          )
          .toList(),
      isAI: false,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ManualBudgetTableScreen(
          user: user,
          budget: editableBudget,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  void _showSavedBudgetsPicker(BuildContext context) {
    final savedBudgets = _savedBudgets;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  "Choose a budget to edit",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: savedBudgets.length,
                  itemBuilder: (context, index) {
                    final budget = savedBudgets[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF2E7D32),
                        child: Icon(
                          budget.isAI ? Icons.smart_toy : Icons.edit_note,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(budget.purpose),
                      subtitle: Text(
                        "UGX ${budget.totalIncome.toStringAsFixed(0)} \u2022 "
                        "${_formatDate(budget.startDate)}",
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _editExistingBudget(context, budget);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedBudgets = _savedBudgets;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Manual Budget"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "How would you like to build your manual budget?",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => _createFromScratch(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  "Create a new budget from scratch",
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 55,
              child: OutlinedButton.icon(
                onPressed: savedBudgets.isEmpty
                    ? null
                    : () => _showSavedBudgetsPicker(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.edit),
                label: const Text(
                  "Edit an existing saved budget",
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
            if (savedBudgets.isEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                "You don't have any saved budgets yet.",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
