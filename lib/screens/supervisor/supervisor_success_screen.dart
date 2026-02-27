import 'dart:ui';
import 'package:application/helpers/fade_route.dart';
import 'package:flutter/material.dart';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'supervisor_login_screen.dart';
// this page after conforming the new password
class SupervisorSuccessScreen extends StatelessWidget {
  const SupervisorSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Screen dimensions for responsive layout
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;

    // Cap the width for tablet/iPad support
    double effectiveWidth = size.width;
    if (effectiveWidth > 450) effectiveWidth = 450;

    // Calculate dynamic scaling ratios based on standard 390 width from Figma
    final double widthRatio = effectiveWidth / 390;

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
                  SizedBox(height: screenHeight * 0.02), // Adjusting for top spacing (y: 77)

                  // Back Button (Chevron Backward)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 24 * widthRatio),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Go back
                        },
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.08), // Spacing before the glass card

                  // Glassmorphism Card (w: 331, h: 426)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Background blur
                      child: Container(
                        width: 331 * widthRatio,
                        height: 426, // Exact height from Figma
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.27), // ffffff 27%
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.white.withOpacity(0.50), // ffffff 50%
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            // Top padding inside the card (Y: 233 - 189 = 44px)
                            const SizedBox(height: 44),

                            // Success Image (7.png)
                            Container(
                              width: 173 * widthRatio,
                              height: 128,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image: const DecorationImage(
                                  image: AssetImage(AppImages.successIcon),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                            // Spacing between Image and Text (Y: 401 - 361 = 40px)
                            const SizedBox(height: 40),

                            // Success Text
                            SizedBox(
                              width: 210 * widthRatio, // Constrained width from Figma
                              child: const Text(
                                'Change password successfully!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600, // SemiBold 24
                                  fontSize: 24,
                                  height: 1.2, // Handles the line height
                                  color: AppColors.white, // ffffff 100%
                                ),
                              ),
                            ),

                            const Spacer(), // Pushes the button to the bottom area

                            // Log In Button
                            GestureDetector(
                              onTap: () {
                                // Navigate back to Login and clear the navigation stack
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  fadeRoute(const SupervisorLoginScreen()),
                                      (route) => false,
                                );
                              },
                              child: Container(
                                width: 291 * widthRatio,
                                height: 62,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue, // 214071 100%
                                  borderRadius: BorderRadius.circular(10), // Radius 10
                                ),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold, // Bold 24
                                    fontSize: 24,
                                    color: AppColors.white, // ffffff 100%
                                  ),
                                ),
                              ),
                            ),

                            // Bottom padding inside the card (Y: 615 - 587 = 28px)
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom padding for safe area
                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}