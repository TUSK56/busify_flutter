import 'dart:ui';
import 'package:application/screens/parent/parent_otp_screen.dart';
import 'package:flutter/material.dart';
// this page for supervisor email otp
class ParentForgetPasswordScreen extends StatelessWidget {
  const ParentForgetPasswordScreen({super.key});

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
            image: AssetImage('assets/images/10.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false, // Let the bottom sheet extend to the very bottom
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
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
                              width: 144 * widthRatio,
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

                        // This spacer pushes the bottom sheet to the bottom of the screen
                        const Spacer(),

                        // Bottom Sheet / Glassmorphism Panel
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Background blur
                            child: Container(
                              width: double.infinity,
                              // The content inside will dictate the exact height, matching Figma's ~602px
                              padding: const EdgeInsets.only(top: 18, bottom: 50),
                              decoration: BoxDecoration(
                                color: const Color(0xFF171723).withOpacity(0.16), // 171723 16%
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withOpacity(0.30), // Approximating linear stroke
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Lock Image (6.png)
                                  Container(
                                    width: 128 * widthRatio,
                                    height: 128 * widthRatio,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: const Color(0xFF000000).withOpacity(0.31), // 000000 31%
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.25), // Drop shadow effect
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      image: const DecorationImage(
                                        image: AssetImage('assets/images/6.png'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Forget Password Title
                                  Text(
                                    'Forget Password',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600, // SemiBold 32
                                      fontSize: 32,
                                      color: const Color(0xFFFFFFFF).withOpacity(0.90), // ffffff 90%
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Subtitle
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 14 * widthRatio),
                                    child: Text(
                                      'Enter your email to receive a password reset link.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400, // Regular 15
                                        fontSize: 15,
                                        color: const Color(0xFFFFFFFF).withOpacity(0.66), // ffffff 66%
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  // Email Label
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 45 * widthRatio),
                                      child: Text(
                                        'Email',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500, // Medium 24
                                          fontSize: 24,
                                          color: const Color(0xFFF5F5F5).withOpacity(0.90), // f5f5f5 90%
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Email TextField Container
                                  Container(
                                    width: 291 * widthRatio,
                                    height: 62,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFFFF).withOpacity(0.21), // ffffff 21%
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: const Color(0xFFFFFFFF).withOpacity(0.79), // ffffff 79%
                                        width: 1,
                                      ),
                                    ),
                                    child: TextField(
                                      style: const TextStyle(color: Colors.white, fontSize: 20),
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                                        hintText: 'Enter your email',
                                        hintStyle: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500, // Medium 20
                                          fontSize: 20,
                                          color: const Color(0xFFFFFFFF).withOpacity(0.66), // ffffff 66%
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  // Get OTP Button
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const ParentOtpScreen()),
                                      );
                                    },
                                    child: Container(
                                      width: 291 * widthRatio,
                                      height: 62,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF214071), // 214071 100%
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Text(
                                        'Get OTP',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600, // SemiBold 24
                                          fontSize: 24,
                                          color: Color(0xFFFFFFFF), // ffffff 100%
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}