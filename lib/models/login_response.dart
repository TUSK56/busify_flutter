import 'package:application/models/user.dart';

/// Response from POST /v1/parent/login or POST /v1/Supervisor/login
class LoginResponse {
  final String token;
  final String? refreshToken;
  final User user;

  const LoginResponse({
    required this.token,
    this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String?,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
