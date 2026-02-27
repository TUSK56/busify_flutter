import 'dart:ui';
import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/parent/parent_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/screens/supervisor/supervisor_login_screen.dart';
// this page have welcome msg with login as supervisor or parent
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Screen dimensions for responsive layout
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;

    // Cap the width for tablet/iPad support
    double effectiveWidth = size.width;
    if (effectiveWidth > 450) effectiveWidth = 450;

    // Calculate dynamic scaling ratios based on your 390 width
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
                  // Top Spacing
                  SizedBox(height: screenHeight * 0.02),

                  // Top Logo (2.png) - Aligned to the left with dynamic padding
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 47 * widthRatio),
                      child: Image.asset(
                        AppImages.logo,
                        width: 144 * widthRatio, // Scales from 144 max
                        height: 115 * widthRatio,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Back Button (Chevron Backward)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 24 * widthRatio),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Go back
                        },
                        child: const SizedBox(
                          width: 45,
                          height: 45,
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 28, // Scaled slightly to match the 45x45 frame
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.01),

                  // Welcome Text
                  const Text(
                    'Welcome!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold, // Bold 32
                      fontSize: 32,
                      letterSpacing: 0,
                      color: AppColors.white,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.01),

                  // Subtitle Text
                  Text(
                    'Please select your role',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400, // Regular 16
                      fontSize: 16,
                      letterSpacing: 0,
                      color: AppColors.white.withOpacity(0.66), // ffffff 66%
                    ),
                  ),

                  // Spacing before Glass Card
                  SizedBox(height: screenHeight * 0.05),

                  // Square Glassmorphism Card (w: 331, h: 331)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Background blur
                      child: Container(
                        width: effectiveWidth * 0.85, // ~331 max
                        height: effectiveWidth * 0.85, // Enforces the perfect square shape you designed
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.27), // ffffff 27%
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.white.withOpacity(0.50), // ffffff 50%
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center, // Vertically centers buttons inside the card
                          children: [

                            // ------------------------------------------
                            // SUPERVISOR BUTTON - NOW NAVIGATES TO SCREEN 6
                            // ------------------------------------------
                            _buildRoleButton(
                              context: context,
                              title: 'Supervisor',
                              width: effectiveWidth * 0.74, // ~291 max
                              onTap: () {
                                // Navigate to Supervisor Login
                                Navigator.push(
                                  context,
                                  fadeRoute(const SupervisorLoginScreen()),
                                );
                              },
                            ),

                            // Spacing between buttons (~16px)
                            SizedBox(height: screenHeight * 0.02),

                            // ------------------------------------------
                            // PARENT BUTTON
                            // ------------------------------------------
                            _buildRoleButton(
                              context: context,
                              title: 'Parent',
                              width: effectiveWidth * 0.74, // ~291 max
                              onTap: () {
                                // Navigate to Parent Login
                                Navigator.push(
                                  context,
                                  fadeRoute(const ParentLoginScreen()),
                                );
                              },
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),

                  // Safe bottom padding
                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // A reusable function widget to build the exact role buttons inside the card
  Widget _buildRoleButton({
    required BuildContext context,
    required String title,
    required double width,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 62,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.21), // ffffff 21%
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppColors.white.withOpacity(0.79), // ffffff 79%
            width: 1,
          ),
        ),
        // We use a Stack so the text stays perfectly in the mathematical center,
        // but the Chevron icon gets pushed nicely to the far right.
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Centered Role Text
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold, // Bold 32
                fontSize: 32,
                color: AppColors.white,
              ),
            ),

            // Right-aligned Forward Chevron (Chevron Backwards rotated 180)
            const Positioned(
              right: 16, // Padding from right edge
              child: Icon(
                Icons.arrow_forward_ios, // Automatically looks like 180-rotated chevron_backward
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}