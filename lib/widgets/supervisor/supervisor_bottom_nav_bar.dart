import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:flutter/material.dart';

enum SupervisorNavTab { home, attendance, profile }

class SupervisorBottomNavBar extends StatelessWidget {
  const SupervisorBottomNavBar({
    super.key,
    required this.activeTab,
    required this.onHomeTap,
    required this.onAttendanceTap,
    required this.onProfileTap,
  });

  final SupervisorNavTab activeTab;
  final VoidCallback onHomeTap;
  final VoidCallback onAttendanceTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: 84,
        decoration: BoxDecoration(
          color: context.appPanelBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _item(
              context: context,
              label: 'Home',
              iconPath: AppImages.navbarHome,
              active: activeTab == SupervisorNavTab.home,
              onTap: onHomeTap,
            ),
            _item(
              context: context,
              label: 'Attendance',
              iconPath: AppImages.navbarAttendance,
              active: activeTab == SupervisorNavTab.attendance,
              onTap: onAttendanceTap,
            ),
            _item(
              context: context,
              label: 'Profile',
              iconPath: AppImages.navbarProfile,
              active: activeTab == SupervisorNavTab.profile,
              onTap: onProfileTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _item({
    required BuildContext context,
    required String label,
    required String iconPath,
    required bool active,
    required VoidCallback onTap,
  }) {
    final color = active ? AppColors.linkBlue : context.appInactiveNav;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            label == 'Profile'
                ? Icon(Icons.person, size: 28, color: color)
                : Image.asset(
                    iconPath,
                    width: 28,
                    height: 28,
                    color: color,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      label == 'Home' ? Icons.home : Icons.fact_check_outlined,
                      size: 28,
                      color: color,
                    ),
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active ? AppColors.linkBlue : context.appSecondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
