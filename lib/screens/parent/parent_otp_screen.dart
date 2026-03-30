import 'package:application/helpers/fade_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/widgets/parent/parent_brand_logo.dart';
import 'parent_reset_password_screen.dart';

class ParentOtpScreen extends StatefulWidget {
  final String email;

  const ParentOtpScreen({super.key, required this.email});

  @override
  State<ParentOtpScreen> createState() => _ParentOtpScreenState();
}

class _ParentOtpScreenState extends State<ParentOtpScreen> {
  // Controllers and FocusNodes for the 4 OTP boxes
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  // Error state for wrong OTP
  String? _errorMessage;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verifyOtp() {
    // Combine the text from all 4 boxes
    String otp = _controllers.map((c) => c.text).join();

    if (otp == '0000') {
      setState(() {
        _errorMessage = null;
      });
      Navigator.push(
        context,
        fadeRoute(ParentResetPasswordScreen(email: widget.email, otp: otp)),
      );
    } else {
      // Wrong OTP, show error message
      setState(() {
        _errorMessage = 'Wrong OTP. Please try 0000 for testing.';
      });

      // Optional: Clear fields on wrong attempt
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus(); // Go back to first box
    }
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: screenHeight * 0.02),

                  // Top Logo (2.png)
                  ParentBrandLogo.image(AppImages.logo),

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

                  SizedBox(height: screenHeight * 0.03),

                  // Title Text
                  const Text(
                    'Enter your OTP',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600, // SemiBold 32
                      fontSize: 32,
                      color: AppColors.white, // ffffff 100%
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle Text
                  Text(
                    "We've sent a code to your email",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500, // Medium 16
                      fontSize: 16,
                      color: AppColors.white.withOpacity(0.66), // ffffff 66%
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.05),

                  // 4 OTP Boxes Frame (Width 288, Gap 16)
                  SizedBox(
                    width: 288,
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (index) {
                        return _buildOTPBox(index);
                      }),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Error Message Display (if wrong OTP)
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  SizedBox(height: screenHeight * 0.04),

                  // Verify / Get OTP Button (Rectangle 221x45)
                  GestureDetector(
                    onTap: _verifyOtp,
                    child: Container(
                      width: 221,
                      height: 45,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryButtonGradient,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        'Reset Password',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600, // SemiBold
                          fontSize: 18,
                          color: AppColors.white, // ffffff 100%
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // Resend OTP Text
                  GestureDetector(
                    onTap: () {
                      // TODO: Logic to resend email
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('OTP resent to email! (Test: 0000)')),
                      );
                    },
                    child: Text(
                      'Resend OTP',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500, // Medium 16
                        fontSize: 16,
                        color: AppColors.white.withOpacity(0.66), // ffffff 66%
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget to build individual 60x60 OTP Input box
  Widget _buildOTPBox(int index) {
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.lightGray.withOpacity(0.32), // f5f5f5 32%
        borderRadius: BorderRadius.circular(10), // Radius 10
        border: Border.all(
          color: AppColors.white, // ffffff 100%
          width: 2, // weight: 2
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1, // Only 1 digit per box
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly, // Enforce numbers
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '', // Hides the character counter below
        ),
        onChanged: (value) {
          // If a digit is typed, move to the NEXT box automatically
          if (value.isNotEmpty) {
            if (index < 3) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus(); // Done typing
            }
          }
          // If deleted, move to the PREVIOUS box automatically
          else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}