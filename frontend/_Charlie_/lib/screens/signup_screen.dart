import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  String? selectedYear;

  final List<String> years = [
    "Year 1",
    "Year 2",
    "Year 3",
    "Year 4",
    "Year 5",
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            TextField(
              decoration: InputDecoration(
                labelText: "Full Name",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Phone Number",
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              decoration: InputDecoration(
                labelText: "University",
                prefixIcon: const Icon(Icons.school),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              decoration: InputDecoration(
                labelText: "Course",
                prefixIcon: const Icon(Icons.menu_book),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: selectedYear,

              decoration: InputDecoration(
                labelText: "Year of Study",
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),

              items: years.map((year) {

                return DropdownMenuItem(
                  value: year,
                  child: Text(year),
                );

              }).toList(),

              onChanged: (value) {

                setState(() {

                  selectedYear = value;

                });

              },
            ),

            const SizedBox(height: 15),

            TextField(
              obscureText: obscurePassword,

              decoration: InputDecoration(
                labelText: "Password",

                prefixIcon: const Icon(Icons.lock),

                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),

                  onPressed: () {

                    setState(() {

                      obscurePassword = !obscurePassword;

                    });

                  },
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              obscureText: obscureConfirmPassword,

              decoration: InputDecoration(
                labelText: "Confirm Password",

                prefixIcon: const Icon(Icons.lock),

                suffixIcon: IconButton(
                  icon: Icon(
                    obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),

                  onPressed: () {

                    setState(() {

                      obscureConfirmPassword =
                      !obscureConfirmPassword;

                    });

                  },
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),

                onPressed: () {

                },

                child: const Text(
                  "CREATE ACCOUNT",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}