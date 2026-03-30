import 'dart:io';
import 'dart:ui';
import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/supervisor/supervisor_home_screen.dart';
import 'package:application/screens/supervisor/supervisor_profile_screen.dart';
import 'package:application/screens/supervisor/supervisor_qr_confirmation_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SupervisorAttendanceScreen extends StatefulWidget {
  final String imagePath;

  const SupervisorAttendanceScreen({super.key, required this.imagePath});

  @override
  State<SupervisorAttendanceScreen> createState() =>
      _SupervisorAttendanceScreenState();
}

class _SupervisorAttendanceScreenState
    extends State<SupervisorAttendanceScreen> {
  late String currentImagePath;

  @override
  void initState() {
    super.initState();
    currentImagePath = widget.imagePath;
  }

  // Rescan Function
  Future<void> _rescan() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        currentImagePath = photo.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                // Header (Figma Position x:-16 y:-14)
                Container(
                  width: double.infinity,
                  height: 235,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue97,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                                size: 38,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Center(
                                child: SizedBox(
                                  height: 80,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Image.asset(
                                      AppImages.logo,
                                      height: 80,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE31E24),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'SOS',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.white,
                              backgroundImage: const AssetImage(
                                AppImages.supervisorAvatar,
                              ),
                              onBackgroundImageError: (_, __) {},
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Welcome, Ali',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Bus #7',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Scanned Image + Glass Card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.file(
                            File(currentImagePath),
                            width: 366,
                            height: 355,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Glass Card (README: 355x154, radius 30, ffffff 37%, blur 30, shadow)
                        Positioned(
                          bottom: 20,
                          left: 15,
                          right: 15,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                              child: Container(
                                height: 154,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.37),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      offset: const Offset(0, 4),
                                      blurRadius: 4,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          AppImages.image14,
                                          width: 54,
                                          height: 24,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.black,
                                                size: 22,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Attendance Recorded',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Text(
                                      'Judy Ahmed',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const Spacer(),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 15,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildRescanBtn(context),
                                          _buildConfirmBtn(context),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom nav (README: Attendance active - 2859c5)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: context.appPanelBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _navItem(
                          context,
                          AppImages.navbarHome,
                          'Home',
                          false,
                          () => Navigator.pushReplacement(
                            context,
                            fadeRoute(const SupervisorHomeScreen()),
                          ),
                        ),
                        _navItem(
                          context,
                          AppImages.navbarAttendanceActive,
                          'Attendance',
                          true,
                          () {},
                        ),
                        _navItem(
                          context,
                          AppImages.navbarProfile,
                          'Profile',
                          false,
                          () => Navigator.push(
                            context,
                            fadeRoute(const SupervisorProfileScreen()),
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

  Widget _buildRescanBtn(BuildContext context) {
    return GestureDetector(
      onTap: _rescan,
      child: Container(
        width: 148,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.e6e9ed.withOpacity(0.94),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.primaryBlue, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Rescan',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.camera_alt_outlined,
              size: 28,
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmBtn(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryButtonGradient,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                fadeRoute(
                  SupervisorQrConfirmationScreen(imagePath: currentImagePath),
                ),
              );
            },
            borderRadius: BorderRadius.circular(7),
            child: const Center(
              child: Text(
                'Confirm',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    String iconPath,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          label == 'Profile'
              ? Icon(
                  Icons.person,
                  size: 28,
                  color: isActive ? AppColors.linkBlue : context.appInactiveNav,
                )
              : Image.asset(
                  iconPath,
                  width: 28,
                  height: 28,
                  color: isActive ? AppColors.linkBlue : context.appInactiveNav,
                  errorBuilder: (_, __, ___) => Icon(
                    label == 'Home' ? Icons.home : Icons.fact_check,
                    size: 28,
                    color: isActive
                        ? AppColors.linkBlue
                        : context.appInactiveNav,
                  ),
                ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? AppColors.linkBlue : context.appSecondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
