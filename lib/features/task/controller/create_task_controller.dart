import 'package:field_work/config/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/helpers.dart';
import '../../member/data/member_datasource.dart';
import '../../member/model/room_member_response.dart';
import '../data/manager_task_datasource.dart';
import '../model/task_form_models.dart';
import '../view/widgets/step_form_sheet.dart';

class CreateTaskController {
  final BuildContext context;
  final VoidCallback reloadData;
  final String roomId;
  final VoidCallback? onCreated;

  final _dataSource = ManagerTaskDatasource();

  bool isSubmitting      = false;
  bool isLoadingMembers  = false;

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
  });

  void init() async => getRoomMembers();

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
        'startDatetime':  startDatetime!.toIso8601String(),
        'endDatetime':    endDatetime!.toIso8601String(),
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