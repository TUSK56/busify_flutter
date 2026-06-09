import 'dart:async';
import 'dart:math' as math;

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/api_json.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/helpers/supervisor_photo.dart';
import 'package:application/routes/fade_route.dart';
import 'package:application/widgets/parent/parent_bottom_nav_bar.dart';
import 'package:application/widgets/resilient_network_image.dart';
import 'package:application/services/service_locator.dart';
import 'package:application/services/push_notifications_service.dart';
import 'package:application/services/trip_live_updates.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';



import 'parent_profile_screen.dart';
import 'parent_track_bus_screen.dart';

/// Layout / visibility knobs for [ParentHomeScreen].
class _ParentHomeLayout {
  _ParentHomeLayout._();

  /// Set to false to hide the back-style arrow next to "Track Bus".
  static const bool showTrackBusBackArrow = true;

  /// Icon size for that arrow (e.g. [Icons.arrow_back_ios_new]).
  static const double trackBusBackArrowSize = 16;

  /// Space between the arrow and the label.
  static const double trackBusBackArrowGap = 8;

  /// If true, the back arrow is drawn after "Track Bus"; if false, before it.
  static const bool trackBusBackArrowAfterLabel = true;

  /// Uniform scale for the Track Bus button: multiplies width, height, padding,
  /// font, and arrow sizes. Use `1.0` as baseline.
  static const double trackBusButtonScale = 1.0;

  /// Outer size of the gradient (before [trackBusButtonScale]).
  static const double trackBusButtonWidth = 220;
  static const double trackBusButtonHeight = 42;

  /// Horizontal padding inside the Track Bus gradient.
  static const double _trackBusBtnPadH = 14;
  static const double _trackBusBtnFont = 20;
}

/// Parent home screen.
class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;
  String _parentName = '';
  String _studentName = '';
  String _studentGrade = '';
  String _busNumber = '--';
  int? _studentId;

  String _todayAttendanceLabel = 'Not scanned yet';
  bool? _todayPresent;
  int _weekPresentDays = 0;

  String _boardedTimeText = '—';
  bool _tripActive = false;
  /// Per-student trip UI (siblings may be on different buses or unattached).
  final Map<int, bool> _tripActiveByStudent = {};
  final Map<int, DateTime?> _tripStartedLocalByStudent = {};
  final Map<int, bool> _childAfternoonDroppedByStudent = {};
  final Map<int, bool> _isAfternoonTripByStudent = {};
  String? _studentPhotoUrl;

  /// Latest scan for **today** from API: `IN`, `ABSENT`, or null (drives week `x/5` + raw state).
  String? _todayLatestScanType;

  Timer? _homePollTimer;
  Timer? _attendancePollTimer;
  StreamSubscription<String>? _liveUpdatesSub;

  static const Duration _tripPollInterval = Duration(milliseconds: 500);
  static const Duration _attendancePollInterval = Duration(seconds: 12);
  final Map<int, int> _inactiveTripPollStreakByStudent = {};

  bool _isAfternoonTrip = false;

  /// True when afternoon trip completed OUT at home for the linked student (server flag).
  bool _childAfternoonDroppedOff = false;
  List<Map<String, dynamic>> _students = const [];
  final Map<int, String> _busNumberByStudent = <int, String>{};
  final Map<int, String?> _todayScanByStudent = <int, String?>{};
  final Map<int, String?> _todayScanTimeByStudent = <int, String?>{};
  final Map<int, int> _weekPresentByStudent = <int, int>{};
  final Map<int, DateTime> _optimisticScanAtByStudent = <int, DateTime>{};

  /// Backend serializes [ScanType] as JSON numbers (IN=0, OUT=1, ABSENT=2) unless configured otherwise.
  static String _normalizeScanType(dynamic v) {
    if (v == null) return '';
    if (v is num) {
      switch (v.toInt()) {
        case 0:
          return 'IN';
        case 1:
          return 'OUT';
        case 2:
          return 'ABSENT';
      }
    }
    return v.toString().toUpperCase();
  }

  static String? _readPhotoUrl(Map<String, dynamic> m) => readPhotoUrlFromMap(m);

  /// API timestamps are UTC; strings without "Z" are treated as UTC for correct local clock.
  static DateTime? _parseApiTimestampToLocal(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final dt = DateTime.tryParse(raw.trim());
    if (dt == null) return null;
    if (dt.isUtc) return dt.toLocal();
    return DateTime.utc(
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond,
      dt.microsecond,
    ).toLocal();
  }

  static DateTime? _parseTripStartedLocal(Map<String, dynamic>? trip) {
    if (trip == null) return null;
    for (final key in [
      'startedAtUtc',
      'StartedAtUtc',
    ]) {
      final parsed = _parseApiTimestampToLocal(trip[key]?.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _entranceController.forward();
    unawaited(PushNotificationsService.registerTokenAfterParentLogin());
    PushNotificationsService.flushPendingNavigation();
    _liveUpdatesSub = TripLiveUpdates.instance.stream.listen((reason) {
      if (!mounted) return;
      if (reason == 'student_link_approved' ||
          reason == 'student_link_rejected') {
        unawaited(_loadParentOverview());
      } else if (reason == 'trip_started') {
        _applyOptimisticTripStarted();
        unawaited(_refreshTripStateOnly());
      } else if (reason == 'trip_ended' || reason == 'emergency_trip_ended') {
        _inactiveTripPollStreakByStudent.clear();
        _applyOptimisticTripEnded();
        unawaited(_refreshTripStateOnly());
        unawaited(_refreshAttendanceOnly());
      } else if (reason == 'attendance_in' ||
          reason == 'student_boarded') {
        _applyOptimisticAttendanceIn();
        unawaited(_refreshTripStateOnly());
        unawaited(_refreshAttendanceOnly());
      } else if (reason == 'attendance_out') {
        unawaited(_refreshTripStateOnly());
        unawaited(_refreshAttendanceOnly());
      } else if (reason == 'attendance_absent' || reason == 'student_absent') {
        _applyOptimisticAttendanceAbsent();
        unawaited(_refreshTripStateOnly());
        unawaited(_refreshAttendanceOnly());
      } else {
        unawaited(_refreshTripStateOnly());
      }
    });
    _loadParentOverview();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(PushNotificationsService.registerTokenAfterParentLogin());
      if (_students.isEmpty) {
        unawaited(_loadParentOverview());
      } else {
        unawaited(_refreshTripStateOnly());
      }
    } else if (state == AppLifecycleState.paused) {
      _stopHomePolling();
    }
  }

  List<int> _linkedStudentIds() {
    if (_students.isNotEmpty) {
      return _students
          .map((s) => s['id'] ?? s['Id'])
          .whereType<num>()
          .map((n) => n.toInt())
          .where((id) => id > 0)
          .toList();
    }
    if (_studentId != null && _studentId! > 0) return [_studentId!];
    return const [];
  }

  void _applyOptimisticTripStarted() {
    final ids = _linkedStudentIds();
    if (ids.isEmpty) return;
    setState(() {
      for (final sid in ids) {
        _tripActiveByStudent[sid] = true;
        _inactiveTripPollStreakByStudent[sid] = 0;
      }
      _tripActive = true;
    });
  }

  void _applyOptimisticTripEnded() {
    final ids = _linkedStudentIds();
    setState(() {
      for (final sid in ids) {
        _tripActiveByStudent[sid] = false;
      }
      _tripActive = false;
    });
  }

  void _applyOptimisticAttendanceIn() {
    final ids = _linkedStudentIds();
    if (ids.isEmpty) return;
    final now = DateTime.now();
    setState(() {
      for (final sid in ids) {
        _tripActiveByStudent[sid] = true;
        _inactiveTripPollStreakByStudent[sid] = 0;
        final wasIn = _todayScanByStudent[sid] == 'IN';
        _todayScanByStudent[sid] = 'IN';
        _todayScanTimeByStudent[sid] = _formatTime(now);
        _optimisticScanAtByStudent[sid] = now;
        if (!wasIn) {
          final prevWeek = _weekPresentByStudent[sid] ?? 0;
          if (prevWeek < 5) {
            _weekPresentByStudent[sid] = prevWeek + 1;
          }
        }
      }
      final primary = _studentId ?? ids.first;
      if (primary > 0) {
        _tripActive = true;
        _todayPresent = true;
        _todayAttendanceLabel = 'Present';
        _todayLatestScanType = 'IN';
      }
    });
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) unawaited(_refreshAttendanceOnly());
    });
    Future<void>.delayed(const Duration(seconds: 6), () {
      if (mounted) unawaited(_refreshAttendanceOnly());
    });
  }

  void _applyOptimisticAttendanceAbsent() {
    final ids = _linkedStudentIds();
    if (ids.isEmpty) return;
    setState(() {
      for (final sid in ids) {
        _todayScanByStudent[sid] = 'ABSENT';
      }
      final primary = _studentId ?? ids.first;
      if (primary > 0) {
        _todayPresent = false;
        _todayAttendanceLabel = 'Absent';
        _todayLatestScanType = 'ABSENT';
      }
    });
  }

  Future<void> _loadParentOverview() async {
    final cachedName = ServiceLocator.tokenStorage.getUserName();
    if (cachedName != null && cachedName.isNotEmpty && mounted) {
      setState(() {
        _parentName = cachedName;
      });
    }
    try {
      final profile = await ServiceLocator.parentService.getProfile();
      final name = (profile['name'] ?? profile['Name'])?.toString();
      final pPhoto = _readPhotoUrl(profile);
      if (!mounted) return;
      setState(() {
        if (name != null && name.isNotEmpty) {
          _parentName = name;
        }
      });
      if (pPhoto != null && pPhoto.isNotEmpty) {
        await ServiceLocator.tokenStorage.saveUserPhotoUrl(pPhoto);
      }
    } catch (_) {}
    try {
      final data = await ServiceLocator.parentService.getChildOverview();
      final parent =
          (data['parent'] ?? data['Parent']) as Map<String, dynamic>?;
      final allStudents = coerceJsonMapList(data['students'] ?? data['Students']);
      final students = allStudents.where((s) {
        final raw = s['linkStatus'] ?? s['link_status'] ?? s['LinkStatus'];
        if (raw == null) return true; // backward-compatible: treat as approved
        final st = raw.toString().toLowerCase().trim();
        return st == 'approved';
      }).toList();
      final busByStudent = <int, String>{};
      for (final s in students) {
        final sidRaw = s['id'] ?? s['Id'];
        if (sidRaw is! num) continue;
        final sid = sidRaw.toInt();
        final sBus = (s['busNumber'] ?? s['BusNumber'] ?? s['bus_number'])
            ?.toString()
            .trim();
        if (sBus != null && sBus.isNotEmpty) {
          busByStudent[sid] = sBus;
        }
      }
      setState(() {
        if (parent != null) {
          final name = (parent['name'] ?? parent['Name'])?.toString();
          if (name != null && name.isNotEmpty) {
            _parentName = name;
          }
        }
        _students = students;
        _busNumberByStudent
          ..clear()
          ..addAll(busByStudent);
        if (students.isNotEmpty) {
          final s = students.first;
          final sid = s['id'] ?? s['Id'];
          final sName = (s['name'] ?? s['Name'])?.toString();
          final sGrade = (s['grade'] ?? s['Grade'])?.toString();
          final sPhoto = _readPhotoUrl(s);
          if (sid is int) _studentId = sid;
          if (sid is num) _studentId = sid.toInt();
          if (sName != null && sName.isNotEmpty) {
            _studentName = sName;
          }
          if (sGrade != null && sGrade.isNotEmpty) {
            _studentGrade = sGrade;
          }
          _studentPhotoUrl =
              (sPhoto != null && sPhoto.trim().isNotEmpty) ? sPhoto.trim() : null;
        } else {
          _studentPhotoUrl = null;
        }
        if (_studentId != null && _studentId! > 0) {
          final own = busByStudent[_studentId!];
          if (own != null && own.isNotEmpty) {
            _busNumber = own;
          } else {
            _busNumber = '--';
          }
        }
      });
      if (students.isNotEmpty) {
        await Future.wait([
          _loadAttendanceForAllStudents(students),
          _refreshTripStateOnly(),
        ]);
      } else {
        await Future.wait([
          _loadAttendanceSummary(),
          _refreshTripStateOnly(),
        ]);
      }
    } catch (_) {}

    if (mounted && _linkedStudentIds().isNotEmpty) {
      _startHomePolling();
    }
  }

  void _startHomePolling() {
    _homePollTimer?.cancel();
    _attendancePollTimer?.cancel();
    unawaited(_refreshTripStateOnly());
    _homePollTimer = Timer.periodic(_tripPollInterval, (_) {
      if (!mounted) return;
      unawaited(_refreshTripStateOnly());
    });
    _attendancePollTimer = Timer.periodic(_attendancePollInterval, (_) {
      if (!mounted) return;
      unawaited(_refreshAttendanceOnly());
    });
  }

  void _stopHomePolling() {
    _homePollTimer?.cancel();
    _homePollTimer = null;
    _attendancePollTimer?.cancel();
    _attendancePollTimer = null;
  }

  Future<void> _refreshAttendanceOnly() async {
    if (_students.isNotEmpty) {
      await _loadAttendanceForAllStudents(_students);
    } else {
      await _loadAttendanceSummary();
    }
    if (!mounted) return;
    for (final sid in _linkedStudentIds()) {
      _applyTripAndTodayUiForStudent(
        studentId: sid,
        tripActive: _tripActiveByStudent[sid] ?? _tripActive,
        tripStartedLocal: _tripStartedLocalByStudent[sid],
        busNoTrip: _busNumberByStudent[sid],
        busFallback: _busNumberByStudent[sid],
        isAfternoonTrip: _isAfternoonTripByStudent[sid] ?? false,
        childAfternoonDroppedOff:
            _childAfternoonDroppedByStudent[sid] ?? false,
      );
    }
  }

  Future<void> _refreshTripStateOnly() async {
    final ids = _linkedStudentIds();
    if (ids.isEmpty) return;

    final results = await Future.wait(
      ids.map((sid) async {
        try {
          final current = await ServiceLocator.parentService.getCurrentTrip(
            studentId: sid,
          );
          return (sid: sid, current: current, ok: true);
        } catch (_) {
          return (sid: sid, current: null, ok: false);
        }
      }),
    );

    if (!mounted) return;

    for (final row in results) {
      final sid = row.sid;
      if (!row.ok || row.current == null) {
        if (_tripActiveByStudent[sid] == true) continue;
        continue;
      }

      final current = row.current!;
      var tripActive = _tripActiveByStudent[sid] ?? false;
      DateTime? tripStartedLocal;
      String? busNoTrip;
      var isAfternoonTrip = false;
      var childAfternoonDroppedOff = false;

      final trip = current['trip'] as Map<String, dynamic>?;
      tripStartedLocal = _parseTripStartedLocal(trip);
      isAfternoonTrip = _tripTypeIsAfternoon(trip);
      final bus = current['bus'] as Map<String, dynamic>?;
      if (bus != null) {
        final bn = bus['busNumber'] ?? bus['BusNumber'] ?? bus['bus_number'];
        if (bn != null && bn.toString().trim().isNotEmpty) {
          busNoTrip = bn.toString().trim();
        }
      }

      final hasActive = current['has_active_trip'] == true ||
          current['hasActiveTrip'] == true;
      if (hasActive) {
        _inactiveTripPollStreakByStudent[sid] = 0;
        tripActive = true;
      } else {
        final streak = (_inactiveTripPollStreakByStudent[sid] ?? 0) + 1;
        _inactiveTripPollStreakByStudent[sid] = streak;
        tripActive = streak < 6 && (_tripActiveByStudent[sid] ?? false);
      }

      if (isAfternoonTrip) {
        childAfternoonDroppedOff =
            current['child_afternoon_dropped_off'] == true ||
                current['childAfternoonDroppedOff'] == true;
      }

      final existingBus = _busNumberByStudent[sid];
      final busFb = (existingBus != null && existingBus.trim().isNotEmpty)
          ? existingBus.trim()
          : null;
      _applyTripAndTodayUiForStudent(
        studentId: sid,
        tripActive: tripActive,
        tripStartedLocal: tripStartedLocal,
        busNoTrip: busNoTrip,
        busFallback: busFb,
        isAfternoonTrip: isAfternoonTrip,
        childAfternoonDroppedOff: childAfternoonDroppedOff,
      );
    }
  }

  static bool _tripTypeIsAfternoon(Map<String, dynamic>? trip) {
    if (trip == null) return false;
    final t =
        (trip['tripType'] ?? trip['TripType'] ?? '').toString().toLowerCase();
    return t.contains('afternoon');
  }

  /// Present only while a trip is active and today's latest scan is IN; absent if marked ABSENT;
  /// otherwise "Not scanned yet" (including IN from a finished trip when no trip is active).
  void _applyTripAndTodayUiForStudent({
    required int studentId,
    required bool tripActive,
    required DateTime? tripStartedLocal,
    String? busNoTrip,
    String? busFallback,
    bool isAfternoonTrip = false,
    bool childAfternoonDroppedOff = false,
  }) {
    final raw = _todayScanByStudent[studentId];
    final rawIn = raw == 'IN';
    final rawAbsent = raw == 'ABSENT';

    bool? displayPresent;
    String label;
    if (rawAbsent) {
      displayPresent = false;
      label = 'Absent';
    } else if (rawIn) {
      displayPresent = true;
      label = tripActive ? 'Present' : 'Boarded';
    } else {
      displayPresent = null;
      label = 'Not scanned yet';
    }

    if (!mounted) return;
    setState(() {
      _tripActiveByStudent[studentId] = tripActive;
      _tripStartedLocalByStudent[studentId] = tripStartedLocal;
      _isAfternoonTripByStudent[studentId] = isAfternoonTrip;
      _childAfternoonDroppedByStudent[studentId] = childAfternoonDroppedOff;
      if (busNoTrip != null && busNoTrip.isNotEmpty) {
        _busNumberByStudent[studentId] = busNoTrip;
      } else if (busFallback != null && busFallback.isNotEmpty) {
        _busNumberByStudent[studentId] = busFallback;
      }
      // Legacy single-card + attendance card: mirror primary student only.
      if (_studentId == studentId) {
        _tripActive = tripActive;
        _todayPresent = displayPresent;
        _todayAttendanceLabel = label;
        _boardedTimeText = _tripStartTimeLabel(tripActive, tripStartedLocal);
        _isAfternoonTrip = isAfternoonTrip;
        _childAfternoonDroppedOff = childAfternoonDroppedOff;
        _todayLatestScanType = raw;
        final bn = _busNumberByStudent[studentId];
        _busNumber = (bn == null || bn.isEmpty) ? '--' : bn;
      }
    });
  }

  /// Line under Bus # below "Boarded Bus" (depends on Morning vs Afternoon trip).
  String _rideStatusLine() {
    if (!_tripActive) return '';
    if (_isAfternoonTrip) {
      if (_childAfternoonDroppedOff) return 'Arrived home';
      if (_todayPresent == true) return 'On the way home';
      return 'On the way';
    }
    if (_todayPresent == true) return 'On the way to school';
    return 'On the way';
  }

  String _rideStatusLineForStudent(int sid, bool? todayPresent) {
    final tripActive = _tripActiveByStudent[sid] ?? false;
    if (!tripActive) return '';
    final isAfternoon = _isAfternoonTripByStudent[sid] ?? false;
    if (isAfternoon) {
      if (_childAfternoonDroppedByStudent[sid] == true) return 'Arrived home';
      if (todayPresent == true) return 'On the way home';
      return 'On the way';
    }
    if (todayPresent == true) return 'On the way to school';
    return 'On the way';
  }

  String _boardedTimeForStudent(int sid) {
    final tripActive = _tripActiveByStudent[sid] ?? false;
    final started = _tripStartedLocalByStudent[sid];
    return _tripStartTimeLabel(tripActive, started);
  }

  /// Time next to "Boarded Bus": supervisor trip start only (not student scan time).
  String _tripStartTimeLabel(bool tripActive, DateTime? tripStartedLocal) {
    if (tripActive && tripStartedLocal != null) {
      return _formatTime(tripStartedLocal);
    }
    return '—';
  }

  String _formatYmd(DateTime d) {
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  /// Prefer lowest student id so the bottom bar matches a stable default.
  int? _defaultTrackStudentId() {
    if (_students.isEmpty) return _studentId;
    int? best;
    for (final s in _students) {
      final id = s['id'] ?? s['Id'];
      if (id is! num) continue;
      final v = id.toInt();
      if (v <= 0) continue;
      if (best == null || v < best) best = v;
    }
    return best ?? _studentId;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    final hh = ((h + 11) % 12) + 1;
    return '$hh:$m $ampm';
  }

  DateTime _mondayOfWeek(DateTime d) {
    final delta = d.weekday - DateTime.monday;
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: delta));
  }

  Future<void> _loadAttendanceSummary() async {
    final sid = _studentId;
    if (sid == null || sid <= 0) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = _mondayOfWeek(today);
    final friday = monday.add(const Duration(days: 4));
    final todayKey = _formatYmd(today);

    try {
      final week = await ServiceLocator.parentService.getAttendance(
        studentId: sid,
        fromDate: _formatYmd(monday.subtract(const Duration(days: 1))),
        toDate: _formatYmd(friday.add(const Duration(days: 1))),
      );
      final latestByDay = <String, ({DateTime ts, String type})>{};
      for (final a in week) {
        final scanType = _normalizeScanType(a['scanType'] ?? a['ScanType']);
        if (scanType != 'IN' && scanType != 'ABSENT') continue;
        final ts = (a['timestamp'] ?? a['Timestamp'])?.toString();
        final local = _parseApiTimestampToLocal(ts);
        if (local == null) continue;
        final day = DateTime(local.year, local.month, local.day);
        if (day.isBefore(monday) || day.isAfter(friday)) continue;
        if (day.weekday < DateTime.monday || day.weekday > DateTime.friday) {
          continue;
        }
        final key = _formatYmd(day);
        final prev = latestByDay[key];
        if (prev == null || local.isAfter(prev.ts)) {
          latestByDay[key] = (ts: local, type: scanType);
        }
      }

      final todayRec = latestByDay[todayKey];
      final latestType =
          (today.weekday >= DateTime.monday && today.weekday <= DateTime.friday)
              ? todayRec?.type
              : null;

      var presentDays = 0;
      for (var d = monday;
          !d.isAfter(friday);
          d = d.add(const Duration(days: 1))) {
        final key = _formatYmd(d);
        final v = latestByDay[key];
        if (v == null) continue;
        if (v.type == 'IN') {
          presentDays++;
        }
      }

      if (!mounted) return;
      setState(() {
        _todayLatestScanType = latestType;
        _weekPresentDays = presentDays;
      });
    } catch (_) {}
  }

  Future<void> _loadAttendanceForAllStudents(
    List<Map<String, dynamic>> students,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = _mondayOfWeek(today);
    final friday = monday.add(const Duration(days: 4));
    final todayKey = _formatYmd(today);

    final scanByStudent = <int, String?>{};
    final scanTimeByStudent = <int, String?>{};
    final weekByStudent = <int, int>{};

    final rows = await Future.wait(
      students.map((s) async {
        final sidRaw = s['id'] ?? s['Id'];
        if (sidRaw is! num) return null;
        final sid = sidRaw.toInt();
        try {
          final week = await ServiceLocator.parentService.getAttendance(
            studentId: sid,
            fromDate: _formatYmd(monday.subtract(const Duration(days: 1))),
            toDate: _formatYmd(friday.add(const Duration(days: 1))),
          );
          final latestByDay = <String, ({DateTime ts, String type})>{};
          for (final a in week) {
            final scanType = _normalizeScanType(a['scanType'] ?? a['ScanType']);
            if (scanType != 'IN' && scanType != 'ABSENT') continue;
            final ts = (a['timestamp'] ?? a['Timestamp'])?.toString();
            final local = _parseApiTimestampToLocal(ts);
            if (local == null) continue;
            final day = DateTime(local.year, local.month, local.day);
            if (day.isBefore(monday) || day.isAfter(friday)) continue;
            if (day.weekday < DateTime.monday || day.weekday > DateTime.friday) {
              continue;
            }
            final key = _formatYmd(day);
            final prev = latestByDay[key];
            if (prev == null || local.isAfter(prev.ts)) {
              latestByDay[key] = (ts: local, type: scanType);
            }
          }
          final todayRec = latestByDay[todayKey];
          var presentDays = 0;
          for (var d = monday;
              !d.isAfter(friday);
              d = d.add(const Duration(days: 1))) {
            final key = _formatYmd(d);
            final v = latestByDay[key];
            if (v?.type == 'IN') presentDays++;
          }
          return (
            sid: sid,
            scan: todayRec?.type,
            scanTime: todayRec != null ? _formatTime(todayRec.ts) : null,
            week: presentDays,
          );
        } catch (_) {
          return null;
        }
      }),
    );

    for (final row in rows) {
      if (row == null) continue;
      final sid = row.sid;
      final prevScan = _todayScanByStudent[sid];
      final optimisticAt = _optimisticScanAtByStudent[sid];
      var scan = row.scan;
      if (scan == null && prevScan == 'IN') {
        final keepOptimistic = optimisticAt != null &&
            DateTime.now().difference(optimisticAt) <
                const Duration(seconds: 120);
        if (keepOptimistic) scan = 'IN';
      } else if (scan == 'IN') {
        _optimisticScanAtByStudent.remove(sid);
      }

      scanByStudent[sid] = scan;
      scanTimeByStudent[sid] = row.scanTime ?? _todayScanTimeByStudent[sid];
      var week = row.week;
      if (scan == 'IN' && week == 0) {
        week = math.max(_weekPresentByStudent[sid] ?? 0, 1);
      }
      weekByStudent[sid] = week;
    }

    if (!mounted) return;
    setState(() {
      for (final e in scanByStudent.entries) {
        _todayScanByStudent[e.key] = e.value;
      }
      for (final e in scanTimeByStudent.entries) {
        _todayScanTimeByStudent[e.key] = e.value;
      }
      for (final e in weekByStudent.entries) {
        _weekPresentByStudent[e.key] = e.value;
      }
    });
  }

  @override
  void dispose() {
    _liveUpdatesSub?.cancel();
    _stopHomePolling();
    WidgetsBinding.instance.removeObserver(this);
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    const horizontalInset = 15.0;
    final cardW = math.min(360.0, screenW - horizontalInset * 2);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: context.appScaffoldBackground,
      body: SafeArea(
        bottom: false,
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sticky header
            buildHeader(),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 8 + bottomInset),
                child: FadeTransition(
                  opacity: _entranceFade,
                  child: SlideTransition(
                    position: _entranceSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 28),
                        buildGreeting(context),
                        const SizedBox(height: 25),
                        ..._buildStudentCards(context, cardW),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Sticky bottom nav
            ParentBottomNavBar(
              activeTab: ParentNavTab.home,
              onHomeTap: () {},
              onTrackBusTap: () {
                final sid = _defaultTrackStudentId();
                String? trackName;
                for (final m in _students) {
                  final id = m['id'] ?? m['Id'];
                  if (id is num && id.toInt() == sid) {
                    trackName = (m['name'] ?? m['Name'])?.toString();
                    break;
                  }
                }
                Navigator.of(context).push(
                  fadeRoute(
                    ParentTrackBusScreen(
                      studentId: sid,
                      studentName: trackName ?? _studentName,
                      studentPhotoUrl: _studentPhotoUrl,
                    ),
                  ),
                );
              },
              onProfileTap: () {
                Navigator.of(context).push(fadeRoute(const ParentProfileScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStudentCards(BuildContext context, double cardW) {
    if (_students.isEmpty) {
      return [buildStudentCard(context, cardW)];
    }
    return _students.map((student) {
      final sidRaw = student['id'] ?? student['Id'];
      final sid = sidRaw is num ? sidRaw.toInt() : null;
      final name =
          (student['name'] ?? student['Name'])?.toString() ?? _studentName;
      final grade =
          (student['grade'] ?? student['Grade'])?.toString() ?? _studentGrade;
      final photo = _readPhotoUrl(student);
      final today = sid == null ? null : _todayScanByStudent[sid];
      final tripA = sid == null ? false : (_tripActiveByStudent[sid] ?? false);
      final rawIn = today == 'IN';
      final bool? present;
      final String label;
      if (today == 'ABSENT') {
        present = false;
        label = 'Absent';
      } else if (rawIn) {
        present = true;
        label = tripA ? 'Present' : 'Boarded';
      } else {
        present = null;
        label = 'Not scanned yet';
      }
      final week = sid == null ? 0 : (_weekPresentByStudent[sid] ?? 0);
      final scanTime = sid == null ? null : _todayScanTimeByStudent[sid];
      final studentBusNumber = sid == null
          ? '--'
          : (_busNumberByStudent[sid] ?? '--');

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildStudentCardItem(
          context: context,
          cardW: cardW,
          studentId: sid,
          studentName: name,
          studentGrade: grade,
          studentPhotoUrl: photo,
          todayLabel: label,
          todayPresent: present,
          weekPresentDays: week,
          todayScanTimeText: scanTime ?? '—',
          busNumber: studentBusNumber,
          tripActive: tripA,
          boardedTimeText: sid == null ? _boardedTimeText : _boardedTimeForStudent(sid),
          rideStatusLine: sid == null
              ? _rideStatusLine()
              : _rideStatusLineForStudent(sid, present),
        ),
      );
    }).toList();
  }

  Widget _buildStudentCardItem({
    required BuildContext context,
    required double cardW,
    required int? studentId,
    required String studentName,
    required String studentGrade,
    required String? studentPhotoUrl,
    required String todayLabel,
    required bool? todayPresent,
    required int weekPresentDays,
    required String todayScanTimeText,
    required String busNumber,
    required bool tripActive,
    required String boardedTimeText,
    required String rideStatusLine,
  }) {
    return Center(
      child: Container(
        width: cardW,
        constraints: const BoxConstraints(minHeight: 329),
        decoration: BoxDecoration(
          color: context.appPanelBackground,
          borderRadius: BorderRadius.circular(15),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 22, top: 11),
              color: AppColors.studentCardHeaderBar,
              alignment: Alignment.centerLeft,
              child: Text(
                'Student',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: context.appPrimaryText,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: _StudentAvatar(
                          photoUrl: studentPhotoUrl,
                          size: const Size(66, 64),
                        ),
                      ),
                      const SizedBox(width: 25),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName.isEmpty ? '—' : studentName,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: context.appPrimaryText,
                              ),
                            ),
                            Text(
                              studentGrade.isEmpty ? '—' : studentGrade,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: context.appSecondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 26,
                        child: Icon(
                          FluentIcons.vehicle_bus_20_filled,
                          size: 26,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(width: 21),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                'Boarded Bus',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gray333,
                                ),
                              ),
                            ),
                            Image.asset(
                              AppImages.parentHomeCheckParent,
                              width: 27,
                              height: 27,
                              fit: BoxFit.contain,
                              color: tripActive && todayPresent == true
                                  ? null
                                  : Colors.transparent,
                            ),
                            const SizedBox(width: 8),
                            if (tripActive)
                              Text(
                                boardedTimeText,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.grayText,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 47, top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (busNumber.isEmpty || busNumber == '--')
                              ? 'Not attached on a bus'
                              : 'Bus #$busNumber',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBlack,
                          ),
                        ),
                        if (tripActive && rideStatusLine.isNotEmpty)
                          Text(
                            rideStatusLine,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.greenStatusBright,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.scale(
                        scaleX: -1,
                        child: const SizedBox(
                          width: 26,
                          child: Icon(
                            FluentIcons.data_bar_vertical_20_filled,
                            size: 20,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 21),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        'Today: ',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: context.appPrimaryText,
                                        ),
                                      ),
                                      Text(
                                        todayLabel,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: todayPresent == true
                                              ? AppColors.greenStatusBright
                                              : (todayPresent == false
                                                  ? const Color(0xFFC62828)
                                                  : context.appSecondaryText),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (todayPresent == true)
                                  Text(
                                    todayScanTimeText,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.grayText,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'This week: $weekPresentDays/5',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: context.appSecondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: _TrackBusButton(
                      enabled: tripActive && studentId != null,
                      onPressed: () {
                        Navigator.of(context).push(
                          fadeRoute(
                            ParentTrackBusScreen(
                              studentId: studentId,
                              studentName: studentName,
                              studentPhotoUrl: studentPhotoUrl,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  /// Header: h 139, primary blue, bottom radius 22, centered brand logo.
  Widget buildHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
      child: SizedBox(
        height: 105,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 139,
              color: AppColors.primaryBlue,
            ),
            Positioned.fill(
              child: Center(
                child: Image.asset(
                  AppImages.parentHomeLogo,
                  width: 126,
                  height: 126,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Greeting + subtitle; profile image beside the name.
  Widget buildGreeting(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _parentName.isEmpty ? 'Hello' : 'Hello , $_parentName',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: context.appPrimaryText,
                ),
              ),
              const SizedBox(width: 10),
              const _ParentGreetingIcon(),
            ],
          ),
          Text(
            "Track your child's bus",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: context.appSecondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStudentCard(BuildContext context, double cardW) {
    if (_students.isEmpty) {
      return Center(
        child: Container(
          width: cardW,
          constraints: const BoxConstraints(minHeight: 220),
          decoration: BoxDecoration(
            color: context.appPanelBackground,
            borderRadius: BorderRadius.circular(15),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.only(left: 22, top: 11),
                color: AppColors.studentCardHeaderBar,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Student',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: context.appPrimaryText,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Text(
                  'No student linked yet',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.appSecondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sid = _studentId;
    final tripA = sid != null ? (_tripActiveByStudent[sid] ?? false) : _tripActive;
    final today = sid == null ? _todayLatestScanType : _todayScanByStudent[sid];
    final rawIn = today == 'IN';
    final bool? todayPresent;
    if (today == 'ABSENT') {
      todayPresent = false;
    } else if (rawIn) {
      todayPresent = true;
    } else {
      todayPresent = null;
    }
    final busNo = sid == null
        ? _busNumber
        : (_busNumberByStudent[sid] ?? '--');
    final boardedTime =
        sid == null ? _boardedTimeText : _boardedTimeForStudent(sid);
    final rideLine = sid == null
        ? _rideStatusLine()
        : _rideStatusLineForStudent(sid, todayPresent);

    return Center(
      child: Container(
        width: cardW,
        constraints: const BoxConstraints(minHeight: 329),
        decoration: BoxDecoration(
          color: context.appPanelBackground,
          borderRadius: BorderRadius.circular(15),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 22, top: 11),
              color: AppColors.studentCardHeaderBar,
              alignment: Alignment.centerLeft,
              child: Text(
                'Student',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: context.appPrimaryText,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: _StudentAvatar(
                          photoUrl: _studentPhotoUrl,
                          size: const Size(66, 64),
                        ),
                      ),
                      const SizedBox(width: 25),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _studentName.isEmpty ? '—' : _studentName,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                // height: 22 / 20,
                                color: context.appPrimaryText,
                              ),
                            ),
                            Text(
                              _studentGrade.isEmpty ? '—' : _studentGrade,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                // height: 22 / 16,
                                color: context.appSecondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        FluentIcons.vehicle_bus_20_filled,
                        size: 26,
                        color: Color(0xFF1E3A8A),
                      ),
                      const SizedBox(width: 21),
                      Expanded(
                        child: Text(
                          'Boarded Bus',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            // height: 22 / 16,
                            color: AppColors.gray333,
                          ),
                        ),
                      ),
                      Image.asset(
                        AppImages.parentHomeCheckParent,
                        width: 27,
                        height: 27,
                        fit: BoxFit.contain,
                        color: tripA && todayPresent == true
                            ? null
                            : Colors.transparent,
                      ),
                      const SizedBox(width: 8),
                      if (tripA)
                        Text(
                          boardedTime,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grayText,
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 47, top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (busNo.isEmpty || busNo == '--')
                              ? 'Not attached on a bus'
                              : 'Bus #$busNo',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            // height: 22 / 16,
                            color: AppColors.textBlack,
                          ),
                        ),
                        if (tripA && rideLine.isNotEmpty)
                          Text(
                            rideLine,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.greenStatusBright,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: _TrackBusButton(
                      enabled: tripA && sid != null,
                      onPressed: () {
                        Navigator.of(context).push(
                          fadeRoute(
                            ParentTrackBusScreen(
                              studentId: sid,
                              studentName: _studentName,
                              studentPhotoUrl: _studentPhotoUrl,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Attendance card: min height 132, radius 15 — content sizes intrinsically to avoid overflow.
  Widget buildAttendanceCard(BuildContext context, double cardW) {
    return Center(
      child: Container(
        width: cardW,
        constraints: const BoxConstraints(minHeight: 132),
        decoration: BoxDecoration(
          color: context.appPanelBackground,
          borderRadius: BorderRadius.circular(15),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 49,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              color: AppColors.studentCardHeaderBar,
              child: Row(
                children: [
                  Transform.scale(
                    scaleX: -1,
                    child: Icon(
                      FluentIcons.data_bar_vertical_20_filled,
                      size: 26,
                      color: Color(0xFF2F80ED),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Attendance',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 22 / 20,
                      color: context.appPrimaryText,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Today: ',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 22 / 16,
                          color: context.appPrimaryText,
                        ),
                      ),
                      Text(
                        _todayAttendanceLabel,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 22 / 16,
                          color: _todayPresent == true
                              ? AppColors.greenStatusBright
                              : (_todayPresent == false
                                  ? const Color(0xFFC62828)
                                  : context.appSecondaryText),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_todayPresent == true)
                        Image.asset(
                          AppImages.parentHomeCheckParent,
                          width: 27,
                          height: 27,
                          fit: BoxFit.contain,
                        )
                      else if (_todayPresent == false)
                        const Icon(Icons.cancel, color: Colors.red, size: 24),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This week: $_weekPresentDays/5',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 22 / 16,
                      color: context.appSecondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Track Bus CTA: gradient, press scale animation.
class _TrackBusButton extends StatefulWidget {
  const _TrackBusButton({required this.onPressed, this.enabled = true});

  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<_TrackBusButton> createState() => _TrackBusButtonState();
}

class _TrackBusButtonState extends State<_TrackBusButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _press, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _ParentHomeLayout.trackBusButtonScale;
    final btnW = _ParentHomeLayout.trackBusButtonWidth * s;
    final btnH = _ParentHomeLayout.trackBusButtonHeight * s;
    final padH = _ParentHomeLayout._trackBusBtnPadH * s;
    final fontSize = _ParentHomeLayout._trackBusBtnFont * s;
    final arrowSize = _ParentHomeLayout.trackBusBackArrowSize * s;
    final arrowGap = _ParentHomeLayout.trackBusBackArrowGap * s;

    return IgnorePointer(
      ignoring: !widget.enabled,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.45,
        child: Listener(
          onPointerDown: (_) => _press.forward(),
          onPointerUp: (_) {
            _press.reverse();
            if (widget.enabled) widget.onPressed();
          },
          onPointerCancel: (_) => _press.reverse(),
          child: ScaleTransition(
            scale: _scale,
            child: SizedBox(
          width: btnW,
          height: btnH,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: AppColors.primaryButtonGradient,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padH),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_ParentHomeLayout.showTrackBusBackArrow &&
                      !_ParentHomeLayout.trackBusBackArrowAfterLabel) ...[
                    Icon(
                      Icons.arrow_back_ios_new,
                      size: arrowSize,
                      color: AppColors.white,
                    ),
                    SizedBox(width: arrowGap),
                  ],
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Text(
                          'Track Bus',
                          style: GoogleFonts.inter(
                            color: AppColors.white,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_ParentHomeLayout.showTrackBusBackArrow &&
                      _ParentHomeLayout.trackBusBackArrowAfterLabel) ...[
                    SizedBox(width: arrowGap),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: arrowSize,
                      color: AppColors.white,
                    ),
                  ],
                ],
              ),
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParentGreetingIcon extends StatelessWidget {
  const _ParentGreetingIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppImages.parentPerson,
      width: 37,
      height: 29,
      fit: BoxFit.contain,
    );
  }
}

class _StudentAvatar extends StatelessWidget {
  const _StudentAvatar({required this.photoUrl, required this.size});

  final String? photoUrl;
  final Size size;

  Widget _fallbackAvatar() {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person,
        color: Color(0xFF6B7280),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = supervisorPhotoResolvedUrls(photoUrl);
    final fallback = _fallbackAvatar();
    if (urls.isNotEmpty) {
      return ResilientNetworkImage(
        urls: urls,
        width: size.width,
        height: size.height,
        fit: BoxFit.cover,
        fallback: fallback,
      );
    }
    return fallback;
  }
}
