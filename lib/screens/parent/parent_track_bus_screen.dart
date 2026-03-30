import 'dart:math' as math;

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/routes/fade_route.dart';
import 'package:application/widgets/parent/parent_bottom_nav_bar.dart';
import 'package:application/widgets/parent/parent_brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'parent_home_screen.dart';
import 'parent_profile_screen.dart';

/// Tune spacing on this screen without hunting through the widget tree.
class _TrackBusLayout {
  _TrackBusLayout._();

  /// Horizontal gap between the "ETA:" label and the time value (e.g. "7 minutes").
  /// Increase to separate them, decrease to bring them closer.
  static const double etaLabelToTimeGap = 6;

  /// Moves the bottom navigation bar vertically. Positive = higher on screen,
  /// negative = lower. Uses [Transform.translate] (does not change hit targets
  /// unless you wrap with a larger hit area — adjust if taps feel off).
  static const double navBarVerticalOffset = 0;
}

/// Parent track bus screen.
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
    final screenW = MediaQuery.sizeOf(context).width;
    final cardW = math.min(364.0, screenW - 26);
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
                padding: EdgeInsets.only(bottom: 12 + bottomInset),
                child: FadeTransition(
                  opacity: _entranceFade,
                  child: SlideTransition(
                    position: _entranceSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buildHeader(context),
                        buildMapSection(),
                        const SizedBox(height: 16),
                        buildBusStatusCard(context, cardW),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -_TrackBusLayout.navBarVerticalOffset),
              child: ParentBottomNavBar(
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
            ),
          ],
        ),
      ),
    );
  }

  /// Blue header (h 139), radius 22, back + centered logo.
  Widget buildHeader(BuildContext context) {
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
              child: ParentBrandLogo.headerImage(AppImages.trackBusLogo),
            ),
            Positioned(
              left: 15,
              top: 10,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.white,
                  size: 22.5,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Center(child: _TrackBusTitle()),
            ),
          ],
        ),
      ),
    );
  }

  /// Full-width map, height 442.
  Widget buildMapSection() {
    return SizedBox(
      width: double.infinity,
      height: 442,
      child: Image.asset(
        AppImages.trackBusMap,
        width: double.infinity,
        height: 442,
        fit: BoxFit.cover,
      ),
    );
  }

  /// Status card 364×187, floating over layout flow (spacing handled by scroll).
  Widget buildBusStatusCard(BuildContext context, double cardW) {
    return Center(
      child: Container(
        width: cardW,
        constraints: const BoxConstraints(minHeight: 187),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.trackBusCardTint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.trackBusCardStroke,
            width: math.max(1.0, 1),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.trackBusCardShadow,
              offset: const Offset(0, 4),
              blurRadius: 4,
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
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    AppImages.trackBusProfile,
                    width: 52,
                    height: 51,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adam Omar',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 22 / 20,
                          color: context.appPrimaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Status: ',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.appSecondaryText,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'On the way',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.greenStatusBright,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            'ETA: ',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.appSecondaryText,
                            ),
                          ),
                          SizedBox(width: _TrackBusLayout.etaLabelToTimeGap),
                          Text(
                            '7 minutes',
                            style: GoogleFonts.inter(
                              fontSize: 16,
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(height: 1, color: AppColors.dividerTrackBus),
            ),
            Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoLine(context, 'Driver:', 'Ahmed Ali'),
                      const SizedBox(height: 5),
                      _infoLine(context, 'Bus:', '7'),
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
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.appSecondaryText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.appSecondaryText,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackBusTitle extends StatelessWidget {
  const _TrackBusTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Track Bus',
      style: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 22 / 24,
        color: AppColors.white,
      ),
    );
  }
}
