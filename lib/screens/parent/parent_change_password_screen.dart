import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/routes/fade_route.dart';
import 'package:application/screens/parent/parent_home_screen.dart';
import 'package:application/screens/parent/parent_profile_screen.dart';
import 'package:application/screens/parent/parent_track_bus_screen.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/widgets/parent/parent_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';


class ParentChangePasswordScreen extends StatefulWidget {
  const ParentChangePasswordScreen({super.key});

  @override
  State<ParentChangePasswordScreen> createState() =>
      _ParentChangePasswordScreenState();
}

class _ParentChangePasswordScreenState extends State<ParentChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final current = _currentController.text;
    final next = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    if (next != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    if (next.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ServiceLocator.parentService.changePassword(
        currentPassword: current,
        newPassword: next,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final titleColor = context.isDarkMode ? context.appPrimaryText : AppColors.textBlack;

    final updateGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        AppColors.lightGray.withValues(alpha: 0.49),
        AppColors.linkBlue.withValues(alpha: 0.49),
      ],
    );

    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 8 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _TopHeader(),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Change Password',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                          color: titleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.profileCardBackground,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PasswordLabel(
                              text: 'Current Password',
                              color: context.isDarkMode
                                  ? context.appPrimaryText
                                  : AppColors.gray333,
                            ),
                            const SizedBox(height: 10),
                            _PasswordField(
                              controller: _currentController,
                              obscure: _obscureCurrent,
                              onToggle: () => setState(
                                () => _obscureCurrent = !_obscureCurrent,
                              ),
                              borderColor:
                                  AppColors.textBlack.withValues(alpha: 0.25),
                              eyeTint:
                                  AppColors.gray333.withValues(alpha: 0.78),
                            ),
                            const SizedBox(height: 18),
                            _PasswordLabel(
                              text: 'New Password',
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(height: 10),
                            _PasswordField(
                              controller: _newController,
                              obscure: _obscureNew,
                              onToggle: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                              borderColor: AppColors.secondaryBlue,
                              eyeTint: AppColors.linkBlue,
                            ),
                            const SizedBox(height: 18),
                            _PasswordLabel(
                              text: 'Confirm New Password',
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(height: 10),
                            _PasswordField(
                              controller: _confirmController,
                              obscure: _obscureConfirm,
                              onToggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              borderColor: AppColors.secondaryBlue,
                              eyeTint: AppColors.linkBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: updateGradient,
                            borderRadius: BorderRadius.circular(33),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _submitting ? null : _submit,
                              borderRadius: BorderRadius.circular(33),
                              child: Center(
                                child: _submitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : Text(
                                        'Update Password',
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          height: 22 / 20,
                                          color: Color(0xff000000),
                                        ),
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
            ),
            ParentBottomNavBar(
              activeTab: ParentNavTab.profile,
              onHomeTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  fadeRoute(const ParentHomeScreen()),
                  (route) => false,
                );
              },
              onTrackBusTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  fadeRoute(const ParentTrackBusScreen()),
                  (route) => false,
                );
              },
              onProfileTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  fadeRoute(const ParentProfileScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(22),
        bottomRight: Radius.circular(22),
      ),
      child: SizedBox(
        height: 105,
        width: double.infinity,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.primaryBlue97)),
            Positioned(
              left: 24,
              top: 35,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const SizedBox(
                    width: 13.88,
                    height: 22.5,
                    child: Icon(
                      Icons.chevron_left,
                      color: AppColors.white,
                      size: 35,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: -9,
              child: Center(
                child: Image.asset(
                  AppImages.logo,
                  width: 126,
                  height: 126,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordLabel extends StatelessWidget {
  const _PasswordLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 322,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            height: 1.15,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.borderColor,
    required this.eyeTint,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final Color borderColor;
  final Color eyeTint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 322,
      height: 44,
      decoration: BoxDecoration(
        color: context.appInputBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 22 / 16,
                color: context.appPrimaryText,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '************',
                hintStyle: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 22 / 16,
                  color: context.appSecondaryText,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                FluentIcons.eye_20_regular,
                size: 26,
                color: Color(0xFF595959),
              ),
            ),
          ),
        ],
      ),
    );
  }
}