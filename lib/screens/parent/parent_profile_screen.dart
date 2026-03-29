import 'dart:math' as math;

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/core/layout/app_layout.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/routes/fade_route.dart';
import 'package:application/screens/onboarding/role_selection_screen.dart';
import 'package:application/screens/parent/parent_edit_profile_screen.dart';
import 'package:application/screens/parent/parent_home_screen.dart';
import 'package:application/screens/parent/parent_track_bus_screen.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/widgets/parent/parent_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Parent profile — Figma frame **390×1240**, unified [AppLayout] scaling.
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
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
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
    final m = AppLayout.metricsOf(context);
    final layout = m.scale;
    final cappedW = m.cappedWidth;

    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 24 * layout + m.bottomInset),
                child: FadeTransition(
                  opacity: _entranceFade,
                  child: SlideTransition(
                    position: _entranceSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buildHeader(context, layout, layout),
                        Center(child: buildProfilePicture(layout, layout)),
                        SizedBox(height: 15 * layout),
                        _buildRoundedContentSheet(context, layout, layout, cappedW),
                        SizedBox(height: 14 * layout),
                        Center(child: buildSettingsCard(context, layout, layout, cappedW)),
                        SizedBox(height: 24 * layout),
                        Center(child: buildSupportAboutCards(context, layout, layout, cappedW)),
                        SizedBox(height: 17 * layout),
                        Center(child: buildLogoutButton(context, layout, layout, cappedW)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ParentBottomNavBar(
              scale: layout,
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

  /// Header **390×128**, bottom radius **22**, fill **214071 @ 97%**.
  Widget buildHeader(BuildContext context, double wr, double layout) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(22 * wr),
        bottomRight: Radius.circular(22 * wr),
      ),
      child: SizedBox(
        height: 128 * layout,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.primaryBlue97)),
            Positioned(
              left: 15 * wr,
              top: 11.25 * layout,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: SizedBox(
                    width: 13.88 * wr,
                    height: 22.5 * layout,
                    child: Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.white,
                    size: 22.5 * wr,
                  ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 132 * wr,
              top: 62 * layout,
              child: Image.asset(
                AppImages.logo,
                width: 126 * wr,
                height: 54 * layout,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **91×78**, full ellipse clip + thin white border (matches reference).
  Widget buildProfilePicture(double wr, double layout) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(999 * wr)),
        border: Border.all(color: AppColors.white, width: 2 * wr),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray333.withValues(alpha: 0.08),
            blurRadius: 6 * wr,
            offset: Offset(0, 2 * layout),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(999 * wr)),
        child: Image.asset(
          AppImages.parentProfilePic,
          width: 91 * wr,
          height: 78 * layout,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Rounded **#F5F5F5** sheet (radius **40**): name + Account + Linked Student.
  Widget _buildRoundedContentSheet(
    BuildContext context,
    double wr,
    double layout,
    double cappedW,
  ) {
    final cardW = math.min(342.0 * wr, cappedW - 48 * wr);

    return Container(
      width: cappedW,
      margin: EdgeInsets.symmetric(
        horizontal: math.max(0, (cappedW - AppLayout.designWidth * wr) / 2),
      ),
      decoration: BoxDecoration(
        color: context.appScaffoldBackground,
        borderRadius: BorderRadius.circular(40 * wr),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 0, left: 24 * wr, right: 24 * wr, bottom: 11 * layout),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'Omar Khaled',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24 * wr,
                  fontWeight: FontWeight.w600,
                  height: 22 / 24,
                  color: context.appPrimaryText,
                ),
              ),
            ),
            SizedBox(height: 14 * layout),
            buildAccountInfoCard(context, wr, layout, cardW),
            SizedBox(height: 32 * layout),
            buildLinkedStudentCard(context, wr, layout, cardW),
          ],
        ),
      ),
    );
  }

  Widget _dividerLine(BuildContext context, double scale, double innerW) {
    return Center(
      child: Container(
        width: math.min(320 * scale, innerW),
        height: 1,
        color: context.appDivider,
      ),
    );
  }

  /// **342×189** min — card uses supervisor-aligned [BuildContext.appCardBackground].
  Widget buildAccountInfoCard(BuildContext context, double scale, double layout, double cardW) {
    final hPad = 27 * scale;
    return Container(
      width: cardW,
      constraints: BoxConstraints(minHeight: 189 * layout),
      padding: EdgeInsets.fromLTRB(hPad, 16 * layout, hPad, 14 * layout),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(15 * scale),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Info',
            style: GoogleFonts.inter(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w600,
              height: 22 / 16,
              color: context.appSecondaryText,
            ),
          ),
          SizedBox(height: 10 * layout),
          _dividerLine(context, scale, cardW - 2 * hPad),
          SizedBox(height: 8 * layout),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AppImages.phone,
                width: 19.5 * scale,
                height: 18.42 * layout,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Text(
                  '01223100458',
                  style: GoogleFonts.inter(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                    color: context.appPrimaryText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * layout),
          _dividerLine(context, scale, cardW - 2 * hPad),
          SizedBox(height: 8 * layout),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AppImages.email,
                width: 21.67 * scale,
                height: 17.33 * layout,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Text(
                  'omar@email.com',
                  style: GoogleFonts.inter(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w500,
                    height: 22 / 15,
                    color: context.appPrimaryText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * layout),
          _dividerLine(context, scale, cardW - 2 * hPad),
          SizedBox(height: 8 * layout),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AppImages.homeParentProfile,
                width: 17.5 * scale,
                height: 18.75 * layout,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 12 * scale),
              Text(
                'Cairo',
                style: GoogleFonts.inter(
                  fontSize: 15 * scale,
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

  /// **342×189** min, “Linked Student”, avatar **38×37**, grade + bus rows.
  Widget buildLinkedStudentCard(
      BuildContext context,
      double wr,
      double layout,
      double cardW,
      ) {
    final hPad = 14 * wr;
    final lineW = cardW - 2 * hPad;

    return Container(
      width: cardW,
      constraints: BoxConstraints(minHeight: 189 * layout),
      padding: EdgeInsets.fromLTRB(hPad, 10 * layout, hPad, 12 * layout),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(15 * wr),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 7 * wr),
            child: Text(
              'Linked Student',
              style: GoogleFonts.inter(
                fontSize: 16 * wr,
                fontWeight: FontWeight.w600,
                height: 22 / 16,
                color: context.appSecondaryText,
              ),
            ),
          ),
          SizedBox(height: 8 * layout),
          _dividerLine(context, wr, lineW),
          SizedBox(height: 8 * layout),

          // Student Info Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: Image.asset(
                  AppImages.parentProfile,
                  width: 38 * wr,
                  height: 37 * layout,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 7 * wr),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adam Omar Ahmed',
                      style: GoogleFonts.inter(
                        fontSize: 16 * wr,
                        fontWeight: FontWeight.w500,
                        height: 35 / 16,
                        color: context.appPrimaryText,
                      ),
                    ),
                    SizedBox(height: 10 * layout),

                    // Grade Row - Extreme Left
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                       crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          AppImages.winParentProfile,
                          width: 21 * wr,
                          height: 21 * layout,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 5 * wr),
                        Text(
                          'Grade 6',
                          style: GoogleFonts.inter(
                            fontSize: 16 * wr,
                            fontWeight: FontWeight.w600,
                            height: 22 / 16,
                            color: context.appPrimaryText,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 6 * layout),

                    // Bus Row - Extreme Left
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          AppImages.busParentProfile,
                          width: 21 * wr,
                          height: 21 * layout,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: 5 * wr),
                        Text(
                          'Bus #7',
                          style: GoogleFonts.inter(
                            fontSize: 16 * wr,
                            fontWeight: FontWeight.w600,
                            height: 35 / 16,
                            color: context.appPrimaryText.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 10 * layout),
          Center(
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  const SnackBar(content: Text('Add another child')),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                padding: EdgeInsets.symmetric(vertical: 4 * layout),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '➕ Add Another Child',
                style: GoogleFonts.inter(
                  fontSize: 20 * wr,
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

  /// **342×184** min, custom **66×28** pill toggle (**595959 @ 33%** track, white thumb **25**).
  Widget buildSettingsCard(BuildContext context, double wr, double layout, double cappedW) {
    final cardW = math.min(342.0 * wr, cappedW - 48 * wr);
    final darkOn = Theme.of(context).brightness == Brightness.dark;
    final hPad = 18 * wr;
    final lineW = cardW - 2 * hPad;

    return Container(
      width: cardW,
      constraints: BoxConstraints(minHeight: 184 * layout),
      padding: EdgeInsets.fromLTRB(hPad, 12 * layout, hPad, 12 * layout),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(15 * wr),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.inter(
              fontSize: 20 * wr,
              fontWeight: FontWeight.w600,
              height: 22 / 20,
              color: context.appPrimaryText,
            ),
          ),
          SizedBox(height: 10 * layout),
          _dividerLine(context, wr, lineW),
          SizedBox(height: 10 * layout),
          Row(
            children: [
              Image.asset(
                AppImages.moon,
                width: 18.32 * wr,
                height: 18.32 * layout,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 10 * wr),
              Expanded(
                child: Text(
                  'Dark Mode',
                  style: GoogleFonts.inter(
                    fontSize: 16 * wr,
                    fontWeight: FontWeight.w500,
                    height: 22 / 16,
                    color: context.appPrimaryText,
                  ),
                ),
              ),
              SizedBox(width: 10 * wr),
              _FigmaPillToggle(
                value: darkOn,
                wr: wr,
                layout: layout,
                onChanged: (v) => ServiceLocator.themeController.setDarkEnabled(v),
              ),
            ],
          ),
          SizedBox(height: 10 * layout),
          _dividerLine(context, wr, lineW),
          SizedBox(height: 8 * layout),
          InkWell(
            onTap: () {
              Navigator.of(context).push(fadeRoute(const ParentEditProfileScreen()));
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4 * layout),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    AppImages.lock,
                    width: 15.6 * wr,
                    height: 20.8 * layout,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: 10 * wr),
                  Expanded(
                    child: Text(
                      'Change Password',
                      style: GoogleFonts.inter(
                        fontSize: 16 * wr,
                        fontWeight: FontWeight.w500,
                        height: 22 / 16,
                        color: context.appPrimaryText,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: context.appSecondaryText,
                    size: 14.5 * wr,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// **342×158** min, “Support” header + Help + About; icons **214071**.
  Widget buildSupportAboutCards(
    BuildContext context,
    double wr,
    double layout,
    double cappedW,
  ) {
    final cardW = math.min(342.0 * wr, cappedW - 48 * wr);
    final hPad = 14 * wr;
    final lineW = cardW - 2 * hPad;

    return Container(
      width: cardW,
      constraints: BoxConstraints(minHeight: 158 * layout),
      padding: EdgeInsets.fromLTRB(hPad, 14 * layout, hPad, 12 * layout),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(15 * wr),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 7 * wr),
            child: Text(
              'Support',
              style: GoogleFonts.inter(
                fontSize: 16 * wr,
                fontWeight: FontWeight.w600,
                height: 22 / 16,
                color: context.appSecondaryText,
              ),
            ),
          ),
          SizedBox(height: 10 * layout),
          _dividerLine(context, wr, lineW),
          InkWell(
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10 * layout),
              child: Row(
                children: [
                  SizedBox(width: 6 * wr),
                  Image.asset(
                    AppImages.questionMark,
                    width: 22 * wr,
                    height: 22 * layout,
                    fit: BoxFit.contain,
                    color: AppColors.primaryBlue,
                  ),
                  SizedBox(width: 13 * wr),
                  Text(
                    'Help & Support',
                    style: GoogleFonts.inter(
                      fontSize: 16 * wr,
                      fontWeight: FontWeight.w600,
                      height: 22 / 16,
                      color: context.appPrimaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _dividerLine(context, wr, lineW),
          InkWell(
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10 * layout),
              child: Row(
                children: [
                  SizedBox(width: 4 * wr),
                  Image.asset(
                    AppImages.aboutMark,
                    width: 23.33 * wr,
                    height: 23.33 * layout,
                    fit: BoxFit.contain,
                    color: AppColors.primaryBlue,
                  ),
                  SizedBox(width: 13 * wr),
                  Text(
                    'About Busify',
                    style: GoogleFonts.inter(
                      fontSize: 16 * wr,
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

  /// **341×46** min, radius **33**, gradient; centered icon + label (avoids padding overflow).
  Widget buildLogoutButton(BuildContext context, double wr, double layout, double cappedW) {
    final w = math.min(341 * wr, cappedW - 32 * wr);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushAndRemoveUntil(
            fadeRoute(const RoleSelectionScreen()),
            (route) => false,
          );
        },
        borderRadius: BorderRadius.circular(33 * wr),
        child: Ink(
          width: w,
          padding: EdgeInsets.symmetric(horizontal: 20 * wr, vertical: 10 * layout),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(33 * wr),
            gradient: AppColors.primaryButtonGradient,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppImages.logoutParentProfile,
                width: 26 * wr,
                height: 26 * layout,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 12 * wr),
              Text(
                'Log Out',
                style: GoogleFonts.inter(
                  fontSize: 20 * wr,
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

/// Figma toggle: **66×28**, radius **33**, track **595959 33%**, thumb **25** white.
class _FigmaPillToggle extends StatelessWidget {
  const _FigmaPillToggle({
    required this.value,
    required this.wr,
    required this.layout,
    required this.onChanged,
  });

  final bool value;
  final double wr;
  final double layout;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 66 * wr,
        height: 28 * layout,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(33 * wr),
          color: AppColors.toggleTrackMuted,
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 1 * wr, vertical: 1 * layout),
                child: Container(
                  width: 25 * wr,
                  height: 25 * layout,
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
