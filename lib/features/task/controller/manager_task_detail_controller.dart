import 'dart:async';
import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/task/data/manager_task_datasource.dart';
import 'package:field_work/features/task/model/task_model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:latlong2/latlong.dart';


/// Holds all state and business logic for [ManagerTaskDetailScreen].
class ManagerTaskDetailController {
  final BuildContext context;
  final VoidCallback reloadData;
  final String taskId;
  final VoidCallback? onTaskUpdated;

  final _ds = ManagerTaskDatasource();

  // ── Core task state ────────────────────────────────────────────────────
  TaskModel? task;
  bool isLoading    = true;
  bool isCancelling = false;
  String? errorMsg;

  // ── Location state ─────────────────────────────────────────────────────
  bool isLoadingLocation    = false;
  bool isLoadingTrace       = false;
  String? locationError;

  // Live location data (current employee position + active step destination)
  Map<String, dynamic>? liveLocationData;

  // Full route trace (list of {coordinates, recordedAt} points)
  List<LatLng>   tracePoints   = [];
  DateTime?      traceStart;
  DateTime?      traceEnd;

  // Which step's trace is currently shown (null = all steps)
  String? selectedTraceStepId;

  ManagerTaskDetailController({
    required this.context,
    required this.reloadData,
    required this.taskId,
    this.onTaskUpdated,
  });

  // ═══════════════════════════════════════════════════════════════════════
  //  INIT / LOAD
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> init() => loadTask();

  Future<void> loadTask() async {
    isLoading = true;
    errorMsg  = null;
    reloadData();

    final res = await _ds.getTaskDetail(taskId);
    if (res?.success == true) {
      task = res!.data?.task;
    } else {
      errorMsg = res?.message ?? 'Failed to load task';
    }

    isLoading = false;
    reloadData();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CANCEL TASK
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> cancelTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Task?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'The employee will be notified. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Task'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Pallete.kRed,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Task'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    isCancelling = true;
    reloadData();

    final res = await _ds.cancelTask(taskId);
    isCancelling = false;

    if (res?['success'] == true) {
      _snack('Task cancelled', success: true);
      onTaskUpdated?.call();
      await loadTask();
    } else {
      _snack(res?['message'] ?? 'Failed to cancel');
    }

    reloadData();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  LIVE LOCATION
  // ═══════════════════════════════════════════════════════════════════════

  /// Fetches the employee's latest GPS position and active step destination.
  Future<void> loadLiveLocation() async {
    isLoadingLocation = true;
    locationError     = null;
    reloadData();

    final res = await _ds.getLiveLocation(taskId);

    if (res?['success'] == true) {
      liveLocationData = res!['data'] as Map<String, dynamic>?;
    } else {
      locationError = res?['message'] ?? 'Could not get live location';
    }

    isLoadingLocation = false;
    reloadData();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  LOCATION TRACE (full route)
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> loadLocationTrace({String? stepId}) async {
    isLoadingTrace      = true;
    selectedTraceStepId = stepId;
    locationError       = null;
    tracePoints         = [];
    reloadData();

    final res = await _ds.getLocationTrace(taskId, stepId: stepId);

    if (res?['success'] == true) {
      final data   = res!['data'] as Map<String, dynamic>;
      final traces = data['traces'] as List<dynamic>? ?? [];

      tracePoints = traces
          .map((t) {
        final coords = t['location']?['coordinates'];
        if (coords == null || coords.length < 2) return null;
        final lng    = (coords[0] as num).toDouble();
        final lat    = (coords[1] as num).toDouble();
        return LatLng(lat, lng);
      })
          .whereType<LatLng>()
          .toList();

      if (traces.isNotEmpty) {
        final first = DateTime.tryParse(
            traces.first['recordedAt'] as String? ?? '');
        final last  = DateTime.tryParse(
            traces.last['recordedAt']  as String? ?? '');
        traceStart  = first?.toLocal();
        traceEnd    = last?.toLocal();
      }
    } else {
      locationError = res?['message'] ?? 'Could not load route trace';
    }

    isLoadingTrace = false;
    reloadData();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  COMPUTED HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  bool get canCancel =>
      !['completed', 'cancelled'].contains(task?.status);

  bool get isActive => task?.status == 'in_progress';

  bool get hasLiveLocation =>
      liveLocationData?['latestLocation']?['coordinates'] != null;

  /// Employee's latest known position from the live-location response.
  LatLng? get employeeLatLng {
    final coords =
    liveLocationData?['latestLocation']?['coordinates'] as List?;
    if (coords == null || coords.length < 2) return null;
    return LatLng(
      (coords[1] as num).toDouble(),
      (coords[0] as num).toDouble(),
    );
  }

  /// Destination of the currently active field-work step.
  LatLng? get destinationLatLng {
    final coords =
    liveLocationData?['destination']?['coordinates'] as List?;
    if (coords == null || coords.length < 2) return null;
    return LatLng(
      (coords[1] as num).toDouble(),
      (coords[0] as num).toDouble(),
    );
  }

  double get progress {
    final total = task?.totalSteps     ?? 0;
    final done  = task?.completedSteps ?? 0;
    return total > 0 ? done / total : 0.0;
  }

  // ── Formatting helpers ─────────────────────────────────────────────────

  String fmtDate(DateTime? dt) {
    if (dt == null) return '--';
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${mo[dt.month - 1]}';
  }

  String fmtTime(DateTime? dt) {
    if (dt == null) return '--';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }

  String fmtDateTime(DateTime? dt) {
    if (dt == null) return '--';
    return '${fmtDate(dt)}, ${fmtTime(dt)}';
  }

  String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ── Color helpers ──────────────────────────────────────────────────────

  static const kGreen  = Pallete.kGreen;
  static const kAmber  = Pallete.kAmber;
  static const kRed    = Pallete.kRed;
  static const kBlue   = Pallete.primaryColor;

  Color statusColor(String? s) => switch (s) {
    'in_progress' => Pallete.primaryColor,
    'completed'   => kGreen,
    'overdue'     => kRed,
    'cancelled'   => Colors.grey,
    _             => kAmber,
  };

  Color stepColor(String? s) => switch (s) {
    'completed'                => kGreen,
    'in_progress' || 'reached' => Pallete.primaryColor,
    'skipped'                  => Colors.grey,
    _                          => Colors.grey,
  };

  Color progressColor(double p) {
    if (p >= 1.0) return kGreen;
    if (p >= 0.5) return Pallete.primaryColor;
    return kAmber;
  }

  String statusLabel(String? s) => switch (s) {
    'in_progress' => 'In Progress',
    'completed'   => 'Completed',
    'overdue'     => 'Overdue',
    'cancelled'   => 'Cancelled',
    _             => 'Pending',
  };

  String stepStatusLabel(String? s) => switch (s) {
    'completed'   => 'Done',
    'in_progress' => 'Active',
    'reached'     => 'Reached',
    'skipped'     => 'Skipped',
    _             => 'Pending',
  };

  String priorityEmoji(String? p) =>
      switch (p) { 'high' => '🔴', 'low' => '🟢', _ => '🟡' };

  // ═══════════════════════════════════════════════════════════════════════
  //  PRIVATE
  // ═══════════════════════════════════════════════════════════════════════

  void _snack(String msg, {bool success = false}) {
    if (!context.mounted) return;
    Helpers.showSnackBar(context, msg,
        type: success ? SnackType.success : SnackType.error);
  }

  void dispose() {}
}