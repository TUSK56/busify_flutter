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
                  SizedBox(height: screenHeight * 0.0001),

                  // Top Logo (2.png) - Aligned to the left with dynamic padding
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 40),
                      child: Image.asset(
                        AppImages.logo,
                        width: 144, // Scales from 144 max
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Back Button (Chevron Backward)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 24),
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

                  // Spacing before role cards (README: supervisor.png, parent.png, cards with gradient buttons)
                  SizedBox(height: screenHeight * 0.03),

                  // Supervisor: image (114x97, radius 50) + card (291x132, radius 15, ffffff 32%, stroke 79%)
                  _buildRoleCard(
                    context: context,
                    imagePath: AppImages.supervisorRole,
                    title: 'Supervisor',
                    titleColor: AppColors.white,
                    onTap: () {
                      Navigator.push(context, fadeRoute(const SupervisorLoginScreen()));
                    },
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // Parent: image + card (Parent text black per README)
                  _buildRoleCard(
                    context: context,
                    imagePath: AppImages.parentRole,
                    title: 'Parent',
                    titleColor: AppColors.white,
                    onTap: () {
                      Navigator.push(context, fadeRoute(const ParentLoginScreen()));
                    },
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

  // README: image (114x97, radius 50), card 291x132 radius 15, ffffff 32% stroke 79%, button 223x43 radius 33 gradient left ffffff right 3f79d7
  Widget _buildRoleCard({
    required BuildContext context,
    required String imagePath,
    required String title,
    required Color titleColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 291,
      height: 181,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 49,
            child: Container(
              width: 291,
              height: 132,
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.32),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppColors.white.withOpacity(0.79),
                  width: 1,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: (291 - 114) / 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(
                imagePath,
                width: 114,
                height: 97,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 114,
                  height: 97,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 124,
            left: (291 - 223) / 2,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 223,
                height: 43,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [AppColors.white, Color(0xFF3F79D7)],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        height: 22 / 24,
                        color: titleColor,
                      ),
                    ),
                    const Positioned(
                      right: 16,
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}