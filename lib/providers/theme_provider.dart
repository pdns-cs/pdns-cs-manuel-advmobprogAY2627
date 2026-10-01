import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class AppPalette {
  static const Color midnight = Color(0xFF06141B);
  static const Color deepNavy = Color(0xFF11212D);
  static const Color blueSlate = Color(0xFF253745);
  static const Color slate = Color(0xFF4A5C6A);
  static const Color mist = Color(0xFF9BA8AB);
  static const Color cloud = Color(0xFFCCD0CF);
}

// Holds the app-wide dark/light mode state and notifies listeners on change.
class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  bool _isDark = false;

  ThemeProvider() {
    _loadThemePreference();
  }

  bool get isDark => _isDark;

  ThemeData get lightTheme => _buildTheme(Brightness.light);

  ThemeData get darkTheme => _buildTheme(Brightness.dark);

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppPalette.slate,
          brightness: brightness,
          surface: isDark ? AppPalette.deepNavy : AppPalette.cloud,
        ).copyWith(
          primary: isDark ? AppPalette.mist : AppPalette.deepNavy,
          onPrimary: isDark ? AppPalette.midnight : AppPalette.cloud,
          secondary: AppPalette.slate,
          onSecondary: AppPalette.cloud,
          tertiary: AppPalette.blueSlate,
          onTertiary: AppPalette.cloud,
          surface: isDark ? AppPalette.deepNavy : AppPalette.cloud,
          onSurface: isDark ? AppPalette.cloud : AppPalette.midnight,
          onSurfaceVariant: isDark ? AppPalette.mist : AppPalette.blueSlate,
          outline: AppPalette.slate,
          outlineVariant: AppPalette.mist,
          surfaceContainerLowest: isDark
              ? AppPalette.midnight
              : AppPalette.cloud,
          surfaceContainerLow: isDark ? AppPalette.deepNavy : AppPalette.cloud,
          surfaceContainer: isDark ? AppPalette.deepNavy : AppPalette.mist,
          surfaceContainerHigh: isDark ? AppPalette.blueSlate : AppPalette.mist,
          surfaceContainerHighest: isDark ? AppPalette.slate : AppPalette.mist,
          primaryContainer: AppPalette.blueSlate,
          onPrimaryContainer: AppPalette.cloud,
          secondaryContainer: AppPalette.slate,
          onSecondaryContainer: AppPalette.cloud,
          tertiaryContainer: AppPalette.mist,
          onTertiaryContainer: AppPalette.midnight,
        );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: isDark ? AppPalette.midnight : AppPalette.mist,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppPalette.midnight : AppPalette.mist,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppPalette.deepNavy : AppPalette.cloud,
        border: inputBorder,
        enabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      ),
      dividerColor: isDark ? AppPalette.blueSlate : AppPalette.mist,
    );
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDark);
    notifyListeners();
  }
}
