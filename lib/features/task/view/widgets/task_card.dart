import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/task/model/task_model.dart';
import 'package:flutter/material.dart';

class TaskCardWidget extends StatelessWidget {
  final TaskModel task;
  final bool isManager;
  final VoidCallback onTap;

  const TaskCardWidget({
    super.key,
    required this.task,
    required this.isManager,
    required this.onTap,
  });

  // ── Status config
  _StatusConfig get _statusConfig {
    switch (task.status) {
      case 'in_progress':
        return _StatusConfig('In Progress', Pallete.primaryColor, Icons.play_circle_rounded);
      case 'completed':
        return _StatusConfig('Completed', const Color(0xFF22C55E), Icons.check_circle_rounded);
      case 'overdue':
        return _StatusConfig('Overdue', Pallete.errorColor, Icons.warning_rounded);
      case 'cancelled':
        return _StatusConfig('Cancelled', Colors.grey, Icons.cancel_rounded);
      default:
        return _StatusConfig('Pending', Pallete.warningColor, Icons.schedule_rounded);
    }
  }

  // ── Priority config
  _PriorityConfig get _priorityConfig {
    switch (task.priority) {
      case 'high':
        return _PriorityConfig('High', Pallete.errorColor);
      case 'low':
        return _PriorityConfig('Low', const Color(0xFF22C55E));
      default:
        return _PriorityConfig('Medium', Pallete.warningColor);
    }
  }

  Color get _cardAccentColor {
    switch (task.status) {
      case 'in_progress': return Pallete.primaryColor;
      case 'completed':   return const Color(0xFF22C55E);
      case 'overdue':     return Pallete.errorColor;
      case 'cancelled':   return Colors.grey;
      default:            return Pallete.warningColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = _statusConfig;
    final priority = _priorityConfig;
    final progress = task.totalSteps != null && task.totalSteps! > 0
        ? (task.completedSteps ?? 0) / task.totalSteps!
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: _cardAccentColor.withValues(alpha: isDark ? 0.08 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top accent line
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: _cardAccentColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Row 1: Title + Priority badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.title ?? 'Untitled Task',
                          style: theme.textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            decoration: task.status == 'cancelled'
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.status == 'cancelled'
                                ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _PriorityBadge(priority: priority),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ── Row 2: Assignee (manager) or Time (employee)
                  if (isManager && task.assignedTo != null)
                    _AssigneeRow(task: task, theme: theme)
                  else
                    _TimeRow(task: task, theme: theme),

                  const SizedBox(height: 10),

                  // ── Row 3: Tags row
                  Row(
                    children: [
                      // Field work tag
                      if (task.isFieldWork == true) ...[
                        _Tag(
                          icon: Icons.location_on_rounded,
                          label: 'Field Work',
                          color: Pallete.primaryColor,
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Group task tag
                      if (task.isGroupTask == true) ...[
                        _Tag(
                          icon: Icons.group_rounded,
                          label: 'Group',
                          color: const Color(0xFF8B5CF6),
                        ),
                        const SizedBox(width: 6),
                      ],
                      // Status badge
                      _StatusBadge(status: status),
                      const Spacer(),
                      // Step count
                      if ((task.totalSteps ?? 0) > 0)
                        _StepCount(task: task, theme: theme),
                    ],
                  ),

                  // ── Progress bar (only if has steps)
                  if ((task.totalSteps ?? 0) > 0) ...[
                    const SizedBox(height: 10),
                    _ProgressBar(
                      progress: progress,
                      accentColor: _cardAccentColor,
                      theme: theme,
                    ),
                  ],

                  // ── Manager: time row below assignee
                  if (isManager && task.assignedTo != null) ...[
                    const SizedBox(height: 8),
                    _TimeRow(task: task, theme: theme),
                  ],

                  // ── Employee: action hint
                  if (!isManager) ...[
                    const SizedBox(height: 8),
                    _EmployeeActionHint(task: task, theme: theme),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────────────────

class _AssigneeRow extends StatelessWidget {
  final TaskModel task;
  final ThemeData theme;
  const _AssigneeRow({required this.task, required this.theme});

  @override
  Widget build(BuildContext context) {
    final user = task.assignedTo;
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: Pallete.primaryColor.withValues(alpha: 0.15),
          backgroundImage: user?.profilePicture != null
              ? NetworkImage(user!.profilePicture!)
              : null,
          child: user?.profilePicture == null
              ? Text(
            (user?.fullName ?? user?.username ?? '?')[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Pallete.primaryColor,
            ),
          )
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            user?.fullName ?? user?.username ?? 'Unassigned',
            style: theme.textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (user?.isOnline == true)
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  final TaskModel task;
  final ThemeData theme;
  const _TimeRow({required this.task, required this.theme});

  String _fmt(DateTime? dt) {
    if (dt == null) return '--';
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: 14,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 4),
        Text(
          '${_fmt(task.startDatetime)} → ${_fmt(task.endDatetime)}',
          style: theme.textTheme.bodySmall!.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final Color accentColor;
  final ThemeData theme;
  const _ProgressBar({required this.progress, required this.accentColor, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 5,
        backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.12),
        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
      ),
    );
  }
}

class _StepCount extends StatelessWidget {
  final TaskModel task;
  final ThemeData theme;
  const _StepCount({required this.task, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      '${task.completedSteps ?? 0}/${task.totalSteps ?? 0} steps',
      style: theme.textTheme.bodySmall!.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Tag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _StatusConfig status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 11, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final _PriorityConfig priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: priority.color.withValues(alpha: 0.25)),
      ),
      child: Text(
        priority.label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: priority.color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EmployeeActionHint extends StatelessWidget {
  final TaskModel task;
  final ThemeData theme;
  const _EmployeeActionHint({required this.task, required this.theme});

  @override
  Widget build(BuildContext context) {
    String hint;
    Color color;
    IconData icon;

    switch (task.status) {
      case 'pending':
        hint = 'Tap to start task';
        color = Pallete.warningColor;
        icon = Icons.play_arrow_rounded;
        break;
      case 'in_progress':
        hint = 'Continue working';
        color = Pallete.primaryColor;
        icon = Icons.arrow_forward_rounded;
        break;
      case 'completed':
        hint = 'View summary';
        color = const Color(0xFF22C55E);
        icon = Icons.check_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          hint,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Icon(icon, size: 14, color: color),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Config helpers
// ─────────────────────────────────────────────────────────

class _StatusConfig {
  final String label;
  final Color color;
  final IconData icon;
  const _StatusConfig(this.label, this.color, this.icon);
}

class _PriorityConfig {
  final String label;
  final Color color;
  const _PriorityConfig(this.label, this.color);
}