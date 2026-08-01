import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text("Notifications"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: const ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange,
                child: Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                ),
              ),
              title: Text(
                "Budget Expiring Soon",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "Your current monthly budget is about to expire. Please create a new budget for the next month.",
              ),
            ),
          ),

          const SizedBox(height: 15),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: const ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(0xFF2E7D32),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                ),
              ),
              title: Text(
                "Financial Tip",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "Review your expenses regularly to stay within your budget.",
              ),
            ),
          ),
        ],
      ),
    );
  }
}