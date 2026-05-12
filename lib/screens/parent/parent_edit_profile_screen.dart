import 'dart:math' as math;

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/helpers/app_back_button.dart';
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

  String? _photoUrl;
  bool _saving = false;
  bool _uploadingPhoto = false;

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
      });
    } catch (_) {}
  }

  bool get _isDirty {
    return _emailController.text.trim() != _initialEmail.trim() ||
        _phoneController.text.trim() != _initialPhone.trim();
  }

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
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    if (_uploadingPhoto) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source, imageQuality: 85);
    if (x == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await ServiceLocator.parentService.uploadProfilePhotoFile(
        x.path,
      );
      if (!mounted) return;
      setState(() => _photoUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
      );
      await ServiceLocator.tokenStorage.saveUser(
        id: ServiceLocator.tokenStorage.getUserId() ?? 0,
        name: _fullNameController.text.trim(),
        email: (updated['email'] ?? email).toString(),
        phone: (updated['phone'] ?? phone).toString(),
        photoUrl: _photoUrl,
      );
      if (!mounted) return;
      setState(() {
        _initialEmail = _emailController.text.trim();
        _initialPhone = _phoneController.text.trim();
      });
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final nav = Navigator.of(context);
            final ok = await _confirmDiscardOrSave();
            if (!mounted) return;
            if (ok) nav.pop();
          },
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 24 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 221,
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
                            top: 125,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          buildFormCard(context),
                          const SizedBox(height: 12),
                          Center(child: buildSaveButton(context)),
                        ],
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

  /// **168** height, bottom radius **40**, **214071 @ 97%**, brand logo **126×54**, title **Edit Profile**.
  Widget buildHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
      child: SizedBox(
        height: 168,
        width: double.infinity,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.primaryBlue97)),
            Positioned.fill(
              top: 40,
              bottom: 72,
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
            Positioned(
              left: 0,
              right: 0,
              top: 95,
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

  /// **341×408** min, radius **15**, **#D9D9D9 49%**.
  Widget buildFormCard(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final cardW = math.min(341.0, screenW - 48);
    final inputW = math.min(271.0, cardW - 70);

    return Container(
      width: cardW,
      constraints: const BoxConstraints(minHeight: 408),
      padding: EdgeInsets.fromLTRB(
        math.max(16, (cardW - inputW) / 2),
        22,
        math.max(16, (cardW - inputW) / 2),
        22,
      ),
      decoration: BoxDecoration(
        color: context.appCardBackground,
        borderRadius: BorderRadius.circular(15),
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
        ],
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
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: AppColors.inputStrokeBlack21, width: 1),
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
            height: 22 / 20,
            color: context.appPrimaryText,
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: inputW,
          height: 40,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            enabled: enabled,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 22 / 16,
              color: context.appPrimaryText,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: context.appInputBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

  /// **341×46** min, radius **33**, gradient **#D9D9D9 → #2859C5**, label **Save** white.
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

/// Ellipse **114×96** `#F5F5F5`, inner photo **91×78**, camera badge.
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
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 114,
            height: 96,
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
                    height: 78,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      AppImages.parentProfilePic,
                      width: 91,
                      height: 78,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    AppImages.parentProfilePic,
                    width: 91,
                    height: 78,
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
