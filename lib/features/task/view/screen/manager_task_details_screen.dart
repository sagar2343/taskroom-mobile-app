import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/task/model/task_model.dart';
import 'package:flutter/material.dart';
import '../../../employee_task/data/task_action_datasource.dart';

class ManagerTaskDetailScreen extends StatefulWidget {
  final String taskId;
  final VoidCallback? onTaskUpdated;

  const ManagerTaskDetailScreen({
    super.key,
    required this.taskId,
    this.onTaskUpdated,
  });

  @override
  State<ManagerTaskDetailScreen> createState() => _ManagerTaskDetailScreenState();
}

class _ManagerTaskDetailScreenState extends State<ManagerTaskDetailScreen> {
  final _ds = TaskActionDataSource();

  TaskModel? _task;
  bool _isLoading = true;
  bool _isCancelling = false;
  String? _error;

  static const _kPurple = Color(0xFF6C63FF);
  static const _kGreen = Color(0xFF10B981);
  static const _kAmber = Color(0xFFF59E0B);
  static const _kRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    final res = await _ds.getTaskDetail(widget.taskId);
    if (res?.success == true) {
      _task = res!.data!.task;
    } else {
      _error = res?.message ?? 'Failed to load task';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _cancelTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Task?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('The employee will be notified. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep Task')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Task'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isCancelling = true);
    final res = await _ds.cancelTask(widget.taskId);
    setState(() => _isCancelling = false);

    if (res?['success'] == true) {
      Helpers.showSnackBar(context, 'Task cancelled', type: SnackType.success);
      widget.onTaskUpdated?.call();
      await _load();
    } else {
      Helpers.showSnackBar(context, res?['message'] ?? 'Failed to cancel', type: SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Detail')),
        body: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(_kPurple))),
      );
    }

    if (_error != null || _task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Detail')),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline_rounded, size: 56, color: _kRed),
          const SizedBox(height: 12),
          Text(_error ?? 'Task not found', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ])),
      );
    }

    final task = _task!;
    final statusColor = _statusColor(task.status);
    final canCancel = !['completed', 'cancelled'].contains(task.status);
    final progress = (task.totalSteps ?? 0) > 0
        ? (task.completedSteps ?? 0) / task.totalSteps!
        : 0.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A16) : const Color(0xFFF5F5FF),
      body: RefreshIndicator(
        onRefresh: _load,
        color: _kPurple,
        child: CustomScrollView(
          slivers: [
            // ── App Bar
            SliverAppBar(
              pinned: true,
              expandedHeight: 220,
              backgroundColor: isDark ? const Color(0xFF0A0A16) : const Color(0xFFF5F5FF),
              leading: Padding(
                padding: const EdgeInsets.all(10),
                child: GestureDetector(
                  onTap: () { widget.onTaskUpdated?.call(); Navigator.pop(context); },
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                  ),
                ),
              ),
              actions: [
                if (canCancel)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: _isCancelling ? null : _cancelTask,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _kRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kRed.withValues(alpha: 0.3)),
                        ),
                        child: _isCancelling
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(_kRed)))
                            : const Text('Cancel Task', style: TextStyle(color: _kRed, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        statusColor.withValues(alpha: 0.85),
                        statusColor.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.5, 1],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(children: [
                          _Pill(_statusLabel(task.status).toUpperCase()),
                          const SizedBox(width: 8),
                          _Pill(_priorityEmoji(task.priority) + ' ' + _capitalize(task.priority ?? 'medium')),
                          if (task.isFieldWork == true) ...[
                            const SizedBox(width: 8),
                            _Pill('📍 Field Work'),
                          ],
                        ]),
                        const SizedBox(height: 10),
                        Text(
                          task.title ?? 'Untitled Task',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.2, shadows: [Shadow(color: Colors.black38, blurRadius: 8)]),
                          maxLines: 2,
                        ),
                        if (task.room != null) ...[
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.meeting_room_rounded, size: 13, color: Colors.white70),
                            const SizedBox(width: 5),
                            Text(task.room?.name ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Employee card
                  if (task.assignedTo != null) _buildEmployeeCard(task, isDark),
                  const SizedBox(height: 12),

                  // ── Schedule + progress
                  _buildScheduleCard(task, progress, isDark),
                  const SizedBox(height: 12),

                  // ── Note
                  if (task.note?.isNotEmpty == true) ...[
                    _buildNoteCard(task, isDark),
                    const SizedBox(height: 12),
                  ],

                  // ── Steps
                  _buildStepsCard(task, isDark),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  CARDS
  // ─────────────────────────────────────────────────────────

  Widget _buildEmployeeCard(TaskModel task, bool isDark) {
    final user = task.assignedTo!;
    return _Card(
      isDark: isDark,
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _kPurple.withValues(alpha: 0.15),
                backgroundImage: user.profilePicture != null ? NetworkImage(user.profilePicture!) : null,
                child: user.profilePicture == null
                    ? Text((user.fullName ?? user.username ?? '?')[0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kPurple))
                    : null,
              ),
              if (user.isOnline == true)
                Positioned(
                  right: 1, bottom: 1,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: _kGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF141428) : Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ASSIGNED TO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(user.fullName ?? user.username ?? 'Employee', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                if (user.username != null)
                  Text('@${user.username}', style: TextStyle(fontSize: 11, color: Colors.grey.withValues(alpha: 0.6))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (user.isOnline == true ? _kGreen : Colors.grey).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  user.isOnline == true ? 'Online' : 'Offline',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: user.isOnline == true ? _kGreen : Colors.grey),
                ),
              ),
              if (task.isGroupTask == true) ...[
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Group Task', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6))),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(TaskModel task, double progress, bool isDark) {
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel('SCHEDULE & PROGRESS'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _TimeBlock(label: 'Start', dt: task.startDatetime, icon: Icons.play_arrow_rounded, color: _kPurple)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.east_rounded, size: 16, color: Colors.grey.withValues(alpha: 0.4)),
              ),
              Expanded(child: _TimeBlock(label: 'Deadline', dt: task.endDatetime, icon: Icons.flag_rounded, color: _kAmber, isDeadline: true)),
            ],
          ),
          if ((task.totalSteps ?? 0) > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${task.completedSteps ?? 0} of ${task.totalSteps} steps done', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.withValues(alpha: 0.7))),
                      Text('${(progress * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _progressColor(progress))),
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(_progressColor(progress)),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ],
          if (task.employeeStartTime != null) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.grey.withValues(alpha: 0.1)),
            const SizedBox(height: 8),
            _TimelineRow(label: 'Employee started', dt: task.employeeStartTime, icon: Icons.play_circle_outline_rounded, color: _kPurple),
          ],
          if (task.completedAt != null) ...[
            const SizedBox(height: 6),
            _TimelineRow(label: 'Completed', dt: task.completedAt, icon: Icons.check_circle_outline_rounded, color: _kGreen),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteCard(TaskModel task, bool isDark) {
    return _Card(
      isDark: isDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sticky_note_2_rounded, size: 18, color: _kAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _CardLabel('TASK NOTE'),
              const SizedBox(height: 4),
              Text(task.note!, style: const TextStyle(fontSize: 13, height: 1.5)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard(TaskModel task, bool isDark) {
    final steps = task.steps ?? [];
    if (steps.isEmpty) return const SizedBox.shrink();

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const _CardLabel('STEPS'),
            const Spacer(),
            Text('${task.completedSteps ?? 0}/${task.totalSteps ?? 0}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _kPurple)),
          ]),
          const SizedBox(height: 12),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final isLast = i == steps.length - 1;
            final stepColor = _stepColor(step.status);
            final isDone = step.status == 'completed' || step.status == 'skipped';
            final isActive = step.status == 'in_progress' || step.status == 'reached';

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline
                  Column(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: isDone ? stepColor : stepColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: stepColor, width: isActive ? 2 : 1.5),
                          boxShadow: isActive ? [BoxShadow(color: stepColor.withValues(alpha: 0.4), blurRadius: 8)] : null,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                              : Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isActive ? stepColor : Colors.grey)),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 3), color: isDone ? stepColor.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.15)),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isActive ? stepColor.withValues(alpha: 0.07) : Colors.grey.withValues(alpha: isDark ? 0.05 : 0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isActive ? stepColor.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(step.title ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDone ? Colors.grey : null)),
                              ),
                              _StepStatusPill(status: step.status, color: stepColor),
                            ]),
                            if (step.isFieldWorkStep == true && step.destinationLocation?.address != null) ...[
                              const SizedBox(height: 5),
                              Row(children: [
                                const Icon(Icons.location_on_rounded, size: 11, color: _kGreen),
                                const SizedBox(width: 4),
                                Expanded(child: Text(step.destinationLocation!.address!, style: const TextStyle(fontSize: 10, color: _kGreen, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ]),
                            ],
                            // Employee timing (if started)
                            if (step.employeeStartTime != null) ...[
                              const SizedBox(height: 4),
                              Row(children: [
                                Icon(Icons.play_arrow_rounded, size: 10, color: Colors.grey.withValues(alpha: 0.5)),
                                const SizedBox(width: 3),
                                Text('Started ${_fmtTime(step.employeeStartTime)}', style: TextStyle(fontSize: 10, color: Colors.grey.withValues(alpha: 0.5))),
                                if (step.employeeCompleteTime != null) ...[
                                  Text('  →  ', style: TextStyle(fontSize: 10, color: Colors.grey.withValues(alpha: 0.4))),
                                  Icon(Icons.check_rounded, size: 10, color: Colors.grey.withValues(alpha: 0.5)),
                                  const SizedBox(width: 3),
                                  Text(_fmtTime(step.employeeCompleteTime), style: TextStyle(fontSize: 10, color: Colors.grey.withValues(alpha: 0.5))),
                                  if (step.isOverdue == true)
                                    Text('  OVERDUE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _kRed.withValues(alpha: 0.8))),
                                ],
                              ]),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────

  Color _statusColor(String? s) => switch (s) {
    'in_progress' => _kPurple,
    'completed' => _kGreen,
    'overdue' => _kRed,
    'cancelled' => Colors.grey,
    _ => _kAmber,
  };

  Color _stepColor(String? s) => switch (s) {
    'completed' => _kGreen,
    'in_progress' || 'reached' => _kPurple,
    'skipped' => Colors.grey,
    _ => Colors.grey,
  };

  Color _progressColor(double p) {
    if (p >= 1.0) return _kGreen;
    if (p >= 0.5) return _kPurple;
    return _kAmber;
  }

  String _statusLabel(String? s) => switch (s) {
    'in_progress' => 'In Progress',
    'completed' => 'Completed',
    'overdue' => 'Overdue',
    'cancelled' => 'Cancelled',
    _ => 'Pending',
  };

  String _priorityEmoji(String? p) => switch (p) { 'high' => '🔴', 'low' => '🟢', _ => '🟡' };
  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _fmtTime(DateTime? dt) {
    if (dt == null) return '--';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF141428) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: child,
  );
}

class _CardLabel extends StatelessWidget {
  final String text;
  const _CardLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.7, color: Colors.grey.withValues(alpha: 0.5)),
  );
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

class _TimeBlock extends StatelessWidget {
  final String label;
  final DateTime? dt;
  final IconData icon;
  final Color color;
  final bool isDeadline;
  const _TimeBlock({required this.label, required this.dt, required this.icon, required this.color, this.isDeadline = false});

  @override
  Widget build(BuildContext context) {
    final isOverdue = isDeadline && dt != null && dt!.isBefore(DateTime.now());
    final effectiveColor = isOverdue ? const Color(0xFFEF4444) : color;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 13, color: effectiveColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: effectiveColor.withValues(alpha: 0.7))),
        ]),
        const SizedBox(height: 5),
        if (dt != null) ...[
          Text(_fmtDate(dt!), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: effectiveColor)),
          Text(_fmtTime(dt!), style: TextStyle(fontSize: 11, color: effectiveColor.withValues(alpha: 0.7))),
        ] else
          const Text('—', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey)),
      ]),
    );
  }

  String _fmtDate(DateTime dt) {
    const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${mo[dt.month - 1]}';
  }
  String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final DateTime? dt;
  final IconData icon;
  final Color color;
  const _TimelineRow({required this.label, this.dt, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 6),
    Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.withValues(alpha: 0.7))),
    const Spacer(),
    if (dt != null)
      Text(_fmt(dt!), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  ]);

  String _fmt(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${mo[dt.month-1]}, $h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _StepStatusPill extends StatelessWidget {
  final String? status;
  final Color color;
  const _StepStatusPill({this.status, required this.color});
  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'completed' => 'Done',
      'in_progress' => 'Active',
      'reached' => 'Reached',
      'skipped' => 'Skipped',
      _ => 'Pending',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
    );
  }
}