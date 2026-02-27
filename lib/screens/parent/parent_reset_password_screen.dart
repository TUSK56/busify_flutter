import 'dart:ui';
import 'package:application/helpers/fade_route.dart';
import 'package:flutter/material.dart';
import 'parent_success_screen.dart';
// this page for creating new password and confirming it
class ParentResetPasswordScreen extends StatefulWidget {
  const ParentResetPasswordScreen({super.key});

  @override
  State<ParentResetPasswordScreen> createState() => _ParentResetPasswordScreenState();
}

class _ParentResetPasswordScreenState extends State<ParentResetPasswordScreen> {
  // States to manage password visibility toggles independently
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/10.png'),
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
                  SizedBox(height: screenHeight * 0.02),

                  // Top Logo (2.png)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 47 * widthRatio),
                      child: Image.asset(
                        'assets/images/2.png',
                        width: 104 * widthRatio,
                        height: 100 * widthRatio,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.01),

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
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Instruction Text
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 45 * widthRatio),
                    child: Text(
                      'Please enter your new password to secure your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400, // Regular 15
                        fontSize: 15,
                        color: const Color(0xFFFFFFFF).withOpacity(0.63), // ffffff 63%
                        height: 1.4, // Line height adjustment
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Glassmorphism Card (w: 331, h: 400)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Background blur
                      child: Container(
                        width: 331 * widthRatio,
                        height: 400, // Fixed height per Figma
                        padding: EdgeInsets.symmetric(
                          horizontal: 18 * widthRatio,
                          vertical: 36, // Adjust padding to match Figma inner Y coordinates
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF).withOpacity(0.27), // ffffff 27%
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFFFFFFFF).withOpacity(0.50), // ffffff 50%
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Password Label
                            Padding(
                              padding: EdgeInsets.only(left: 10 * widthRatio, bottom: 8.0),
                              child: Text(
                                'Password',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500, // Medium 24
                                  fontSize: 24,
                                  color: const Color(0xFFFFFFFF).withOpacity(0.90), // ffffff 90%
                                ),
                              ),
                            ),

                            // Password Input Box
                            _buildPasswordField(
                              widthRatio: widthRatio,
                              isObscured: _obscurePassword,
                              strokeOpacity: 0.18, // ffffff 18%
                              onToggleVisibility: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),

                            const SizedBox(height: 24),

                            // Confirm Password Label
                            Padding(
                              padding: EdgeInsets.only(left: 10 * widthRatio, bottom: 8.0),
                              child: Text(
                                'Confirm Password',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500, // Medium 24
                                  fontSize: 24,
                                  color: const Color(0xFFFFFFFF).withOpacity(0.90), // ffffff 90%
                                ),
                              ),
                            ),

                            // Confirm Password Input Box
                            _buildPasswordField(
                              widthRatio: widthRatio,
                              isObscured: _obscureConfirmPassword,
                              strokeOpacity: 0.25, // ffffff 25%
                              onToggleVisibility: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),

                            const Spacer(),

                            // Create New Password Button
                            Align(
                              alignment: Alignment.center,
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to Success Screen
                                  Navigator.push(
                                    context,
                                    fadeRoute(const ParentSuccessScreen()),
                                  );
                                },
                                child: Container(
                                  width: 291 * widthRatio,
                                  height: 62,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF214071), // 214071 100%
                                    borderRadius: BorderRadius.circular(10), // Radius 10
                                  ),
                                  child: const Text(
                                    'Create New Password',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600, // SemiBold 20
                                      fontSize: 20,
                                      color: Color(0xFFFFFFFF), // ffffff 100%
                                    ),
                                  ),
                                ),
                              ),
                            ),
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

  // Helper widget to build the exact password text fields based on Figma specs
  Widget _buildPasswordField({
    required double widthRatio,
    required bool isObscured,
    required double strokeOpacity,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      width: 294 * widthRatio,
      height: 49, // Exact height from Figma
      alignment: Alignment.center,
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withOpacity(0.21), // ffffff 21%
        borderRadius: BorderRadius.circular(10), // Radius 10
        border: Border.all(
          color: const Color(0xFFFFFFFF).withOpacity(strokeOpacity), // Stroke opacity varies
          width: 1,
        ),
      ),
      child: TextField(
        obscureText: isObscured,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600, // SemiBold 24
          letterSpacing: 2.0, // Space out asterisks
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isCollapsed: true, // Centers the content properly inside the 49px container
          hintText: '*************',
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600, // SemiBold 24
            fontSize: 24,
            letterSpacing: 2.0,
            color: const Color(0xFFFFFFFF).withOpacity(0.66), // ffffff 66%
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 45,
            minHeight: 49,
          ),
          suffixIcon: GestureDetector(
            onTap: onToggleVisibility,
            child: Icon(
              isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFFFFFFFF).withOpacity(0.66), // ffffff 66%
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}