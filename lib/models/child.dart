/// Model for child in parent registration request
class Child {
  final String name;
  final int schoolId;
  final String birthdate; // yyyy-MM-dd
  final String grade;
  final String? photoUrl;

  const Child({
    required this.name,
    required this.schoolId,
    required this.birthdate,
    required this.grade,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'schoolId': schoolId,
      'birthdate': birthdate,
      'grade': grade,
      'photoUrl': photoUrl,
    };
  }
}
