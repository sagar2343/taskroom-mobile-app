import 'package:field_work/config/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/helpers.dart';
import '../../../services/review_helper.dart';
import '../../member/data/member_datasource.dart';
import '../../member/model/room_member_response.dart';
import '../data/manager_task_datasource.dart';
import '../model/task_form_models.dart';
import '../model/task_model.dart';
import '../view/widgets/step_form_sheet.dart';

class CreateTaskController {
  final BuildContext context;
  final VoidCallback reloadData;
  final String roomId;
  final VoidCallback? onCreated;
  /// When set, the form is pre-filled from this (cancelled/expired) task —
  /// the manager tapped "Recreate Task". See _applyRecreateData().
  final TaskModel? recreateFrom;

  final _dataSource = ManagerTaskDatasource();

  bool isSubmitting      = false;
  bool isLoadingMembers  = false;
  bool isLoading = false;

  // ── Form: task-level fields ────────────────────────────────────────────
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController noteCtrl  = TextEditingController();
  String priority        = 'medium';

  /// When true the backend pings the employee's GPS every 30 s for the
  /// entire task duration. Sent as [isFieldWork] in the API body.
  bool trackLocation = false;

  DateTime? startDatetime;
  DateTime? endDatetime;

  final List<TaskFormStep> steps       = [];
  List<RoomMemberItem>     roomMembers = [];
  final Set<String>        selectedIds = {};

  CreateTaskController({
    required this.context,
    required this.reloadData,
    required this.roomId,
    this.onCreated,
    this.recreateFrom,
  });

  void init() async {
    await getRoomMembers();
    if (recreateFrom != null) _applyRecreateData();
  }

  Future<void> getRoomMembers() async {
    isLoadingMembers = true;
    reloadData();
    try {
      final response = await MemberDatasource().getRoomMembers(roomId);
      if (response?.success ?? false) {
        roomMembers = response?.data?.members ?? [];
      }
    } catch (e) {
      debugPrint('load members error: $e');
    }
    isLoadingMembers = false;
    reloadData();
  }

  // ── Recreate from a cancelled/expired task ─────────────────────────────────

  void _applyRecreateData() {
    isLoading = true;
    reloadData();
    final original = recreateFrom!;

    titleCtrl.text = original.title ?? '';
    noteCtrl.text  = original.note  ?? '';
    priority       = original.priority ?? 'medium';
    trackLocation  = original.isFieldWork ?? false;

    Duration shift = Duration.zero;

    final origStart = original.startDatetime;
    final origEnd   = original.endDatetime;
    if (origStart != null && origEnd != null) {
      final duration = origEnd.difference(origStart);
      final now      = DateTime.now();

      var newStart = DateTime(now.year, now.month, now.day, origStart.hour, origStart.minute);
      if (!newStart.isAfter(now)) {
        // That time slot already happened today — push to the same time
        // tomorrow instead of creating a task that starts in the past.
        newStart = newStart.add(const Duration(days: 1));
      }

      startDatetime = newStart;
      endDatetime   = newStart.add(duration);
      shift         = newStart.difference(origStart);
    }

    // Steps — same relative timing, shifted by the same amount as the task.
    for (final s in original.steps ?? <TaskStep>[]) {
      steps.add(TaskFormStep(
        title:       s.title ?? '',
        description: s.description ?? '',
        startDatetime: s.startDatetime != null ? s.startDatetime!.add(shift) : startDatetime,
        endDatetime:   s.endDatetime   != null ? s.endDatetime!.add(shift)   : endDatetime,
        latitude:  s.destinationLocation?.coordinates != null
            ? s.destinationLocation!.coordinates![1] : null,
        longitude: s.destinationLocation?.coordinates != null
            ? s.destinationLocation!.coordinates![0] : null,
        address:   s.destinationLocation?.address,
        locationRadiusMeters: s.locationRadiusMeters ?? 100,
        requirePhoto:         s.validations?.requirePhoto ?? false,
        requireSignature:     s.validations?.requireSignature ?? false,
        signatureFrom:        s.validations?.signatureFrom,
        requireLocationCheck: s.validations?.requireLocationCheck ?? false,
        requireLocationTrace: s.validations?.requireLocationTrace ?? trackLocation,
      ));
    }

    // Pre-select the original assignee, but only if they're still a member
    // of this room — they may have left since the task was created.
    final originalAssigneeId = original.assignedTo?.id;
    if (originalAssigneeId != null &&
        roomMembers.any((m) => m.user?.id == originalAssigneeId)) {
      selectedIds.add(originalAssigneeId);
    }
    isLoading = false;
    reloadData();
  }

  // ── Steps ────────────────────────────────────────────────────────────────

  void addStep() {
    steps.add(TaskFormStep(
      startDatetime:        startDatetime,
      endDatetime:          endDatetime,
      // Inherit live-trace setting from the task-level toggle.
      // The step form never shows this toggle — it's automatic.
      requireLocationTrace: trackLocation,
    ));
    reloadData();
  }

  void updateStep(TaskFormStep updated) {
    final i = steps.indexWhere((s) => s.localId == updated.localId);
    if (i != -1) { steps[i] = updated; reloadData(); }
  }

  void deleteStep(String localId) {
    steps.removeWhere((s) => s.localId == localId);
    reloadData();
  }

  void reorderSteps(int oldIdx, int newIdx) {
    if (newIdx > oldIdx) newIdx--;
    final step = steps.removeAt(oldIdx);
    steps.insert(newIdx, step);
    reloadData();
  }

  void addAndOpenStep() {
    addStep();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (steps.isNotEmpty) openStepSheet(steps.last);
    });
  }

  void openStepSheet(TaskFormStep step) {
    StepFormSheet.show(
      context,
      step:      step,
      taskStart: startDatetime,
      taskEnd:   endDatetime,
      onSave:    updateStep,
    );
  }

  // ── When the task-level toggle changes, update all existing steps ─────────

  void onTrackLocationToggled(bool value) {
    trackLocation = value;
    // Propagate the new requireLocationTrace to steps that haven't been
    // individually configured yet (i.e. those without a custom location check).
    for (int i = 0; i < steps.length; i++) {
      steps[i] = steps[i].copyWith(requireLocationTrace: value);
    }
    reloadData();
  }

  // ── Employee selection ────────────────────────────────────────────────────

  void toggleMember(String id) {
    selectedIds.contains(id) ? selectedIds.remove(id) : selectedIds.add(id);
    reloadData();
  }

  void selectAll() {
    selectedIds.addAll(roomMembers.map((m) => m.user!.id!));
    reloadData();
  }

  void clearAll() { selectedIds.clear(); reloadData(); }

  bool get allSelected =>
      roomMembers.isNotEmpty && selectedIds.length == roomMembers.length;

  // ── Date / time pickers ───────────────────────────────────────────────────

  Future<void> pickStart() async {
    final dt = await _pickDatetime(
      initial: startDatetime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
    );
    if (dt != null) {
      startDatetime = dt;
      if (endDatetime != null && endDatetime!.isBefore(dt)) endDatetime = null;
      reloadData();
    }
  }

  Future<void> pickEnd() async {
    final dt = await _pickDatetime(
      initial: endDatetime ?? startDatetime,
      firstDate: startDatetime ?? DateTime.now(),
    );
    if (dt != null) { endDatetime = dt; reloadData(); }
  }

  Future<DateTime?> _pickDatetime({
    DateTime? initial,
    required DateTime firstDate,
  }) async {
    final now        = initial ?? DateTime.now();
    final safeInitial = now.isBefore(firstDate) ? firstDate : now;

    final date = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: _pickerTheme,
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(safeInitial),
      builder: _pickerTheme,
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Widget Function(BuildContext, Widget?) get _pickerTheme =>
          (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: Pallete.primaryColor),
        ),
        child: child!,
      );

  // ── Validation ────────────────────────────────────────────────────────────

  String? validate() {
    if (titleCtrl.text.trim().isEmpty) return 'Task title is required';
    if (startDatetime == null) return 'Start date & time is required';
    if (endDatetime   == null) return 'End date & time is required';
    if (endDatetime!.isBefore(startDatetime!)) return 'End must be after start';
    if (steps.isEmpty) return 'Add at least one step';
    if (selectedIds.isEmpty) return 'Assign to at least one employee';
    for (int i = 0; i < steps.length; i++) {
      final err = steps[i].validationError;
      if (err != null) return 'Step ${i + 1}: $err';
    }
    return null;
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> submit() async {
    final err = validate();
    if (err != null) {
      Helpers.showSnackBar(context, err, type: SnackType.error);
      return;
    }

    isSubmitting = true;
    reloadData();

    try {
      final body = {
        'roomId':         roomId,
        'title':          titleCtrl.text.trim(),
        if (noteCtrl.text.trim().isNotEmpty) 'note': noteCtrl.text.trim(),
        'priority':       priority,
        'startDatetime':  startDatetime!.toUtc().toIso8601String(),
        'endDatetime':    endDatetime!.toUtc().toIso8601String(),
        // isFieldWork = "track live location" in the new mental model
        'isFieldWork':    trackLocation,
        'assignedTo':     selectedIds.toList(),
        'steps':          steps.map((s) => s.toApiJson()).toList(),
      };

      final response = await _dataSource.createTask(body);

      if (response == null) {
        Helpers.showSnackBar(context, 'Something went wrong.',
            type: SnackType.error);
        return;
      }

      if (response['success'] ?? false) {
        final n = selectedIds.length;
        onCreated?.call();
        if (context.mounted) Navigator.pop(context, true);
        Helpers.showSnackBar(
          context,
          n > 1 ? 'Task created for $n employees!' : 'Task created successfully!',
          type: SnackType.success,
        );

        // Manager just successfully created & assigned a task.
        ReviewHelper.requestReview();
      } else {
        Helpers.showSnackBar(context,
            response['message'] ?? 'Something went wrong!',
            type: SnackType.error);
      }
    } catch (e) {
      debugPrint('createTask error: $e');
      Helpers.showSnackBar(context,
          'Something went wrong. Please try again.',
          type: SnackType.error);
    } finally {
      isSubmitting = false;
      reloadData();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String formatDt(DateTime? dt) {
    if (dt == null) return 'Set';
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${mo[dt.month - 1]} · $h:$m $p';
  }

  void dispose() {
    titleCtrl.dispose();
    noteCtrl.dispose();
  }
}