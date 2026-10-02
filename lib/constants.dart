import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String host = dotenv.env['HOST'] ?? 'https://dummyjson.com';

class AppRoutes {
  static const String splash = '/splash';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String home = '/home';
  static const String settings = '/settings';
}

class AppAssets {
  static const String nuLogo = 'assets/images/nu_logo.png';
}

class AppColors {
  static const Color nuBlue = Color(0xFF0B48A8);
  static const Color nuNavy = Color(0xFF071A3D);
  static const Color nuGold = Color(0xFFF4B321);
  static const Color sky = Color(0xFF2F80ED);
  static const Color teal = Color(0xFF0E9384);
  static const Color coral = Color(0xFFE25555);
  static const Color violet = Color(0xFF6A5AE0);
  static const Color blueSoft = Color(0xFFEAF2FF);
  static const Color goldSoft = Color(0xFFFFF4D6);
  static const Color tealSoft = Color(0xFFE7F8F5);
  static const Color violetSoft = Color(0xFFF1EEFF);
  static const Color background = Color(0xFFF4F7FD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF101827);
  static const Color textSecondary = Color(0xFF667085);
  static const Color divider = Color(0xFFE6EAF2);
  static const Color success = Color(0xFF15803D);
  static const Color error = Color(0xFFB42318);
}
