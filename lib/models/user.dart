/// Model for user returned in login response
class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? photoUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.photoUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'] ?? json['Id'];
    final userId = idRaw is num ? idRaw.toInt() : int.parse(idRaw.toString());
    return User(
      id: userId,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      phone: (json['phone'] ?? json['Phone'])?.toString(),
      photoUrl: (json['photoUrl'] ?? json['photo_url'])?.toString(),
    );
  }
}
