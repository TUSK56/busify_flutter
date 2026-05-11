import 'package:application/constants/app_images.dart';
import 'package:application/helpers/supervisor_photo.dart';
import 'package:application/services/service_locator.dart';
import 'package:flutter/material.dart';

/// Profile image for the logged-in supervisor: uploaded photo or placeholder asset.
class SupervisorAvatar extends StatelessWidget {
  final double radius;
  final Color? placeholderColor;

  const SupervisorAvatar({
    super.key,
    this.radius = 26,
    this.placeholderColor,
  });

  @override
  Widget build(BuildContext context) {
    final fullUrl = supervisorPhotoFullUrl(
      ServiceLocator.tokenStorage.getUserPhotoUrl(),
    );
    final size = radius * 2;
    final placeholder = placeholderColor ?? Colors.grey.shade300;

    Widget fallback() {
      return Image.asset(
        AppImages.supervisorAvatar,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.person,
          size: radius * 1.2,
          color: Colors.grey,
        ),
      );
    }

    if (fullUrl != null && fullUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          fullUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallback(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              color: placeholder,
              alignment: Alignment.center,
              child: SizedBox(
                width: radius * 0.8,
                height: radius * 0.8,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      );
    }

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: placeholder,
        alignment: Alignment.center,
        child: fallback(),
      ),
    );
  }
}
