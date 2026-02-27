import 'dart:ui';
import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/parent/parent_signup_student_screen.dart';
import 'package:flutter/material.dart';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';

class ParentSignupInfoScreen extends StatefulWidget {
  const ParentSignupInfoScreen({super.key});

  @override
  State<ParentSignupInfoScreen> createState() => _ParentSignupInfoScreenState();
}

class _ParentSignupInfoScreenState extends State<ParentSignupInfoScreen> {
  // State to manage password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
      extendBodyBehindAppBar: true,
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
          bottom: false, // Let the bottom sheet extend to the very bottom
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.01),

              // Top Logo (2.png)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 47 * widthRatio),
                  child: Image.asset(
                    AppImages.logo,
                    width: 104 * widthRatio,
                    height: 44 * widthRatio,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Header Row: Back Button & Title
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Back Button (Chevron Backward)
                  Padding(
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

                  // Create Account Title
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Create Account',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600, // SemiBold 24
                        fontSize: 24,
                        color: AppColors.white, // ffffff 100%
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.03),

              // Expanded Bottom Sheet for inputs
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Background blur
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.37), // ffffff 37%
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.30), // Approximating linear stroke
                            width: 1,
                          ),
                        ),
                      ),
                      // ScrollView prevents keyboard overflow
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Column(
                          children: [

                            // 1. Parent Name
                            _buildInputField(
                              widthRatio: widthRatio,
                              label: 'Parent Name',
                              hintText: 'Enter your name',
                            ),

                            // 2. Email
                            _buildInputField(
                              widthRatio: widthRatio,
                              label: 'Email',
                              hintText: 'Enter your email',
                              keyboardType: TextInputType.emailAddress,
                            ),

                            // 3. Mobile Number
                            _buildInputField(
                              widthRatio: widthRatio,
                              label: 'Mobile Number',
                              hintText: 'Enter your mobile number',
                              keyboardType: TextInputType.phone,
                            ),

                            // 4. Address
                            _buildInputField(
                              widthRatio: widthRatio,
                              label: 'Address',
                              hintText: 'Enter your address',
                            ),

                            // 5. Password
                            _buildInputField(
                              widthRatio: widthRatio,
                              label: 'Password',
                              hintText: 'Enter password',
                              isPassword: true,
                              obscureText: _obscurePassword,
                              onToggleVisibility: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),

                            // 6. Confirm Password
                            _buildInputField(
                              widthRatio: widthRatio,
                              label: 'Confirm password',
                              hintText: 'Confirm your password',
                              isPassword: true,
                              obscureText: _obscureConfirmPassword,
                              onToggleVisibility: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),

                            SizedBox(height: screenHeight * 0.04),

                            // Continue Button
                            GestureDetector(
                              onTap: () {
                                // Navigate to Success Screen
                                Navigator.push(
                                  context,
                                  fadeRoute(const ParentSignupStudentScreen()),
                                );
                              },
                              child: Container(
                                width: 291 * widthRatio,
                                height: 62,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue, // 214071 100%
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600, // SemiBold 32
                                    fontSize: 32,
                                    color: AppColors.white, // ffffff 100%
                                  ),
                                ),
                              ),
                            ),

                            // Bottom padding to ensure scroll clears the keyboard nicely
                            SizedBox(height: screenHeight * 0.05),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable builder for the complex Label + Text Field combination
  Widget _buildInputField({
    required double widthRatio,
    required String label,
    required String hintText,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0), // Spacing between each input block
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Aligns elements to the left inside the column
        children: [
          // The Pill-shaped Label
          Padding(
            padding: EdgeInsets.only(left: 19 * widthRatio), // Offsets the label perfectly over the field
            child: Container(
              width: 154 * widthRatio, // Fixed width from Figma
              height: 24, // Fixed height from Figma
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue, // 214071 100%
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400, // Regular 14
                  fontSize: 14,
                  color: AppColors.lightGray, // f5f5f5 100%
                ),
              ),
            ),
          ),

          const SizedBox(height: 8), // Slight gap between label and field

          // The Input Field
          Container(
            width: 291 * widthRatio,
            height: 40, // Height restricted to 40 per Figma spec
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.21), // ffffff 21%
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.white.withOpacity(0.79), // ffffff 79%
                width: 1,
              ),
            ),
            child: TextField(
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true, // Condenses the padding to fit inside 40px height
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Centers text vertically
                hintText: hintText,
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: AppColors.white.withOpacity(0.50), // Subtle hint text
                ),
                // Only show suffix icon if it's a password field
                suffixIcon: isPassword
                    ? GestureDetector(
                  onTap: onToggleVisibility,
                  child: Icon(
                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.white.withOpacity(0.66),
                    size: 20,
                  ),
                )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}