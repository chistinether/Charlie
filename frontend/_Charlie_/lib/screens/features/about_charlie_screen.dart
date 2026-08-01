import 'package:flutter/material.dart';

import '../../widgets/speak_button.dart';

class AboutCharlieScreen extends StatelessWidget {
  const AboutCharlieScreen({super.key});

  static const String _intro =
      "Charlie is a student financial management application designed to "
      "help students manage their personal finances efficiently. "
      "The application allows students to: track income and expenses, "
      "create and monitor budgets, store important financial documents, "
      "receive notifications when budgets are about to expire, and view "
      "financial summaries and recent transactions. "
      "Charlie's goal is to help students develop better financial habits, "
      "improve budgeting skills and make informed financial decisions.";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text("About Charlie"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [

              const Icon(
                Icons.account_balance_wallet,
                size: 90,
                color: Color(0xFF2E7D32),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Charlie",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SpeakButton(text: _intro),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                "Charlie is a student financial management application designed to help students manage their personal finances efficiently."
                "\n\n"
                "The application allows students to:"
                "\n\n• Track income and expenses."
                "\n• Create and monitor budgets."
                "\n• Store important financial documents."
                "\n• Receive notifications when budgets are about to expire."
                "\n• View financial summaries and recent transactions."
                "\n\n"
                "Charlie's goal is to help students develop better financial habits, improve budgeting skills and make informed financial decisions.",
                style: TextStyle(
                  fontSize: 17,
                  height: 1.6,
                ),
                textAlign: TextAlign.justify,
              ),

              const SizedBox(height: 30),

              const Text(
                "Version 1.0.0",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
