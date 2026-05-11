import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/helpers/fade_route.dart';
import 'package:application/screens/onboarding/role_selection_screen.dart';
import 'package:application/screens/supervisor/supervisor_change_password_screen.dart';
import 'package:application/screens/supervisor/supervisor_home_screen.dart';
import 'package:application/screens/supervisor/supervisor_trip_screen.dart';
import 'package:application/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class SupervisorProfileScreen extends StatefulWidget {
  const SupervisorProfileScreen({super.key});

  @override
  State<SupervisorProfileScreen> createState() =>
      _SupervisorProfileScreenState();
}

class _SupervisorProfileScreenState extends State<SupervisorProfileScreen> {
  static const Color _logoutIconColor = Color(0xFFC94A4A);
  String _name = '';
  String _email = '';
  String _phone = '';
  String _busNumber = '—';

  @override
  void initState() {
    super.initState();
    ServiceLocator.themeController.addListener(_handleThemeChanged);
    _hydrate();
  }

  Future<void> _hydrate() async {
    setState(() {
      _name = ServiceLocator.tokenStorage.getUserName() ?? '';
      _email = ServiceLocator.tokenStorage.getUserEmail() ?? '';
      _phone = ServiceLocator.tokenStorage.getUserPhone() ?? '';
    });
    try {
      final me = await ServiceLocator.supervisorService.getMe();
      if (!mounted) return;
      setState(() {
        _name = me.name;
        _email = me.email;
        _phone = me.phone;
        _busNumber = me.busNumber ?? '—';
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    ServiceLocator.themeController.removeListener(_handleThemeChanged);
    super.dispose();
  }

  void _handleThemeChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final avatarImageCacheSize = (80 * MediaQuery.of(context).devicePixelRatio)
        .round();

    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Expanded(
                  child: SizedBox(
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
                                          height: 170,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Image.asset(
                                              AppImages.logo,
                                              height: 160,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) =>
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
                              Transform.translate(
                                offset: const Offset(0, -45),
                                child: Container(
                                  width: 86,
                                  height: 80,
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context.appAvatarPlaceholder,
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        AppImages.profileAvatarLarge,
                                        fit: BoxFit.cover,
                                        filterQuality: FilterQuality.high,
                                        isAntiAlias: true,
                                        cacheWidth: avatarImageCacheSize,
                                        cacheHeight: avatarImageCacheSize,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.person,
                                              size: 42,
                                              color: AppColors.grayText,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(0, -30),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        _name.isEmpty ? 'Supervisor' : _name,
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: context.appPrimaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Bus Supervisor',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: context.appSecondaryText,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildAccountCard(),
                                      const SizedBox(height: 14),
                                      _buildSettingsCard(context),
                                      const SizedBox(height: 14),
                                      _buildLogoutButton(context),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: _buildBottomNav(context),
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

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: context.appDivider,
    );
  }

  Widget _buildAccountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Info',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: context.appPrimaryText,
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            Icons.phone,
            _phone.isEmpty ? '—' : _phone,
            iconTint: const Color(0xFF1BD95D),
          ),
          _buildDivider(),
          _buildInfoRow(
            Icons.email_outlined,
            _email.isEmpty ? '—' : _email,
            iconTint: AppColors.linkBlue,
          ),
          _buildDivider(),
          _buildInfoRow(Icons.directions_bus_filled, 'Bus #$_busNumber'),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    final themeController = ServiceLocator.themeController;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: context.appPrimaryText,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Transform.scale(
                scaleX: -1,
                child: Icon(
                  FluentIcons.weather_moon_20_filled,
                  size: 26,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(width: 18),
              Text(
                'Dark Mode',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appPrimaryText,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 66,
                height: 28,
                child: Switch(
                  value: context.isDarkMode,
                  onChanged: (value) {
                    themeController.setDarkEnabled(value);
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  thumbColor: WidgetStateProperty.resolveWith(
                    (states) => AppColors.white,
                  ),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.linkBlue;
                    }
                    return context.appSecondaryText.withValues(alpha: 0.33);
                  }),
                  trackOutlineColor: WidgetStateProperty.resolveWith(
                    (states) => Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
          _buildDivider(),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                fadeRoute(const SupervisorChangePasswordScreen()),
              );
            },
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 26,
                  color: AppColors.grayText,
                ),
                const SizedBox(width: 18),
                Text(
                  'Change Password',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.appPrimaryText,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: context.appInactiveNav,
                  size: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final logoutGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        context.isDarkMode
            ? const Color(0xFF162233)
            : AppColors.lightGray.withValues(alpha: 0.49),
        AppColors.linkBlue.withValues(alpha: context.isDarkMode ? 0.75 : 0.49),
      ],
    );

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: logoutGradient,
          borderRadius: BorderRadius.circular(33),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await ServiceLocator.tokenStorage.clearToken();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                fadeRoute(const RoleSelectionScreen()),
                (route) => false,
              );
            },
            borderRadius: BorderRadius.circular(33),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, size: 28, color: _logoutIconColor),
                const SizedBox(width: 12),
                Text(
                  'Log Out',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: context.appPrimaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData iconData, String text, {Color? iconTint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(iconData, size: 26, color: iconTint ?? AppColors.grayText),
          const SizedBox(width: 16),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.appPrimaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Padding(
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
            _navItem(context, AppImages.navbarHome, 'Home', false, () {
              Navigator.pushReplacement(
                context,
                fadeRoute(const SupervisorHomeScreen()),
              );
            }),
            _navItem(
              context,
              AppImages.navbarAttendance,
              'Attendance',
              false,
              () {
                Navigator.pushReplacement(
                  context,
                  fadeRoute(const SupervisorTripScreen()),
                );
              },
            ),
            _navItem(
              context,
              AppImages.navbarProfileActive,
              'Profile',
              true,
              () {},
            ),
          ],
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
                  errorBuilder: (context, error, stackTrace) => Icon(
                    label == 'Home' ? Icons.home : Icons.fact_check_outlined,
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
