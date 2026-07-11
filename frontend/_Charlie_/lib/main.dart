import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const CharlieApp());
}

class CharlieApp extends StatelessWidget {
  const CharlieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Charlie',
      home: const SplashScreen(),
    );
  }
}