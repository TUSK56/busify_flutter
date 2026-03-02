/// Data collected from parent signup info screen, passed to student screen.
class ParentSignupData {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String password;

  const ParentSignupData({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.password,
  });
}
