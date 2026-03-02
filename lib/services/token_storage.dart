import 'package:shared_preferences/shared_preferences.dart';

/// Stores and retrieves JWT token using SharedPreferences.
class TokenStorage {
  static const String _tokenKey = 'auth_token';

  final SharedPreferences _prefs;

  TokenStorage(this._prefs);

  /// Saves the JWT token locally.
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  /// Retrieves the stored token, or null if none.
  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  /// Removes the stored token (logout).
  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  /// Returns true if a token is stored.
  bool get hasToken => getToken() != null && getToken()!.isNotEmpty;
}
