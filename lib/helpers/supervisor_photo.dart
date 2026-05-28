import 'package:application/utils/api_config.dart';

/// Turns a relative API path (e.g. /uploads/supervisors/x.jpg) into a full URL for [Image.network].
///
/// If the server stored an absolute URL (e.g. from registration) with a different host than
/// [ApiConfig.baseUrl], the path is reused with the app's API origin so images load on device/emulator.
String? supervisorPhotoFullUrl(String? relativeOrAbsolute) {
  final s = relativeOrAbsolute?.trim();
  if (s == null || s.isEmpty) return null;
  String normalizePath(String path) {
    if (path.startsWith('/upload/')) {
      return '/uploads/${path.substring('/upload/'.length)}';
    }
    return path;
  }
  if (s.startsWith('http://') || s.startsWith('https://')) {
    try {
      final uri = Uri.parse(s);
      if (uri.path.isEmpty) return s;
      // Keep third-party absolute URLs (e.g. Cloudinary) unchanged.
      if (!uri.host.contains('herokuapp.com') &&
          !uri.host.contains('localhost') &&
          !uri.host.contains('127.0.0.1')) {
        return s;
      }
      final normalizedPath = normalizePath(uri.path);
      final base = Uri.parse(ApiConfig.baseUrl);
      if (uri.host != base.host ||
          uri.scheme != base.scheme ||
          uri.port != base.port) {
        return base.replace(path: normalizedPath, query: uri.query).toString();
      }
      if (normalizedPath != uri.path) {
        return uri.replace(path: normalizedPath).toString();
      }
    } catch (_) {}
    return s;
  }
  final path = normalizePath(s.startsWith('/') ? s : '/$s');
  return '${ApiConfig.baseUrl}$path';
}

/// URLs to try when loading a photo (static files may be mapped as `/uploads/...` or `/upload/...` on the host).
List<String> supervisorPhotoResolvedUrls(String? relativeOrAbsolute) {
  final primary = supervisorPhotoFullUrl(relativeOrAbsolute);
  if (primary == null || primary.isEmpty) return const [];
  final out = <String>{primary};
  try {
    final u = Uri.parse(primary);
    if (!u.hasScheme || u.host.isEmpty) return out.toList();
    final path = u.path;
    if (path.startsWith('/uploads/')) {
      final altPath = '/upload${path.substring('/uploads'.length)}';
      out.add(u.replace(path: altPath).toString());
    } else if (path.startsWith('/upload/') && !path.startsWith('/uploads/')) {
      final altPath = '/uploads${path.substring('/upload'.length)}';
      out.add(u.replace(path: altPath).toString());
    }
  } catch (_) {}
  return out.toList();
}
