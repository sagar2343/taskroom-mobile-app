// lib/features/task/view/widgets/task_location_map_sheet.dart
//
//  Key fixes in this version:
//  1. CRASH FIX — Replaced Completer<GoogleMapController> with a nullable
//     GoogleMapController? field. On tab switch the old controller is disposed
//     and the new onMapCreated callback stores the fresh one. Every call to
//     _fitMap / animateCamera is guarded with a mounted + null check.
//  2. SIMULTANEOUS ANIMATION — polyline trail and employee marker now update
//     in the same setState call so they move together.
//  3. REFRESH BUTTON — history panel has a refresh icon that reloads the trace.
//  4. SMOOTH TAB SWITCH — _switchTab disposes WS, nulls the map controller,
//     then awaits _load() so data is fetched before the map tries to fit.

import 'dart:ui' as ui;

import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/location_tracking/service/manager_location_controller.dart';
import 'package:field_work/features/task/controller/manager_task_detail_controller.dart';
import 'package:field_work/features/task/model/task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Step colours
// _____________________________________________________________________________

const _kStepColors = [
  Color(0xFFF59E0B),
  Color(0xFF6366F1),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFFEF4444),
];
Color _stepColor(int i) => _kStepColors[i % _kStepColors.length];

// ─────────────────────────────────────────────────────────────────────────────
//  Smooth LatLng animator
// _____________________________________________________________________________

class _LatLngTween {
  final LatLng from, to;
  _LatLngTween(this.from, this.to);
  LatLng lerp(double t) {
    t = t.clamp(0.0, 1.0);
    return LatLng(
      from.latitude  + (to.latitude  - from.latitude)  * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
  }
}

class _MarkerAnimator {
  final TickerProvider vsync;
  final void Function(LatLng) onUpdate;

  Ticker?        _ticker;
  _LatLngTween?  _tween;
  Duration       _elapsed = Duration.zero;
  final Duration _dur     = const Duration(milliseconds: 800);
  LatLng?        _current;

  _MarkerAnimator({required this.vsync, required this.onUpdate});

  void animateTo(LatLng target) {
    if (_current == null) { _current = target; onUpdate(target); return; }
    if (_current == target) return;
    _tween   = _LatLngTween(_current!, target);
    _elapsed = Duration.zero;
    _ticker?.stop(); _ticker?.dispose();
    _ticker  = vsync.createTicker((e) {
      _elapsed = e;
      final t  = (_elapsed.inMilliseconds / _dur.inMilliseconds).clamp(0.0, 1.0);
      _current = _tween!.lerp(t);
      onUpdate(_current!);
      if (t >= 1.0) _ticker?.stop();
    })..start();
  }

  LatLng? get current => _current;
  void dispose() { _ticker?.stop(); _ticker?.dispose(); }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bitmap builders
// _____________________________________________________________________________

Future<BitmapDescriptor> _buildNumberedPin({
  required int number, required Color color, required bool isActive,
}) async {
  const sz = 108.0, cx = sz / 2;
  final pinH = isActive ? 90.0 : 80.0;
  final pinW = isActive ? 58.0 : 50.0;
  final r = pinW / 2, top = (sz - pinH) / 2;

  final rec = ui.PictureRecorder();
  final cvs = Canvas(rec, Rect.fromLTWH(0, 0, sz, sz));

  cvs.drawOval(
    Rect.fromCenter(center: Offset(cx, pinH + 5), width: pinW * .65, height: 7),
    Paint()..color = Colors.black.withValues(alpha: .22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );
  final body = Path()
    ..addOval(Rect.fromCircle(center: Offset(cx, top + r), radius: r))
    ..moveTo(cx - r * .42, top + pinW * .76)
    ..lineTo(cx, top + pinH)
    ..lineTo(cx + r * .42, top + pinW * .76)
    ..close();
  cvs.drawPath(body, Paint()..color = color);
  cvs.drawOval(
    Rect.fromCenter(center: Offset(cx - r * .18, top + r * .52),
        width: r * .85, height: r * .6),
    Paint()..color = Colors.white.withValues(alpha: .26),
  );
  cvs.drawCircle(Offset(cx, top + r), r * .55, Paint()..color = Colors.white);
  if (isActive) {
    cvs.drawCircle(Offset(cx, top + r), r + 5,
        Paint()..color = color.withValues(alpha: .3)
          ..style = PaintingStyle.stroke..strokeWidth = 4);
  }
  final tp = TextPainter(
    text: TextSpan(text: '$number',
        style: TextStyle(color: color,
            fontSize: isActive ? 22 : 19, fontWeight: FontWeight.w900)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(cvs, Offset(cx - tp.width / 2, top + r - tp.height / 2));

  final img   = await rec.endRecording().toImage(sz.toInt(), sz.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}

Future<BitmapDescriptor> _buildEmployeeMarker() async {
  const sz = 100.0, cx = sz / 2, cy = sz / 2;
  final rec = ui.PictureRecorder();
  final cvs = Canvas(rec, Rect.fromLTWH(0, 0, sz, sz));
  cvs.drawCircle(const Offset(cx, cy), 42,
      Paint()..color = const Color(0xFF22C55E).withValues(alpha: .12));
  cvs.drawCircle(const Offset(cx, cy), 30,
      Paint()..color = const Color(0xFF22C55E).withValues(alpha: .25));
  cvs.drawCircle(const Offset(cx, cy + 2), 18,
      Paint()..color = Colors.black.withValues(alpha: .2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
  cvs.drawCircle(const Offset(cx, cy), 18,
      Paint()..color = const Color(0xFF22C55E));
  cvs.drawCircle(const Offset(cx, cy), 18,
      Paint()..color = Colors.white
        ..style = PaintingStyle.stroke..strokeWidth = 3);
  cvs.drawCircle(const Offset(cx - 5, cy - 5), 4,
      Paint()..color = Colors.white.withValues(alpha: .6));
  final img   = await rec.endRecording().toImage(sz.toInt(), sz.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}

Future<BitmapDescriptor> _buildFlagMarker({
  required String label, required Color color,
}) async {
  const sz = 90.0, cx = sz / 2;
  final rec = ui.PictureRecorder();
  final cvs = Canvas(rec, Rect.fromLTWH(0, 0, sz, sz));
  cvs.drawOval(Rect.fromCenter(center: Offset(cx, 76), width: 22, height: 8),
      Paint()..color = Colors.black.withValues(alpha: .18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  cvs.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 2.5, 14, 5, 58), const Radius.circular(2)),
      Paint()..color = color);
  cvs.drawCircle(Offset(cx, 72), 6, Paint()..color = color);
  cvs.drawPath(
    Path()..moveTo(cx + 2.5, 14)..lineTo(cx + 36, 22)
      ..lineTo(cx + 2.5, 40)..close(),
    Paint()..color = color,
  );
  final tp = TextPainter(
    text: TextSpan(text: label,
        style: const TextStyle(color: Colors.white, fontSize: 13,
            fontWeight: FontWeight.w900)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(cvs, Offset(cx + 11, 21));
  final img   = await rec.endRecording().toImage(sz.toInt(), sz.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}

// ─────────────────────────────────────────────────────────────────────────────
//  TaskLocationMapSheet
// _____________________________________________________________________________

class TaskLocationMapSheet extends StatefulWidget {
  final ManagerTaskDetailController controller;
  final bool initialLiveMode;

  const TaskLocationMapSheet({
    super.key,
    required this.controller,
    this.initialLiveMode = true,
  });

  static Future<void> show(
      BuildContext context, {
        required ManagerTaskDetailController controller,
        bool isLiveMode = true,
      }) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: false,
        builder: (_) => TaskLocationMapSheet(
          controller: controller,
          initialLiveMode: isLiveMode,
        ),
      );

  @override
  State<TaskLocationMapSheet> createState() => _TaskLocationMapSheetState();
}

class _TaskLocationMapSheetState extends State<TaskLocationMapSheet>
    with TickerProviderStateMixin {

  ManagerTaskDetailController get _c => widget.controller;

  // ── Tab ───────────────────────────────────────────────────────────────────
  late bool _isLiveMode;

  // ── Map controller ────────────────────────────────────────────────────────
  // KEY FIX: plain nullable field instead of Completer.
  // A Completer can only complete once — when the tab switches, GoogleMap
  // re-creates and fires onMapCreated with a NEW controller, but the Completer
  // still resolves to the old DISPOSED one → crash.
  // With a nullable field we simply overwrite it on every onMapCreated call.
  GoogleMapController? _mapCtrl;

  // ── WS + animation ────────────────────────────────────────────────────────
  ManagerLocationController? _wsCtrl;
  _MarkerAnimator?  _empAnimator;
  LatLng?           _animatedEmpPos;

  // ── Overlays ──────────────────────────────────────────────────────────────
  Set<Polyline> _polylines = {};
  Set<Marker>   _markers   = {};

  // ── Bitmaps ───────────────────────────────────────────────────────────────
  BitmapDescriptor? _employeeBitmap;
  BitmapDescriptor? _startFlagBitmap;
  BitmapDescriptor? _endFlagBitmap;
  final Map<int, BitmapDescriptor> _pinBitmaps = {};
  bool _bitmapsReady = false;

  // ── History refresh ───────────────────────────────────────────────────────
  bool _isRefreshing = false;

  // ── Pulse animation ───────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  static const _kGreen = Color(0xFF22C55E);
  static const _kBlue  = Color(0xFF6366F1);
  static const _kRed   = Color(0xFFEF4444);

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _isLiveMode = widget.initialLiveMode;

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: .3, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _empAnimator = _MarkerAnimator(
      vsync: this,
      onUpdate: (pos) {
        if (!mounted) return;
        _animatedEmpPos = pos;
        // FIX: rebuild polylines AND markers in ONE setState → simultaneous
        setState(() {
          _polylines = _buildPolylines();
          _markers   = _buildMarkers();
        });
      },
    );
    _buildBitmapsThenLoad();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _empAnimator?.dispose();
    _wsCtrl?.dispose();
    _safeDisposeMapCtrl();
    super.dispose();
  }

  void _safeDisposeMapCtrl() {
    final ctrl = _mapCtrl;
    _mapCtrl = null;
    try { ctrl?.dispose(); } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Tab switch
  // _________________________________________________________________________
  Future<void> _switchTab(bool toLive) async {
    if (_isLiveMode == toLive) return;

    if (_isLiveMode && !toLive) {
      _wsCtrl?.dispose();
      _wsCtrl = null;
    }

    // Null out BEFORE setState so any in-flight async reaching _safeFitMap
    // after this point finds null and bails out instead of crashing.
    _safeDisposeMapCtrl();

    setState(() {
      _isLiveMode     = toLive;
      _animatedEmpPos = null;
      _polylines      = {};
      _markers        = {};
    });

    await _load();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Refresh history
  // _________________________________________________________________________
  Future<void> _refreshHistory() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _c.loadLocationTrace();
    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
      _rebuildOverlays();
    });
    _safeFitMap();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Bitmaps then load
  // _________________________________________________________________________
  Future<void> _buildBitmapsThenLoad() async {
    final steps = _c.task?.steps ?? [];
    final activeStepId = steps
        .firstWhere(
          (s) => ['in_progress', 'travelling', 'reached'].contains(s.status),
      orElse: () => TaskStep(),
    )
        .stepId;

    final fieldEntries = steps
        .asMap()
        .entries
        .where((e) =>
    e.value.isFieldWorkStep == true &&
        e.value.destinationLocation?.coordinates != null)
        .toList();

    final results = await Future.wait([
      _buildEmployeeMarker(),
      _buildFlagMarker(label: 'S', color: _kGreen),
      _buildFlagMarker(label: 'E', color: _kRed),
      ...fieldEntries.map((e) => _buildNumberedPin(
        number:   e.key + 1,
        color:    _stepColor(e.key),
        isActive: e.value.stepId == activeStepId,
      )),
    ]);

    _employeeBitmap  = results[0];
    _startFlagBitmap = results[1];
    _endFlagBitmap   = results[2];
    for (int i = 0; i < fieldEntries.length; i++) {
      _pinBitmaps[fieldEntries[i].key] = results[3 + i];
    }

    if (!mounted) return;
    setState(() => _bitmapsReady = true);
    await _load();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Load
  // _________________________________________________________________________
  Future<void> _load() async {
    if (_isLiveMode) {
      await _c.loadLiveLocation();
      if (!mounted) return;

      final seed = _c.employeeLatLng;
      if (seed != null) {
        _animatedEmpPos = seed;
        _empAnimator!.animateTo(seed);
      }
      setState(() => _rebuildOverlays());
      _safeFitMap();

      _wsCtrl?.dispose();
      _wsCtrl = ManagerLocationController(
        taskId:     _c.taskId,
        reloadData: _onWsUpdate,
      );
      _wsCtrl!.connect();
    } else {
      await _c.loadLocationTrace();
      if (!mounted) return;
      setState(() => _rebuildOverlays());
      _safeFitMap();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  WS update — marker + polyline move simultaneously
  // _________________________________________________________________________
  void _onWsUpdate() {
    if (!mounted) return;
    final update = _wsCtrl?.latestUpdate;
    if (update != null) {
      _animatedEmpPos ??= update.latLng;
      // animateTo → onUpdate → setState rebuilds both polylines + markers
      _empAnimator!.animateTo(update.latLng);
    } else {
      setState(() => _polylines = _buildPolylines());
    }
  }

  void _rebuildOverlays() {
    _polylines = _buildPolylines();
    _markers   = _buildMarkers();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Safe camera fit
  // _________________________________________________________________________
  void _safeFitMap() {
    final ctrl = _mapCtrl;
    if (ctrl == null || !mounted) return;
    try {
      _fitMap(ctrl);
    } catch (_) {
      // Disposed between null-check and call — ignore silently.
    }
  }

  void _fitMap(GoogleMapController ctrl) {
    final pts = <LatLng>[];
    if (_isLiveMode) {
      if (_animatedEmpPos != null) pts.add(_animatedEmpPos!);
    } else {
      pts.addAll(_c.tracePoints);
    }
    for (final step in (_c.task?.steps ?? [])) {
      final coords = step.destinationLocation?.coordinates;
      if (coords != null && coords.length >= 2) {
        pts.add(LatLng(coords[1], coords[0]));
      }
    }
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      ctrl.animateCamera(CameraUpdate.newLatLngZoom(pts.first, 16));
      return;
    }
    double minLat = pts[0].latitude, maxLat = pts[0].latitude;
    double minLng = pts[0].longitude, maxLng = pts[0].longitude;
    for (final p in pts) {
      if (p.latitude  < minLat) minLat = p.latitude;
      if (p.latitude  > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    ctrl.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat - .001, minLng - .001),
        northeast: LatLng(maxLat + .001, maxLng + .001),
      ),
      80,
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Polylines
  // _________________________________________________________________________
  Set<Polyline> _buildPolylines() {
    final lines = <Polyline>{};
    if (!_isLiveMode && _c.tracePoints.length >= 2) {
      lines.add(Polyline(
        polylineId: const PolylineId('trace'),
        points:     _c.tracePoints,
        color:      _kBlue,
        width:      5,
        jointType:  JointType.round,
        endCap:     Cap.roundCap,
        startCap:   Cap.roundCap,
      ));
    }
    if (_isLiveMode) {
      final trail = _wsCtrl?.liveTrail ?? [];
      if (trail.length >= 2) {
        lines.add(Polyline(
          polylineId: const PolylineId('live_trail'),
          points:     trail,
          color:      _kGreen.withValues(alpha: .5),
          width:      4,
          jointType:  JointType.round,
          endCap:     Cap.roundCap,
          startCap:   Cap.roundCap,
        ));
      }
    }
    return lines;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Markers
  // _________________________________________________________________________
  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    final steps   = _c.task?.steps ?? [];

    if (_isLiveMode) {
      final pos = _animatedEmpPos ?? _c.employeeLatLng;
      if (pos != null) {
        final empName =
            (_c.liveLocationData?['employee']?['fullName'] as String?) ??
                'Employee';
        markers.add(Marker(
          markerId:   const MarkerId('employee'),
          position:   pos,
          icon:       _employeeBitmap ??
              BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
          anchor:     const Offset(.5, .5),
          infoWindow: InfoWindow(title: '📍 $empName',
              snippet: 'Live position'),
          zIndex: 10,
        ));
      }
    }

    for (int i = 0; i < steps.length; i++) {
      final step   = steps[i];
      final coords = step.destinationLocation?.coordinates;
      if (step.isFieldWorkStep != true ||
          coords == null || coords.length < 2) continue;

      final isActive =
      ['in_progress', 'travelling', 'reached'].contains(step.status);
      final isDone =
          step.status == 'completed' || step.status == 'skipped';
      final address =
          step.destinationLocation?.address ?? 'Step ${i + 1} destination';
      final statusSnippet = switch (step.status) {
        'completed'   => '✅ Completed',
        'in_progress' => '🔵 In progress',
        'reached'     => '📍 Reached',
        'travelling'  => '🚗 Travelling',
        'skipped'     => '⏭ Skipped',
        _             => '⏳ Pending',
      };
      markers.add(Marker(
        markerId:   MarkerId('dest_$i'),
        position:   LatLng(coords[1], coords[0]),
        icon:       _pinBitmaps[i] ??
            BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
        anchor:     const Offset(.5, 1.0),
        infoWindow: InfoWindow(
          title:   'Step ${i + 1} · ${step.title ?? ''}',
          snippet: '$address\n$statusSnippet',
        ),
        alpha:  isDone ? .5 : 1.0,
        zIndex: isActive ? 5 : (isDone ? 1 : 3),
      ));
    }

    if (!_isLiveMode) {
      if (_c.tracePoints.isNotEmpty) {
        markers.add(Marker(
          markerId:   const MarkerId('route_start'),
          position:   _c.tracePoints.first,
          icon:       _startFlagBitmap ??
              BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
          anchor:     const Offset(.15, 1.0),
          infoWindow: InfoWindow(
            title:   '🟢 Route Start',
            snippet: _c.traceStart != null
                ? _c.fmtTime(_c.traceStart) : null,
          ),
          zIndex: 4,
        ));
      }
      if (_c.tracePoints.length > 1) {
        markers.add(Marker(
          markerId:   const MarkerId('route_end'),
          position:   _c.tracePoints.last,
          icon:       _endFlagBitmap ??
              BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
          anchor:     const Offset(.15, 1.0),
          infoWindow: InfoWindow(
            title:   '🔴 Route End',
            snippet: _c.traceEnd != null
                ? _c.fmtTime(_c.traceEnd) : null,
          ),
          zIndex: 4,
        ));
      }
    }
    return markers;
  }

  LatLng _initialCenter() {
    if (_isLiveMode) {
      return _animatedEmpPos ?? _c.employeeLatLng ??
          _c.destinationLatLng ?? const LatLng(20.5937, 78.9629);
    }
    return _c.tracePoints.isNotEmpty
        ? _c.tracePoints.first
        : const LatLng(20.5937, 78.9629);
  }

  String _calcDistance(List<LatLng> pts) {
    if (pts.length < 2) return '0m';
    double d = 0;
    for (int i = 1; i < pts.length; i++) {
      d += Geolocator.distanceBetween(
        pts[i - 1].latitude, pts[i - 1].longitude,
        pts[i].latitude,     pts[i].longitude,
      );
    }
    return d >= 1000
        ? '${(d / 1000).toStringAsFixed(1)}km'
        : '${d.round()}m';
  }

  String _calcDuration(DateTime? s, DateTime? e) {
    if (s == null || e == null) return '--';
    final diff = e.difference(s);
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inMinutes}m';
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // _________________________________________________________________________
  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final h        = MediaQuery.of(context).size.height;
    final bg       = isDark ? const Color(0xFF0D0F14) : Colors.white;
    final surface  = isDark ? const Color(0xFF131620) : const Color(0xFFF7F8FC);
    final divColor = isDark ? const Color(0xFF1E2235) : const Color(0xFFEEEFF5);

    final isLoading = !_bitmapsReady ||
        (_isLiveMode ? _c.isLoadingLocation : _c.isLoadingTrace);
    final error = !_isLiveMode ? _c.locationError : null;

    return Container(
      height: h * 0.92,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [

        // ── Handle ──────────────────────────────────────────────────────────
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: .25),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: divColor),
                ),
                child: Row(children: [
                  _TabBtn(
                    label:  'Live Location',
                    icon:   Icons.location_searching_rounded,
                    active: _isLiveMode,
                    color:  _kGreen,
                    onTap:  () => _switchTab(true),
                  ),
                  _TabBtn(
                    label:  'Route History',
                    icon:   Icons.route_rounded,
                    active: !_isLiveMode,
                    color:  _kBlue,
                    onTap:  () => _switchTab(false),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            // Refresh (history only)
            if (!_isLiveMode) ...[
              _IconBtn(
                icon:     _isRefreshing
                    ? Icons.hourglass_empty_rounded
                    : Icons.refresh_rounded,
                color:    _kBlue,
                surface:  surface,
                divColor: divColor,
                onTap:    _refreshHistory,
                tooltip:  'Refresh route',
              ),
              const SizedBox(width: 6),
            ],
            _IconBtn(
              icon:     Icons.close_rounded,
              surface:  surface,
              divColor: divColor,
              onTap:    () => Navigator.pop(context),
            ),
          ]),
        ),

        // ── Subtitle ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          child: Row(children: [
            if (_isLiveMode) ...[
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_wsCtrl?.isConnected ?? false)
                        ? _kGreen.withValues(alpha: _pulseAnim.value)
                        : Colors.grey.withValues(alpha: .4),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                (_wsCtrl?.isConnected ?? false)
                    ? 'Connected · updates in real-time'
                    : 'Connecting to live feed…',
                style: TextStyle(
                  fontSize: 11,
                  color: (_wsCtrl?.isConnected ?? false)
                      ? _kGreen
                      : Colors.grey.withValues(alpha: .5),
                ),
              ),
            ] else ...[
              Icon(Icons.history_rounded, size: 12,
                  color: _kBlue.withValues(alpha: .7)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _c.tracePoints.isEmpty
                      ? 'No route data yet — tap refresh to load'
                      : '${_c.tracePoints.length} pts recorded · tap refresh to update',
                  style: TextStyle(fontSize: 11,
                      color: Colors.grey.withValues(alpha: .55)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ]),
        ),

        const SizedBox(height: 10),
        Divider(height: 1, color: divColor),

        // ── Loading ──────────────────────────────────────────────────────────
        if (isLoading)
          Expanded(child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 36, height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(
                      _isLiveMode ? _kGreen : _kBlue),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _isLiveMode
                    ? 'Fetching live position…'
                    : 'Loading route history…',
                style: TextStyle(fontSize: 13,
                    color: Colors.grey.withValues(alpha: .55)),
              ),
            ],
          )))

        // ── Error ────────────────────────────────────────────────────────────
        else if (error != null)
          Expanded(child: Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                      color: _kRed.withValues(alpha: .08),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.location_off_rounded,
                      size: 32, color: _kRed),
                ),
                const SizedBox(height: 16),
                Text(error, textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          )))

        // ── Map + panels ─────────────────────────────────────────────────────
        else ...[

            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(children: [

                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                          target: _initialCenter(), zoom: 14),
                      onMapCreated: (ctrl) {
                        // KEY FIX: always replace with fresh controller.
                        // Do NOT call _mapCtrl?.dispose() here — the old one
                        // is already being disposed by the framework when
                        // the widget rebuilds. Calling dispose() twice throws.
                        _mapCtrl = ctrl;
                        if (!_isLiveMode) _safeFitMap();
                      },
                      polylines:               _polylines,
                      markers:                 _markers,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled:     true,
                      mapToolbarEnabled:       false,
                      scrollGesturesEnabled:   true,
                      zoomGesturesEnabled:     true,
                      rotateGesturesEnabled:   true,
                      tiltGesturesEnabled:     true,
                    ),

                    if (_isLiveMode)
                      Positioned(top: 10, left: 10,
                          child: _LiveChip(
                            isConnected: _wsCtrl?.isConnected ?? false,
                            pulseAnim:   _pulseAnim,
                          )),

                    if (!_isLiveMode && _c.tracePoints.isNotEmpty)
                      Positioned(top: 10, left: 10,
                          child: _MapChip(
                            icon:  Icons.route_rounded,
                            label: '${_c.tracePoints.length} points',
                            color: _kBlue,
                          )),

                    if (_isLiveMode)
                      Positioned(top: 10, right: 10,
                          child: _AccuracyChip(
                              c: _c, wsUpdate: _wsCtrl?.latestUpdate)),

                    Positioned(bottom: 10, right: 10,
                        child: _MapLegend(
                          isLiveMode: _isLiveMode,
                          steps:      _c.task?.steps ?? [],
                        )),
                  ]),
                ),
              ),
            ),

            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(children: [
                  const SizedBox(height: 10),
                  if (_isLiveMode)
                    _LiveBottomPanel(
                      c:        _c,
                      wsUpdate: _wsCtrl?.latestUpdate,
                      isDark:   isDark,
                      divColor: divColor,
                      surface:  surface,
                    )
                  else
                    _HistoryBottomPanel(
                      c:        _c,
                      isDark:   isDark,
                      divColor: divColor,
                      surface:  surface,
                      distance: _calcDistance(_c.tracePoints),
                      duration: _calcDuration(_c.traceStart, _c.traceEnd),
                    ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared small widgets
// _____________________________________________________________________________

class _TabBtn extends StatelessWidget {
  final String label; final IconData icon;
  final bool active; final Color color;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.icon,
    required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        padding: const EdgeInsets.symmetric(vertical: 5),
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: .12) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: active ? Border.all(color: color.withValues(alpha: .3)) : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 12,
              color: active ? color : Colors.grey.withValues(alpha: .45)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: active ? color : Colors.grey.withValues(alpha: .45))),
        ]),
      ),
    ),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon; final Color? color;
  final Color surface, divColor;
  final VoidCallback onTap; final String? tooltip;
  const _IconBtn({required this.icon, required this.surface,
    required this.divColor, required this.onTap,
    this.color, this.tooltip});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip ?? '',
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: surface, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: divColor),
        ),
        child: Icon(icon, size: 16,
            color: color ?? Colors.grey.withValues(alpha: .6)),
      ),
    ),
  );
}

class _LiveChip extends StatelessWidget {
  final bool isConnected; final Animation<double> pulseAnim;
  const _LiveChip({required this.isConnected, required this.pulseAnim});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: isConnected
          ? const Color(0xFF22C55E).withValues(alpha: .92)
          : Colors.grey.withValues(alpha: .88),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: .18), blurRadius: 8)],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, __) => Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: pulseAnim.value),
          ),
        ),
      ),
      const SizedBox(width: 5),
      Text(isConnected ? 'Live' : 'Connecting…',
          style: const TextStyle(color: Colors.white,
              fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _MapChip extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _MapChip({required this.icon, required this.label,
    required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: .12), blurRadius: 6)],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

class _AccuracyChip extends StatelessWidget {
  final ManagerTaskDetailController c;
  final EmployeeLocationUpdate? wsUpdate;
  const _AccuracyChip({required this.c, required this.wsUpdate});

  @override
  Widget build(BuildContext context) {
    final acc = wsUpdate?.accuracy ??
        (c.liveLocationData?['latestLocation']?['accuracyMeters'] as num?)
            ?.toDouble();
    if (acc == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.gps_fixed_rounded, size: 10,
            color: Color(0xFF22C55E)),
        const SizedBox(width: 4),
        Text('±${acc.round()}m',
            style: const TextStyle(color: Color(0xFF22C55E),
                fontSize: 10, fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Map legend
// _____________________________________________________________________________

class _MapLegend extends StatefulWidget {
  final bool isLiveMode; final List<TaskStep> steps;
  const _MapLegend({required this.isLiveMode, required this.steps});
  @override State<_MapLegend> createState() => _MapLegendState();
}

class _MapLegendState extends State<_MapLegend> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final fieldSteps = widget.steps.asMap().entries
        .where((e) => e.value.isFieldWorkStep == true).toList();

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.map_rounded, size: 12, color: Colors.black54),
              const SizedBox(width: 4),
              const Text('Legend',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: Colors.black87)),
              const SizedBox(width: 3),
              AnimatedRotation(
                turns: _expanded ? .5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 13, color: Colors.black45),
              ),
            ]),
            if (_expanded) ...[
              const SizedBox(height: 7),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 7),
              if (widget.isLiveMode)
                _LegendRow(swatch: const Color(0xFF22C55E),
                    label: 'Employee (live)', isCircle: true),
              ...fieldSteps.map((e) {
                final suffix = switch (e.value.status) {
                  'completed'   => ' ✓',
                  'in_progress' => ' ●',
                  'reached'     => ' ◎',
                  'skipped'     => ' –',
                  _             => '',
                };
                return _LegendRow(
                    swatch: _stepColor(e.key),
                    label: 'Step ${e.key + 1}$suffix');
              }),
              if (!widget.isLiveMode) ...[
                _LegendRow(swatch: const Color(0xFF22C55E),
                    label: 'Start', isFlag: true),
                _LegendRow(swatch: const Color(0xFFEF4444),
                    label: 'End', isFlag: true),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color swatch; final String label;
  final bool isCircle, isFlag;
  const _LegendRow({required this.swatch, required this.label,
    this.isCircle = false, this.isFlag = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (isCircle)
        Container(width: 9, height: 9,
            decoration: BoxDecoration(shape: BoxShape.circle, color: swatch,
                border: Border.all(color: Colors.white, width: 1.5)))
      else if (isFlag)
        CustomPaint(size: const Size(11, 13),
            painter: _MiniFlagPainter(color: swatch))
      else
        CustomPaint(size: const Size(9, 13),
            painter: _MiniPinPainter(color: swatch)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 9,
          fontWeight: FontWeight.w600, color: Colors.black87)),
    ]),
  );
}

class _MiniPinPainter extends CustomPainter {
  final Color color; const _MiniPinPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    canvas.drawPath(
        Path()
          ..addOval(Rect.fromCircle(center: Offset(r, r), radius: r))
          ..moveTo(r * .4, size.height * .7)..lineTo(r, size.height)
          ..lineTo(r * 1.6, size.height * .7)..close(),
        Paint()..color = color);
    canvas.drawCircle(Offset(r, r), r * .5, Paint()..color = Colors.white);
  }
  @override bool shouldRepaint(_) => false;
}

class _MiniFlagPainter extends CustomPainter {
  final Color color; const _MiniFlagPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    canvas.drawRect(
        Rect.fromLTWH(size.width * .4, 0, size.width * .12, size.height), p);
    canvas.drawPath(
        Path()..moveTo(size.width * .5, 0)
          ..lineTo(size.width, size.height * .35)
          ..lineTo(size.width * .5, size.height * .6)..close(), p);
  }
  @override bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Live bottom panel
// _____________________________________________________________________________

class _LiveBottomPanel extends StatelessWidget {
  final ManagerTaskDetailController c;
  final EmployeeLocationUpdate? wsUpdate;
  final bool isDark; final Color divColor, surface;
  const _LiveBottomPanel({required this.c, required this.wsUpdate,
    required this.isDark, required this.divColor, required this.surface});

  static const _kGreen = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final data     = c.liveLocationData;
    final employee = data?['employee'] as Map<String, dynamic>?;
    final battery  = wsUpdate?.battery ??
        data?['latestLocation']?['batteryLevel'];
    final updatedAt = wsUpdate?.timestamp ??
        (data?['latestLocation']?['recordedAt'] != null
            ? DateTime.tryParse(
            data!['latestLocation']!['recordedAt'] as String)?.toLocal()
            : null);

    final fieldSteps = (c.task?.steps ?? [])
        .asMap().entries
        .where((e) => e.value.isFieldWorkStep == true)
        .toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131620) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kGreen.withValues(alpha: .2)),
          ),
          child: Row(children: [
            Stack(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _kGreen.withValues(alpha: .12),
                backgroundImage: employee?['profilePicture'] != null
                    ? NetworkImage(employee!['profilePicture']) : null,
                child: employee?['profilePicture'] == null
                    ? Text((employee?['fullName'] ?? '?')[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w800,
                        color: _kGreen)) : null,
              ),
              Positioned(right: 0, bottom: 0,
                  child: Container(
                    width: 11, height: 11,
                    decoration: BoxDecoration(
                      color: _kGreen, shape: BoxShape.circle,
                      border: Border.all(
                          color: isDark
                              ? const Color(0xFF131620) : Colors.white,
                          width: 2),
                    ),
                  )),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee?['fullName'] ??
                    employee?['username'] ?? 'Employee',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                if (updatedAt != null)
                  Text('Updated ${c.fmtTime(updatedAt)}',
                      style: TextStyle(fontSize: 10,
                          color: Colors.grey.withValues(alpha: .55))),
              ],
            )),
            if (battery != null)
              _SmallChip(
                icon:  Icons.battery_charging_full_rounded,
                label: '$battery%',
                color: (battery as num) > 20
                    ? _kGreen : const Color(0xFFEF4444),
              ),
          ]),
        ),
      ),
      if (fieldSteps.isNotEmpty) ...[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Text('DESTINATIONS', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: .08,
                color: Colors.grey.withValues(alpha: .5))),
          ]),
        ),
        const SizedBox(height: 6),
        ...fieldSteps.map((e) => _StepRow(
            step: e.value, index: e.key,
            isDark: isDark, divColor: divColor)),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  History bottom panel
// _____________________________________________________________________________

class _HistoryBottomPanel extends StatelessWidget {
  final ManagerTaskDetailController c;
  final bool isDark; final Color divColor, surface;
  final String distance, duration;
  const _HistoryBottomPanel({required this.c, required this.isDark,
    required this.divColor, required this.surface,
    required this.distance, required this.duration});

  @override
  Widget build(BuildContext context) {
    final fieldSteps = (c.task?.steps ?? [])
        .asMap().entries
        .where((e) => e.value.isFieldWorkStep == true)
        .toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          _StatCard(value: '${c.tracePoints.length}',
              label: 'GPS PTS', isDark: isDark),
          const SizedBox(width: 8),
          _StatCard(value: distance, label: 'DISTANCE', isDark: isDark),
          const SizedBox(width: 8),
          _StatCard(value: duration, label: 'DURATION', isDark: isDark),
        ]),
      ),
      const SizedBox(height: 10),
      if (c.traceStart != null && c.traceEnd != null)
        _TimelineBar(
          start: c.traceStart!, end: c.traceEnd!,
          steps: c.task?.steps ?? [], c: c, isDark: isDark,
        ),
      if (fieldSteps.isNotEmpty) ...[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Text('STEPS COVERED', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: .08,
                color: Colors.grey.withValues(alpha: .5))),
          ]),
        ),
        const SizedBox(height: 6),
        ...fieldSteps.map((e) => _StepRow(
            step: e.value, index: e.key,
            isDark: isDark, divColor: divColor, showTime: true)),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Step row
// _____________________________________________________________________________

class _StepRow extends StatelessWidget {
  final TaskStep step; final int index;
  final bool isDark, showTime; final Color divColor;
  const _StepRow({required this.step, required this.index,
    required this.isDark, required this.divColor, this.showTime = false});

  String _fmtT(DateTime? dt) {
    if (dt == null) return '--';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _stepColor(index);
    final (statusLabel, badgeColor) = switch (step.status) {
      'completed'   => ('Done',    const Color(0xFF22C55E)),
      'in_progress' => ('Active',  const Color(0xFF6366F1)),
      'reached'     => ('Reached', const Color(0xFF6366F1)),
      'skipped'     => ('Skipped', Colors.grey),
      _             => ('Pending', Colors.grey),
    };
    String? subtitle;
    if (showTime && step.employeeStartTime != null) {
      final e = step.employeeCompleteTime != null
          ? _fmtT(step.employeeCompleteTime) : '—';
      subtitle = '${_fmtT(step.employeeStartTime)} → $e';
    } else {
      subtitle = step.destinationLocation?.address;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131620) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: divColor),
        ),
        child: Row(children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: .12)),
            child: Center(child: Text('${index + 1}',
                style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w800, color: color))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title ?? 'Step ${index + 1}',
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600)),
              if (subtitle != null && subtitle.isNotEmpty)
                Text(subtitle, style: TextStyle(fontSize: 10,
                    color: Colors.grey.withValues(alpha: .5))),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: badgeColor.withValues(alpha: .2)),
            ),
            child: Text(statusLabel, style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700,
                color: badgeColor)),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Stat card
// _____________________________________________________________________________

class _StatCard extends StatelessWidget {
  final String value, label; final bool isDark;
  const _StatCard({required this.value, required this.label,
    required this.isDark});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131620) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark
            ? const Color(0xFF1E2235) : const Color(0xFFEEEFF5)),
      ),
      child: Column(children: [
        Text(value, style: const TextStyle(fontSize: 17,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()])),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, letterSpacing: .07,
            color: Colors.grey.withValues(alpha: .5))),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Timeline bar
// _____________________________________________________________________________

class _TimelineBar extends StatelessWidget {
  final DateTime start, end;
  final List<TaskStep> steps;
  final ManagerTaskDetailController c;
  final bool isDark;
  const _TimelineBar({required this.start, required this.end,
    required this.steps, required this.c, required this.isDark});

  static const _kBlue = Color(0xFF6366F1);

  double _frac(DateTime? dt) {
    if (dt == null) return 0;
    final total = end.difference(start).inSeconds;
    if (total <= 0) return 0;
    return (dt.difference(start).inSeconds / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final barColor = isDark
        ? const Color(0xFF1E2235) : const Color(0xFFEEEFF5);
    final dots = steps
        .where((s) => s.isFieldWorkStep == true &&
        s.employeeStartTime != null)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131620) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark
              ? const Color(0xFF1E2235) : const Color(0xFFEEEFF5)),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(c.fmtTime(start),
                style: const TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w600, color: _kBlue,
                    fontFeatures: [FontFeature.tabularFigures()])),
            Text('TIMELINE', style: TextStyle(fontSize: 9,
                letterSpacing: .08,
                color: Colors.grey.withValues(alpha: .45))),
            Text(c.fmtTime(end),
                style: const TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                    fontFeatures: [FontFeature.tabularFigures()])),
          ]),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (_, constraints) {
            final w = constraints.maxWidth;
            return SizedBox(height: 20, child: Stack(children: [
              Positioned(top: 7, left: 0, right: 0,
                  child: Container(height: 6,
                      decoration: BoxDecoration(color: barColor,
                          borderRadius: BorderRadius.circular(3)))),
              Positioned(top: 7, left: 0,
                  child: Container(width: w, height: 6,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            _kBlue, _kBlue.withValues(alpha: .35)]),
                          borderRadius: BorderRadius.circular(3)))),
              Positioned(top: 6, left: -1,
                  child: Container(width: 8, height: 8,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF22C55E)))),
              Positioned(top: 6, right: -1,
                  child: Container(width: 8, height: 8,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFEF4444)))),
              ...dots.asMap().entries.map((e) {
                final frac = _frac(e.value.employeeStartTime);
                final col  = _stepColor(steps.indexOf(e.value));
                return Positioned(
                    top: 4, left: (w * frac - 6).clamp(0, w - 12),
                    child: Container(width: 12, height: 12,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: col,
                            border: Border.all(
                                color: isDark
                                    ? const Color(0xFF131620) : Colors.white,
                                width: 2))));
              }),
            ]));
          }),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Start', style: TextStyle(fontSize: 9,
                color: Colors.grey.withValues(alpha: .45))),
            Text('End', style: TextStyle(fontSize: 9,
                color: Colors.grey.withValues(alpha: .45))),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Small chip
// _____________________________________________________________________________

class _SmallChip extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _SmallChip({required this.icon, required this.label,
    required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .2))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10,
          fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}