// lib/features/employee_task/controller/employee_task_detail_controller.dart
//
// Changes vs original:
//   1. _syncPingTimer() removed — replaced by LocationBackgroundService
//   2. startTask()  → calls LocationBackgroundService.instance.startTracking()
//   3. startStep()  → calls LocationBackgroundService.instance.updateStep()
//   4. completeStep() → if task is done, calls stopTracking()
//   5. dispose()    → no longer calls _stopPing() (background service manages itself)
//
// Everything else (UI, signature, photo, markReached) is UNCHANGED.

import 'dart:io';
import 'package:field_work/features/employee_task/data/task_action_datasource.dart';
import 'package:field_work/features/location_tracking/service/location_background_service.dart';
import 'package:field_work/features/task/model/task_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme/app_pallete.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/upload_service.dart';

class EmployeeTaskController {
  final BuildContext context;
  final VoidCallback reloadData;
  final String taskId;

  final notesCtrl = TextEditingController();

  final _dataSource = TaskActionDataSource();
  final _picker     = ImagePicker();

  // ── Task state ─────────────────────────────────────────────────────────
  TaskModel? task;
  bool       isLoading          = true;
  bool       isActionInProgress = false;
  String?    errorMsg;

  // ── Completion sheet state ─────────────────────────────────────────────
  File?   capturedPhoto;
  String? signatureBase64;

  EmployeeTaskController({
    required this.context,
    required this.reloadData,
    required this.taskId,
  });

  Future<void> init() => loadTask();

  Future<void> loadTask() async {
    isLoading = true;
    errorMsg  = null;
    reloadData();

    final response = await _dataSource.getTaskDetail(taskId);

    if (response?.success == true) {
      task = response!.data?.task;
      // Sync the background service state with current task
      _syncBackgroundService();
    } else {
      errorMsg = response?.message ?? 'Failed to load task';
    }
    isLoading = false;
    reloadData();
  }

  // ── Sync background service with task state ─────────────────────────────
  void _syncBackgroundService() {
    final t = task;
    if (t == null) return;

    if (t.status == 'in_progress' && t.isFieldWork == true) {
      final step = activeStep;
      if (step?.stepId != null) {
        LocationBackgroundService.instance.startTracking(
          taskId: taskId,
          stepId: step!.stepId!,
          roomId: t.room?.id ?? '',
        );
      }
    } else if (t.status == 'completed' || t.status == 'cancelled') {
      LocationBackgroundService.instance.stopTracking();
    }
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

        // ── Start background GPS tracking ──────────────────────────────
        if (task?.isFieldWork == true) {
          final step = activeStep;
          await LocationBackgroundService.instance.startTracking(
            taskId: taskId,
            stepId: step?.stepId ?? '',
            roomId: task?.room?.id ?? '',
          );
        }
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

        // ── Notify background service of new active step ───────────────
        await LocationBackgroundService.instance.updateStep(stepId);
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

    // Validate before locking the UI
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

      String? uploadedPhotoUrl;
      if (capturedPhoto != null) {
        uploadedPhotoUrl = await UploadService.uploadStepPhoto(
          capturedPhoto!,
          taskId: taskId,
          stepId: stepId,
        );

        if (uploadedPhotoUrl == null) {
          if (context.mounted) {
            _snack('Photo upload failed. Check your connection and try again.');
          }
          return;
        }
      }

      // ── Step 2: Capture GPS if required ────────────────────────────────────
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

      // ── Step 3: Call backend to complete the step ──────────────────────────
      final res = await _dataSource.completeStep(
        taskId,
        stepId,
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
        // _snack(
        //   taskDone ? '🎉 All steps done! Task completed!' : 'Step completed!',
        //   success: true,
        // );
        _clearCompletionState();
        await loadTask();

        if (context.mounted) {
          _snack(
            taskDone ? '🎉 All steps done! Task completed!' : 'Step completed!',
            success: true,
          );
        }

        // ── Stop tracking when entire task is done ─────────────────────
        if (taskDone) {
          await LocationBackgroundService.instance.stopTracking();
        }
      } else {
        if (context.mounted) {
          _snack(res?['message'] ?? 'Failed to complete step');
        }
      }
    } finally { _setAction(false); }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PHOTO / SIGNATURE  (unchanged)
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> capturePhoto() async {
    try {
      final xf = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
          maxWidth: 1280,
          maxHeight: 1280,
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
  void onSignatureReceived(String base64) { signatureBase64 = base64; reloadData(); }
  void clearSignature() { signatureBase64 = null; reloadData(); }

  // ═══════════════════════════════════════════════════════════════════════
  //  COMPUTED PROPERTIES
  // ═══════════════════════════════════════════════════════════════════════

  bool get isTaskPending => task?.status == 'pending';
  bool get isTaskActive  => task?.status == 'in_progress';
  bool get isTaskDone    =>
      task?.status == 'completed' || task?.status == 'cancelled';

  TaskStep? get activeStep {
    try {
      return task?.steps?.firstWhere((s) =>
      s.status == 'in_progress' ||
          s.status == 'travelling'  ||
          s.status == 'reached');
    } catch (_) { return null; }
  }

  // Kept for backwards compatibility — still used in some UI paths
  TaskStep? get activeFieldStep {
    try {
      return task?.steps?.firstWhere((s) =>
      (s.status == 'in_progress' ||
          s.status == 'travelling'  ||
          s.status == 'reached') &&
          s.isFieldWorkStep == true);
    } catch (_) { return null; }
  }

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
          perm == LocationPermission.deniedForever) return null;
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) { return null; }
  }

  void _snack(String msg, {bool success = false}) {
    if (!context.mounted) return;
    Helpers.showSnackBar(context, msg,
        type: success ? SnackType.success : SnackType.error);
  }

  // ── Label / color helpers (unchanged) ─────────────────────────────────

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
    // Background service lifecycle is managed globally — do NOT stop it here
  }
}