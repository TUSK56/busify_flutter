import 'dart:async';

/// Lightweight signal for trip/attendance data changes (FCM, etc.).
/// Screens subscribe and refresh only their own data — no full-app reload.
class TripLiveUpdates {
  TripLiveUpdates._();

  static final TripLiveUpdates instance = TripLiveUpdates._();

  final _controller = StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  void notify(String reason) {
    if (_controller.isClosed) return;
    _controller.add(reason);
  }

  void dispose() {
    _controller.close();
  }
}
