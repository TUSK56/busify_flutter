import 'dart:ui';
import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/parent/parent_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'parent_forget_password_screen.dart'; // Ensure the file name matches
import 'parent_signup_info_screen.dart';

// Login page for Parent with email/password, forget password, and bottom text
class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  // State to manage password visibility toggle
  bool _isObscured = true;

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
            // SingleChildScrollView prevents keyboard overflow errors
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
                        AppImages.logo,
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

                  // Login Title
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 40 * widthRatio),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold, // Bold 24
                          fontSize: 24,
                          letterSpacing: 0,
                          color: AppColors.white.withOpacity(0.90), // ffffff 90% opacity
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Glassmorphism Login Card (w: 331, h: 400)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Background blur
                      child: Container(
                        width: 331 * widthRatio,
                        height: 400, // Fixed height from Figma
                        padding: EdgeInsets.symmetric(
                            horizontal: 20 * widthRatio,
                            vertical: 24
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.27), // ffffff 27%
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.white.withOpacity(0.50), // ffffff 50%
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Email Label
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                              child: Text(
                                'Email',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500, // Medium 24
                                  fontSize: 24,
                                  color: AppColors.lightGray.withOpacity(0.90), // f5f5f5 90%
                                ),
                              ),
                            ),

                            // Email TextField Container
                            _buildTextFieldContainer(
                              width: 291 * widthRatio,
                              child: TextField(
                                style: const TextStyle(color: Colors.white, fontSize: 20),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Enter your email',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400, // Regular 20
                                    fontSize: 20,
                                    color: AppColors.white.withOpacity(0.66), // ffffff 66%
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: AppColors.white.withOpacity(0.67), // ffffff 67%
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Password Label
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                              child: Text(
                                'Password',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500, // Medium 24
                                  fontSize: 24,
                                  color: AppColors.lightGray.withOpacity(0.90), // f5f5f5 95% base, applied 90%
                                ),
                              ),
                            ),

                            // Password TextField Container
                            _buildTextFieldContainer(
                              width: 291 * widthRatio,
                              child: TextField(
                                obscureText: _isObscured,
                                style: const TextStyle(color: Colors.white, fontSize: 20),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Enter your password',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400, // Regular 20
                                    fontSize: 20,
                                    color: AppColors.white.withOpacity(0.66), // ffffff 66%
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: AppColors.white.withOpacity(0.67), // ffffff 67%
                                    size: 28,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: AppColors.white.withOpacity(0.66), // ffffff 66%
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isObscured = !_isObscured;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Forgot Password Text
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to Forget Password Screen
                                Navigator.push(
                                    context,
                                    fadeRoute(const ParentForgetPasswordScreen()),
                                  );
                                },
                                child: Text(
                                  'Forget Password?',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500, // Medium 16
                                    fontSize: 16,
                                    color: AppColors.lightGray.withOpacity(0.66), // f5f5f5 66%
                                  ),
                                ),
                              ),
                            ),

                            const Spacer(),

                            // Log In Button
                            GestureDetector(
                              onTap: () {
                                // Navigate to Create Account screen
                                Navigator.push(
                                  context,
                                  fadeRoute(const ParentHomeScreen()),
                                );
                              },
                              child: Container(
                                width: 291 * widthRatio,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue, // 214071 100%
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: AppColors.primaryBlue, // Match border to fill
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
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
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Spacing between the card and the bottom text
                  SizedBox(height: screenHeight * 0.04),

                  // ==========================================
                  // UPDATED MULTI-COLORED BOTTOM TEXT (NO UNDERLINE)
                  // ==========================================
                  GestureDetector(
                    onTap: () {
                      // Navigate to Forget Password Screen
                      Navigator.push(
                        context,
                        fadeRoute(const ParentSignupInfoScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500, // Medium 16
                          fontSize: 16,
                          color: AppColors.white.withOpacity(0.90), // White text
                          decoration: TextDecoration.none, // Removes underline
                        ),
                        children: [
                          TextSpan(
                            text: "Sign Up",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: AppColors.linkBlue.withOpacity(0.90), // 4da3ff 90%
                              decoration: TextDecoration.none, // Removes underline
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Spacing for safety
                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Reusable container for the input fields to keep UI matching Figma closely
  Widget _buildTextFieldContainer({required double width, required Widget child}) {
    return Container(
      width: width,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.21), // ffffff 21%
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.white.withOpacity(0.79), // ffffff 79%
          width: 1,
        ),
      ),
      child: child,
    );
  }
}