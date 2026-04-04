import 'dart:async';
import 'dart:io';
import 'package:field_work/config/constant/http_constants.dart';
import 'package:field_work/features/employee_task/data/task_action_datasource.dart';
import 'package:field_work/features/task/model/task_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme/app_pallete.dart';
import '../../../core/utils/helpers.dart';

class EmployeeTaskController {
  final BuildContext context;
  final VoidCallback reloadData;
  final String taskId;

  final notesCtrl = TextEditingController();

  final _dataSource = TaskActionDataSource();
  final _picker = ImagePicker();

  // ── Task state ────────────────────────────────────────────────────────
  TaskModel? task;
  bool       isLoading          = true;
  bool       isActionInProgress = false;
  String?    errorMsg;

  // ── Completion sheet state ────────────────────────────────────────────
  File?   capturedPhoto;
  String? signatureBase64;
  String? employeeNotes;

  // ── GPS ping timer ────────────────────────────────────────────────────
  Timer? _pingTimer;

  EmployeeTaskController({
    required this.context,
    required this.reloadData,
    required this.taskId,
  });

  Future<void> init() => loadTask();
  // Future<void> init() async {
  //   await loadTask();
  // }

  Future<void> loadTask() async {
    isLoading = true;
    errorMsg  = null;
    reloadData();

    final response = await _dataSource.getTaskDetail(taskId);

    if (response?.success == true) {
      task = response!.data?.task;
      // _restartPingIfNeeded();   // restart timer whenever task state changes
      _syncPingTimer();
    } else {
      errorMsg = response?.message ?? 'Failed to load task';
    }
    isLoading = false;
    reloadData();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  TASK / STEP ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> startTask() async {
    if (isActionInProgress) return;
    _setAction(true);

    try {
      final pos = await _safeGetLocation();
      final res = await _dataSource.startTask(
        taskId,
        coordinates: pos != null ? [pos.longitude, pos.latitude] : null,
      );
      if (res?['success'] == true) {
        _snack("Task started! Let's go 💪", success: true);
        await loadTask();
      } else {
        _snack(res?['message'] ?? 'Failed to start task');
      }
    } finally { _setAction(false); }
  }

  Future<void> startStep(String stepId) async {
    if (isActionInProgress) return;
    _setAction(true);
    try {
      final res = await _dataSource.startStep(taskId, stepId);
      if (res?['success'] == true) {
        _snack('Step started', success: true);
        await loadTask();
      } else {
        _snack(res?['message'] ?? 'Failed to start step');
      }
    } finally { _setAction(false); }
  }

  Future<void> markReached(String stepId) async {
    if (isActionInProgress) return;
    final pos = await _safeGetLocation();
    if (pos == null) {
      _snack('Could not get location. Enable GPS and try again.');
      return;
    }
    _setAction(true);
    try {
      final res = await _dataSource.markReached(
        taskId, stepId, [pos.longitude, pos.latitude],
      );
      if (res?['success'] == true) {
        _snack("Location verified! You've reached the destination ✅",
            success: true);
        await loadTask();
      } else {
        _snack(res?['message'] ?? 'Location check failed');
      }
    } finally { _setAction(false); }
  }

  Future<void> completeStep(
    String stepId, {
    required bool requirePhoto,
    required bool requireSignature,
    required String? signatureFrom,
    required bool requireLocationCheck,
  }) async {
    if (isActionInProgress) return;

    if (requirePhoto && capturedPhoto == null) {
      _snack('Please take a photo first');
      return;
    }
    if (requireSignature && signatureBase64 == null) {
      _snack('Please collect the signature first');
      return;
    }
    _setAction(true);
    try {
      // TODO: Replace with your actual upload (S3 / Cloudinary / etc.)
      final String? uploadedPhotoUrl = capturedPhoto?.path; // placeholder

      Map<String, dynamic>? locationPayload;
      if (requireLocationCheck) {
        final pos = await _safeGetLocation();
        if (pos != null) {
          locationPayload = {
            'coordinates': [pos.longitude, pos.latitude],
            'accuracyMeters': pos.accuracy,
          };
        }
      }

      final res = await _dataSource.completeStep(
        taskId, stepId,
        photoUrl:          uploadedPhotoUrl,
        signatureData:     signatureBase64,
        signatureSignedBy: signatureFrom,
        signatureRole:     signatureFrom,
        currentLocation:   locationPayload,
        employeeNotes:
        (notesCtrl.text.trim().isNotEmpty) ? notesCtrl.text.trim() : null,
      );

      if (res?['success'] == true) {
        final taskDone = res!['data']?['taskCompleted'] == true;
        _snack(
          taskDone ? '🎉 All steps done! Task completed!' : 'Step completed!',
          success: true,
        );
        _clearCompletionState();
        await loadTask();
        if (taskDone) _stopPing();
      } else {
        _snack(res?['message'] ?? 'Failed to complete step');
      }
    } finally { _setAction(false); }
  }


  // ═══════════════════════════════════════════════════════════════════════
  //  PHOTO
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> capturePhoto() async {
    try {
      final xf = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1280,
      );
      if (xf != null) {
        capturedPhoto = File(xf.path);
        reloadData();
      }
    } catch (_) {
      _snack('Could not open camera. Check permissions.');
    }
  }

  void removePhoto() { capturedPhoto = null; reloadData(); }

  // ═══════════════════════════════════════════════════════════════════════
  //  SIGNATURE
  // ═══════════════════════════════════════════════════════════════════════

  void onSignatureReceived(String base64) {
    signatureBase64 = base64; reloadData();
  }

  void clearSignature() { signatureBase64 = null; reloadData(); }

  // ═══════════════════════════════════════════════════════════════════════
  //  GPS PING  (background location trace while a field step is active)
  // ═══════════════════════════════════════════════════════════════════════

  void _syncPingTimer() {
    final shouldPing = _shouldPingNow();

    if (shouldPing && _pingTimer == null) {
      // Start fresh timer.
      _pingTimer = Timer.periodic(HttpConstants.kPingInterval, (_) => _ping());
      debugPrint('[Ping] Timer STARTED — task tracking is active');
    } else if (!shouldPing && _pingTimer != null) {
      // Task finished or tracking not required — kill timer.
      _stopPing();
      debugPrint('[Ping] Timer STOPPED — task no longer needs tracking');
    }
    // If shouldPing == true and timer already running → do nothing (keep it).
  }

  bool _shouldPingNow() {
    if (task == null) return false;
    if (task!.status != 'in_progress') return false;
    return task!.isFieldWork == true;
  }

  // void _restartPingIfNeeded() {
  //   _stopPing();
  //   final step = activeFieldStep;
  //   if (step == null) return;
  //   if (step.validations?.requireLocationTrace != true) return;
  //
  //   _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _ping());
  // }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  Future<void> _ping() async {
    // If task is gone or finished, kill the timer.
    if (!_shouldPingNow()) {
      _stopPing();
      return;
    }

    final step = activeStep;
    if (step?.stepId == null) {
      debugPrint('[Ping] Skipped — no active step yet');
      return;
    }

    final pos = await _safeGetLocation();
    if (pos == null) {
      debugPrint('[Ping] Skipped — could not get GPS');
      return;
    }

    try {
      await _dataSource.pingLocation(
        taskId:      taskId,
        stepId:      step!.stepId!,
        coordinates: [pos.longitude, pos.latitude],
        accuracy:    pos.accuracy,
      );
      debugPrint('[Ping] Sent for step ${step.stepId}');
    } catch (e) {
      debugPrint('[Ping] Error: $e');
    }
  }


  // ═══════════════════════════════════════════════════════════════════════
  //  COMPUTED PROPERTIES  (used directly by the UI)
  // ═══════════════════════════════════════════════════════════════════════
  bool get isTaskPending => task?.status == 'pending';
  bool get isTaskActive  => task?.status == 'in_progress';
  bool get isTaskDone =>
      task?.status == 'completed' || task?.status == 'cancelled';

  /// First step that is currently active (in_progress / travelling / reached)
  TaskStep? get activeStep {
    try {
      return task?.steps?.firstWhere((s) =>
      s.status == 'in_progress' ||
          s.status == 'travelling'  ||
          s.status == 'reached');
    } catch (_) { return null; }
  }

  /// Active step that is also a field-work step — used for GPS ping
  TaskStep? get activeFieldStep {
    try {
      return task?.steps?.firstWhere((s) =>
      (s.status == 'in_progress' ||
          s.status == 'travelling'  ||
          s.status == 'reached') &&
          s.isFieldWorkStep == true);
    } catch (_) { return null; }
  }

  /// First step still waiting to be started
  TaskStep? get nextPendingStep {
    try {
      return task?.steps?.firstWhere((s) => s.status == 'pending');
    } catch (_) { return null; }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  void _setAction(bool v) { isActionInProgress = v; reloadData(); }

  void _clearCompletionState() {
    capturedPhoto   = null;
    signatureBase64 = null;
    notesCtrl.clear();
  }

  Future<Position?> _safeGetLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }

      if (!await Geolocator.isLocationServiceEnabled()) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) { return null; }
  }

  void _snack(String msg, {bool success = false}) {
    if (!context.mounted) return;
    Helpers.showSnackBar(
      context, msg,
      type: success ? SnackType.success : SnackType.error,
    );
  }

  // ───label helpers ────────────────────────────────────────────

  Color statusColor(String? s) => switch (s) {
    'in_progress' => Pallete.primaryColor,
    'completed'   => Pallete.kGreen,
    'overdue'     => Pallete.kRed,
    'cancelled'   => Colors.grey,
    _             => Pallete.kAmber,
  };

  String statusLabel(String? s) => switch (s) {
    'in_progress' => 'IN PROGRESS',
    'completed'   => 'COMPLETED',
    'overdue'     => 'OVERDUE',
    'cancelled'   => 'CANCELLED',
    _             => 'PENDING',
  };

  Color priorityColor(String? p) => switch (p) {
    'high' => Pallete.kRed,
    'low'  => Pallete.kGreen,
    _      => Pallete.kAmber,
  };

  String priorityLabel(String? p) => switch (p) {
    'high' => '🔴 High Priority',
    'low'  => '🟢 Low Priority',
    _      => '🟡 Medium Priority',
  };

  Color progressColor(double p) {
    if (p >= 1.0) return Pallete.kGreen;
    if (p >= 0.5) return Pallete.primaryColor;
    return Pallete.kAmber;
  }

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

  String? capitalize(String? s) =>
      (s == null || s.isEmpty) ? s : s[0].toUpperCase() + s.substring(1);


  void dispose() {
    notesCtrl.dispose();
    _stopPing();
  }
}