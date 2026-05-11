import 'package:shared_preferences/shared_preferences.dart';

/// Stores and retrieves JWT token using SharedPreferences.
class TokenStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'auth_user_id';
  static const String _userNameKey = 'auth_user_name';
  static const String _userEmailKey = 'auth_user_email';
  static const String _userPhoneKey = 'auth_user_phone';
  static const String _userPhotoUrlKey = 'auth_user_photo_url';
  static const String _studentPhotoUrlKey = 'auth_student_photo_url';

  final SharedPreferences _prefs;

  TokenStorage(this._prefs);

  /// Saves the JWT token locally.
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  Future<void> saveUser({
    required int id,
    required String name,
    required String email,
    String? phone,
    String? photoUrl,
  }) async {
    await _prefs.setInt(_userIdKey, id);
    await _prefs.setString(_userNameKey, name);
    await _prefs.setString(_userEmailKey, email);
    if (phone != null) {
      await _prefs.setString(_userPhoneKey, phone);
    } else {
      await _prefs.remove(_userPhoneKey);
    }
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      await _prefs.setString(_userPhotoUrlKey, photoUrl.trim());
    } else {
      await _prefs.remove(_userPhotoUrlKey);
    }
  }

  /// Retrieves the stored token, or null if none.
  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  int? getUserId() => _prefs.getInt(_userIdKey);
  String? getUserName() => _prefs.getString(_userNameKey);
  String? getUserEmail() => _prefs.getString(_userEmailKey);
  String? getUserPhone() => _prefs.getString(_userPhoneKey);
  String? getUserPhotoUrl() => _prefs.getString(_userPhotoUrlKey);
  String? getStudentPhotoUrl() => _prefs.getString(_studentPhotoUrlKey);

  Future<void> saveUserPhotoUrl(String? photoUrl) async {
    final s = photoUrl?.trim();
    if (s == null || s.isEmpty) {
      await _prefs.remove(_userPhotoUrlKey);
    } else {
      await _prefs.setString(_userPhotoUrlKey, s);
    }
  }

  Future<void> saveStudentPhotoUrl(String? photoUrl) async {
    final s = photoUrl?.trim();
    if (s == null || s.isEmpty) {
      await _prefs.remove(_studentPhotoUrlKey);
    } else {
      await _prefs.setString(_studentPhotoUrlKey, s);
    }
  }

  /// Removes the stored token (logout).
  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userNameKey);
    await _prefs.remove(_userEmailKey);
    await _prefs.remove(_userPhoneKey);
    await _prefs.remove(_userPhotoUrlKey);
    await _prefs.remove(_studentPhotoUrlKey);
  }

  /// Returns true if a token is stored.
  bool get hasToken => getToken() != null && getToken()!.isNotEmpty;
}
