import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/helpers/app_feedback.dart';
import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/supervisor/supervisor_home_screen.dart';
import 'package:application/screens/supervisor/supervisor_trip_screen.dart';
import 'package:application/widgets/supervisor/supervisor_bottom_nav_bar.dart';
import 'package:flutter/material.dart';

class SupervisorChangePasswordScreen extends StatefulWidget {
  const SupervisorChangePasswordScreen({super.key});

  @override
  State<SupervisorChangePasswordScreen> createState() =>
      _SupervisorChangePasswordScreenState();
}

class _SupervisorChangePasswordScreenState
    extends State<SupervisorChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionButtonGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        context.isDarkMode
            ? const Color(0xFF162233)
            : AppColors.lightGray.withOpacity(0.49),
        AppColors.linkBlue.withOpacity(context.isDarkMode ? 0.75 : 0.49),
      ],
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 96),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 130,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  0,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryBlue97,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(40),
                                    bottomRight: Radius.circular(40),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(
                                        Icons.chevron_left,
                                        color: AppColors.white,
                                        size: 35,
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: SizedBox(
                                          height: 126,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Image.asset(
                                              AppImages.logo,
                                              height: 126,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                    Icons.directions_bus,
                                                    color: AppColors.white,
                                                    size: 40,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 40),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  15,
                                  18,
                                  15,
                                  0,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Change Password',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: context.appPrimaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.fromLTRB(
                                        15,
                                        14,
                                        15,
                                        16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.appCardBackground,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildPasswordLabel(
                                            'Current Password',
                                            isBlue: false,
                                          ),
                                          const SizedBox(height: 10),
                                          _buildPasswordField(
                                            controller: _currentController,
                                            obscure: _obscureCurrent,
                                            onToggle: () => setState(
                                              () => _obscureCurrent =
                                                  !_obscureCurrent,
                                            ),
                                            borderColor: context.appLine,
                                            useBlueEye: false,
                                          ),
                                          const SizedBox(height: 14),
                                          _buildPasswordLabel(
                                            'New Password',
                                            isBlue: true,
                                          ),
                                          const SizedBox(height: 10),
                                          _buildPasswordField(
                                            controller: _newController,
                                            obscure: _obscureNew,
                                            onToggle: () => setState(
                                              () => _obscureNew = !_obscureNew,
                                            ),
                                            borderColor:
                                                AppColors.secondaryBlue,
                                            useBlueEye: true,
                                          ),
                                          const SizedBox(height: 14),
                                          _buildPasswordLabel(
                                            'Confirm New Password',
                                            isBlue: true,
                                          ),
                                          const SizedBox(height: 10),
                                          _buildPasswordField(
                                            controller: _confirmController,
                                            obscure: _obscureConfirm,
                                            onToggle: () => setState(
                                              () => _obscureConfirm =
                                                  !_obscureConfirm,
                                            ),
                                            borderColor:
                                                AppColors.secondaryBlue,
                                            useBlueEye: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: 275,
                                      height: 46,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: actionButtonGradient,
                                          borderRadius: BorderRadius.circular(
                                            33,
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              showAppFeedback(
                                                context,
                                                'Password update not implemented yet',
                                                isError: true,
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(
                                              33,
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'Update Password',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textBlack,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: SupervisorBottomNavBar(
                            activeTab: SupervisorNavTab.profile,
                            onHomeTap: () {
                              Navigator.pushReplacement(
                                context,
                                fadeRoute(const SupervisorHomeScreen()),
                              );
                            },
                            onAttendanceTap: () {
                              Navigator.pushReplacement(
                                context,
                                fadeRoute(const SupervisorTripScreen()),
                              );
                            },
                            onProfileTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required Color borderColor,
    required bool useBlueEye,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.appInputBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: context.appPrimaryText,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          hintText: '************',
          hintStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: context.appSecondaryText,
          ),
          suffixIcon: GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Image.asset(
                useBlueEye ? AppImages.blueEye : AppImages.eye,
                width: 25,
                height: 25,
                color: useBlueEye
                    ? AppColors.linkBlue
                    : AppColors.gray333.withOpacity(0.78),
                errorBuilder: (_, __, ___) => Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 22,
                  color: useBlueEye
                      ? AppColors.linkBlue
                      : AppColors.gray333.withOpacity(0.78),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordLabel(String label, {required bool isBlue}) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: isBlue ? AppColors.primaryBlue : context.appPrimaryText,
      ),
    );
  }

}
