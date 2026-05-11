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
    final tripRaw = json['activeTripId'];
    int? activeTripId;
    if (tripRaw is int) {
      activeTripId = tripRaw > 0 ? tripRaw : null;
    } else if (tripRaw is num) {
      final t = tripRaw.toInt();
      activeTripId = t > 0 ? t : null;
    }

    return SupervisorDashboard(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      photoUrl: (json['photoUrl'] ?? json['photo_url'])?.toString(),
      busNumber: busNumber,
      activeTripId: activeTripId,
      assignedCount: (json['assignedCount'] as num?)?.toInt() ?? 0,
      boardedCount: (json['boardedCount'] as num?)?.toInt() ?? 0,
      notYetCount: (json['notYetCount'] as num?)?.toInt() ?? 0,
    );
  }
}
