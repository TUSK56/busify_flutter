import 'dart:ui';
import 'package:application/helpers/fade_route.dart';
import 'package:application/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'supervisor_login_screen.dart';

class SupervisorResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const SupervisorResetPasswordScreen({super.key, required this.email, required this.otp});

  @override
  State<SupervisorResetPasswordScreen> createState() => _SupervisorResetPasswordScreenState();
}

class _SupervisorResetPasswordScreenState extends State<SupervisorResetPasswordScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

                  // Instruction Text
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 45),
                    child: Text(
                      'Please enter your new password to secure your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400, // Regular 15
                        fontSize: 15,
                        color: AppColors.white.withOpacity(0.63), // ffffff 63%
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
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 331),
                        child: Container(
                          width: double.infinity,
                          height: 400, // Fixed height per Figma
                        padding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 36, // Adjust padding to match Figma inner Y coordinates
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

                            // Password Label
                            Padding(
                              padding: EdgeInsets.only(left: 10, bottom: 8.0),
                              child: Text(
                                'Password',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500, // Medium 24
                                  fontSize: 24,
                                  color: AppColors.white.withOpacity(0.90), // ffffff 90%
                                ),
                              ),
                            ),

                            // Password Input Box
                            _buildPasswordField(
                              controller: _passwordController,
                              isObscured: _obscurePassword,
                              strokeOpacity: 0.18,
                              onToggleVisibility: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),

                            const SizedBox(height: 24),

                            // Confirm Password Label
                            Padding(
                              padding: EdgeInsets.only(left: 10, bottom: 8.0),
                              child: Text(
                                'Confirm Password',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500, // Medium 24
                                  fontSize: 24,
                                  color: AppColors.white.withOpacity(0.90), // ffffff 90%
                                ),
                              ),
                            ),

                            // Confirm Password Input Box
                            _buildPasswordField(
                              controller: _confirmPasswordController,
                              isObscured: _obscureConfirmPassword,
                              strokeOpacity: 0.25,
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
                                onTap: _isLoading ? null : () async {
                                  final password = _passwordController.text;
                                  final confirm = _confirmPasswordController.text;
                                  if (password.isEmpty || confirm.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please fill both fields.')),
                                    );
                                    return;
                                  }
                                  if (password != confirm) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Passwords do not match.')),
                                    );
                                    return;
                                  }
                                  if (password.length < 6) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Password must be at least 6 characters.')),
                                    );
                                    return;
                                  }
                                  setState(() => _isLoading = true);
                                  try {
                                    await ServiceLocator.supervisorService.resetPassword(
                                      email: widget.email,
                                      otp: widget.otp,
                                      newPassword: password,
                                    );
                                    if (!mounted) return;
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      fadeRoute(const SupervisorLoginScreen()),
                                      (route) => false,
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
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryButtonGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
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
                                    'Create New Password',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600, // SemiBold 20
                                      fontSize: 20,
                                      color: AppColors.white, // ffffff 100%
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

  Widget _buildPasswordField({
    TextEditingController? controller,
    required bool isObscured,
    required double strokeOpacity,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      width: 294,
      height: 49, // Exact height from Figma
      alignment: Alignment.center,
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.21), // ffffff 21%
        borderRadius: BorderRadius.circular(10), // Radius 10
        border: Border.all(
          color: AppColors.white.withOpacity(strokeOpacity), // Stroke opacity varies
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
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
            color: AppColors.white.withOpacity(0.66), // ffffff 66%
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 45,
            minHeight: 49,
          ),
          suffixIcon: GestureDetector(
            onTap: onToggleVisibility,
            child: Icon(
              isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.white.withOpacity(0.66), // ffffff 66%
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}