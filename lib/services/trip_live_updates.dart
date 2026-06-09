import 'dart:async';

/// Lightweight signal for trip/attendance data changes (FCM, supervisor UI, etc.).
class TripLiveUpdateEvent {
  final String reason;
  final int? studentId;
  final String? busNumber;

  const TripLiveUpdateEvent(
    this.reason, {
    this.studentId,
    this.busNumber,
  });
}

/// Screens subscribe and refresh only their own data — no full-app reload.
class TripLiveUpdates {
  TripLiveUpdates._();

  static final TripLiveUpdates instance = TripLiveUpdates._();

  final _controller = StreamController<TripLiveUpdateEvent>.broadcast();

  Stream<TripLiveUpdateEvent> get stream => _controller.stream;

  void notify(
    String reason, {
    int? studentId,
    String? busNumber,
  }) {
    if (_controller.isClosed) return;
    _controller.add(
      TripLiveUpdateEvent(
        reason,
        studentId: studentId,
        busNumber: busNumber,
      ),
    );
  }

  void dispose() {
    _controller.close();
  }
}
