import 'dart:math' as math;

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/routes/fade_route.dart';
import 'package:application/widgets/parent/parent_bottom_nav_bar.dart';
import 'package:application/widgets/parent/parent_brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'parent_profile_screen.dart';
import 'parent_track_bus_screen.dart';

/// Layout / visibility knobs for [ParentHomeScreen].
class _ParentHomeLayout {
  _ParentHomeLayout._();

  /// Set to false to hide the back-style arrow next to "Track Bus".
  static const bool showTrackBusBackArrow = true;

  /// Icon size for that arrow (e.g. [Icons.arrow_back_ios_new]).
  static const double trackBusBackArrowSize = 16;

  /// Space between the arrow and the label.
  static const double trackBusBackArrowGap = 8;

  /// If true, the back arrow is drawn after "Track Bus"; if false, before it.
  static const bool trackBusBackArrowAfterLabel = true;

  /// Uniform scale for the Track Bus button: multiplies width, height, padding,
  /// font, and arrow sizes. Use `1.0` as baseline.
  static const double trackBusButtonScale = 1.0;

  /// Outer size of the gradient (before [trackBusButtonScale]).
  static const double trackBusButtonWidth = 220;
  static const double trackBusButtonHeight = 42;

  /// Horizontal padding inside the Track Bus gradient.
  static const double _trackBusBtnPadH = 14;
  static const double _trackBusBtnFont = 20;
}

/// Parent home screen.
class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();
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
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    const horizontalInset = 15.0;
    final cardW = math.min(360.0, screenW - horizontalInset * 2);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 8 + bottomInset),
                child: FadeTransition(
                  opacity: _entranceFade,
                  child: SlideTransition(
                    position: _entranceSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buildHeader(),
                        const SizedBox(height: 28),
                        buildGreeting(context),
                        const SizedBox(height: 25),
                        buildStudentCard(context, cardW),
                        const SizedBox(height: 20),
                        buildAttendanceCard(context, cardW),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ParentBottomNavBar(
              activeTab: ParentNavTab.home,
              onHomeTap: () {},
              onTrackBusTap: () {
                Navigator.of(
                  context,
                ).push(fadeRoute(const ParentTrackBusScreen()));
              },
              onProfileTap: () {
                Navigator.of(
                  context,
                ).push(fadeRoute(const ParentProfileScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Header: h 139, primary blue, bottom radius 22, centered brand logo.
  Widget buildHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(22),
        bottomRight: Radius.circular(22),
      ),
      child: SizedBox(
        height: 139,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 139,
              color: AppColors.primaryBlue,
            ),
            Positioned.fill(
              child: ParentBrandLogo.headerImage(AppImages.parentHomeLogo),
            ),
          ],
        ),
      ),
    );
  }

  /// Greeting + subtitle; profile image beside the name.
  Widget buildGreeting(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Hello , Omar',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: context.appPrimaryText,
                ),
              ),
              const SizedBox(width: 10),
              Image.asset(
                AppImages.parentHomePerson,
                width: 37,
                height: 29,
                fit: BoxFit.contain,
              ),
            ],
          ),
          Text(
            "Track your child's bus",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: context.appSecondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStudentCard(BuildContext context, double cardW) {
    return Center(
      child: Container(
        width: cardW,
        constraints: const BoxConstraints(minHeight: 329),
        decoration: BoxDecoration(
          color: context.appPanelBackground,
          borderRadius: BorderRadius.circular(15),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 22, top: 11),
              color: AppColors.studentCardHeaderBar,
              alignment: Alignment.centerLeft,
              child: Text(
                'Student',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: context.appPrimaryText,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(
                          AppImages.parentHomeStudentAvatar,
                          width: 66,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 25),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Adam Omar',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                // height: 22 / 20,
                                color: context.appPrimaryText,
                              ),
                            ),
                            Text(
                              'Grade 6',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                // height: 22 / 16,
                                color: context.appSecondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Image.asset(
                        AppImages.parentHomeBus,
                        width: 26,
                        height: 26,
                      ),
                      const SizedBox(width: 21),
                      Expanded(
                        child: Text(
                          'Boarded Bus',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            // height: 22 / 16,
                            color: AppColors.gray333,
                          ),
                        ),
                      ),
                      Image.asset(
                        AppImages.parentHomeCheckParent,
                        width: 27,
                        height: 27,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '7:30 AM',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          // height: 22 / 15,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 47, top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bus #7',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            // height: 22 / 16,
                            color: AppColors.textBlack,
                          ),
                        ),
                        Text(
                          'On the way',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            // height: 22 / 16,
                            color: AppColors.greenStatusBright,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: _TrackBusButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).push(fadeRoute(const ParentTrackBusScreen()));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Attendance card: min height 132, radius 15 — content sizes intrinsically to avoid overflow.
  Widget buildAttendanceCard(BuildContext context, double cardW) {
    return Center(
      child: Container(
        width: cardW,
        constraints: const BoxConstraints(minHeight: 132),
        decoration: BoxDecoration(
          color: context.appPanelBackground,
          borderRadius: BorderRadius.circular(15),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 49,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              color: AppColors.studentCardHeaderBar,
              child: Row(
                children: [
                  Image.asset(
                    AppImages.parentHomeAttendanceChart,
                    width: 28,
                    height: 24.5,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Attendance',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 22 / 20,
                      color: context.appPrimaryText,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Today: ',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 22 / 16,
                          color: context.appPrimaryText,
                        ),
                      ),
                      Text(
                        'Present',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 22 / 16,
                          color: AppColors.greenStatusBright,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Image.asset(
                        AppImages.parentHomeCheckParent,
                        width: 27,
                        height: 27,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This Week: 4 / 5 days',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 22 / 16,
                      color: context.appSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Track Bus CTA: gradient, press scale animation.
class _TrackBusButton extends StatefulWidget {
  const _TrackBusButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_TrackBusButton> createState() => _TrackBusButtonState();
}

class _TrackBusButtonState extends State<_TrackBusButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _press, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _ParentHomeLayout.trackBusButtonScale;
    final btnW = _ParentHomeLayout.trackBusButtonWidth * s;
    final btnH = _ParentHomeLayout.trackBusButtonHeight * s;
    final padH = _ParentHomeLayout._trackBusBtnPadH * s;
    final fontSize = _ParentHomeLayout._trackBusBtnFont * s;
    final arrowSize = _ParentHomeLayout.trackBusBackArrowSize * s;
    final arrowGap = _ParentHomeLayout.trackBusBackArrowGap * s;

    return Listener(
      onPointerDown: (_) => _press.forward(),
      onPointerUp: (_) {
        _press.reverse();
        widget.onPressed();
      },
      onPointerCancel: (_) => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: btnW,
          height: btnH,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: AppColors.primaryButtonGradient,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padH),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_ParentHomeLayout.showTrackBusBackArrow &&
                      !_ParentHomeLayout.trackBusBackArrowAfterLabel) ...[
                    Icon(
                      Icons.arrow_back_ios_new,
                      size: arrowSize,
                      color: AppColors.white,
                    ),
                    SizedBox(width: arrowGap),
                  ],
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          'Track Bus',
                          style: GoogleFonts.inter(
                            color: AppColors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_ParentHomeLayout.showTrackBusBackArrow &&
                      _ParentHomeLayout.trackBusBackArrowAfterLabel) ...[
                    SizedBox(width: arrowGap),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: arrowSize,
                      color: AppColors.white,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
