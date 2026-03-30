import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom navigation shared by parent flows — **Profile** active uses [AppColors.linkBlue].
enum ParentNavTab { home, trackBus, profile }

class ParentBottomNavBar extends StatelessWidget {
  const ParentBottomNavBar({
    super.key,
    required this.activeTab,
    required this.onHomeTap,
    required this.onTrackBusTap,
    required this.onProfileTap,
  });

  final ParentNavTab activeTab;
  final VoidCallback onHomeTap;
  final VoidCallback onTrackBusTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 84,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.appPanelBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _item(
              asset: AppImages.profileScreenNavHome,
              label: 'Home',
              iconW: 32,
              iconH: 35,
              active: activeTab == ParentNavTab.home,
              onTap: onHomeTap,
            ),
            _item(
              asset: AppImages.profileScreenNavTrack,
              label: 'Track Bus',
              iconW: 36,
              iconH: 36,
              active: activeTab == ParentNavTab.trackBus,
              onTap: onTrackBusTap,
            ),
            _item(
              asset: AppImages.profileScreenNavProfileActive,
              label: 'Profile',
              iconW: 26.25,
              iconH: 26.25,
              active: activeTab == ParentNavTab.profile,
              onTap: onProfileTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _item({
    required String asset,
    required String label,
    required double iconW,
    required double iconH,
    required bool active,
    required VoidCallback onTap,
  }) {
    final Color iconColor;
    final Color labelColor;
    if (active) {
      iconColor = AppColors.linkBlue;
      labelColor = AppColors.linkBlue;
    } else if (label == 'Track Bus') {
      iconColor = AppColors.textBlack;
      labelColor = AppColors.grayText;
    } else {
      iconColor = AppColors.textBlack;
      labelColor = AppColors.textBlack;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              asset,
              width: iconW,
              height: iconH,
              color: iconColor,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 22 / 12,
                color: labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
