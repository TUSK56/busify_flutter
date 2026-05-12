// JSON helpers: coerce jsonDecode maps/lists to Map<String, dynamic> so list items
// are not dropped when the runtime type is not exactly Map<String, dynamic>.

Map<String, dynamic>? coerceJsonMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) {
    return v.map((k, val) => MapEntry(k.toString(), val));
  }
  return null;
}

List<Map<String, dynamic>> coerceJsonMapList(dynamic v) {
  if (v is! List) return const [];
  final out = <Map<String, dynamic>>[];
  for (final e in v) {
    final m = coerceJsonMap(e);
    if (m != null) out.add(m);
  }
  return out;
}

// Student / profile photo fields from API (camelCase + PascalCase + common aliases).
String? readPhotoUrlFromMap(Map<String, dynamic> m) {
  for (final k in const [
    'photoUrl',
    'photo_url',
    'PhotoUrl',
    'imageUrl',
    'image_url',
    'ImageUrl',
    'profilePhotoUrl',
    'profile_photo_url',
    'pictureUrl',
    'picture_url',
    'PictureUrl',
  ]) {
    final s = m[k]?.toString().trim();
    if (s != null && s.isNotEmpty) return s;
  }
  return null;
}
