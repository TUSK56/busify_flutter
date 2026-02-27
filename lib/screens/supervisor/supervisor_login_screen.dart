import 'dart:ui';
import 'package:flutter/material.dart';
import 'supervisor_forget_password_screen.dart';// Ensure the file name matches
import 'supervisor_home_screen.dart';
// login page for supervisor with email password login and forget password
class SupervisorLoginScreen extends StatefulWidget {
  const SupervisorLoginScreen({super.key});

  @override
  State<SupervisorLoginScreen> createState() => _SupervisorLoginScreenState();
}

class _SupervisorLoginScreenState extends State<SupervisorLoginScreen> {
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
            image: AssetImage('assets/images/10.png'),
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
                          color: const Color(0xFFFFFFFF).withOpacity(0.90), // ffffff 90% opacity
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

                            // Email Label
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
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
                                    color: const Color(0xFFFFFFFF).withOpacity(0.66), // ffffff 66%
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: const Color(0xFFFFFFFF).withOpacity(0.67), // ffffff 67%
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
                                  color: const Color(0xFFF5F5F5).withOpacity(0.90), // f5f5f5 95% base, applied 90%
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
                                    color: const Color(0xFFFFFFFF).withOpacity(0.66), // ffffff 66%
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: const Color(0xFFFFFFFF).withOpacity(0.67), // ffffff 67%
                                    size: 28,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: const Color(0xFFFFFFFF).withOpacity(0.66), // ffffff 66%
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
                            // Forgot Password Text
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to Forget Password Screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SupervisorForgetPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Forget Password?',
                                // ... rest of the code
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500, // Medium 16
                                    fontSize: 16,
                                    color: const Color(0xFFF5F5F5).withOpacity(0.66), // f5f5f5 66%
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
                                  MaterialPageRoute(builder: (context) => const SupervisorHomeScreen()),
                                );
                              },
                              child: Container(
                                width: 291 * widthRatio,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF214071), // 214071 100%
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: const Color(0xFF214071), // Match border to fill
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
        color: const Color(0xFFFFFFFF).withOpacity(0.21), // ffffff 21%
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFFFFFF).withOpacity(0.79), // ffffff 79%
          width: 1,
        ),
      ),
      child: child,
    );
  }
}