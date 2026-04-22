import 'package:shared_preferences/shared_preferences.dart';

/// Stores and retrieves JWT token using SharedPreferences.
class TokenStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'auth_user_id';
  static const String _userNameKey = 'auth_user_name';
  static const String _userEmailKey = 'auth_user_email';
  static const String _userPhoneKey = 'auth_user_phone';

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
  }) async {
    await _prefs.setInt(_userIdKey, id);
    await _prefs.setString(_userNameKey, name);
    await _prefs.setString(_userEmailKey, email);
    if (phone != null) {
      await _prefs.setString(_userPhoneKey, phone);
    } else {
      await _prefs.remove(_userPhoneKey);
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

  /// Removes the stored token (logout).
  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userNameKey);
    await _prefs.remove(_userEmailKey);
    await _prefs.remove(_userPhoneKey);
  }

  /// Returns true if a token is stored.
  bool get hasToken => getToken() != null && getToken()!.isNotEmpty;
}
