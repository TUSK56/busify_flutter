import 'dart:math' as math;

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/helpers/app_back_button.dart';
import 'package:application/helpers/app_feedback.dart';
import 'package:application/helpers/parent_gps_location.dart';
import 'package:application/helpers/supervisor_photo.dart';
import 'package:application/routes/fade_route.dart';
import 'package:application/screens/parent/parent_home_screen.dart';
import 'package:application/screens/parent/parent_profile_screen.dart';
import 'package:application/screens/parent/parent_track_bus_screen.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/widgets/parent/parent_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

/// Parent **Edit Profile** screen.
class ParentEditProfileScreen extends StatefulWidget {
  const ParentEditProfileScreen({super.key});

  @override
  State<ParentEditProfileScreen> createState() => _ParentEditProfileScreenState();
}

class _ParentEditProfileScreenState extends State<ParentEditProfileScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;

  String? _photoUrl;
  bool _saving = false;
  bool _uploadingPhoto = false;
  bool _resolvingLocation = false;

  /// GPS `address` field (lat,lng CSV) and reverse-geocode parts (same as signup).
  String _governorate = '';
  String _street = '';
  String _apiAddress = '';
  String _snapGov = '';
  String _snapStr = '';
  String _snapAddr = '';

  late String _initialEmail;
  late String _initialPhone;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: ServiceLocator.tokenStorage.getUserName() ?? '',
    );
    _emailController = TextEditingController(
      text: ServiceLocator.tokenStorage.getUserEmail() ?? '',
    );
    _phoneController = TextEditingController(
      text: ServiceLocator.tokenStorage.getUserPhone() ?? '',
    );
    _locationController = TextEditingController();
    _photoUrl = ServiceLocator.tokenStorage.getUserPhotoUrl();
    _initialEmail = _emailController.text;
    _initialPhone = _phoneController.text;
    _refreshFromServer();
  }

  Future<void> _refreshFromServer() async {
    try {
      final p = await ServiceLocator.parentService.getProfile();
      if (!mounted) return;
      final name = (p['name'] ?? p['Name'])?.toString();
      final email = (p['email'] ?? p['Email'])?.toString();
      final phone = (p['phone'] ?? p['Phone'])?.toString();
      final photoRaw = (p['photoUrl'] ?? p['photo_url'])?.toString();
      if (photoRaw != null && photoRaw.trim().isNotEmpty) {
        await ServiceLocator.tokenStorage.saveUserPhotoUrl(photoRaw.trim());
      }
      if (!mounted) return;
      final gov = (p['governorate'] ?? p['Governorate'] ?? '').toString().trim();
      final str = (p['street'] ?? p['Street'] ?? '').toString().trim();
      final addr = (p['address'] ?? p['Address'] ?? '').toString().trim();
      setState(() {
        if (name != null && name.trim().isNotEmpty) {
          _fullNameController.text = name.trim();
        }
        if (email != null && email.trim().isNotEmpty) {
          _emailController.text = email.trim();
          _initialEmail = email.trim();
        }
        if (phone != null && phone.trim().isNotEmpty) {
          _phoneController.text = phone.trim();
          _initialPhone = phone.trim();
        }
        if (photoRaw != null && photoRaw.trim().isNotEmpty) {
          _photoUrl = photoRaw.trim();
        }
        _governorate = gov;
        _street = str;
        _apiAddress = addr;
        _snapGov = gov;
        _snapStr = str;
        _snapAddr = addr;
        _locationController.text = (gov.isNotEmpty && str.isNotEmpty)
            ? '$gov, $str'
            : (addr.isNotEmpty ? addr : '');
      });
    } catch (_) {}
  }

  bool get _isDirty =>
      _emailController.text.trim() != _initialEmail.trim() ||
          _phoneController.text.trim() != _initialPhone.trim() ||
          _governorate.trim() != _snapGov.trim() ||
          _street.trim() != _snapStr.trim() ||
          _apiAddress.trim() != _snapAddr.trim();

  Future<bool> _confirmDiscardOrSave() async {
    if (!_isDirty) return true;
    final action = await showDialog<_LeaveAction>(
      context: context,
      builder: (context) => const _UnsavedChangesDialog(),
    );
    if (action == _LeaveAction.discard) return true;
    if (action == _LeaveAction.save) {
      await _save();
      return !_isDirty;
    }
    return false;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickCurrentLocation() async {
    if (_resolvingLocation) return;
    setState(() => _resolvingLocation = true);
    try {
      final r = await resolveParentGpsWithNominatim();
      if (!mounted) return;
      setState(() {
        _governorate = r.governorate;
        _street = r.street;
        _apiAddress = r.addressLatLngCsv;
        _locationController.text = r.displayLine;
      });
    } catch (e) {
      if (!mounted) return;
      await showAppFeedback(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _resolvingLocation = false);
    }
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    if (_uploadingPhoto) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source, imageQuality: 85);
    if (x == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await ServiceLocator.parentService.uploadProfilePhotoFile(x.path);
      if (!mounted) return;
      setState(() => _photoUrl = url);
      await showAppFeedback(context, 'Profile photo updated.');
    } catch (e) {
      if (!mounted) return;
      await showAppFeedback(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final updated = await ServiceLocator.parentService.updateProfile(
        email: email,
        phone: phone,
        address: _apiAddress,
        governorate: _governorate,
        street: _street,
      );
      await ServiceLocator.tokenStorage.saveUser(
        id: ServiceLocator.tokenStorage.getUserId() ?? 0,
        name: _fullNameController.text.trim(),
        email: (updated['email'] ?? email).toString(),
        phone: (updated['phone'] ?? phone).toString(),
        photoUrl: _photoUrl,
      );
      if (!mounted) return;
      final g = (updated['governorate'] ?? updated['Governorate'] ?? _governorate)
          .toString()
          .trim();
      final s = (updated['street'] ?? updated['Street'] ?? _street).toString().trim();
      final a = (updated['address'] ?? updated['Address'] ?? _apiAddress)
          .toString()
          .trim();
      setState(() {
        _initialEmail = _emailController.text.trim();
        _initialPhone = _phoneController.text.trim();
        _governorate = g;
        _street = s;
        _apiAddress = a;
        _snapGov = g;
        _snapStr = s;
        _snapAddr = a;
        _locationController.text =
            (g.isNotEmpty && s.isNotEmpty) ? '$g, $s' : (a.isNotEmpty ? a : '');
      });
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      await showAppFeedback(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        top: false,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final nav = Navigator.of(context);
            final ok = await _confirmDiscardOrSave();
            if (!mounted) return;
            if (ok) nav.pop();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final headerBlockH = h < 520 ? 200.0 : 221.0;
              final avatarTop = h < 520 ? 108.0 : 125.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: headerBlockH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: buildHeader(context),
                        ),
                        Positioned(
                          top: avatarTop,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _EditProfilePicture(
                              photoUrl: _photoUrl,
                              uploading: _uploadingPhoto,
                              onPick: () => _showPickPhotoSheet(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        0,
                        24,
                        16 + bottomInset + keyboardBottom,
                      ),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                          children: [
                            Center(child: buildFormCard(context)),
                            const SizedBox(height: 24),
                            Center(child: buildSaveButton(context)),
                          ],
                        ),
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
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPickPhotoSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              runSpacing: 12,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickAndUploadPhoto(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickAndUploadPhoto(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.primaryBlue97)),
            Positioned.fill(top: 0, bottom: 30,
              child: Center(
                child: Image.asset(
                  AppImages.logo,
                  width: 126,
                  height: 126,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              left: 15,
              top: 50,
              child: AppBackButton(
                onTap: () async {
                  final ok = await _confirmDiscardOrSave();
                  if (!context.mounted) return;
                  if (ok) Navigator.of(context).maybePop();
                },
                color: AppColors.white,
                icon: Icons.chevron_left,
                iconSize: 35,
              ),
            ),
            Positioned(left: 0, right: 0, top: 95,
              child: Text(
                'Edit Profile',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  height: 22 / 24,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFormCard(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final cardW = math.min(341.0, screenW - 48);
    final inputW = math.min(271.0, cardW - 70);

    return Padding(
      padding: const EdgeInsets.only(top: 11),
      child: Container(
        width: cardW,
        constraints: const BoxConstraints(minHeight: 0),
        padding: EdgeInsets.fromLTRB(
          math.max(16, (cardW - inputW) / 2),
          22,
          math.max(16, (cardW - inputW) / 2),
          22,
        ),
        decoration: BoxDecoration(
          color: context.appCardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFormField(
              context: context,
              inputW: inputW,
              label: 'Full Name',
              controller: _fullNameController,
              obscure: false,
              enabled: false,
            ),
            const SizedBox(height: 22),
            buildFormField(
              context: context,
              inputW: inputW,
              label: 'Email',
              controller: _emailController,
              obscure: false,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 22),
            buildFormField(
              context: context,
              inputW: inputW,
              label: 'Phone Number',
              controller: _phoneController,
              obscure: false,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 22),
            buildFormField(
              context: context,
              inputW: inputW,
              label: 'Location',
              controller: _locationController,
              obscure: false,
              readOnly: true,
              hintText: 'Tap icon for current location',
              suffixIcon: _resolvingLocation
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(end: 4),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _pickCurrentLocation,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 48,
                        maxWidth: 44,
                        maxHeight: 48,
                      ),
                      icon: Icon(
                        Icons.my_location,
                        size: 20,
                        color: AppColors.linkBlue.withValues(alpha: 0.85),
                      ),
                      tooltip: 'Current location',
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFormField({
    required BuildContext context,
    required double inputW,
    required String label,
    required TextEditingController controller,
    required bool obscure,
    TextInputType? keyboardType,
    bool enabled = true,
    bool readOnly = false,
    String? hintText,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.inputStrokeBlack21, width: 1),
    );

    // 48px row avoids clipped text vs old 40px + tight line-height; suffix has fixed width.
    const fieldHeight = 48.0;
    final hasSuffix = suffixIcon != null;
    final contentPadding = EdgeInsetsDirectional.fromSTEB(
      16,
      12,
      hasSuffix ? 4 : 16,
      12,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            height: 1.2,
            color: context.appPrimaryText,
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: inputW,
          height: fieldHeight,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            enabled: enabled,
            readOnly: readOnly,
            maxLines: 1,
            textAlignVertical: TextAlignVertical.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.25,
              color: context.appPrimaryText,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: context.appInputBackground,
              contentPadding: contentPadding,
              hintText: hintText,
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.25,
                color: context.appSecondaryText,
              ),
              suffixIcon: suffixIcon,
              suffixIconConstraints: hasSuffix
                  ? const BoxConstraints(
                      minWidth: 44,
                      maxWidth: 44,
                      minHeight: fieldHeight,
                      maxHeight: fieldHeight,
                    )
                  : null,
              border: border,
              enabledBorder: border,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: AppColors.linkBlue, width: 1.2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSaveButton(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final w = math.min(341.0, screenW - 48);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _saving ? null : _save,
        borderRadius: BorderRadius.circular(33),
        child: Ink(
          width: w,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(33),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF214D71), Color(0xFF3F79D7)],
            ),
          ),
          child: Center(
            child: Text(
              _saving ? 'Saving...' : 'Save Changes',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                height: 22 / 20,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile picture widget
// ─────────────────────────────────────────────────────────────────────────────

class _EditProfilePicture extends StatelessWidget {
  const _EditProfilePicture({
    required this.photoUrl,
    required this.uploading,
    required this.onPick,
  });

  final String? photoUrl;
  final bool uploading;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final full = supervisorPhotoFullUrl(photoUrl);
    return SizedBox(
      width: 114,
      height: 105,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 114,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: full != null && full.isNotEmpty
                ? Image.network(
              full,
              width: 91,
              height: 91,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                AppImages.parentProfilePic,
                width: 91,
                height: 91,
                fit: BoxFit.cover,
              ),
            )
                : Image.asset(
              AppImages.parentProfilePic,
              width: 91,
              height: 91,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.grayText,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              child: uploading
                  ? const Padding(
                padding: EdgeInsets.all(6),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : IconButton(
                padding: EdgeInsets.zero,
                onPressed: onPick,
                icon: const Icon(
                  Icons.camera_alt,
                  size: 14,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unsaved-changes dialog
// ─────────────────────────────────────────────────────────────────────────────

enum _LeaveAction { save, discard }

class _UnsavedChangesDialog extends StatelessWidget {
  const _UnsavedChangesDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Unsaved changes',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.appPrimaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have changes that are not saved. ماذا تريد أن تفعل؟',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: context.appSecondaryText,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop<_LeaveAction>(_LeaveAction.discard),
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop<_LeaveAction>(_LeaveAction.save),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}