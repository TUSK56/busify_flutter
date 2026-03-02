/// Model for school returned from GET /v1/schools
class School {
  final int id;
  final String name;

  const School({
    required this.id,
    required this.name,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
