import 'dart:async';
import 'dart:math' as math;

import 'package:application/constants/app_colors.dart';
import 'package:application/constants/app_images.dart';
import 'package:application/helpers/app_theme.dart';
import 'package:application/helpers/supervisor_photo.dart';
import 'package:application/routes/fade_route.dart';
import 'package:application/widgets/parent/parent_bottom_nav_bar.dart';
import 'package:application/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';



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
  bool _boarded = false;
  bool _tripActive = false;
  String? _studentPhotoUrl;

  /// Latest scan for **today** from API: `IN`, `ABSENT`, or null (drives week `x/5` + raw state).
  String? _todayLatestScanType;

  Timer? _homePollTimer;

  static const Duration _homePollInterval = Duration(seconds: 5);

  bool _isAfternoonTrip = false;

  /// True when afternoon trip completed OUT at home for the linked student (server flag).
  bool _childAfternoonDroppedOff = false;

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

  static String? _readPhotoUrl(Map<String, dynamic> m) {
    for (final k in [
      'photoUrl',
      'photo_url',
      'PhotoUrl',
    ]) {
      final s = m[k]?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return null;
  }

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

  /// TripStatus.NotStarted = 0, Started = 1 (System.Text.Json default for enums).
  static bool _tripLooksStarted(Map<String, dynamic>? trip) {
    if (trip == null) return false;
    final st = trip['status'] ?? trip['Status'];
    if (st == null) return true;
    if (st is num) return st.toInt() == 1;
    final s = st.toString().toLowerCase();
    return s == '1' || s == 'started';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _studentPhotoUrl = ServiceLocator.tokenStorage.getStudentPhotoUrl();
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
    _loadParentOverview();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadParentOverview());
    } else if (state == AppLifecycleState.paused) {
      _stopHomePolling();
    }
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
    String? busFromOverview;
    try {
      final data = await ServiceLocator.parentService.getChildOverview();
      final parent =
          (data['parent'] ?? data['Parent']) as Map<String, dynamic>?;
      final busMap = data['bus'] as Map<String, dynamic>?;
      if (busMap != null) {
        final bn =
            busMap['busNumber'] ?? busMap['BusNumber'] ?? busMap['bus_number'];
        if (bn != null && bn.toString().trim().isNotEmpty) {
          busFromOverview = bn.toString().trim();
        }
      }
      final students =
          ((data['students'] ?? data['Students']) as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      setState(() {
        if (busFromOverview != null) {
          _busNumber = busFromOverview;
        }
        if (parent != null) {
          final name = (parent['name'] ?? parent['Name'])?.toString();
          if (name != null && name.isNotEmpty) {
            _parentName = name;
          }
        }
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
          if (sPhoto != null && sPhoto.trim().isNotEmpty) {
            _studentPhotoUrl = sPhoto.trim();
            unawaited(ServiceLocator.tokenStorage.saveStudentPhotoUrl(_studentPhotoUrl));
          }
        }
      });
    } catch (_) {}

    await _refreshTripAttendanceState(busFallback: busFromOverview);
    if (mounted && _studentId != null && _studentId! > 0) {
      _startHomePolling();
    }
  }

  void _startHomePolling() {
    _homePollTimer?.cancel();
    _homePollTimer = Timer.periodic(_homePollInterval, (_) {
      if (!mounted) return;
      unawaited(_refreshTripAttendanceState());
    });
  }

  void _stopHomePolling() {
    _homePollTimer?.cancel();
    _homePollTimer = null;
  }

  /// Refetches active trip + attendance so supervisor scans show up without leaving the screen.
  Future<void> _refreshTripAttendanceState({String? busFallback}) async {
    final sid = _studentId;
    if (sid == null || sid <= 0) return;

    var tripActive = false;
    DateTime? tripStartedLocal;
    String? busNoTrip;
    var isAfternoonTrip = false;
    var childAfternoonDroppedOff = false;
    try {
      final current = await ServiceLocator.parentService.getCurrentTrip();
      final trip = current['trip'] as Map<String, dynamic>?;
      tripStartedLocal = _parseTripStartedLocal(trip);
      final tripLooksStarted = trip != null ? _tripLooksStarted(trip) : false;
      isAfternoonTrip = _tripTypeIsAfternoon(trip);
      final bus = current['bus'] as Map<String, dynamic>?;
      if (bus != null) {
        final bn =
            bus['busNumber'] ?? bus['BusNumber'] ?? bus['bus_number'];
        if (bn != null && bn.toString().trim().isNotEmpty) {
          busNoTrip = bn.toString().trim();
        }
      }

      if (!mounted) return;

      tripActive = (current['has_active_trip'] == true ||
              current['hasActiveTrip'] == true) &&
          trip != null &&
          tripLooksStarted;
      if (isAfternoonTrip) {
        childAfternoonDroppedOff =
            current['child_afternoon_dropped_off'] == true ||
                current['childAfternoonDroppedOff'] == true;
      }
    } catch (_) {
      tripActive = false;
      isAfternoonTrip = false;
      childAfternoonDroppedOff = false;
    }

    await _loadAttendanceSummary();

    if (!mounted) return;
    _applyTripAndTodayUi(
      tripActive: tripActive,
      tripStartedLocal: tripStartedLocal,
      busNoTrip: busNoTrip,
      busFallback: busFallback,
      isAfternoonTrip: isAfternoonTrip,
      childAfternoonDroppedOff: childAfternoonDroppedOff,
    );
  }

  static bool _tripTypeIsAfternoon(Map<String, dynamic>? trip) {
    if (trip == null) return false;
    final t =
        (trip['tripType'] ?? trip['TripType'] ?? '').toString().toLowerCase();
    return t.contains('afternoon');
  }

  /// Present only while a trip is active and today's latest scan is IN; absent if marked ABSENT;
  /// otherwise "Not scanned yet" (including IN from a finished trip when no trip is active).
  void _applyTripAndTodayUi({
    required bool tripActive,
    required DateTime? tripStartedLocal,
    String? busNoTrip,
    String? busFallback,
    bool isAfternoonTrip = false,
    bool childAfternoonDroppedOff = false,
  }) {
    final raw = _todayLatestScanType;
    final rawIn = raw == 'IN';
    final rawAbsent = raw == 'ABSENT';

    bool? displayPresent;
    String label;
    if (rawAbsent) {
      displayPresent = false;
      label = 'Absent';
    } else if (rawIn && tripActive) {
      displayPresent = true;
      label = 'Present';
    } else {
      displayPresent = null;
      label = 'Not scanned yet';
    }

    if (!mounted) return;
    setState(() {
      _tripActive = tripActive;
      _todayPresent = displayPresent;
      _todayAttendanceLabel = label;
      _boarded = tripActive && rawIn;
      _boardedTimeText = _tripStartTimeLabel(tripActive, tripStartedLocal);
      _isAfternoonTrip = isAfternoonTrip;
      _childAfternoonDroppedOff = childAfternoonDroppedOff;
      if (busNoTrip != null && busNoTrip.isNotEmpty) {
        _busNumber = busNoTrip;
      } else if (busFallback != null && busFallback.isNotEmpty) {
        _busNumber = busFallback;
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

  @override
  void dispose() {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                        buildHeader(),
                        const SizedBox(height: 28),
                        buildGreeting(context),
                        const SizedBox(height: 25),
                        buildStudentCard(context, cardW),
                        const SizedBox(height: 20),
                        buildAttendanceCard(context, cardW),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ParentBottomNavBar(
              activeTab: ParentNavTab.home,
              onHomeTap: () {},
              onTrackBusTap: () {
                Navigator.of(
                  context,
                ).push(fadeRoute(const ParentTrackBusScreen()));
              },
              onProfileTap: () {
                Navigator.of(
                  context,
                ).push(fadeRoute(const ParentProfileScreen()));
              },
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
        bottomLeft: Radius.circular(22),
        bottomRight: Radius.circular(22),
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
                        child: _StudentAvatar(photoUrl: _studentPhotoUrl, size: const Size(66, 64)),
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
                        color: _boarded ? null : Colors.transparent,
                      ),
                      const SizedBox(width: 8),
                      if (_tripActive)
                        Text(
                          _boardedTimeText,
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
                          (_busNumber.isEmpty || _busNumber == '--')
                              ? 'Bus'
                              : 'Bus #$_busNumber',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            // height: 22 / 16,
                            color: AppColors.textBlack,
                          ),
                        ),
                        if (_tripActive)
                          Text(
                            _rideStatusLine(),
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
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).push(fadeRoute(const ParentTrackBusScreen()));
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
  const _TrackBusButton({required this.onPressed});

  final VoidCallback onPressed;

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

    return Listener(
      onPointerDown: (_) => _press.forward(),
      onPointerUp: (_) {
        _press.reverse();
        widget.onPressed();
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

  @override
  Widget build(BuildContext context) {
    final full = supervisorPhotoFullUrl(photoUrl);
    if (full != null && full.isNotEmpty) {
      return Image.network(
        full,
        width: size.width,
        height: size.height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          AppImages.parentHomeStudentAvatar,
          width: size.width,
          height: size.height,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      AppImages.parentHomeStudentAvatar,
      width: size.width,
      height: size.height,
      fit: BoxFit.cover,
    );
  }
}
