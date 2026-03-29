import 'dart:math' as math;

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/core/layout/app_layout.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/routes/fade_route.dart';
import 'package:application/widgets/parent/parent_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'parent_home_screen.dart';
import 'parent_profile_screen.dart';

/// Parent track bus — unified [AppLayout] scaling.
class ParentTrackBusScreen extends StatefulWidget {
  const ParentTrackBusScreen({super.key});

  @override
  State<ParentTrackBusScreen> createState() => _ParentTrackBusScreenState();
}

class _ParentTrackBusScreenState extends State<ParentTrackBusScreen>
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
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
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
    final m = AppLayout.metricsOf(context);
    final layout = m.scale;
    final cappedW = m.cappedWidth;
    final cardW = math.min(364.0 * layout, cappedW - 26 * layout);

    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 12 * layout + m.bottomInset),
                child: FadeTransition(
                  opacity: _entranceFade,
                  child: SlideTransition(
                    position: _entranceSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buildHeader(context, layout, layout),
                        buildMapSection(layout, layout),
                        SizedBox(height: 16 * layout),
                        buildBusStatusCard(context, layout, layout, cardW),
                        SizedBox(height: 24 * layout),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ParentBottomNavBar(
              scale: layout,
              activeTab: ParentNavTab.trackBus,
              onHomeTap: () {
                final nav = Navigator.of(context);
                if (nav.canPop()) {
                  nav.pop();
                } else {
                  nav.pushReplacement(fadeRoute(const ParentHomeScreen()));
                }
              },
              onTrackBusTap: () {},
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

  /// Blue header (h 139), radius 22, back + centered logo.
  Widget buildHeader(BuildContext context, double wr, double hr) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(22 * wr),
        bottomRight: Radius.circular(22 * wr),
      ),
      child: SizedBox(
        height: 139 * hr,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: AppColors.primaryBlue),
            ),
            Positioned(
              left: 15 * wr,
              top: 10 * hr,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.white,
                  size: 22.5 * wr,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: 52 * hr,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset(
                  AppImages.trackBusLogo,
                  width: 108 * wr,
                  height: 46 * hr,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10 * hr,
              child: Center(child: buildTitle(wr, hr)),
            ),
          ],
        ),
      ),
    );
  }

  /// Track Bus title (white, Inter SemiBold 24) — placed in header via [buildHeader].
  Widget buildTitle(double wr, double hr) {
    return Text(
      'Track Bus',
      style: GoogleFonts.inter(
        fontSize: 24 * wr,
        fontWeight: FontWeight.w600,
        height: 22 / 24,
        color: AppColors.white,
      ),
    );
  }

  /// Full-width map, height 442 (scaled).
  Widget buildMapSection(double wr, double hr) {
    return SizedBox(
      width: double.infinity,
      height: 442 * hr,
      child: Image.asset(
        AppImages.trackBusMap,
        width: double.infinity,
        height: 442 * hr,
        fit: BoxFit.cover,
      ),
    );
  }

  /// Status card 364×187, floating over layout flow (spacing handled by scroll).
  Widget buildBusStatusCard(BuildContext context, double wr, double hr, double cardW) {
    return Center(
      child: Container(
        width: cardW,
        constraints: BoxConstraints(minHeight: 187 * hr),
        padding: EdgeInsets.all(18 * wr),
        decoration: BoxDecoration(
          color: AppColors.trackBusCardTint,
          borderRadius: BorderRadius.circular(20 * wr),
          border: Border.all(
            color: AppColors.trackBusCardStroke,
            width: math.max(1.0, 1 * wr),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.trackBusCardShadow,
              offset: Offset(0, 4 * hr),
              blurRadius: 4 * wr,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50 * wr),
                  child: Image.asset(
                    AppImages.trackBusProfile,
                    width: 52 * wr,
                    height: 51 * hr,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 15 * wr),
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
                      SizedBox(height: 4 * hr),
                      Row(
                        children: [
                          Text(
                            'Status: ',
                            style: GoogleFonts.inter(
                              fontSize: 16 * wr,
                              fontWeight: FontWeight.w500,
                              color: context.appSecondaryText,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'On the way',
                              style: GoogleFonts.inter(
                                fontSize: 16 * wr,
                                fontWeight: FontWeight.w600,
                                color: AppColors.greenStatusBright,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4 * hr),
                      Row(
                        children: [
                          Text(
                            'ETA: ',
                            style: GoogleFonts.inter(
                              fontSize: 16 * wr,
                              fontWeight: FontWeight.w500,
                              color: context.appSecondaryText,
                            ),
                          ),
                          Text(
                            '7 minutes',
                            style: GoogleFonts.inter(
                              fontSize: 16 * wr,
                              fontWeight: FontWeight.w500,
                              color: context.appSecondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10 * hr),
              child: Container(height: 1, color: AppColors.dividerTrackBus),
            ),
            Row(
              children: [
                SizedBox(width: 10 * wr),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoLine(context, 'Driver:', 'Ahmed Ali', wr, hr),
                      SizedBox(height: 5 * hr),
                      _infoLine(context, 'Bus:', '7', wr, hr),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(
    BuildContext context,
    String label,
    String value,
    double wr,
    double hr,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60 * wr,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16 * wr,
              fontWeight: FontWeight.w500,
              color: context.appSecondaryText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16 * wr,
              fontWeight: FontWeight.w500,
              color: context.appSecondaryText,
            ),
          ),
        ),
      ],
    );
  }
}
