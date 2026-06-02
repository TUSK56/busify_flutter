/// Response from GET /v1/Supervisor/me
class SupervisorDashboard {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? photoUrl;
  final String? busNumber;
  final int? activeTripId;
  final int assignedCount;
  final int boardedCount;
  final int notYetCount;

  const SupervisorDashboard({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.busNumber,
    this.activeTripId,
    required this.assignedCount,
    required this.boardedCount,
    required this.notYetCount,
  });

  factory SupervisorDashboard.fromJson(Map<String, dynamic> json) {
    final bus = json['bus'];
    String? busNumber;
    if (bus is Map<String, dynamic>) {
      busNumber = (bus['busNumber'] ?? bus['bus_number'])?.toString();
    }
    final tripRaw = json['activeTripId'] ?? json['active_trip_id'] ?? json['ActiveTripId'];
    int? activeTripId;
    if (tripRaw is int) {
      activeTripId = tripRaw > 0 ? tripRaw : null;
    } else if (tripRaw is num) {
      final t = tripRaw.toInt();
      activeTripId = t > 0 ? t : null;
    } else if (tripRaw is String) {
      final t = int.tryParse(tripRaw.trim());
      activeTripId = (t != null && t > 0) ? t : null;
    }

    final idRaw = json['id'] ?? json['Id'];
    final supervisorId = idRaw is num ? idRaw.toInt() : int.parse(idRaw.toString());

    return SupervisorDashboard(
      id: supervisorId,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      photoUrl: (json['photoUrl'] ?? json['photo_url'])?.toString(),
      busNumber: busNumber,
      activeTripId: activeTripId,
      assignedCount: _readInt(json, const ['assignedCount', 'assigned_count']) ?? 0,
      boardedCount: _readInt(json, const ['boardedCount', 'boarded_count']) ?? 0,
      notYetCount: _readInt(json, const ['notYetCount', 'not_yet_count']) ?? 0,
    );
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v is num) return v.toInt();
      final parsed = int.tryParse(v?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }
}
