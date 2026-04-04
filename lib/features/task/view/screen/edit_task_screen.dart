import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/task/controller/edit_task_controller.dart';
import 'package:field_work/features/task/model/task_form_models.dart';
import 'package:field_work/features/task/model/task_model.dart';
import 'package:field_work/features/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';

class EditTaskScreen extends StatefulWidget {
  final String taskId;
  final VoidCallback? onTaskUpdated;

  const EditTaskScreen({
    super.key,
    required this.taskId,
    this.onTaskUpdated,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late final EditTaskController _c;

  @override
  void initState() {
    super.initState();
    _c = EditTaskController(
      context:    context,
      reloadData: _reload,
      taskId:     widget.taskId,
      onSaved:    widget.onTaskUpdated,
    );
    _c.init();
  }

  void _reload() { if (mounted) setState(() {}); }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  // ═══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ── Loading ────────────────────────────────────────────────────────
    if (_c.isLoading) {
      return Scaffold(
        appBar: _buildAppBar(theme, hasTask: false),
        body: const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Pallete.primaryColor)),
        ),
      );
    }

    // ── Error ──────────────────────────────────────────────────────────
    if (_c.errorMsg != null || _c.task == null) {
      return Scaffold(
        appBar: _buildAppBar(theme, hasTask: false),
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: Pallete.kRed),
            const SizedBox(height: 12),
            Text(_c.errorMsg ?? 'Task not found', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _c.init,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(backgroundColor: Pallete.primaryColor),
            ),
          ],
        )),
      );
    }

    // ── Completed / cancelled guard ────────────────────────────────────
    if (!_c.canEditTask) {
      return Scaffold(
        appBar: _buildAppBar(theme, hasTask: true),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  shape: BoxShape.circle),
              child: const Icon(Icons.lock_rounded, size: 48, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text('Task is ${_c.task!.status}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 8),
            Text(
              'Completed and cancelled tasks cannot be edited.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.withValues(alpha: 0.7)),
            ),
          ]),
        )),
      );
    }

    final task = _c.task!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: _buildAppBar(theme, hasTask: true),
        body: Column(children: [

          // ── Status banner (shown when task is in_progress) ───────────
          if (_c.isInProgress) _StatusBanner(task: task),

          Expanded(
            child: CustomScrollView(slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ── Task Details card ──────────────────────────────────────
              SliverToBoxAdapter(child: _buildCard(
                icon: Icons.assignment_rounded,
                title: 'Task Details',
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _formLbl('TITLE *'),
                    CustomTextField(
                      controller: _c.titleCtrl,
                      hint: 'e.g. Deliver Order to Site C',
                    ),

                    const SizedBox(height: 14),

                    _formLbl('NOTE'),
                    CustomTextField(
                      controller: _c.noteCtrl,
                      hint: 'Extra instructions for the employee...',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    // Priority
                    _formLbl('PRIORITY'),
                    Row(children: [
                      for (final p in ['low', 'medium', 'high'])
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: p != 'high' ? 8 : 0),
                            child: _PriorityBtn(
                              label: p[0].toUpperCase() + p.substring(1),
                              value: p,
                              selected: _c.priority == p,
                              onTap: () { _c.priority = p; _reload(); },
                            ),
                          ),
                        ),
                    ]),

                    const SizedBox(height: 16),

                    // Schedule
                    _formLbl('SCHEDULE'),
                    Row(children: [
                      Expanded(child: _dateBtn(
                        'START',
                        _c.formatDt(_c.startDatetime),
                        _c.startDatetime != null,
                        _c.isPending
                            ? () async { await _c.pickStart(); }
                            : null, // locked once started
                        locked: !_c.isPending,
                        lockReason: 'Start time is locked once a task begins',
                      )),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.east_rounded, size: 14,
                            color: Colors.grey.withValues(alpha: 0.5)),
                      ),
                      Expanded(child: _dateBtn(
                        'END',
                        _c.formatDt(_c.endDatetime),
                        _c.endDatetime != null,
                            () async { await _c.pickEnd(); },
                      )),
                    ]),

                    const SizedBox(height: 16),

                    // Track location toggle
                    _TrackLocationToggle(
                      value: _c.trackLocation,
                      onChanged: _c.onTrackLocationToggled,
                    ),
                  ],
                ),
              )),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // ── Steps card ─────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildCard(
                icon: Icons.checklist_rtl_rounded,
                title: 'Steps',
                badge: '${_c.stepStates.length + _c.newSteps.length}',
                isDark: isDark,
                child: Column(children: [

                  // ── Existing steps ────────────────────────────────────
                  ...List.generate(_c.stepStates.length, (i) {
                    final ss = _c.stepStates[i];
                    final e  = ss.editability(_c.task!);
                    return _ExistingStepRow(
                      ss:       ss,
                      index:    i,
                      task:     task,
                      editability: e,
                      canRemove: _c.canRemoveStep(ss),
                      onEdit:   () => _c.openStepSheet(ss),
                      onRemove: () async {
                        final confirmed = await _confirmRemove(
                            context, ss.displayTitle);
                        if (confirmed == true) {
                          final res = await _c.ds.removeStep(
                              _c.taskId, ss.original.stepId!);
                          if (res?['success'] == true) {
                            _c.stepStates.remove(ss);
                            _reload();
                          } else {
                            _c.snack(res?['message'] ?? 'Could not remove step');
                          }
                        }
                      },
                    );
                  }),

                  // ── New (unsaved) steps ───────────────────────────────
                  ...List.generate(_c.newSteps.length, (i) {
                    final ns = _c.newSteps[i];
                    return _NewStepRow(
                      step:     ns,
                      index:    _c.stepStates.length + i,
                      onEdit:   () => _c.editNewStep(ns),
                      onDelete: () { _c.removeNewStep(ns.localId); },
                    );
                  }),

                  const SizedBox(height: 10),

                  // Add new step button
                  if (_c.canAddSteps)
                    GestureDetector(
                      onTap: _c.addNewStep,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Pallete.primaryColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Pallete.primaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline_rounded,
                                size: 18, color: Pallete.primaryColor),
                            const SizedBox(width: 7),
                            Text('Add New Step',
                                style: TextStyle(
                                    color: Pallete.primaryColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                ]),
              )),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ]),
          ),

          // ── Bottom save button ───────────────────────────────────────
          _SaveBar(controller: _c, isDark: isDark),
        ]),
      ),
    );
  }

  Future<bool?> _confirmRemove(BuildContext ctx, String title) =>
      showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Remove Step?',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: Text('Remove "$title"? This cannot be undone.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Pallete.kRed, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════
  //  SMALL BUILDERS
  // ═══════════════════════════════════════════════════════════════════════

  AppBar _buildAppBar(ThemeData theme, {required bool hasTask}) => AppBar(
    elevation: 0,
    leading: Padding(
      padding: const EdgeInsets.all(10),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.close_rounded, size: 20),
        ),
      ),
    ),
    title: Column(children: [
      Text('Edit Task',
          style: theme.textTheme.titleMedium!
              .copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      if (hasTask && _c.task != null)
        Text(
          _c.task!.title ?? '',
          style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
    ]),
    centerTitle: true,
  );

  Widget _formLbl(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: Colors.grey.withValues(alpha: 0.55))),
  );

  Widget _dateBtn(
      String label,
      String value,
      bool isSet,
      VoidCallback? onTap, {
        bool locked = false,
        String? lockReason,
      }) {
    return Tooltip(
      message: locked ? (lockReason ?? '') : '',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: locked
                ? Colors.grey.withValues(alpha: 0.05)
                : isSet
                ? Pallete.primaryColor.withValues(alpha: 0.08)
                : Colors.grey.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: locked
                  ? Colors.grey.withValues(alpha: 0.12)
                  : isSet
                  ? Pallete.primaryColor.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.15),
              width: isSet && !locked ? 1.5 : 1,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.grey.withValues(alpha: 0.6))),
              if (locked) ...[
                const SizedBox(width: 4),
                Icon(Icons.lock_rounded, size: 9,
                    color: Colors.grey.withValues(alpha: 0.4)),
              ],
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.access_time_rounded, size: 12,
                  color: locked ? Colors.grey.withValues(alpha: 0.35)
                      : isSet ? Pallete.primaryColor : Colors.grey),
              const SizedBox(width: 5),
              Flexible(child: Text(value,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: locked
                          ? Colors.grey.withValues(alpha: 0.4)
                          : isSet ? null : Colors.grey.withValues(alpha: 0.4)),
                  overflow: TextOverflow.ellipsis)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Widget child,
    required bool isDark,
    String? badge,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14142A) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: Pallete.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: Pallete.primaryColor, size: 16),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14, letterSpacing: -0.2)),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: Pallete.primaryColor,
                        borderRadius: BorderRadius.circular(99)),
                    child: Text(badge,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: child,
            ),
          ]),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════
//  STATUS BANNER  — shown when task is in_progress
// ═══════════════════════════════════════════════════════════════════════

class _StatusBanner extends StatelessWidget {
  final TaskModel task;
  const _StatusBanner({required this.task});

  @override
  Widget build(BuildContext context) {
    final done  = task.completedSteps ?? 0;
    final total = task.totalSteps     ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Pallete.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Pallete.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: Pallete.primaryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9)),
          child: const Icon(Icons.play_circle_rounded,
              size: 16, color: Pallete.primaryColor),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Task is in progress',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13,
                    color: Pallete.primaryColor)),
            Text(
              'Completed/active steps are locked. '
                  '$done of $total steps done.',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.withValues(alpha: 0.65)),
            ),
          ],
        )),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  EXISTING STEP ROW
// ═══════════════════════════════════════════════════════════════════════

class _ExistingStepRow extends StatelessWidget {
  final StepEditState       ss;
  final int                 index;
  final TaskModel           task;
  final StepEditability     editability;
  final bool                canRemove;
  final VoidCallback        onEdit;
  final VoidCallback        onRemove;

  const _ExistingStepRow({
    required this.ss, required this.index, required this.task,
    required this.editability, required this.canRemove,
    required this.onEdit, required this.onRemove,
  });

  static const _kGreen  = Color(0xFF10B981);
  static const _kAmber  = Color(0xFFF59E0B);
  static const _kRed    = Color(0xFFEF4444);

  Color get _accentForStatus {
    final s = ss.original.status ?? 'pending';
    return switch (s) {
      'completed'                => _kGreen,
      'in_progress' || 'reached' || 'travelling' => Pallete.primaryColor,
      'skipped'                  => Colors.grey,
      _                          => Pallete.primaryColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDirty     = ss.draft != null;
    final isInvalid   = isDirty && !ss.isValid;
    final accent      = _accentForStatus;
    final statusStr   = ss.original.status ?? 'pending';

    // Border color: red if invalid, accent if dirty, default otherwise
    final borderColor = isInvalid
        ? _kRed.withValues(alpha: 0.5)
        : isDirty
        ? Pallete.primaryColor.withValues(alpha: 0.4)
        : accent.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minLeadingWidth: 20,
          leading: _StepNumberBadge(
              index: index, status: statusStr, accent: accent),
          title: Row(children: [
            Expanded(
              child: Text(
                ss.displayTitle,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13,
                    color: statusStr == 'completed' || statusStr == 'skipped'
                        ? Colors.grey.withValues(alpha: 0.5) : null),
              ),
            ),
            if (isDirty && !isInvalid)
              _EditedBadge(),
          ]),
          subtitle: _StepSubtitle(
              ss: ss, editability: editability, isInvalid: isInvalid),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            // Edit button
            if (editability != StepEditability.locked)
              _SmallBtn(
                icon:  Icons.edit_rounded,
                color: Pallete.primaryColor,
                onTap: onEdit,
              ),
            const SizedBox(width: 4),
            // Remove button
            if (canRemove)
              _SmallBtn(
                icon:  Icons.delete_outline_rounded,
                color: _kRed,
                onTap: onRemove,
              )
            else
              Tooltip(
                message: editability == StepEditability.locked
                    ? 'Completed/active steps cannot be removed'
                    : 'Must keep at least one step',
                child: _SmallBtn(
                  icon:  Icons.lock_rounded,
                  color: Colors.grey.withValues(alpha: 0.4),
                  onTap: null,
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _StepNumberBadge extends StatelessWidget {
  final int    index;
  final String status;
  final Color  accent;
  const _StepNumberBadge({required this.index, required this.status, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDone = status == 'completed' || status == 'skipped';
    return Container(
      width: 36, height: 38,
      decoration: BoxDecoration(
        color: isDone ? accent : accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : Text('${index + 1}',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: accent, fontSize: 15)),
      ),
    );
  }
}

class _StepSubtitle extends StatelessWidget {
  final StepEditState ss;
  final StepEditability editability;
  final bool isInvalid;
  const _StepSubtitle({required this.ss, required this.editability, required this.isInvalid});

  static const _kRed = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final label = switch (editability) {
      StepEditability.full    => 'Pending · Full edit',
      StepEditability.limited => 'Active · Limited edit (title, desc, end time)',
      StepEditability.locked  => 'Locked · ${ss.original.status}',
    };
    final color = switch (editability) {
      StepEditability.full    => Pallete.primaryColor,
      StepEditability.limited => const Color(0xFFF59E0B),
      StepEditability.locked  => Colors.grey,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(
              editability == StepEditability.locked
                  ? Icons.lock_rounded
                  : editability == StepEditability.limited
                  ? Icons.edit_off_rounded
                  : Icons.edit_rounded,
              size: 11, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700), maxLines: 2,),
          ),
        ]),
        if (isInvalid)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, size: 11, color: _kRed),
              const SizedBox(width: 3),
              Text(ss.validationError ?? 'Incomplete',
                  style: const TextStyle(
                      fontSize: 10, color: _kRed, fontWeight: FontWeight.w700)),
            ]),
          ),
      ],
    );
  }
}

class _EditedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 6),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
        color: Pallete.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5)),
    child: const Text('Edited',
        style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w800,
            color: Pallete.primaryColor)),
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  NEW STEP ROW
// ═══════════════════════════════════════════════════════════════════════

class _NewStepRow extends StatelessWidget {
  final TaskFormStep step;
  final int index;
  final VoidCallback onEdit, onDelete;

  const _NewStepRow({
    required this.step, required this.index,
    required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final valid = step.isValid;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Pallete.primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: valid
                ? Pallete.primaryColor.withValues(alpha: 0.35)
                : const Color(0xFFEF4444).withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          leading: Container(
            width: 36, height: 38,
            decoration: BoxDecoration(
                color: Pallete.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Text('${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Pallete.primaryColor, fontSize: 15)),
            ),
          ),
          title: Row(children: [
            Expanded(
              child: Text(
                step.title.isEmpty ? 'New step (tap to configure)' : step.title,
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13,
                    color: step.title.isEmpty
                        ? Colors.grey.withValues(alpha: 0.55) : null),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Pallete.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5)),
              child: const Text('NEW',
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w900,
                      color: Pallete.primaryColor)),
            ),
          ]),
          subtitle: Row(children: [
            if (!valid) ...[
              const Icon(Icons.warning_amber_rounded,
                  size: 11, color: Color(0xFFEF4444)),
              const SizedBox(width: 3),
              Text(step.validationError ?? 'Incomplete',
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w700)),
            ] else ...[
              const Icon(Icons.check_circle_rounded,
                  size: 11, color: Color(0xFF10B981)),
              const SizedBox(width: 3),
              const Text('Ready to save',
                  style: TextStyle(
                      fontSize: 10, color: Color(0xFF10B981),
                      fontWeight: FontWeight.w700)),
            ],
          ]),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            _SmallBtn(
                icon: Icons.edit_rounded,
                color: Pallete.primaryColor,
                onTap: onEdit),
            const SizedBox(width: 4),
            _SmallBtn(
                icon: Icons.delete_outline_rounded,
                color: const Color(0xFFEF4444),
                onTap: onDelete),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  TRACK LOCATION TOGGLE
// ═══════════════════════════════════════════════════════════════════════

class _TrackLocationToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _TrackLocationToggle({required this.value, required this.onChanged});

  static const _kBlue = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: value
            ? _kBlue.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: value
                ? _kBlue.withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.15),
            width: value ? 1.5 : 1),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: (value ? _kBlue : Colors.grey).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.location_searching_rounded,
              color: value ? _kBlue : Colors.grey, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Track Employee Location',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13,
                    color: value ? _kBlue : Colors.grey)),
            Text('Pings live GPS every 30 s for the full task duration',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.withValues(alpha: 0.65))),
          ],
        )),
        Switch.adaptive(
            value: value, onChanged: onChanged,
            activeColor: _kBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  SAVE BAR
// ═══════════════════════════════════════════════════════════════════════

class _SaveBar extends StatelessWidget {
  final EditTaskController controller;
  final bool isDark;
  const _SaveBar({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
        16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF0C0C18) : Colors.white,
      border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
    ),
    child: GestureDetector(
      onTap: controller.isSaving ? null : controller.save,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: controller.isSaving
              ? null
              : const LinearGradient(
              colors: [Pallete.primaryLightColor, Pallete.primaryColor]),
          color: controller.isSaving
              ? Colors.grey.withValues(alpha: 0.15) : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: controller.isSaving ? null : [
            BoxShadow(
                color: Pallete.primaryColor.withValues(alpha: 0.4),
                blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: controller.isSaving
            ? const Center(child: SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(Colors.white))))
            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.save_rounded, color: Colors.white, size: 19),
          SizedBox(width: 10),
          Text('Save Changes',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800,
                  fontSize: 15, letterSpacing: -0.2)),
        ]),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  PRIORITY BUTTON (reused from create screen)
// ═══════════════════════════════════════════════════════════════════════

class _PriorityBtn extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _PriorityBtn({required this.label, required this.value,
    required this.selected, required this.onTap});

  Color get _c => switch (value) {
    'high' => const Color(0xFFEF4444),
    'low'  => const Color(0xFF22C55E),
    _      => const Color(0xFFF59E0B),
  };

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: selected ? _c.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: selected ? _c : Colors.grey.withValues(alpha: 0.15),
            width: selected ? 1.5 : 1),
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800,
                color: selected ? _c : Colors.grey)),
      ),
    ),
  );
}

// ─── Small icon button ────────────────────────────────────────────────

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _SmallBtn({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 15, color: color),
    ),
  );
}