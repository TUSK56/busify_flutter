import 'package:application/services/token_storage.dart';

/// Central auth service - provides token for protected requests.
class AuthService {
  final TokenStorage _tokenStorage;

  AuthService(this._tokenStorage);

  /// Returns the stored JWT token for Authorization header.
  String? get token => _tokenStorage.getToken();

  /// Returns true if user is logged in.
  bool get isLoggedIn => _tokenStorage.hasToken;

  /// Clears token on logout.
  Future<void> logout() async {
    await _tokenStorage.clearToken();
  }
}
