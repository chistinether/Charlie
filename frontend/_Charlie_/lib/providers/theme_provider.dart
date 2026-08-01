import 'package:flutter/material.dart';

class ThemeProvider {
  static final ValueNotifier<bool> isDarkMode = ValueNotifier(false);

  static void toggleTheme(bool value) {
    isDarkMode.value = value;
  }
}