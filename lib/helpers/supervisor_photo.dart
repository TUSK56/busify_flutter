import 'package:application/utils/api_config.dart';

/// Turns a relative API path (e.g. /uploads/supervisors/x.jpg) into a full URL for [Image.network].
///
/// If the server stored an absolute URL (e.g. from registration) with a different host than
/// [ApiConfig.baseUrl], the path is reused with the app's API origin so images load on device/emulator.
String? supervisorPhotoFullUrl(String? relativeOrAbsolute) {
  final s = relativeOrAbsolute?.trim();
  if (s == null || s.isEmpty) return null;
  if (s.startsWith('http://') || s.startsWith('https://')) {
    try {
      final uri = Uri.parse(s);
      if (uri.path.isEmpty) return s;
      final base = Uri.parse(ApiConfig.baseUrl);
      final uploads = uri.path.contains('/uploads/');
      if (uploads &&
          (uri.host != base.host ||
              uri.scheme != base.scheme ||
              uri.port != base.port)) {
        return base.replace(path: uri.path, query: uri.query).toString();
      }
    } catch (_) {}
    return s;
  }
  final path = s.startsWith('/') ? s : '/$s';
  return '${ApiConfig.baseUrl}$path';
}
