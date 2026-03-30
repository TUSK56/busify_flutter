import 'dart:ui';
import 'package:application/helpers/fade_route.dart';
import 'package:application/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'supervisor_forget_password_screen.dart';
import 'supervisor_home_screen.dart';

class SupervisorLoginScreen extends StatefulWidget {
  const SupervisorLoginScreen({super.key});

  @override
  State<SupervisorLoginScreen> createState() => _SupervisorLoginScreenState();
}

class _SupervisorLoginScreenState extends State<SupervisorLoginScreen> {
  bool _isObscured = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
                      padding: EdgeInsets.only(left: 47),
                      child: Image.asset(
                        AppImages.logo,
                        width: 104,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.01),

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
                      padding: EdgeInsets.only(left: 40),
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
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 331),
                        child: Container(
                          width: double.infinity,
                          height: 400, // Fixed height from Figma
                        padding: EdgeInsets.symmetric(
                            horizontal: 20,
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
                              width: 291,
                              child: TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
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
                              width: 291,
                              child: TextField(
                                controller: _passwordController,
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
                            // Forgot Password Text
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to Forget Password Screen
                                  Navigator.push(
                                    context,
                                    fadeRoute(const SupervisorForgetPasswordScreen()),
                                  );
                                },
                                child: Text(
                                  'Forget Password?',
                                // ... rest of the code
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
                              onTap: _isLoading ? null : () async {
                                final email = _emailController.text.trim();
                                final password = _passwordController.text;
                                if (email.isEmpty || password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter email and password.')),
                                  );
                                  return;
                                }
                                setState(() => _isLoading = true);
                                try {
                                  await ServiceLocator.supervisorService.login(
                                    email: email,
                                    password: password,
                                  );
                                  if (!mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    fadeRoute(const SupervisorHomeScreen()),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                } finally {
                                  if (mounted) setState(() => _isLoading = false);
                                }
                              },
                              child: Container(
                                width: 291,
                                height: 62,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryButtonGradient,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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