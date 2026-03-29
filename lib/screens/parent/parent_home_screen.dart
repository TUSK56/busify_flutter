import 'dart:math' as math;

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/core/layout/app_layout.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/routes/fade_route.dart';
import 'package:application/widgets/parent/parent_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'parent_profile_screen.dart';
import 'parent_track_bus_screen.dart';

/// Parent home — unified [AppLayout] scaling (390 pt reference).
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
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = AppLayout.metricsOf(context);
    final layout = m.scale;
    final cappedW = m.cappedWidth;
    final horizontalInset = 15.0 * layout;
    final cardW = math.min(360.0 * layout, cappedW - horizontalInset * 2);

    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 8 + m.bottomInset),
              child: FadeTransition(
                opacity: _entranceFade,
                child: SlideTransition(
                  position: _entranceSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildHeader(layout, layout),
                      SizedBox(height: 28 * layout),
                      buildGreeting(context, layout, layout),
                      SizedBox(height: 25 * layout),
                      buildStudentCard(context, layout, layout, cardW),
                      SizedBox(height: 20 * layout),
                      buildAttendanceCard(context, layout, layout, cardW),
                      SizedBox(height: 32 * layout),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ParentBottomNavBar(
            scale: layout,
            activeTab: ParentNavTab.home,
            onHomeTap: () {},
            onTrackBusTap: () {
              Navigator.of(context).push(
                fadeRoute(const ParentTrackBusScreen()),
              );
            },
            onProfileTap: () {
              Navigator.of(context).push(
                fadeRoute(const ParentProfileScreen()),
              );
            },
          ),
        ],
      ),
      ),
    );
  }

  /// Header: h 139, primary blue, bottom radius 22, centered logo.
  Widget buildHeader(double wr, double hr) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(22 * wr),
        bottomRight: Radius.circular(22 * wr),
      ),
      child: SizedBox(
        height: 139 * hr,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 139 * hr,
              color: AppColors.primaryBlue,
            ),
            Positioned(
              top: 62 * hr,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  AppImages.parentHomeLogo,
                  width: 126 * wr,
                  height: 54 * hr,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Greeting + subtitle + profile image 43×43.
  Widget buildGreeting(BuildContext context, double wr, double hr) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24 * wr),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 43 * wr),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Hello, Omar',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 35 * wr,
                    fontWeight: FontWeight.w600,
                    height: 22 / 35,
                    color: context.appPrimaryText,
                  ),
                ),
                Text(
                  "Track your child's bus",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16 * wr,
                    fontWeight: FontWeight.w400,
                    height: 22 / 16,
                    color: context.appSecondaryText,
                  ),
                ),
              ],
            ),
          ),
          ClipOval(
            child: Image.asset(
              AppImages.parentHomePerson,
              width: 43 * wr,
              height: 43 * wr,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  /// Student + bus card: 360×329 (scaled), radius 15, #E6E9ED.
  Widget buildStudentCard(BuildContext context, double wr, double hr, double cardW) {
    return Center(
      child: SizedBox(
        width: cardW,
        height: 329 * hr,
        child: Container(
          decoration: BoxDecoration(
            color: context.appPanelBackground,
            borderRadius: BorderRadius.circular(15 * wr),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 40 * hr,
                padding: EdgeInsets.only(left: 22 * wr, top: 11 * hr),
                color: AppColors.studentCardHeaderBar,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Student',
                  style: GoogleFonts.inter(
                    fontSize: 20 * wr,
                    fontWeight: FontWeight.w600,
                    height: 22 / 20,
                    color: context.appPrimaryText,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20 * wr, vertical: 16 * hr),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50 * wr),
                            child: Image.asset(
                              AppImages.parentHomeStudentAvatar,
                              width: 66 * wr,
                              height: 64 * hr,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 25 * wr),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Adam Omar',
                                  style: GoogleFonts.inter(
                                    fontSize: 20 * wr,
                                    fontWeight: FontWeight.w600,
                                    height: 22 / 20,
                                    color: context.appPrimaryText,
                                  ),
                                ),
                                Text(
                                  'Grade 6',
                                  style: GoogleFonts.inter(
                                    fontSize: 16 * wr,
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
                      SizedBox(height: 16 * hr),
                      Container(height: 1, color: AppColors.divider),
                      SizedBox(height: 16 * hr),
                      Row(
                        children: [
                          Image.asset(
                            AppImages.parentHomeBus,
                            width: 26 * wr,
                            height: 26 * hr,
                          ),
                          SizedBox(width: 21 * wr),
                          Expanded(
                            child: Text(
                              'Boarded Bus',
                              style: GoogleFonts.inter(
                                fontSize: 16 * wr,
                                fontWeight: FontWeight.w600,
                                height: 22 / 16,
                                color: AppColors.gray333,
                              ),
                            ),
                          ),
                          Image.asset(
                            AppImages.parentHomeCheckParent,
                            width: 27 * wr,
                            height: 27 * hr,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(width: 8 * wr),
                          Text(
                            '7:30 AM',
                            style: GoogleFonts.inter(
                              fontSize: 15 * wr,
                              fontWeight: FontWeight.w500,
                              height: 22 / 15,
                              color: AppColors.grayText,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 47 * wr, top: 8 * hr),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bus #7',
                              style: GoogleFonts.inter(
                                fontSize: 16 * wr,
                                fontWeight: FontWeight.bold,
                                height: 22 / 16,
                                color: AppColors.textBlack,
                              ),
                            ),
                            Text(
                              'On the way',
                              style: GoogleFonts.inter(
                                fontSize: 16 * wr,
                                fontWeight: FontWeight.w600,
                                height: 22 / 16,
                                color: AppColors.greenStatusBright,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 6 * hr),
                      Center(
                        child: _TrackBusButton(
                          wr: wr,
                          hr: hr,
                          onPressed: () {
                            Navigator.of(context).push(
                              fadeRoute(const ParentTrackBusScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Attendance card: min height 132 (scaled), radius 15 — content sizes intrinsically to avoid overflow.
  Widget buildAttendanceCard(BuildContext context, double wr, double hr, double cardW) {
    return Center(
      child: Container(
        width: cardW,
        constraints: BoxConstraints(minHeight: 132 * hr),
        decoration: BoxDecoration(
          color: context.appPanelBackground,
          borderRadius: BorderRadius.circular(15 * wr),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 49 * hr,
              padding: EdgeInsets.symmetric(horizontal: 15 * wr),
              color: AppColors.studentCardHeaderBar,
              child: Row(
                children: [
                  Image.asset(
                    AppImages.parentHomeAttendanceChart,
                    width: 28 * wr,
                    height: 24.5 * hr,
                  ),
                  SizedBox(width: 10 * wr),
                  Text(
                    'Attendance',
                    style: GoogleFonts.inter(
                      fontSize: 20 * wr,
                      fontWeight: FontWeight.w600,
                      height: 22 / 20,
                      color: context.appPrimaryText,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15 * wr, vertical: 12 * hr),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Today: ',
                        style: GoogleFonts.inter(
                          fontSize: 16 * wr,
                          fontWeight: FontWeight.w600,
                          height: 22 / 16,
                          color: context.appPrimaryText,
                        ),
                      ),
                      Text(
                        'Present',
                        style: GoogleFonts.inter(
                          fontSize: 16 * wr,
                          fontWeight: FontWeight.w600,
                          height: 22 / 16,
                          color: AppColors.greenStatusBright,
                        ),
                      ),
                      SizedBox(width: 10 * wr),
                      Image.asset(
                        AppImages.parentHomeCheckParent,
                        width: 27 * wr,
                        height: 27 * hr,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  SizedBox(height: 10 * hr),
                  Text(
                    'This Week: 4 / 5 days',
                    style: GoogleFonts.inter(
                      fontSize: 16 * wr,
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
  const _TrackBusButton({
    required this.wr,
    required this.hr,
    required this.onPressed,
  });

  final double wr;
  final double hr;
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
    _scale = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          width: 220 * widget.wr,
          height: 42 * widget.hr,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15 * widget.wr),
              gradient: AppColors.primaryButtonGradient,
            ),
            child: Center(
              child: Text(
                'Track Bus',
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 20 * widget.wr,
                  fontWeight: FontWeight.w600,
                  height: 22 / 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
