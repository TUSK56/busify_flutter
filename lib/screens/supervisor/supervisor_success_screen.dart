import 'dart:ui';
import 'dart:io';
import 'package:application/helpers/fade_route.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'supervisor_login_screen.dart';
// this page after conforming the new password
class SupervisorSuccessScreen extends StatelessWidget {
  final bool isAttendanceFlow;
  final String? imagePath;
  final String? studentName;
  final String? studentGrade;
  final String? studentBirthdate;
  final int? boarded;
  final int? remaining;

  const SupervisorSuccessScreen({super.key})
      : isAttendanceFlow = false,
        imagePath = null,
        studentName = null,
        studentGrade = null,
        studentBirthdate = null,
        boarded = null,
        remaining = null;

  const SupervisorSuccessScreen.attendance({
    super.key,
    required this.imagePath,
    required this.studentName,
    required this.studentGrade,
    required this.studentBirthdate,
    required this.boarded,
    required this.remaining,
  }) : isAttendanceFlow = true;

  @override
  Widget build(BuildContext context) {
    if (isAttendanceFlow) {
      return Scaffold(
        backgroundColor: context.appScaffoldBackground,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 140,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Center(
                  child: Image.asset(AppImages.logo, height: 80, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Attendance Saved',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.linkBlue,
                ),
              ),
              const SizedBox(height: 16),
              if (imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(imagePath!), width: 120, height: 120, fit: BoxFit.cover),
                ),
              const SizedBox(height: 12),
              Text(
                studentName ?? 'Student',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: context.appPrimaryText,
                ),
              ),
              const SizedBox(height: 10),
              if (studentGrade != null && studentBirthdate != null)
                Text(
                  'Grade: $studentGrade    •    Birthdate: $studentBirthdate',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.appPrimaryText,
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Boarded: ${boarded ?? 0}    Remaining: ${remaining ?? 0}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: context.appPrimaryText,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Back To Trip',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                  SizedBox(height: screenHeight * 0.02), // Adjusting for top spacing (y: 77)

                  // Back Button (Chevron Backward)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 24),
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
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 331),
                        child: Container(
                          width: double.infinity,
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
                              width: 173,
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
                              width: 210, // Constrained width from Figma
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
                                width: 291,
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