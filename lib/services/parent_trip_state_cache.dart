/// Persists parent home trip/attendance UI across screen recreations.
class ParentTripStateSnapshot {
  final Map<int, bool> tripActiveByStudent;
  final Map<int, DateTime?> tripStartedLocalByStudent;
  final Map<int, bool> isAfternoonTripByStudent;
  final Map<int, bool> childAfternoonDroppedByStudent;
  final Map<int, String> busNumberByStudent;
  final Map<int, String?> todayScanByStudent;
  final Map<int, String?> todayScanTimeByStudent;
  final Map<int, int> weekPresentByStudent;
  final Map<int, DateTime> optimisticScanAtByStudent;
  final bool tripActive;
  final int? primaryStudentId;
  final DateTime cachedAt;

  const ParentTripStateSnapshot({
    required this.tripActiveByStudent,
    required this.tripStartedLocalByStudent,
    required this.isAfternoonTripByStudent,
    required this.childAfternoonDroppedByStudent,
    required this.busNumberByStudent,
    required this.todayScanByStudent,
    required this.todayScanTimeByStudent,
    required this.weekPresentByStudent,
    required this.optimisticScanAtByStudent,
    required this.tripActive,
    required this.primaryStudentId,
    required this.cachedAt,
  });

  bool get isFresh =>
      DateTime.now().difference(cachedAt) < const Duration(hours: 12);
}

class ParentTripStateCache {
  ParentTripStateCache._();

  static final ParentTripStateCache instance = ParentTripStateCache._();

  ParentTripStateSnapshot? _snapshot;

  void save(ParentTripStateSnapshot snapshot) {
    _snapshot = snapshot;
  }

  ParentTripStateSnapshot? readFresh() {
    final snap = _snapshot;
    if (snap == null || !snap.isFresh) return null;
    return snap;
  }

  bool tripActiveFor(int studentId) {
    final snap = readFresh();
    if (snap == null) return false;
    return snap.tripActiveByStudent[studentId] ?? false;
  }

  void clear() => _snapshot = null;
}
