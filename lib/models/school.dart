/// Model for school returned from GET /v1/schools
class School {
  final int id;
  final String name;

  const School({
    required this.id,
    required this.name,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'] ?? json['Id'];
    final schoolId = idRaw is num ? idRaw.toInt() : int.parse(idRaw.toString());
    return School(
      id: schoolId,
      name: json['name'] as String,
    );
  }
}
