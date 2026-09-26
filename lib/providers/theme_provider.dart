import 'package:flutter/material.dart';

import '../constants.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.nuBlue,
          primary: AppColors.nuBlue,
          secondary: AppColors.nuGold,
          tertiary: AppColors.teal,
          error: AppColors.error,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.nuNavy,
          elevation: 0,
        ),
        cardColor: AppColors.surface,
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 2,
          shadowColor: AppColors.nuBlue.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.nuBlue,
            foregroundColor: AppColors.surface,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.nuBlue, width: 1.4),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: AppColors.nuBlue,
          unselectedItemColor: AppColors.textSecondary,
          backgroundColor: AppColors.surface,
          type: BottomNavigationBarType.fixed,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.nuGold,
        ),
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.nuBlue,
          brightness: Brightness.dark,
          primary: AppColors.nuGold,
          secondary: AppColors.nuBlue,
          error: AppColors.error,
        ),
      );

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
