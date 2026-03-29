import 'dart:math' as math;

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/core/layout/app_layout.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/routes/fade_route.dart';
import 'package:application/screens/parent/parent_home_screen.dart';
import 'package:application/screens/parent/parent_profile_screen.dart';
import 'package:application/screens/parent/parent_track_bus_screen.dart';
import 'package:application/widgets/parent/parent_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Parent **Edit Profile** — unified [AppLayout] scaling.
class ParentEditProfileScreen extends StatefulWidget {
  const ParentEditProfileScreen({super.key});

  @override
  State<ParentEditProfileScreen> createState() => _ParentEditProfileScreenState();
}

class _ParentEditProfileScreenState extends State<ParentEditProfileScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: 'Ali Ahmed');
    _emailController = TextEditingController(text: 'ali@busify.com');
    _phoneController = TextEditingController(text: '01233470453');
    _passwordController = TextEditingController(text: '************');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 221 * layout,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: buildHeader(context, layout, layout),
                          ),
                          Positioned(
                            top: 125 * layout,
                            left: 0,
                            right: 0,
                            child: buildProfilePicture(layout, layout),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24 * layout),
                      child: Column(
                        children: [
                          buildFormCard(context, layout, layout, cappedW),
                          SizedBox(height: 26 * layout),
                          Center(child: buildSaveButton(context, layout, layout, cappedW)),
                        ],
                      ),
                    ),
                  ],
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
              onProfileTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  fadeRoute(const ParentProfileScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// **168** height, bottom radius **40**, **214071 @ 97%**, logo **81×34**, title **Edit Profile**.
  Widget buildHeader(BuildContext context, double wr, double layout) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(40 * wr),
        bottomRight: Radius.circular(40 * wr),
      ),
      child: SizedBox(
        height: 168 * layout,
        width: double.infinity,
        child: Stack(
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
                      Icons.chevron_left,
                      color: AppColors.white,
                      size: math.min(22.5 * layout, 22 * wr),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 54 * layout,
              child: Center(
                child: Image.asset(
                  AppImages.logo,
                  width: 81 * wr,
                  height: 34 * layout,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 103 * layout,
              child: Text(
                'Edit Profile',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24 * wr,
                  fontWeight: FontWeight.w500,
                  height: 22 / 24,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ellipse **114×96** `#F5F5F5`, inner photo **91×78**, camera badge.
  Widget buildProfilePicture(double wr, double layout) {
    return SizedBox(
      width: 114 * wr,
      height: 96 * layout,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 114 * wr,
            height: 96 * layout,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(999 * wr),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(999 * wr),
            child: Image.asset(
              AppImages.parentProfilePic,
              width: 91 * wr,
              height: 78 * layout,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 2 * wr,
            bottom: 2 * layout,
            child: Container(
              width: 26 * wr,
              height: 26 * layout,
              decoration: BoxDecoration(
                color: AppColors.grayText,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1.5 * wr),
              ),
              child: Icon(
                Icons.camera_alt,
                size: 14 * wr,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// **341×408** min, radius **15**, **#D9D9D9 49%**.
  Widget buildFormCard(BuildContext context, double wr, double layout, double cappedW) {
    final cardW = math.min(341.0 * wr, cappedW - 48 * wr);
    final inputW = math.min(271.0 * wr, cardW - 70 * wr);

    return Container(
      width: cardW,
      constraints: BoxConstraints(minHeight: 408 * layout),
      padding: EdgeInsets.fromLTRB(
        math.max(16 * wr, (cardW - inputW) / 2),
        22 * layout,
        math.max(16 * wr, (cardW - inputW) / 2),
        22 * layout,
      ),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(15 * wr),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildFormField(
            context: context,
            wr: wr,
            layout: layout,
            inputW: inputW,
            label: 'Full Name',
            controller: _fullNameController,
            obscure: false,
          ),
          SizedBox(height: 22 * layout),
          buildFormField(
            context: context,
            wr: wr,
            layout: layout,
            inputW: inputW,
            label: 'Email',
            controller: _emailController,
            obscure: false,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 22 * layout),
          buildFormField(
            context: context,
            wr: wr,
            layout: layout,
            inputW: inputW,
            label: 'Phone Number',
            controller: _phoneController,
            obscure: false,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 22 * layout),
          buildFormField(
            context: context,
            wr: wr,
            layout: layout,
            inputW: inputW,
            label: 'Password',
            controller: _passwordController,
            obscure: true,
          ),
        ],
      ),
    );
  }

  Widget buildFormField({
    required BuildContext context,
    required double wr,
    required double layout,
    required double inputW,
    required String label,
    required TextEditingController controller,
    required bool obscure,
    TextInputType? keyboardType,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15 * wr),
      borderSide: const BorderSide(color: AppColors.inputStrokeBlack21, width: 1),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 20 * wr,
            fontWeight: FontWeight.w500,
            height: 22 / 20,
            color: context.appPrimaryText,
          ),
        ),
        SizedBox(height: 7 * layout),
        SizedBox(
          width: inputW,
          height: 40 * layout,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(
              fontSize: 16 * wr,
              fontWeight: FontWeight.w500,
              height: 22 / 16,
              color: context.appPrimaryText,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: context.appInputBackground,
              contentPadding: EdgeInsets.symmetric(horizontal: 16 * wr, vertical: 10 * layout),
              border: border,
              enabledBorder: border,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15 * wr),
                borderSide: const BorderSide(color: AppColors.linkBlue, width: 1.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// **341×46** min, radius **33**, gradient **#D9D9D9 → #2859C5**, label **Save** white.
  Widget buildSaveButton(
    BuildContext context,
    double wr,
    double layout,
    double cappedW,
  ) {
    final w = math.min(341 * wr, cappedW - 48 * wr);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(33 * wr),
        child: Ink(
          width: w,
          padding: EdgeInsets.symmetric(vertical: 12 * layout),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(33 * wr),
            gradient: AppColors.editProfileSaveGradient,
          ),
          child: Center(
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                fontSize: 20 * wr,
                fontWeight: FontWeight.w500,
                height: 22 / 20,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

}
