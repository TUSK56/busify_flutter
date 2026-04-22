/// Data collected from parent signup info screen, passed to student screen.
class ParentSignupData {
  final String name;
  final String email;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  final String governorate;
  final String street;
  final String password;

  const ParentSignupData({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.governorate,
    required this.street,
    required this.password,
  });
}
