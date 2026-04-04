import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/task/data/manager_task_datasource.dart';
import 'package:field_work/features/task/model/task_form_models.dart';
import 'package:field_work/features/task/model/task_model.dart';
import 'package:field_work/features/task/view/widgets/step_form_sheet.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════
//  STEP EDIT STATE
//  Wraps an existing TaskStep with a mutable overlay for the edit form.
// ═══════════════════════════════════════════════════════════════════════

/// What kind of edit is permitted on this step right now.
enum StepEditability {
  /// Step is pending — full edit allowed.
  full,

  /// Step is active (in_progress / travelling / reached) —
  /// only title, description, and endDatetime may change.
  limited,

  /// Step is completed, skipped, or the step before an active one that
  /// has already been passed — no changes allowed.
  locked,
}

class StepEditState {
  /// Original step from the server.
  final TaskStep original;

  /// Form-level mutable copy. Null means "use original value".
  TaskFormStep? draft;

  /// Unique key used as widget key in lists.
  final String localId;

  StepEditState({required this.original})
      : localId = original.stepId ?? DateTime.now().toIso8601String();

  /// Returns the effective title shown in the list.
  String get displayTitle =>
      (draft?.title.isNotEmpty == true)
          ? draft!.title
          : (original.title ?? 'Untitled Step');

  bool get isFieldWorkStep =>
      draft?.isFieldWorkStep ?? original.isFieldWorkStep ?? false;

  bool get isValid => draft?.isValid ?? true;

  String? get validationError => draft?.validationError;

  StepEditability editability(TaskModel task) {
    final s = original.status ?? 'pending';

    // Completed / skipped — permanently locked
    if (s == 'completed' || s == 'skipped') return StepEditability.locked;

    // Active — limited edit
    if (s == 'in_progress' || s == 'travelling' || s == 'reached') {
      return StepEditability.limited;
    }

    // Pending — check if a *later* active step exists (which would mean this
    // pending step was somehow skipped, but that's the backend's concern).
    return StepEditability.full;
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  CONTROLLER
// ═══════════════════════════════════════════════════════════════════════

class EditTaskController {
  final BuildContext context;
  final VoidCallback reloadData;
  final String taskId;
  final VoidCallback? onSaved;

  final ds = ManagerTaskDatasource();

  // ── Load state ─────────────────────────────────────────────────────────
  TaskModel? task;
  bool isLoading   = true;
  bool isSaving    = false;
  String? errorMsg;

  // ── Task-level form fields ──────────────────────────────────────────────
  late TextEditingController titleCtrl;
  late TextEditingController noteCtrl;
  String priority        = 'medium';
  bool   trackLocation   = false;
  DateTime? startDatetime;
  DateTime? endDatetime;

  // ── Steps ───────────────────────────────────────────────────────────────
  final List<StepEditState> stepStates = [];

  /// Pending new steps that haven't been saved yet.
  final List<TaskFormStep> newSteps = [];

  EditTaskController({
    required this.context,
    required this.reloadData,
    required this.taskId,
    this.onSaved,
  });

  // ═══════════════════════════════════════════════════════════════════════
  //  INIT / LOAD
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> init() async {
    isLoading = true;
    errorMsg  = null;
    reloadData();

    final res = await ds.getTaskDetail(taskId);
    if (res?.success == true && res!.data?.task != null) {
      task = res.data!.task!;
      _populateFromTask(task!);
    } else {
      errorMsg = res?.message ?? 'Failed to load task';
    }

    isLoading = false;
    reloadData();
  }

  void _populateFromTask(TaskModel t) {
    titleCtrl  = TextEditingController(text: t.title ?? '');
    noteCtrl   = TextEditingController(text: t.note  ?? '');
    priority       = t.priority      ?? 'medium';
    trackLocation  = t.isFieldWork   ?? false;
    startDatetime  = t.startDatetime;
    endDatetime    = t.endDatetime;

    stepStates.clear();
    for (final step in t.steps ?? <TaskStep>[]) {
      stepStates.add(StepEditState(original: step));
    }

    newSteps.clear();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  EDITABILITY GUARDS
  // ═══════════════════════════════════════════════════════════════════════

  /// True when any task-level field can be changed at all.
  bool get canEditTask {
    final s = task?.status ?? 'pending';
    return !['completed', 'cancelled'].contains(s);
  }

  /// True when the task hasn't started yet — allows full schedule edits.
  bool get isPending => task?.status == 'pending';

  /// True when the task is actively running.
  bool get isInProgress => task?.status == 'in_progress';

  /// Can we still add new steps?
  bool get canAddSteps =>
      canEditTask && !['completed', 'cancelled'].contains(task?.status ?? '');

  /// Can this existing step be removed?
  bool canRemoveStep(StepEditState ss) {
    if (stepStates.length + newSteps.length <= 1) return false; // must keep ≥1
    final e = ss.editability(task!);
    return e == StepEditability.full;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STEP ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  void openStepSheet(StepEditState ss) {
    if (!canEditTask) { snack('Task is ${task?.status} — edits not allowed'); return; }
    final e = ss.editability(task!);
    if (e == StepEditability.locked) {
      snack('This step is ${ss.original.status} and cannot be edited');
      return;
    }

    // Build a TaskFormStep pre-filled from either draft or original
    final orig = ss.original;
    final d    = ss.draft;
    final preloaded = TaskFormStep(
      localId:              ss.localId,
      title:                d?.title       ?? orig.title ?? '',
      description:          d?.description ?? orig.description ?? '',
      startDatetime:        d?.startDatetime ?? orig.startDatetime,
      endDatetime:          d?.endDatetime   ?? orig.endDatetime,
      latitude:             d?.latitude  ?? orig.destinationLocation?.coordinates?.let((c) => c.length > 1 ? c[1] : null),
      longitude:            d?.longitude ?? orig.destinationLocation?.coordinates?.let((c) => c.isNotEmpty ? c[0] : null),
      address:              d?.address   ?? orig.destinationLocation?.address,
      locationRadiusMeters: d?.locationRadiusMeters ?? orig.locationRadiusMeters ?? 100,
      requirePhoto:         d?.requirePhoto         ?? orig.validations?.requirePhoto         ?? false,
      requireSignature:     d?.requireSignature     ?? orig.validations?.requireSignature     ?? false,
      signatureFrom:        d?.signatureFrom        ?? orig.validations?.signatureFrom,
      requireLocationCheck: d?.requireLocationCheck ?? orig.validations?.requireLocationCheck ?? false,
      requireLocationTrace: d?.requireLocationTrace ?? orig.validations?.requireLocationTrace ?? false,
    );

    StepFormSheet.show(
      context,
      step:      preloaded,
      taskStart: startDatetime,
      taskEnd:   endDatetime,
      onSave:    (updated) {
        ss.draft = updated;
        reloadData();
      },
      // Pass editability so the sheet can grey out locked fields
      // (the sheet itself ignores fields it can't touch for limited edits)
    );
  }

  void addNewStep() {
    final newStep = TaskFormStep(
      startDatetime:        startDatetime,
      endDatetime:          endDatetime,
      requireLocationTrace: trackLocation,
    );
    newSteps.add(newStep);
    reloadData();

    // Open the sheet immediately for the new step
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openNewStepSheet(newSteps.last);
    });
  }

  void _openNewStepSheet(TaskFormStep step) {
    StepFormSheet.show(
      context,
      step:      step,
      taskStart: startDatetime,
      taskEnd:   endDatetime,
      onSave:    (updated) {
        final i = newSteps.indexWhere((s) => s.localId == updated.localId);
        if (i != -1) { newSteps[i] = updated; reloadData(); }
      },
    );
  }

  void editNewStep(TaskFormStep step) => _openNewStepSheet(step);

  void removeNewStep(String localId) {
    newSteps.removeWhere((s) => s.localId == localId);
    reloadData();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  DATE / TIME PICKERS
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> pickStart() async {
    if (!isPending) {
      snack('Start time cannot be changed once a task is in progress');
      return;
    }
    final dt = await _pickDatetime(
      initial:   startDatetime,
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
      initial:   endDatetime ?? startDatetime,
      firstDate: startDatetime ?? DateTime.now(),
    );
    if (dt != null) { endDatetime = dt; reloadData(); }
  }

  Future<DateTime?> _pickDatetime({DateTime? initial, required DateTime firstDate}) async {
    final now         = initial ?? DateTime.now();
    final safeInitial = now.isBefore(firstDate) ? firstDate : now;

    final date = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate:   firstDate,
      lastDate:    DateTime.now().add(const Duration(days: 730)),
      builder:     _pickerTheme,
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context:     context,
      initialTime: TimeOfDay.fromDateTime(safeInitial),
      builder:     _pickerTheme,
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Widget Function(BuildContext, Widget?) get _pickerTheme =>
          (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: Pallete.primaryColor),
        ),
        child: child!,
      );

  // ═══════════════════════════════════════════════════════════════════════
  //  TRACK LOCATION TOGGLE
  // ═══════════════════════════════════════════════════════════════════════

  void onTrackLocationToggled(bool value) {
    trackLocation = value;
    // Propagate to new (unsaved) steps
    for (int i = 0; i < newSteps.length; i++) {
      newSteps[i] = newSteps[i].copyWith(requireLocationTrace: value);
    }
    reloadData();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  VALIDATION
  // ═══════════════════════════════════════════════════════════════════════

  String? _validate() {
    if (!canEditTask) return 'Task is ${task?.status} — no changes allowed';
    if (titleCtrl.text.trim().isEmpty) return 'Task title is required';
    if (endDatetime == null) return 'End date & time is required';
    if (startDatetime != null && endDatetime!.isBefore(startDatetime!)) {
      return 'End time must be after start time';
    }

    // Check modified steps
    for (int i = 0; i < stepStates.length; i++) {
      final ss  = stepStates[i];
      final err = ss.validationError;
      if (err != null) return 'Step ${i + 1}: $err';
    }

    // Check new steps
    for (int i = 0; i < newSteps.length; i++) {
      final err = newSteps[i].validationError;
      if (err != null) return 'New Step ${i + 1}: $err';
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SAVE
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> save() async {
    final err = _validate();
    if (err != null) { snack(err); return; }

    isSaving = true;
    reloadData();

    try {
      final errors = <String>[];

      // ── 1. Update task-level fields ──────────────────────────────────
      final taskRes = await ds.editTask(
        taskId,
        title:         titleCtrl.text.trim(),
        note:          noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        priority:      priority,
        startDatetime: isPending ? startDatetime?.toIso8601String() : null,
        endDatetime:   endDatetime?.toIso8601String(),
      );
      if (taskRes?['success'] != true) {
        errors.add('Task fields: ${taskRes?['message'] ?? 'Update failed'}');
      }

      // ── 2. Update modified existing steps ────────────────────────────
      for (final ss in stepStates) {
        if (ss.draft == null) continue; // no changes
        final d        = ss.draft!;
        final e        = ss.editability(task!);
        if (e == StepEditability.locked) continue;

        final Map<String, dynamic> payload = {
          'title':       d.title,
          'description': d.description.isNotEmpty ? d.description : null,
          'endDatetime': d.endDatetime?.toIso8601String(),
        };

        // Full edits only for pending steps
        if (e == StepEditability.full) {
          payload['startDatetime'] = d.startDatetime?.toIso8601String();
          payload['isFieldWorkStep'] = d.isFieldWorkStep;
          if (d.isFieldWorkStep && d.hasLocation) {
            payload['destinationLocation'] = {
              'coordinates': [d.longitude!, d.latitude!],
              if (d.address != null) 'address': d.address,
            };
          }
          payload['locationRadiusMeters'] = d.locationRadiusMeters;
          payload['validations'] = {
            'requirePhoto':         d.requirePhoto,
            'requireSignature':     d.requireSignature,
            if (d.requireSignature && d.signatureFrom != null)
              'signatureFrom':      d.signatureFrom,
            'requireLocationCheck': d.requireLocationCheck,
            'requireLocationTrace': d.requireLocationTrace,
          };
        }

        final stepRes = await ds.editStep(
          taskId, ss.original.stepId!,
          title:               payload['title'] as String?,
          description:         payload['description'] as String?,
          startDatetime:       payload['startDatetime'] as String?,
          endDatetime:         payload['endDatetime'] as String?,
          isFieldWorkStep:     payload['isFieldWorkStep'] as bool?,
          destinationLocation: payload['destinationLocation'] as Map<String, dynamic>?,
          locationRadiusMeters:payload['locationRadiusMeters'] as int?,
          validations:         payload['validations'] as Map<String, dynamic>?,
        );
        if (stepRes?['success'] != true) {
          errors.add('Step "${ss.original.title}": ${stepRes?['message'] ?? 'Update failed'}');
        }
      }

      // ── 3. Add new steps ─────────────────────────────────────────────
      for (final ns in newSteps) {
        if (!ns.isValid) continue;
        final addRes = await ds.addStep(
          taskId,
          title:               ns.title,
          description:         ns.description.isNotEmpty ? ns.description : null,
          startDatetime:       ns.startDatetime!.toIso8601String(),
          endDatetime:         ns.endDatetime!.toIso8601String(),
          isFieldWorkStep:     ns.isFieldWorkStep,
          destinationLocation: ns.isFieldWorkStep && ns.hasLocation
              ? {
            'coordinates': [ns.longitude!, ns.latitude!],
            if (ns.address != null) 'address': ns.address,
          }
              : null,
          locationRadiusMeters: ns.locationRadiusMeters,
          validations: {
            'requirePhoto':         ns.requirePhoto,
            'requireSignature':     ns.requireSignature,
            if (ns.requireSignature && ns.signatureFrom != null)
              'signatureFrom':      ns.signatureFrom,
            'requireLocationCheck': ns.requireLocationCheck,
            'requireLocationTrace': ns.requireLocationTrace,
          },
        );
        if (addRes?['success'] != true) {
          errors.add('New step "${ns.title}": ${addRes?['message'] ?? 'Add failed'}');
        }
      }

      isSaving = false;
      reloadData();

      if (errors.isEmpty) {
        onSaved?.call();
        if (context.mounted) Navigator.pop(context, true);
        snack('Task updated successfully!', success: true);
      } else {
        // Partial success — show first error, stay on page
        snack('Some changes failed: ${errors.first}');
        await init(); // reload latest state from server
      }

    } catch (e) {
      isSaving = false;
      reloadData();
      snack('Something went wrong. Please try again.');
      debugPrint('EditTask save error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  String formatDt(DateTime? dt) {
    if (dt == null) return 'Set';
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${mo[dt.month - 1]} · $h:$m $p';
  }

  void snack(String msg, {bool success = false}) {
    if (!context.mounted) return;
    Helpers.showSnackBar(context, msg,
        type: success ? SnackType.success : SnackType.error);
  }

  void dispose() {
    titleCtrl.dispose();
    noteCtrl.dispose();
  }
}

// ignore: avoid_classes_with_only_static_members
extension _NullableExt<T> on T? {
  R? let<R>(R? Function(T) fn) => this == null ? null : fn(this as T);
}