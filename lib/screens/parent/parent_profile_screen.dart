import 'dart:math' as math;

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/routes/fade_route.dart';
import 'package:application/screens/onboarding/role_selection_screen.dart';
import 'package:application/screens/parent/parent_edit_profile_screen.dart';
import 'package:application/screens/parent/parent_home_screen.dart';
import 'package:application/screens/parent/parent_track_bus_screen.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/widgets/parent/parent_bottom_nav_bar.dart';
import 'package:application/widgets/parent/parent_brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// أبعاد ومسافات موحّدة لكل بطاقات شاشة البروفايل — عدّل هنا للتحكم في الشكل كله.
abstract final class _ParentProfileCards {
  _ParentProfileCards._();

  /// أقصى عرض للبطاقة؛ على الشاشات الأضيق تقل تلقائياً مع هامش جانبي.
  static const double maxCardWidth = 380;
  static const double horizontalScreenInset = 24;
  static const double logoutHorizontalInset = 16;

  /// حشوة داخلية موحّدة لكل البطاقات (يمين/شمال + يمكن تخصيص عمودي لكل بطاقة).
  static const double innerHorizontalPadding = 18;

  static const double cardRadius = 15;
  static const double dividerMaxWidth = 320;

  static double cardWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return math.min(maxCardWidth, w - 2 * horizontalScreenInset);
  }

  static double logoutWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return math.min(maxCardWidth, w - 2 * logoutHorizontalInset);
  }

  static double innerContentWidth(double cardWidth) =>
      cardWidth - 2 * innerHorizontalPadding;
}

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ServiceLocator.themeController.addListener(_onThemeChanged);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _entranceController.forward();
  }

  @override
  void dispose() {
    ServiceLocator.themeController.removeListener(_onThemeChanged);
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final cardW = _ParentProfileCards.cardWidth(context);

    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 24 + bottomInset),
                child: FadeTransition(
                  opacity: _entranceFade,
                  child: SlideTransition(
                    position: _entranceSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context),
                        const Center(child: _ProfileAvatar()),
                        const SizedBox(height: 15),
                        _buildRoundedContentSheet(context, cardW),
                        const SizedBox(height: 14),
                        Center(child: _buildSettingsCard(context, cardW)),
                        const SizedBox(height: 24),
                        Center(child: _buildSupportCard(context, cardW)),
                        const SizedBox(height: 17),
                        Center(child: _buildLogoutButton(context)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ParentBottomNavBar(
              activeTab: ParentNavTab.profile,
              onHomeTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  fadeRoute(const ParentHomeScreen()),
                  (route) => false,
                );
              },
              onTrackBusTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  fadeRoute(const ParentTrackBusScreen()),
                  (route) => false,
                );
              },
              onProfileTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(22),
        bottomRight: Radius.circular(22),
      ),
      child: SizedBox(
        height: 128,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: ColoredBox(color: AppColors.primaryBlue97),
            ),
            Positioned.fill(
              child: ParentBrandLogo.headerImage(AppImages.logo),
            ),
            Positioned(
              left: 15,
              top: 11.25,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const SizedBox(
                    width: 13.88,
                    height: 22.5,
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.white,
                      size: 22.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundedContentSheet(BuildContext context, double cardW) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appScaffoldBackground,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: _ParentProfileCards.horizontalScreenInset,
          right: _ParentProfileCards.horizontalScreenInset,
          bottom: 11,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'Omar Khaled',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 22 / 24,
                  color: context.appPrimaryText,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildAccountInfoCard(context, cardW),
            const SizedBox(height: 32),
            _buildLinkedStudentCard(context, cardW),
          ],
        ),
      ),
    );
  }

  Widget _dividerLine(BuildContext context, double innerW) {
    return Center(
      child: Container(
        width: math.min(_ParentProfileCards.dividerMaxWidth, innerW),
        height: 1,
        color: context.appDivider,
      ),
    );
  }

  Widget _buildAccountInfoCard(BuildContext context, double cardW) {
    final innerW = _ParentProfileCards.innerContentWidth(cardW);
    const vPad = EdgeInsets.fromLTRB(
      _ParentProfileCards.innerHorizontalPadding,
      16,
      _ParentProfileCards.innerHorizontalPadding,
      14,
    );

    return _ProfileCard(
      width: cardW,
      padding: vPad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Info',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 22 / 16,
              color: context.appSecondaryText,
            ),
          ),
          const SizedBox(height: 10),
          _dividerLine(context, innerW),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AppImages.phone,
                width: 19.5,
                height: 18.42,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '01223100458',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                    color: context.appPrimaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _dividerLine(context, innerW),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AppImages.email,
                width: 21.67,
                height: 17.33,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'omar@email.com',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 22 / 15,
                    color: context.appPrimaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _dividerLine(context, innerW),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AppImages.homeParentProfile,
                width: 17.5,
                height: 18.75,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Text(
                'Cairo',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 22 / 15,
                  color: context.appPrimaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedStudentCard(BuildContext context, double cardW) {
    final innerW = _ParentProfileCards.innerContentWidth(cardW);
    const vPad = EdgeInsets.fromLTRB(
      _ParentProfileCards.innerHorizontalPadding,
      10,
      _ParentProfileCards.innerHorizontalPadding,
      12,
    );

    return _ProfileCard(
      width: cardW,
      padding: vPad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Text(
              'Linked Student',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 22 / 16,
                color: context.appSecondaryText,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _dividerLine(context, innerW),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipOval(
                    child: Image.asset(
                      AppImages.parentProfile,
                      width: 38,
                      height: 37,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Adam Omar Ahmed',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 35 / 16,
                        color: context.appPrimaryText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    AppImages.winParentProfile,
                    width: 21,
                    height: 21,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Grade 6',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 22 / 16,
                      color: context.appPrimaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    AppImages.busParentProfile,
                    width: 21,
                    height: 21,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Bus #7',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 35 / 16,
                      color: context.appPrimaryText.withValues(
                        alpha: 0.85,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  const SnackBar(content: Text('Add another child')),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '➕ Add Another Child',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 22 / 20,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, double cardW) {
    final innerW = _ParentProfileCards.innerContentWidth(cardW);
    final darkOn = Theme.of(context).brightness == Brightness.dark;
    const vPad = EdgeInsets.symmetric(
      horizontal: _ParentProfileCards.innerHorizontalPadding,
      vertical: 12,
    );

    return _ProfileCard(
      width: cardW,
      padding: vPad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 22 / 20,
              color: context.appPrimaryText,
            ),
          ),
          const SizedBox(height: 10),
          _dividerLine(context, innerW),
          const SizedBox(height: 10),
          Row(
            children: [
              Image.asset(
                AppImages.moon,
                width: 18.32,
                height: 18.32,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dark Mode',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 22 / 16,
                    color: context.appPrimaryText,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _FigmaPillToggle(
                value: darkOn,
                onChanged: (v) =>
                    ServiceLocator.themeController.setDarkEnabled(v),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _dividerLine(context, innerW),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                fadeRoute(const ParentEditProfileScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    AppImages.lock,
                    width: 15.6,
                    height: 20.8,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Change Password',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 22 / 16,
                        color: context.appPrimaryText,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.white,
                    size: 14.5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context, double cardW) {
    final innerW = _ParentProfileCards.innerContentWidth(cardW);
    const vPad = EdgeInsets.fromLTRB(
      _ParentProfileCards.innerHorizontalPadding,
      14,
      _ParentProfileCards.innerHorizontalPadding,
      12,
    );

    return _ProfileCard(
      width: cardW,
      padding: vPad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Text(
              'Support',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 22 / 16,
                color: context.appSecondaryText,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _dividerLine(context, innerW),
          InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Image.asset(
                    AppImages.questionMark,
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 13),
                  Text(
                    'Help & Support',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 22 / 16,
                      color: context.appPrimaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Image.asset(
                    AppImages.aboutMark,
                    width: 23.33,
                    height: 23.33,
                    fit: BoxFit.contain,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 13),
                  Text(
                    'About Busify',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 22 / 16,
                      color: context.appPrimaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final w = _ParentProfileCards.logoutWidth(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushAndRemoveUntil(
            fadeRoute(const RoleSelectionScreen()),
            (route) => false,
          );
        },
        borderRadius: BorderRadius.circular(33),
        child: Ink(
          width: w,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(33),
            gradient: AppColors.primaryButtonGradient,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppImages.logoutParentProfile,
                width: 26,
                height: 26,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Text(
                'Log Out',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 22 / 20,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// غلاف موحّد لكل بطاقات المحتوى — الارتفاع حسب المحتوى فقط.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.width,
    required this.padding,
    required this.child,
  });

  final double width;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(_ParentProfileCards.cardRadius),
      ),
      child: child,
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(color: AppColors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray333.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        child: Image.asset(
          AppImages.parentProfilePic,
          width: 91,
          height: 78,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _FigmaPillToggle extends StatelessWidget {
  const _FigmaPillToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 66,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(33),
          color: AppColors.toggleTrackMuted,
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
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
