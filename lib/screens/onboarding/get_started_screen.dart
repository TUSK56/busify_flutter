import 'package:application/screens/onboarding/role_selection_screen.dart';
import 'package:application/helpers/fade_route.dart';
import 'package:flutter/material.dart';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'onboarding_screen_two.dart';
// first page that have 2 logo and get started with login
class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;

    // We cap the maximum width at 450 so it doesn't look stretched on tablets/iPads
    double effectiveWidth = size.width;
    if (effectiveWidth > 450) effectiveWidth = 450;

    // Mathematical proportions based exactly on your Figma dimensions
    final double img1Width = effectiveWidth * 0.66; // 260 / 390
    final double img2Width = effectiveWidth * 0.59; // 231 / 390
    final double img2TopOffset = img1Width * 0.688; // 179 / 260
    final double totalStackHeight = img1Width * 1.57; // 410 / 260

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppImages.background), // Updated Path
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
                  // Top spacing dynamically scaling to ~15% of screen height
                  SizedBox(height: screenHeight * 0.15),

                  // Responsive Stack to handle the overlapping images
                  SizedBox(
                    height: totalStackHeight,
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // Image 1 (3D Bus Icon)
                        Positioned(
                          top: 0,
                          child: Image.asset(
                            AppImages.busIcon, // Updated Path
                            width: img1Width,
                            fit: BoxFit.contain,
                          ),
                        ),
                        // Image 2 (Busify Wordmark)
                        Positioned(
                          top: img2TopOffset, // Dynamically calculates overlap
                          child: Image.asset(
                            AppImages.logo, // Updated Path
                            width: img2Width,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Spacing between the bottom of Image 2 and Button (~4.5% of height)
                  SizedBox(height: screenHeight * 0.045),

                  // "Get Started" Button (Width scales, but caps at 291 max)
                  SizedBox(
                    width: effectiveWidth * 0.74 > 291 ? 291 : effectiveWidth * 0.74,
                    height: 62,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: const BorderSide(
                            color: AppColors.primaryBlue,
                            width: 1,
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          fadeRoute(const OnboardingScreenTwo()),
                        );
                      },
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          height: 22 / 24,
                          letterSpacing: 0,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),

                  // Spacing between Button and Bottom Text (~13% of height)
                  SizedBox(height: screenHeight * 0.13),

                  // Bottom Text "Already have an account? Log in"
                  GestureDetector(
                    onTap: () {
                      // Navigate to Role Selection
                      Navigator.push(
                        context,
                        fadeRoute(const RoleSelectionScreen()),
                      );
                    },
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          height: 22 / 16,
                          letterSpacing: 0,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(color: AppColors.white),
                          ),
                          TextSpan(
                            text: 'Log in',
                            style: TextStyle(
                              color: AppColors.linkBlue, // Dropped .withOpacity(0.9) to ensure sharp text on maps
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Extra padding at the bottom for scroll safety
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