import 'dart:math' as math;

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/routes/fade_route.dart';
import 'package:application/screens/parent/parent_home_screen.dart';
import 'package:application/screens/parent/parent_profile_screen.dart';
import 'package:application/screens/parent/parent_track_bus_screen.dart';
import 'package:application/widgets/parent/parent_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Parent **Edit Profile** screen.
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 221,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: buildHeader(context),
                          ),
                          const Positioned(
                            top: 125,
                            left: 0,
                            right: 0,
                            child: Center(child: _EditProfilePicture()),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          buildFormCard(context),
                          const SizedBox(height: 26),
                          Center(child: buildSaveButton(context)),
                        ],
                      ),
                    ),
                  ],
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

  /// **168** height, bottom radius **40**, **214071 @ 97%**, brand logo **126×54**, title **Edit Profile**.
  Widget buildHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
      child: SizedBox(
        height: 168,
        width: double.infinity,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.primaryBlue97)),
            Positioned.fill(
              top: 40,
              bottom: 72,
              child: Center(
                child: Image.asset(
                  AppImages.logo,
                  width: 126,
                  height: 54,
                  fit: BoxFit.contain,
                ),
              ),
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
                      Icons.chevron_left,
                      color: AppColors.white,
                      size: 22.5,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 103,
              child: Text(
                'Edit Profile',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
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

  /// **341×408** min, radius **15**, **#D9D9D9 49%**.
  Widget buildFormCard(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final cardW = math.min(341.0, screenW - 48);
    final inputW = math.min(271.0, cardW - 70);

    return Container(
      width: cardW,
      constraints: const BoxConstraints(minHeight: 408),
      padding: EdgeInsets.fromLTRB(
        math.max(16, (cardW - inputW) / 2),
        22,
        math.max(16, (cardW - inputW) / 2),
        22,
      ),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildFormField(
            context: context,
            inputW: inputW,
            label: 'Full Name',
            controller: _fullNameController,
            obscure: false,
          ),
          const SizedBox(height: 22),
          buildFormField(
            context: context,
            inputW: inputW,
            label: 'Email',
            controller: _emailController,
            obscure: false,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 22),
          buildFormField(
            context: context,
            inputW: inputW,
            label: 'Phone Number',
            controller: _phoneController,
            obscure: false,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 22),
          buildFormField(
            context: context,
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
    required double inputW,
    required String label,
    required TextEditingController controller,
    required bool obscure,
    TextInputType? keyboardType,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.inputStrokeBlack21, width: 1),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            height: 22 / 20,
            color: context.appPrimaryText,
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: inputW,
          height: 40,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 22 / 16,
              color: context.appPrimaryText,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: context.appInputBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: border,
              enabledBorder: border,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: AppColors.linkBlue, width: 1.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// **341×46** min, radius **33**, gradient **#D9D9D9 → #2859C5**, label **Save** white.
  Widget buildSaveButton(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final w = math.min(341.0, screenW - 48);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(33),
        child: Ink(
          width: w,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(33),
            gradient: AppColors.editProfileSaveGradient,
          ),
          child: Center(
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                fontSize: 20,
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

/// Ellipse **114×96** `#F5F5F5`, inner photo **91×78**, camera badge.
class _EditProfilePicture extends StatelessWidget {
  const _EditProfilePicture();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 114,
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 114,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Image.asset(
              AppImages.parentProfilePic,
              width: 91,
              height: 78,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.grayText,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 14,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
