import 'dart:async';
import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/task/controller/manager_task_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

class _TaskLocationMapSheetState extends State<TaskLocationMapSheet> {
  final Completer<GoogleMapController> _mapCompleter = Completer();

  ManagerTaskDetailController get _c => widget.controller;

  static const _kGreen = Color(0xFF10B981);
  static const _kBlue  = Pallete.primaryColor;
  static const _kRed   = Color(0xFFEF4444);

  // ── Google Maps sets ──────────────────────────────────────────────────
  Set<Polyline> _polylines = {};
  Set<Marker>   _markers   = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _mapCompleter.future.then((c) => c.dispose());
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    if (widget.isLiveMode) {
      await _c.loadLiveLocation();
    } else {
      await _c.loadLocationTrace();
    }
    if (!mounted) return;
    setState(() {
      _polylines = _buildPolylines();
      _markers   = _buildMarkers();
    });
    // Wait for the controller, then fit the camera.
    final mapCtrl = await _mapCompleter.future;
    _fitMap(mapCtrl);
  }

  void _fitMap(GoogleMapController mapCtrl) {
    final points = widget.isLiveMode
        ? [
      if (_c.employeeLatLng  != null) _c.employeeLatLng!,
      if (_c.destinationLatLng != null) _c.destinationLatLng!,
    ]
        : _c.tracePoints;

    if (points.isEmpty) return;

    if (points.length == 1) {
      mapCtrl.animateCamera(CameraUpdate.newLatLngZoom(points.first, 16));
      return;
    }

    double minLat = points[0].latitude,  maxLat = points[0].latitude;
    double minLng = points[0].longitude, maxLng = points[0].longitude;
    for (final p in points) {
      if (p.latitude  < minLat) minLat = p.latitude;
      if (p.latitude  > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    mapCtrl.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        60, // padding
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  Build Google Maps overlays
  // ─────────────────────────────────────────────────────────────────────

  Set<Polyline> _buildPolylines() {
    final lines = <Polyline>{};

    if (!widget.isLiveMode && _c.tracePoints.length > 1) {
      lines.add(Polyline(
        polylineId: const PolylineId('trace'),
        points:     _c.tracePoints,
        color:      _kBlue,
        width:      4,
      ));
    }

    if (widget.isLiveMode && _c.tracePoints.length > 1) {
      lines.add(Polyline(
        polylineId: const PolylineId('live_trail'),
        points:     _c.tracePoints,
        color:      _kGreen.withValues(alpha: 0.7),
        width:      3,
      ));
    }

    return lines;
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (widget.isLiveMode) {
      final emp = _c.employeeLatLng;
      if (emp != null) {
        markers.add(Marker(
          markerId: const MarkerId('employee'),
          position: emp,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Employee'),
        ));
      }

      final dest = _c.destinationLatLng;
      if (dest != null) {
        markers.add(Marker(
          markerId: const MarkerId('destination'),
          position: dest,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        ));
      }
    } else {
      if (_c.tracePoints.isNotEmpty) {
        markers.add(Marker(
          markerId: const MarkerId('start'),
          position: _c.tracePoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start'),
        ));
      }
      if (_c.tracePoints.length > 1) {
        markers.add(Marker(
          markerId: const MarkerId('end'),
          position: _c.tracePoints.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'End'),
        ));
      }
    }

    return markers;
  }

  // ─────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final h      = MediaQuery.of(context).size.height;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isLiveMode ? 'Live Location' : 'Full Route Trace',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      widget.isLiveMode
                          ? 'Real-time employee position'
                          : 'Complete path recorded during task',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
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

        // ── Loading / error ──────────────────────────────────────────────
        if (_c.isLoadingLocation || _c.isLoadingTrace)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(
                        widget.isLiveMode ? _kGreen : _kBlue),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isLiveMode
                        ? 'Fetching live position…'
                        : 'Loading route…',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          )

        else if (_c.locationError != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _kRed.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_off_rounded,
                        size: 36, color: _kRed),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _c.locationError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.isLiveMode ? _kGreen : _kBlue,
                    ),
                  ),
                ],
              ),
            ),
          )

        else ...[

            // ── Google Map ─────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(children: [

                    // ← THIS IS THE KEY FIX
                    // Absorb all vertical drag gestures so the bottom sheet
                    // doesn't intercept map scroll/pan/zoom gestures.
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _initialCenter(),
                        zoom: 14,
                      ),
                      onMapCreated: (ctrl) {
                        if (!_mapCompleter.isCompleted) {
                          _mapCompleter.complete(ctrl);
                        }
                      },
                      polylines: _polylines,
                      markers:   _markers,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled:     true,   // ← show +/- buttons
                      mapToolbarEnabled:       false,
                      scrollGesturesEnabled:   true,
                      zoomGesturesEnabled:     true,
                      rotateGesturesEnabled:   true,
                      tiltGesturesEnabled:     true,
                    ),

                    // ── Refresh button (live mode only) ──────────────────
                    if (widget.isLiveMode)
                      Positioned(
                        top: 12, right: 12,
                        child: GestureDetector(
                          onTap: _loadData,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Icon(Icons.refresh_rounded,
                                color: _kGreen, size: 18),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Bottom info panel ──────────────────────────────────────────
            if (widget.isLiveMode)
              _LiveInfoPanel(c: _c, isDark: isDark)
            else
              _TraceInfoPanel(c: _c, isDark: isDark),

            const SizedBox(height: 20),
          ],
      ]),
    );
  }

  LatLng _initialCenter() {
    if (widget.isLiveMode) {
      return _c.employeeLatLng ??
          _c.destinationLatLng ??
          const LatLng(20.5937, 78.9629);
    }
    return _c.tracePoints.isNotEmpty
        ? _c.tracePoints.first
        : const LatLng(20.5937, 78.9629);
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  INFO PANELS  (unchanged — kept as-is)
// ═══════════════════════════════════════════════════════════════════════

class _LiveInfoPanel extends StatelessWidget {
  final ManagerTaskDetailController c;
  final bool isDark;
  const _LiveInfoPanel({required this.c, required this.isDark});

  static const _kGreen = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final data     = c.liveLocationData;
    final employee = data?['employee'] as Map<String, dynamic>?;
    final loc      = data?['latestLocation'] as Map<String, dynamic>?;
    final accuracy = loc?['accuracyMeters'];
    final recorded = loc?['recordedAt'] != null
        ? DateTime.tryParse(loc!['recordedAt'] as String)?.toLocal()
        : null;
    final battery  = loc?['batteryLevel'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141428) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10, offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          Stack(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Pallete.primaryColor.withValues(alpha: 0.15),
              backgroundImage: employee?['profilePicture'] != null
                  ? NetworkImage(employee!['profilePicture'])
                  : null,
              child: employee?['profilePicture'] == null
                  ? Text(
                (employee?['fullName'] ?? '?')[0].toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Pallete.primaryColor),
              )
                  : null,
            ),
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: _kGreen, shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee?['fullName'] ?? employee?['username'] ?? 'Employee',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13),
                ),
                if (recorded != null)
                  Text(
                    'Updated ${c.fmtTime(recorded)}',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.withValues(alpha: 0.6)),
                  ),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (accuracy != null)
              _InfoChip(
                icon: Icons.gps_fixed_rounded,
                label: '±${accuracy.round()}m',
                color: _kGreen,
              ),
            if (battery != null) ...[
              const SizedBox(height: 4),
              _InfoChip(
                icon: Icons.battery_charging_full_rounded,
                label: '$battery%',
                color: battery > 20 ? _kGreen : const Color(0xFFEF4444),
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141428) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBlue.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10, offset: const Offset(0, 3))
          ],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${c.tracePoints.length} GPS points recorded',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13),
                ),
                if (c.traceStart != null && c.traceEnd != null)
                  Text(
                    '${c.fmtTime(c.traceStart)}  →  ${c.fmtTime(c.traceEnd)}',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.withValues(alpha: 0.6)),
                  ),
              ],
            ),
          ),
          _InfoChip(
            icon: Icons.pin_drop_rounded,
            label: c.tracePoints.isNotEmpty ? 'Route' : 'No data',
            color: c.tracePoints.isNotEmpty ? _kBlue : Colors.grey,
          ),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}