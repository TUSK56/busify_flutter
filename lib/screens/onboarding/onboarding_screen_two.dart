import 'dart:ui'; // Required for the blur effect (ImageFilter)
import 'package:application/helpers/fade_route.dart';
import 'package:flutter/material.dart';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'onboarding_screen_three.dart';
import 'role_selection_screen.dart';
// second page that have 1 pic of bus and next skip arrow back
class OnboardingScreenTwo extends StatelessWidget {
  const OnboardingScreenTwo({super.key});

  @override
  Widget build(BuildContext context) {
    // Screen dimensions for responsive layout
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;

    // Cap the width for tablet/iPad support
    double effectiveWidth = size.width;
    if (effectiveWidth > 450) effectiveWidth = 450;

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

                  // Header (Back Arrow & Skip Text)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: effectiveWidth * 0.06), // ~24px
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back arrow hidden on first onboarding screen (nothing to go back to)
                        const SizedBox(width: 22.5),
                        // Skip Text
                        GestureDetector(
                          onTap: () {
                            // Navigate to Role Selection
                            Navigator.push(
                              context,
                              fadeRoute(const RoleSelectionScreen()),
                            );
                          },
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600, // SemiBold
                              fontSize: 24,
                              height: 22 / 24,
                              letterSpacing: 0,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Spacing between Header and Glass Card
                  SizedBox(height: screenHeight * 0.06), // ~57px distance

                  // Glassmorphism Card (w: 331, h: 427)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Background blur effect
                      child: Container(
                        width: effectiveWidth * 0.85, // ~331 max
                        // height scales responsively but maintains the general proportion
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.14), // ffffff 14%
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.white.withOpacity(0.76), // ffffff 76% stroke
                            width: 1, // inside weight 1
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Hugs the content
                          children: [
                            // Image 3.png
                            Image.asset(
                              AppImages.onboardingBus,
                              width: effectiveWidth * 0.74, // ~290 max
                              height: screenHeight * 0.23, // ~196 max
                              fit: BoxFit.contain,
                            ),

                            SizedBox(height: screenHeight * 0.03), // Spacing

                            // Title Text
                            const Text(
                              'School Bus on the way',
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

                            SizedBox(height: screenHeight * 0.03), // Spacing

                            // Divider Line (w: 254, weight: 2)
                            Container(
                              width: effectiveWidth * 0.65, // ~254 max
                              height: 2, // weight: 2
                              color: AppColors.white.withOpacity(0.66), // ffffff 66%
                            ),

                            SizedBox(height: screenHeight * 0.025), // Spacing

                            // Subtitle Text
                            const Text(
                              'Track the bus in real-time as it heads to school.',
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

                            // Extra padding at the bottom of the card
                            SizedBox(height: screenHeight * 0.01),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Spacing between Card and Next Button
                  SizedBox(height: screenHeight * 0.055), // ~48px

                  // "Next" Button (README: gradient 214071 right, 3f79d7 left)
                  SizedBox(
                    width: effectiveWidth * 0.74 > 291 ? 291 : effectiveWidth * 0.74,
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
                            Navigator.push(context, fadeRoute(const OnboardingScreenThree()));
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: const Center(
                            child: Text(
                              'Next',
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