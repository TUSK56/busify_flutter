import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- Parent home (Figma) ---
  static const Color textBlack = Color(0xFF000000);
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFE6E9ED);
  static const Color greenStatus = Color(0xFF156E1B);
  /// Figma “On the way” / success accent (#1BD95D)
  static const Color greenStatusBright = Color(0xFF1BD95D);
  /// Divider stroke rgba(51,51,51,0.54)
  static const Color divider = Color(0x8A333333);
  /// Track bus status card inner divider rgba(51,51,51,0.1)
  static const Color dividerTrackBus = Color(0x1A333333);

  static const Color primaryBlue = Color(0xFF214071);
  static const Color primaryBlue97 = Color(0xF7214071); // 214071 97% opacity
  static const Color scaffoldBackground = Color(0xFF0D1B2A);

  static const Color linkBlue = Color(0xFF2859C5);
  static const Color secondaryBlue = Color(0xFF3F79D7);
  /// Active nav / accent (Figma button blue)
  static const Color buttonBlue = Color(0xFF3F79D7);
  static const Color grayText = Color(0xFF595959);
  static const Color gray333 = Color(0xFF333333);
  static const Color gray333Light = Color(0x1A333333); // 333333 10%

  /// #000000 85% (e.g. Bus #7 on profile)
  static Color get textBlack85 => textBlack.withValues(alpha: 0.85);

  /// #595959 @ 33% (Figma profile dark-mode track)
  static Color get toggleTrackMuted => grayText.withValues(alpha: 0.33);

  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color successGreen = Color(0xFF156E1B);
  static const Color lightGreen = Color(0xFFB4D9BA);
  static const Color panelDark = Color(0xFF171723);

  static const Color e6e9ed = Color(0xFFE6E9ED);
  /// Track bus floating card base (#F7F9FB @ 56% opacity)
  static const Color trackBusCardTint = Color(0x8FF7F9FB);
  /// Track bus card stroke (#595959 @ 57%)
  static Color get trackBusCardStroke => grayText.withValues(alpha: 0.57);
  /// Drop shadow rgba(0,0,0,0.25)
  static const Color trackBusCardShadow = Color(0x40000000);
  static const Color d9d9d9 = Color(0xFFD9D9D9);

  /// Profile / spec cards: #D9D9D9 @ 49%
  static Color get profileCardBackground =>
      d9d9d9.withValues(alpha: 0.49);
  static const Color gray33354 = Color(0x8A333333); // 54% opacity for divider

  /// Student card inner title bar (d9d9d9 @ 56% over card)
  static Color get studentCardHeaderBar =>
      d9d9d9.withValues(alpha: 0.56);

  /// Linear gradient for primary buttons (left 214071 → right 3f79d7)
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF214071), Color(0xFF3F79D7)],
  );

  // --- Parent edit profile (Figma) ---
  /// Input fill #F5F5F5 @ 78%
  static Color get inputFill78 => background.withValues(alpha: 0.78);

  /// Input stroke rgba(0,0,0,0.21)
  static const Color inputStrokeBlack21 = Color(0x36000000);

  /// Save button: #D9D9D9 → #2859C5
  static const LinearGradient editProfileSaveGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFD9D9D9), Color(0xFF2859C5)],
  );
}
