import 'package:application/constants/app_colors.dart';
import 'package:application/helpers/app_feedback.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/widgets/supervisor_avatar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Change supervisor profile photo only (uploads immediately; no separate confirm step).
class SupervisorEditProfileScreen extends StatefulWidget {
  const SupervisorEditProfileScreen({super.key});

  @override
  State<SupervisorEditProfileScreen> createState() =>
      _SupervisorEditProfileScreenState();
}

class _SupervisorEditProfileScreenState extends State<SupervisorEditProfileScreen> {
  bool _uploading = false;

  Future<void> _pickAndUpload(ImageSource source) async {
    if (_uploading) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source, imageQuality: 85);
    if (x == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      await ServiceLocator.supervisorService.uploadProfilePhotoFile(x.path);
      if (!mounted) return;
      await showAppFeedback(context, 'Profile photo updated.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      await showAppFeedback(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = ServiceLocator.tokenStorage.getUserName() ?? 'Supervisor';

    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue97,
        foregroundColor: Colors.white,
        title: const Text('Edit profile'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: context.appPrimaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a new photo. It updates everywhere as soon as upload finishes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.appSecondaryText,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const SupervisorAvatar(radius: 64),
                    if (_uploading)
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _uploading
                    ? null
                    : () => _pickAndUpload(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose from gallery'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _uploading
                    ? null
                    : () => _pickAndUpload(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take a photo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
