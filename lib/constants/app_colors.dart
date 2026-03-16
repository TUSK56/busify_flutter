import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF214071);
  static const Color primaryBlue97 = Color(0xF7214071); // 214071 97% opacity
  static const Color scaffoldBackground = Color(0xFF0D1B2A);

  static const Color linkBlue = Color(0xFF2859C5);
  static const Color secondaryBlue = Color(0xFF3F79D7);
  static const Color grayText = Color(0xFF595959);
  static const Color gray333 = Color(0xFF333333);
  static const Color gray333Light = Color(0x1A333333); // 333333 10%

  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color panelDark = Color(0xFF171723);

  static const Color e6e9ed = Color(0xFFE6E9ED);
  static const Color d9d9d9 = Color(0xFFD9D9D9);

  /// Linear gradient for primary buttons (left 214071 → right 3f79d7)
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF214071), Color(0xFF3F79D7)],
  );
}
