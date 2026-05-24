import 'package:application/helpers/fade_route.dart';
import 'package:flutter/material.dart';
import 'package:application/helpers/app_back_button.dart';
import 'package:application/helpers/app_feedback.dart';
import 'package:flutter/services.dart';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/services/supervisor_service.dart';
import 'supervisor_reset_password_screen.dart';

class SupervisorOtpScreen extends StatefulWidget {
  final String email;

  const SupervisorOtpScreen({super.key, required this.email});

  @override
  State<SupervisorOtpScreen> createState() => _SupervisorOtpScreenState();
}

class _SupervisorOtpScreenState extends State<SupervisorOtpScreen> {
  // Controllers and FocusNodes for the 6-digit OTP from email
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

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
    final otp = _controllers.map((c) => c.text).join();

    // Backend sends 6 digits; "0000" remains supported as a dev fallback.
    if (otp.length != 6 && otp != '0000') {
      setState(() {
        _errorMessage = 'Enter the 6-digit code from your email.';
      });
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      return;
    }

    setState(() {
      _errorMessage = null;
    });
    Navigator.push(
      context,
      fadeRoute(SupervisorResetPasswordScreen(email: widget.email, otp: otp)),
    );
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
                      child: AppBackButton(
                        onTap: () => Navigator.pop(context),
                        color: Colors.white,
                        icon: Icons.arrow_back_ios,
                        iconSize: 28,
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

                  // 6 OTP digits (matches emailed code)
                  SizedBox(
                    width: 320,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 6,
                      runSpacing: 8,
                      children: List.generate(6, _buildOTPBox),
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
                    onTap: () async {
                      try {
                        await ServiceLocator.supervisorService.sendPasswordResetOtp(email: widget.email);
                        if (!context.mounted) return;
                        await showAppFeedback(
                          context,
                          'A new code was sent to your email.',
                        );
                      } on SupervisorServiceException catch (e) {
                        if (!context.mounted) return;
                        await showAppFeedback(
                          context,
                          e.message,
                          isError: true,
                        );
                      }
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

  Widget _buildOTPBox(int index) {
    return Container(
      width: 46,
      height: 54,
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
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}