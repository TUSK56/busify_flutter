/// Model for child in parent registration request
class Child {
  final String name;
  final int schoolId;
  final String birthdate; // yyyy-MM-dd
  final String grade;
  final String? photoUrl;
  /// JPEG/PNG bytes as base64 (optional; server saves file and sets [photoUrl]).
  final String? photoBase64;
  /// Averaged embedding JSON from five live scans (optional).
  final String? embeddingJson;

  const Child({
    required this.name,
    required this.schoolId,
    required this.birthdate,
    required this.grade,
    this.photoUrl,
    this.photoBase64,
    this.embeddingJson,
  });

  Map<String, dynamic> toJson() {
    final pb = photoBase64;
    final emb = embeddingJson;
    return {
      'name': name,
      'schoolId': schoolId,
      'birthdate': birthdate,
      'grade': grade,
      'photoUrl': photoUrl,
      if (pb != null && pb.isNotEmpty) 'photoBase64': pb,
      if (emb != null && emb.isNotEmpty) 'embeddingJson': emb,
    };
  }
}
