import 'package:flutter/material.dart';

// Holds the app-wide dark/light mode state and notifies listeners on change.
class ThemeProvider with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeData get lightTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      );

  ThemeData get darkTheme => ThemeData.dark(useMaterial3: true);

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
