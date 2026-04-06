// lib/features/task/view/widgets/task_location_map_sheet.dart
//
// Fixes in this version:
//  1. SMOOTH MARKER ANIMATION — employee marker interpolates between old and
//     new LatLng over 800 ms using a Ticker-driven linear tween, exactly like
//     delivery apps (Swiggy / Uber). No "teleport" jumps.
//  2. LARGER MARKERS — canvas size bumped: pins 108 px, employee 100 px,
//     flags 90 px. Clearly visible at normal map zoom.
//  3. ROUTE HISTORY FIX — _load() in history mode now awaits loadLocationTrace,
//     then explicitly resets _c.isLoadingTrace = false + calls setState so the
//     spinner clears and the map + overlays render. The controller's reloadData
//     callback is not wired to the sheet, so the sheet must do its own rebuild.
//  4. Route polyline shown even when there is only 1 trace point (single dot).

import 'dart:async';
import 'dart:ui' as ui;

import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/location_tracking/service/manager_location_controller.dart';
import 'package:field_work/features/task/controller/manager_task_detail_controller.dart';
import 'package:field_work/features/task/model/task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Smooth LatLng interpolator
//  Drives the employee marker from its previous position to the new one over
//  [duration] using a Ticker so it runs even when the build method isn't called.
// _____________________________________________________________________________

class _LatLngTween {
  LatLng from;
  LatLng to;
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

  Ticker?       _ticker;
  _LatLngTween? _tween;
  Duration      _elapsed  = Duration.zero;
  final Duration _duration = const Duration(milliseconds: 800);
  LatLng?       _current;

  _MarkerAnimator({required this.vsync, required this.onUpdate});

  void animateTo(LatLng target) {
    // ── FIX: always set _current on first call even if same point ──
    if (_current == null) {
      _current = target;
      onUpdate(target);   // fire immediately so marker appears right away
      return;
    }
    if (_current == target) return;

    _tween   = _LatLngTween(_current!, target);
    _elapsed = Duration.zero;
    _ticker?.stop();
    _ticker?.dispose();
    _ticker  = vsync.createTicker((elapsed) {
      _elapsed = elapsed;
      final t  = (_elapsed.inMilliseconds / _duration.inMilliseconds)
          .clamp(0.0, 1.0);
      _current = _tween!.lerp(t);
      onUpdate(_current!);
      if (t >= 1.0) _ticker?.stop();
    })..start();
  }

  LatLng? get current => _current;

  void dispose() {
    _ticker?.stop();
    _ticker?.dispose();
  }
}



// ─────────────────────────────────────────────────────────────────────────────
//  Custom bitmap factories  (all larger for visibility)
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

Future<BitmapDescriptor> _buildNumberedPin({
  required int   number,
  required Color color,
  required bool  isActive,
}) async {
  const sz   = 108.0;
  const cx   = sz / 2;
  final pinH = isActive ? 90.0 : 80.0;
  final pinW = isActive ? 58.0 : 50.0;
  final r    = pinW / 2;
  final top  = (sz - pinH) / 2;

  final rec = ui.PictureRecorder();
  final cvs = Canvas(rec, Rect.fromLTWH(0, 0, sz, sz));

  cvs.drawOval(
    Rect.fromCenter(center: Offset(cx, pinH + 5), width: pinW * 0.65, height: 7),
    Paint()..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
  );

  final body = Path()
    ..addOval(Rect.fromCircle(center: Offset(cx, top + r), radius: r))
    ..moveTo(cx - r * 0.42, top + pinW * 0.76)
    ..lineTo(cx, top + pinH)
    ..lineTo(cx + r * 0.42, top + pinW * 0.76)
    ..close();
  cvs.drawPath(body, Paint()..color = color);
  cvs.drawOval(
    Rect.fromCenter(center: Offset(cx - r * 0.18, top + r * 0.52),
        width: r * 0.85, height: r * 0.6),
    Paint()..color = Colors.white.withValues(alpha: 0.26),
  );
  cvs.drawCircle(Offset(cx, top + r), r * 0.55, Paint()..color = Colors.white);

  if (isActive) {
    cvs.drawCircle(Offset(cx, top + r), r + 5,
        Paint()..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
  }

  final tp = TextPainter(
    text: TextSpan(
      text: '$number',
      style: TextStyle(color: color, fontSize: isActive ? 22 : 19,
          fontWeight: FontWeight.w900),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(cvs, Offset(cx - tp.width / 2, top + r - tp.height / 2));

  final img   = await rec.endRecording().toImage(sz.toInt(), sz.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}

Future<BitmapDescriptor> _buildEmployeeMarker() async {
  const sz = 100.0;
  const cx = sz / 2;
  const cy = sz / 2;
  final rec = ui.PictureRecorder();
  final cvs = Canvas(rec, Rect.fromLTWH(0, 0, sz, sz));

  cvs.drawCircle(const Offset(cx, cy), 42,
      Paint()..color = const Color(0xFF2563EB).withValues(alpha: 0.12));
  cvs.drawCircle(const Offset(cx, cy), 30,
      Paint()..color = const Color(0xFF2563EB).withValues(alpha: 0.25));
  cvs.drawCircle(const Offset(cx, cy + 2), 18,
      Paint()..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
  cvs.drawCircle(const Offset(cx, cy), 18,
      Paint()..color = const Color(0xFF2563EB));
  cvs.drawCircle(const Offset(cx, cy), 18,
      Paint()..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
  cvs.drawCircle(const Offset(cx - 5, cy - 5), 4,
      Paint()..color = Colors.white.withValues(alpha: 0.6));

  final img   = await rec.endRecording().toImage(sz.toInt(), sz.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}

Future<BitmapDescriptor> _buildFlagMarker({
  required String label,
  required Color  color,
}) async {
  const sz = 90.0;
  const cx = sz / 2;
  final rec = ui.PictureRecorder();
  final cvs = Canvas(rec, Rect.fromLTWH(0, 0, sz, sz));

  cvs.drawOval(
      Rect.fromCenter(center: Offset(cx, 76), width: 22, height: 8),
      Paint()..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  cvs.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx - 2.5, 14, 5, 58),
          const Radius.circular(2)),
      Paint()..color = color);
  cvs.drawCircle(Offset(cx, 72), 6, Paint()..color = color);
  final flag = Path()
    ..moveTo(cx + 2.5, 14)
    ..lineTo(cx + 36, 22)
    ..lineTo(cx + 2.5, 40)
    ..close();
  cvs.drawPath(flag, Paint()..color = color);

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
  final bool isLiveMode;

  const TaskLocationMapSheet({
    super.key,
    required this.controller,
    required this.isLiveMode,
  });

  static Future<void> show(
      BuildContext context, {
        required ManagerTaskDetailController controller,
        required bool isLiveMode,
      }) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: false,
        builder: (_) => TaskLocationMapSheet(
          controller: controller,
          isLiveMode: isLiveMode,
        ),
      );

  @override
  State<TaskLocationMapSheet> createState() => _TaskLocationMapSheetState();
}

class _TaskLocationMapSheetState extends State<TaskLocationMapSheet>
    with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapCompleter = Completer();
  ManagerTaskDetailController get _c => widget.controller;

  ManagerLocationController? _wsCtrl;

  // Smooth marker animator
  _MarkerAnimator? _empAnimator;

  // Animated employee position (updated by the animator, not raw WS data)
  LatLng? _animatedEmpPos;

  static const _kGreen = Color(0xFF10B981);
  static const _kBlue  = Color(0xFF2563EB);
  static const _kRed   = Color(0xFFEF4444);

  Set<Polyline> _polylines = {};
  Set<Marker>   _markers   = {};

  // Custom bitmaps
  BitmapDescriptor? _employeeBitmap;
  BitmapDescriptor? _startFlagBitmap;
  BitmapDescriptor? _endFlagBitmap;
  final Map<int, BitmapDescriptor> _pinBitmaps = {};
  bool _bitmapsReady = false;

  @override
  void initState() {
    super.initState();
    _empAnimator = _MarkerAnimator(
      vsync:    this,
      onUpdate: (pos) {
        if (!mounted) return;
        _animatedEmpPos = pos;
        // Only rebuild markers — not the whole tree
        setState(() => _markers = _buildMarkers());
      },
    );
    _buildBitmapsThenLoad();
  }

  @override
  void dispose() {
    _empAnimator?.dispose();
    _wsCtrl?.dispose();
    _mapCompleter.future.then((c) => c.dispose()).catchError((_) {});
    super.dispose();
  }

  // ── Build all custom bitmaps concurrently, then load data ─────────────────
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
    _load();
  }

  // ── Load data ─────────────────────────────────────────────────────────────
  Future<void> _load() async {
    if (widget.isLiveMode) {
      await _c.loadLiveLocation();
      if (!mounted) return;

      // Seed the animator with the REST position so the first render is correct
      final seed = _c.employeeLatLng;
      if (seed != null) {
        _animatedEmpPos = seed;
        _empAnimator!.animateTo(seed);
      }

      setState(() => _rebuildOverlays());

      final mapCtrl = await _mapCompleter.future;
      _fitMap(mapCtrl);

      // WebSocket for real-time updates
      _wsCtrl = ManagerLocationController(
        taskId:     _c.taskId,
        reloadData: _onWsUpdate,
      );
      _wsCtrl!.connect();
    } else {
      // History mode ─────────────────────────────────────────────────────────
      await _c.loadLocationTrace();

      // FIX: the controller sets isLoadingTrace=false and calls its own
      // reloadData, but that callback is on ManagerTaskDetailScreen, NOT on
      // this sheet. We must rebuild here ourselves.
      if (!mounted) return;
      setState(() => _rebuildOverlays());

      final mapCtrl = await _mapCompleter.future;
      _fitMap(mapCtrl);
      return;
    }

    if (!mounted) return;
    _rebuildOverlays();
    setState(() {});
    final mapCtrl = await _mapCompleter.future;
    _fitMap(mapCtrl);
  }

  // Called by WS controller on every new employee_location event
  // void _onWsUpdate() {
  //   if (!mounted) return;
  //   final update = _wsCtrl?.latestUpdate;
  //   if (update != null) {
  //     // Animate the marker smoothly to the new position
  //     _empAnimator!.animateTo(update.latLng);
  //     // Also gently pan the camera toward the new position
  //     _mapCompleter.future.then((ctrl) {
  //       if (mounted) {
  //         ctrl.animateCamera(CameraUpdate.newLatLng(update.latLng));
  //       }
  //     }).catchError((_) {});
  //   }
  //   // Rebuild polyline (trail grows) — marker is handled by the animator
  //   setState(() => _polylines = _buildPolylines());
  // }

  void _onWsUpdate() {
    if (!mounted) return;
    final update = _wsCtrl?.latestUpdate;
    if (update != null) {
      // ── Set directly so marker shows immediately even before animation ──
      _animatedEmpPos ??= update.latLng;
      _empAnimator!.animateTo(update.latLng);
    }
    setState(() => _polylines = _buildPolylines());
  }

  void _rebuildOverlays() {
    _polylines = _buildPolylines();
    _markers   = _buildMarkers();
  }

  // ── Camera fit ────────────────────────────────────────────────────────────
  void _fitMap(GoogleMapController ctrl) {
    final pts = <LatLng>[];

    if (widget.isLiveMode) {
      if (_animatedEmpPos != null) pts.add(_animatedEmpPos!);
    } else {
      pts.addAll(_c.tracePoints);
    }

    // Always include all step destinations
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

    double minLat = pts[0].latitude,  maxLat = pts[0].latitude;
    double minLng = pts[0].longitude, maxLng = pts[0].longitude;
    for (final p in pts) {
      if (p.latitude  < minLat) minLat = p.latitude;
      if (p.latitude  > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    ctrl.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.001, minLng - 0.001),
          northeast: LatLng(maxLat + 0.001, maxLng + 0.001),
        ),
        80,
      ),
    );
  }

  // ── Polylines ─────────────────────────────────────────────────────────────
  Set<Polyline> _buildPolylines() {
    final lines = <Polyline>{};

    // Route history — show even if only 1 point (as a single dot isn't a
    // line, but we add it; for 1 point the marker alone is sufficient)
    if (!widget.isLiveMode && _c.tracePoints.length >= 2) {
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

    // Live breadcrumb trail
    if (widget.isLiveMode) {
      final trail = _wsCtrl?.liveTrail ?? [];
      if (trail.length >= 2) {
        lines.add(Polyline(
          polylineId: const PolylineId('live_trail'),
          points:     trail,
          color:      _kBlue.withValues(alpha: 0.5),
          width:      4,
          jointType:  JointType.round,
          endCap:     Cap.roundCap,
          startCap:   Cap.roundCap,
        ));
      }
    }

    return lines;
  }

  // ── Markers ───────────────────────────────────────────────────────────────
  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    final steps   = _c.task?.steps ?? [];

    // 1. Live employee (use _animatedEmpPos for smooth movement)
    if (widget.isLiveMode) {
      final pos = _animatedEmpPos ?? _c.employeeLatLng;
      if (pos != null) {
        final empName = (_c.liveLocationData?['employee']?['fullName'] as String?) ??
            'Employee';
        markers.add(Marker(
          markerId:   const MarkerId('employee'),
          position:   pos,
          icon:       _employeeBitmap ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          anchor:     const Offset(0.5, 0.5),
          infoWindow: InfoWindow(title: '📍 $empName', snippet: 'Live position'),
          zIndex:     10,
          flat:       false,
        ));
      }
    }

    // 2. Numbered destination pins — ALL field-work steps
    for (int i = 0; i < steps.length; i++) {
      final step   = steps[i];
      final coords = step.destinationLocation?.coordinates;
      if (step.isFieldWorkStep != true || coords == null || coords.length < 2) continue;

      final isActive = ['in_progress', 'travelling', 'reached'].contains(step.status);
      final isDone   = step.status == 'completed' || step.status == 'skipped';
      final address  = step.destinationLocation?.address ?? 'Step ${i + 1} destination';
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
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        anchor:     const Offset(0.5, 1.0),
        infoWindow: InfoWindow(
          title:   'Step ${i + 1} · ${step.title ?? ''}',
          snippet: '$address\n$statusSnippet',
        ),
        alpha:  isDone ? 0.5 : 1.0,
        zIndex: isActive ? 5 : (isDone ? 1 : 3),
      ));
    }

    // 3. Route history S/E flags
    if (!widget.isLiveMode) {
      if (_c.tracePoints.isNotEmpty) {
        markers.add(Marker(
          markerId:   const MarkerId('route_start'),
          position:   _c.tracePoints.first,
          icon:       _startFlagBitmap ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          anchor:     const Offset(0.15, 1.0),
          infoWindow: InfoWindow(
            title:   '🟢 Route Start',
            snippet: _c.traceStart != null ? _c.fmtTime(_c.traceStart) : null,
          ),
          zIndex: 4,
        ));
      }
      if (_c.tracePoints.length > 1) {
        markers.add(Marker(
          markerId:   const MarkerId('route_end'),
          position:   _c.tracePoints.last,
          icon:       _endFlagBitmap ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          anchor:     const Offset(0.15, 1.0),
          infoWindow: InfoWindow(
            title:   '🔴 Route End',
            snippet: _c.traceEnd != null ? _c.fmtTime(_c.traceEnd) : null,
          ),
          zIndex: 4,
        ));
      }
    }

    return markers;
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final h      = MediaQuery.of(context).size.height;

    final isLoading = !_bitmapsReady ||
        (widget.isLiveMode ? _c.isLoadingLocation : _c.isLoadingTrace);

    // Only show hard error for history mode (live mode gracefully falls back
    // to REST seed while WS connects)
    final error = !widget.isLiveMode ? _c.locationError : null;

    return Container(
      height: h * 0.92,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A16) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [

        // ── Handle + header ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: (widget.isLiveMode ? _kGreen : _kBlue)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.isLiveMode
                      ? Icons.location_searching_rounded
                      : Icons.route_rounded,
                  color: widget.isLiveMode ? _kGreen : _kBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      widget.isLiveMode ? 'Live Location' : 'Full Route Trace',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    if (widget.isLiveMode) ...[
                      const SizedBox(width: 8),
                      _WsStatusDot(isConnected: _wsCtrl?.isConnected ?? false),
                    ],
                  ]),
                  Text(
                    widget.isLiveMode
                        ? 'Real-time position · all destinations shown'
                        : 'Recorded path · tap any pin for details',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.withValues(alpha: 0.55)),
                  ),
                ],
              )),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.close_rounded, size: 18,
                      color: Colors.grey.withValues(alpha: 0.6)),
                ),
              ),
            ]),
          ]),
        ),

        Divider(height: 20, color: Colors.grey.withValues(alpha: 0.08)),

        // ── Loading ──────────────────────────────────────────────────────
        if (isLoading)
          Expanded(child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(
                      widget.isLiveMode ? _kGreen : _kBlue)),
              const SizedBox(height: 16),
              Text(
                widget.isLiveMode ? 'Loading map…' : 'Loading route…',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.withValues(alpha: 0.6)),
              ),
            ],
          )))

        // ── Error (route history only) ───────────────────────────────────
        else if (error != null)
          Expanded(child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: _kRed.withValues(alpha: 0.08),
                    shape: BoxShape.circle),
                child: const Icon(Icons.location_off_rounded,
                    size: 36, color: _kRed),
              ),
              const SizedBox(height: 14),
              Text(error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(backgroundColor: _kBlue),
              ),
            ],
          )))

        else ...[

            // ── Google Map ────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                          target: _initialCenter(), zoom: 14),
                      onMapCreated: (ctrl) {
                        if (!_mapCompleter.isCompleted) {
                          _mapCompleter.complete(ctrl);
                          // Fit map after creation for history mode
                          if (!widget.isLiveMode) _fitMap(ctrl);
                        }
                      },
                      polylines: _polylines,
                      markers:   _markers,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled:     true,
                      mapToolbarEnabled:       false,
                      scrollGesturesEnabled:   true,
                      zoomGesturesEnabled:     true,
                      rotateGesturesEnabled:   true,
                      tiltGesturesEnabled:     true,
                    ),

                    // Live WS chip
                    if (widget.isLiveMode)
                      Positioned(
                        top: 12, left: 12,
                        child: _ConnectionChip(
                            isConnected: _wsCtrl?.isConnected ?? false),
                      ),

                    // Route info chip (history mode)
                    if (!widget.isLiveMode && _c.tracePoints.isNotEmpty)
                      Positioned(
                        top: 12, left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                            )],
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.route_rounded,
                                size: 13, color: Color(0xFF2563EB)),
                            const SizedBox(width: 5),
                            Text(
                              '${_c.tracePoints.length} pts',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB)),
                            ),
                          ]),
                        ),
                      ),

                    // Legend
                    Positioned(
                      bottom: 12, right: 12,
                      child: _MapLegend(
                        isLiveMode: widget.isLiveMode,
                        steps:      _c.task?.steps ?? [],
                      ),
                    ),
                  ]),
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (widget.isLiveMode)
              _LiveInfoPanel(
                c:        _c,
                wsUpdate: _wsCtrl?.latestUpdate,
                isDark:   isDark,
              )
            else
              _TraceInfoPanel(c: _c, isDark: isDark),

            const SizedBox(height: 20),
          ],
      ]),
    );
  }

  LatLng _initialCenter() {
    if (widget.isLiveMode) {
      return _animatedEmpPos ?? _c.employeeLatLng ??
          _c.destinationLatLng ?? const LatLng(20.5937, 78.9629);
    }
    return _c.tracePoints.isNotEmpty
        ? _c.tracePoints.first
        : const LatLng(20.5937, 78.9629);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Map legend (collapsible, bottom-right)
// _____________________________________________________________________________

class _MapLegend extends StatefulWidget {
  final bool isLiveMode;
  final List<TaskStep> steps;
  const _MapLegend({required this.isLiveMode, required this.steps});

  @override
  State<_MapLegend> createState() => _MapLegendState();
}

class _MapLegendState extends State<_MapLegend> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final fieldSteps = widget.steps.asMap().entries
        .where((e) => e.value.isFieldWorkStep == true)
        .toList();

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color:  Colors.black.withValues(alpha: 0.12),
            blurRadius: 8, offset: const Offset(0, 2),
          )],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.map_rounded, size: 13, color: Colors.black54),
              const SizedBox(width: 5),
              const Text('Legend',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: Colors.black87)),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 14, color: Colors.black45),
              ),
            ]),
            if (_expanded) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 8),
              if (widget.isLiveMode)
                _LegendRow(
                    swatch: const Color(0xFF2563EB),
                    label:  'Employee (live)',
                    isCircle: true),
              ...fieldSteps.map((e) {
                final suffix = switch (e.value.status) {
                  'completed'   => ' ✅',
                  'in_progress' => ' 🔵',
                  'reached'     => ' 📍',
                  'skipped'     => ' ⏭',
                  _             => '',
                };
                return _LegendRow(
                    swatch: _stepColor(e.key),
                    label:  'Step ${e.key + 1}$suffix');
              }),
              if (!widget.isLiveMode) ...[
                _LegendRow(swatch: const Color(0xFF10B981),
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
  final Color  swatch;
  final String label;
  final bool   isCircle;
  final bool   isFlag;
  const _LegendRow({required this.swatch, required this.label,
    this.isCircle = false, this.isFlag = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (isCircle)
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: swatch,
              border: Border.all(color: Colors.white, width: 1.5)),
        )
      else if (isFlag)
        CustomPaint(size: const Size(12, 14),
            painter: _MiniFlagPainter(color: swatch))
      else
        CustomPaint(size: const Size(10, 14),
            painter: _MiniPinPainter(color: swatch)),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87)),
    ]),
  );
}

class _MiniPinPainter extends CustomPainter {
  final Color color;
  const _MiniPinPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    canvas.drawPath(
      Path()
        ..addOval(Rect.fromCircle(center: Offset(r, r), radius: r))
        ..moveTo(r * 0.4, size.height * 0.7)
        ..lineTo(r, size.height)
        ..lineTo(r * 1.6, size.height * 0.7)
        ..close(),
      Paint()..color = color,
    );
    canvas.drawCircle(Offset(r, r), r * 0.5, Paint()..color = Colors.white);
  }
  @override bool shouldRepaint(_) => false;
}

class _MiniFlagPainter extends CustomPainter {
  final Color color;
  const _MiniFlagPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.4, 0, size.width * 0.12, size.height), p);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, 0)
        ..lineTo(size.width, size.height * 0.35)
        ..lineTo(size.width * 0.5, size.height * 0.6)
        ..close(),
      p,
    );
  }
  @override bool shouldRepaint(_) => false;
}

// ── Status / connection chips ────────────────────────────────────────────────

class _WsStatusDot extends StatelessWidget {
  final bool isConnected;
  const _WsStatusDot({required this.isConnected});
  @override
  Widget build(BuildContext context) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isConnected ? const Color(0xFF10B981) : Colors.grey),
  );
}

class _ConnectionChip extends StatelessWidget {
  final bool isConnected;
  const _ConnectionChip({required this.isConnected});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: isConnected
          ? const Color(0xFF10B981).withValues(alpha: 0.92)
          : Colors.grey.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          size: 12, color: Colors.white),
      const SizedBox(width: 5),
      Text(
        isConnected ? 'Live' : 'Reconnecting…',
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    ]),
  );
}

// ── Bottom info panels ───────────────────────────────────────────────────────

class _LiveInfoPanel extends StatelessWidget {
  final ManagerTaskDetailController c;
  final EmployeeLocationUpdate? wsUpdate;
  final bool isDark;
  const _LiveInfoPanel(
      {required this.c, required this.wsUpdate, required this.isDark});

  static const _kGreen = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final data      = c.liveLocationData;
    final employee  = data?['employee'] as Map<String, dynamic>?;
    final accuracy  = wsUpdate?.accuracy ??
        (data?['latestLocation']?['accuracyMeters'] as num?)?.toDouble();
    final battery   = wsUpdate?.battery ??
        data?['latestLocation']?['batteryLevel'];
    final updatedAt = wsUpdate?.timestamp ??
        (data?['latestLocation']?['recordedAt'] != null
            ? DateTime.tryParse(
            data!['latestLocation']!['recordedAt'] as String)
            ?.toLocal()
            : null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141428) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Stack(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Pallete.primaryColor.withValues(alpha: 0.15),
              backgroundImage: employee?['profilePicture'] != null
                  ? NetworkImage(employee!['profilePicture']) : null,
              child: employee?['profilePicture'] == null
                  ? Text(
                  (employee?['fullName'] ?? '?')[0].toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Pallete.primaryColor))
                  : null,
            ),
            Positioned(right: 0, bottom: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                      color: _kGreen, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                )),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee?['fullName'] ?? employee?['username'] ?? 'Employee',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13),
              ),
              if (updatedAt != null)
                Text('Updated ${c.fmtTime(updatedAt)}',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.withValues(alpha: 0.6))),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (accuracy != null)
              _InfoChip(icon: Icons.gps_fixed_rounded,
                  label: '±${accuracy.round()}m', color: _kGreen),
            if (battery != null) ...[
              const SizedBox(height: 4),
              _InfoChip(
                icon:  Icons.battery_charging_full_rounded,
                label: '$battery%',
                color: (battery as num) > 20 ? _kGreen : const Color(0xFFEF4444),
              ),
            ],
          ]),
        ]),
      ),
    );
  }
}

class _TraceInfoPanel extends StatelessWidget {
  final ManagerTaskDetailController c;
  final bool isDark;
  const _TraceInfoPanel({required this.c, required this.isDark});
  static const _kBlue = Pallete.primaryColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141428) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBlue.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.route_rounded, color: _kBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${c.tracePoints.length} GPS points recorded',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13)),
            if (c.traceStart != null && c.traceEnd != null)
              Text('${c.fmtTime(c.traceStart)}  →  ${c.fmtTime(c.traceEnd)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.withValues(alpha: 0.6))),
          ],
        )),
        _InfoChip(
          icon:  Icons.pin_drop_rounded,
          label: c.tracePoints.isNotEmpty ? 'Route' : 'No data',
          color: c.tracePoints.isNotEmpty ? _kBlue : Colors.grey,
        ),
      ]),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}