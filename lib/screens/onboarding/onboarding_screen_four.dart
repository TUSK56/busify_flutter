import 'dart:ui';
import 'package:application/helpers/app_back_button.dart';
import 'package:application/helpers/fade_route.dart';
import 'package:flutter/material.dart';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'role_selection_screen.dart';
// Onboarding page four that have 1 pic of parent with phone and get started arrow back
class OnboardingScreenFour extends StatelessWidget {
  const OnboardingScreenFour({super.key});

  @override
  Widget build(BuildContext context) {
    // Screen dimensions for responsive layout
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.background),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Header Spacing (~3% of height)
                  SizedBox(height: screenHeight * 0.03),

                  // Header (Back Arrow Only - Skip is removed on this screen)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AppBackButton(
                        onTap: () => Navigator.pop(context),
                        color: Colors.white,
                        icon: Icons.arrow_back_ios,
                        iconSize: 22.5,
                      ),
                    ),
                  ),

                  // Spacing between Header and Glass Card
                  SizedBox(height: screenHeight * 0.06),

                  // Glassmorphism Card (w: 331, h: 427)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 331),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.14), // ffffff 14%
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.white.withOpacity(0.76), // ffffff 76% stroke
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Image 5.png
                            Image.asset(
                              AppImages.onboardingParentTrack,
                              width: 290, // ~290 max
                              height: 196, // ~196 max
                              fit: BoxFit.contain,
                            ),

                            SizedBox(height: screenHeight * 0.03),

                            // Title Text
                            const Text(
                              'Parents Track the Route',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600, // SemiBold
                                fontSize: 24,
                                height: 22 / 24,
                                letterSpacing: 0,
                                color: AppColors.white,
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.03),

                            // Divider Line (w: 254, weight: 2)
                            Container(
                              width: 254, // ~254 max
                              height: 2,
                              color: AppColors.white.withOpacity(0.66), // ffffff 66%
                            ),

                            SizedBox(height: screenHeight * 0.025),

                            // Subtitle Text
                            const Text(
                              "Monitor your child's journey in real-time on the map.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400, // Regular
                                fontSize: 16,
                                height: 22 / 16,
                                letterSpacing: 0,
                                color: AppColors.white,
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.01),
                          ],
                        ),
                      ),
                    ),
                    ),
                  ),

                  // Spacing between Card and Action Button
                  SizedBox(height: screenHeight * 0.055),

                  // "Get Started" Button (README: gradient)
                  SizedBox(
                    width: 291,
                    height: 62,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryButtonGradient,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(context, fadeRoute(const RoleSelectionScreen()));
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: const Center(
                            child: Text(
                              'Get Started',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                                height: 22 / 32,
                                letterSpacing: 0,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Safe padding at the bottom
                  SizedBox(height: screenHeight * 0.04),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}