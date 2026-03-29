import 'package:application/constants/app_colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.lightGray,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primaryBlue,
          secondary: AppColors.linkBlue,
          surface: AppColors.lightGray,
        ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: const Color(0xFF0D1B2A),
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.primaryBlue,
          secondary: AppColors.linkBlue,
          surface: const Color(0xFF162233),
          onSurface: Colors.white,
        ),
  );
}

extension AppThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get appScaffoldBackground =>
      isDarkMode ? const Color(0xFF0D1B2A) : AppColors.lightGray;

  Color get appCardBackground => isDarkMode
      ? const Color(0xFF162233)
      : AppColors.d9d9d9.withValues(alpha: 0.49);

  Color get appPanelBackground =>
      isDarkMode ? const Color(0xFF1B2A3A) : AppColors.e6e9ed;

  Color get appPrimaryText => isDarkMode ? Colors.white : Colors.black;

  Color get appSecondaryText =>
      isDarkMode ? const Color(0xFFB8C3D1) : AppColors.grayText;

  Color get appDivider => isDarkMode
      ? Colors.white.withValues(alpha: 0.12)
      : AppColors.gray333Light;

  Color get appInputBackground => isDarkMode
      ? const Color(0xFF203041)
      : AppColors.white.withValues(alpha: 0.58);

  Color get appOverlayButtonBackground =>
      isDarkMode ? const Color(0xFF162233) : Colors.white;

  Color get appOverlayButtonIcon => isDarkMode ? Colors.white : Colors.black;

  Color get appShadow => isDarkMode
      ? Colors.black.withValues(alpha: 0.35)
      : Colors.black.withValues(alpha: 0.15);

  Color get appLine => isDarkMode
      ? Colors.white.withValues(alpha: 0.18)
      : const Color(0x8A000000);

  Color get appProgressTrack =>
      isDarkMode ? const Color(0xFF2A3644) : const Color(0xBCD4D4D4);

  Color get appInactiveNav =>
      isDarkMode ? const Color(0xFFB8C3D1) : AppColors.gray333;

  Color get appAvatarPlaceholder =>
      isDarkMode ? const Color(0xFF314255) : Colors.grey.shade300;
}
