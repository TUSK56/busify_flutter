/// Model for school returned from GET /v1/schools
class School {
  final int id;
  final String name;

  const School({
    required this.id,
    required this.name,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'] ?? json['Id'] ?? json['schoolAdminId'];
    final schoolId = idRaw is num
        ? idRaw.toInt()
        : int.tryParse(idRaw?.toString() ?? '') ?? 0;
    if (schoolId <= 0) {
      throw FormatException('School id missing in API response');
    }
    final nameRaw = json['name'] ?? json['Name'];
    return School(
      id: schoolId,
      name: (nameRaw == null || nameRaw.toString().trim().isEmpty)
          ? 'School'
          : nameRaw.toString().trim(),
    );
  }
}
