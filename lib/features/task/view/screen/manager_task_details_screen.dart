import 'dart:convert';
import 'dart:typed_data';
import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/task/controller/manager_task_detail_controller.dart';
import 'package:field_work/features/task/model/task_model.dart';
import 'package:field_work/features/task/view/screen/edit_task_screen.dart';
import 'package:field_work/features/task/view/widgets/task_location_map_sheet.dart';
import 'package:flutter/material.dart';

class ManagerTaskDetailScreen extends StatefulWidget {
  final String taskId;
  final VoidCallback? onTaskUpdated;

  const ManagerTaskDetailScreen({
    super.key,
    required this.taskId,
    this.onTaskUpdated,
  });

  @override
  State<ManagerTaskDetailScreen> createState() =>
      _ManagerTaskDetailScreenState();
}

class _ManagerTaskDetailScreenState extends State<ManagerTaskDetailScreen> {
  late final ManagerTaskDetailController _c;

  @override
  void initState() {
    super.initState();
    _c = ManagerTaskDetailController(
      context:       context,
      reloadData:    _reload,
      taskId:        widget.taskId,
      onTaskUpdated: widget.onTaskUpdated,
    );
    _c.init();
  }

  void _reload() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  // ═══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Loading ────────────────────────────────────────────────────────
    if (_c.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Detail')),
        body: const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Pallete.primaryColor)),
        ),
      );
    }

    // ── Error ──────────────────────────────────────────────────────────
    if (_c.errorMsg != null || _c.task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Detail')),
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: Pallete.kRed),
            const SizedBox(height: 12),
            Text(_c.errorMsg ?? 'Task not found',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _c.loadTask,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                  backgroundColor: Pallete.primaryColor),
            ),
          ],
        )),
      );
    }

    final task        = _c.task!;
    final statusColor = _c.statusColor(task.status);
    final prog        = _c.progress;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF0A0A16) : const Color(0xFFF5F5FF),
      body: RefreshIndicator(
        onRefresh: _c.loadTask,
        color: Pallete.primaryColor,
        child: CustomScrollView(slivers: [

          // ── HERO APP BAR ─────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 230,
            backgroundColor:
            isDark ? const Color(0xFF0A0A16) : const Color(0xFFF5F5FF),
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: GestureDetector(
                onTap: () {
                  widget.onTaskUpdated?.call();
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Colors.white),
                ),
              ),
            ),
            actions: [
              if (_c.canCancel)...[
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: _c.isCancelling ? null : _c.cancelTask,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Pallete.kRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Pallete.kRed.withValues(alpha: 0.3)),
                      ),
                      child: _c.isCancelling
                          ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                  Pallete.kRed)))
                          : const Text('Cancel Task',
                          style: TextStyle(
                              color: Pallete.kRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder:
                          (context) => EditTaskScreen(taskId: _c.taskId)))
                          .then((_) => _c.init());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Pallete.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Pallete.primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: _c.isCancelling
                          ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                  Pallete.primaryColor)))
                          : const Text('Edit Task',
                          style: TextStyle(
                              color: Pallete.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  ),
                ),
              ]
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      statusColor.withValues(alpha: 0.9),
                      statusColor.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Badges
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        _HeroPill(
                            _c.statusLabel(task.status).toUpperCase()),
                        _HeroPill('${_c.priorityEmoji(task.priority)}'
                            ' ${_c.capitalize(task.priority ?? 'medium')}'),
                        if (task.isFieldWork == true)
                          const _HeroPill('📍 Track Location'),
                      ]),
                      const SizedBox(height: 10),
                      Text(
                        task.title ?? 'Untitled Task',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5, height: 1.2,
                          shadows: [Shadow(
                              color: Colors.black38, blurRadius: 8)],
                        ),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      if (task.room?.name != null) ...[
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.meeting_room_rounded,
                              size: 13, color: Colors.white70),
                          const SizedBox(width: 5),
                          Text(task.room!.name!,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Employee card ──────────────────────────────────────
                if (task.assignedTo != null)
                  _buildEmployeeCard(task, isDark),

                const SizedBox(height: 12),

                // ── Schedule + progress ────────────────────────────────
                _buildScheduleCard(task, prog, isDark),

                const SizedBox(height: 12),

                // ── Location tracking button ───────────────────────────
                if (task.isFieldWork == true)
                  _buildLocationCard(task, isDark),

                if (task.isFieldWork == true) const SizedBox(height: 12),

                // ── Note ───────────────────────────────────────────────
                if (task.note?.isNotEmpty == true) ...[
                  _buildNoteCard(task, isDark),
                  const SizedBox(height: 12),
                ],

                // ── Steps ──────────────────────────────────────────────
                _buildStepsCard(task, isDark),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CARD BUILDERS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildEmployeeCard(TaskModel task, bool isDark) {
    final u = task.assignedTo!;
    return _Card(isDark: isDark, child: Row(children: [
      Stack(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Pallete.primaryColor.withValues(alpha: 0.15),
          backgroundImage: u.profilePicture != null
              ? NetworkImage(u.profilePicture!) : null,
          child: u.profilePicture == null
              ? Text(
              (u.fullName ?? u.username ?? '?')[0].toUpperCase(),
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: Pallete.primaryColor))
              : null,
        ),
        if (u.isOnline == true)
          Positioned(right: 1, bottom: 1,
              child: Container(width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: Pallete.kGreen, shape: BoxShape.circle,
                    border: Border.all(
                        color: isDark
                            ? const Color(0xFF141428)
                            : Colors.white,
                        width: 2),
                  ))),
      ]),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ASSIGNED TO',
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w800,
                  letterSpacing: 0.8, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(u.fullName ?? u.username ?? 'Employee',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15)),
          if (u.username != null)
            Text('@${u.username}',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.withValues(alpha: 0.6))),
        ],
      )),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: (u.isOnline == true ? Pallete.kGreen : Colors.grey)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            u.isOnline == true ? 'Online' : 'Offline',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: u.isOnline == true
                    ? Pallete.kGreen : Colors.grey),
          ),
        ),
        if (task.isGroupTask == true) ...[
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: const Text('Group Task',
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700,
                    color: Color(0xFF8B5CF6))),
          ),
        ],
      ]),
    ]));
  }

  Widget _buildScheduleCard(
      TaskModel task, double prog, bool isDark) {
    return _Card(isDark: isDark, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('SCHEDULE & PROGRESS'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _TimeBlock(
            label: 'Start', dt: task.startDatetime,
            icon: Icons.play_arrow_rounded,
            color: Pallete.primaryColor,
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.east_rounded, size: 16,
                color: Colors.grey.withValues(alpha: 0.4)),
          ),
          Expanded(child: _TimeBlock(
            label: 'Deadline', dt: task.endDatetime,
            icon: Icons.flag_rounded,
            color: Pallete.kAmber, isDeadline: true,
          )),
        ]),
        if ((task.totalSteps ?? 0) > 0) ...[
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${task.completedSteps ?? 0}/${task.totalSteps} steps done',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: Colors.grey.withValues(alpha: 0.7))),
                Text('${(prog * 100).round()}%',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800,
                        color: _c.progressColor(prog))),
              ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: prog, minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(_c.progressColor(prog)),
            ),
          ),
        ],
        if (task.employeeStartTime != null) ...[
          const SizedBox(height: 12),
          Divider(color: Colors.grey.withValues(alpha: 0.1)),
          const SizedBox(height: 8),
          _TimelineRow(label: 'Employee started',
              dt: task.employeeStartTime,
              icon: Icons.play_circle_outline_rounded,
              color: Pallete.primaryColor),
        ],
        if (task.completedAt != null) ...[
          const SizedBox(height: 6),
          _TimelineRow(label: 'Completed',
              dt: task.completedAt,
              icon: Icons.check_circle_outline_rounded,
              color: Pallete.kGreen),
        ],
        if (task.cancelledAt != null) ...[
          const SizedBox(height: 6),
          _TimelineRow(label: 'Cancelled',
              dt: task.cancelledAt,
              icon: Icons.cancel_outlined,
              color: Pallete.kRed),
        ],
      ],
    ));
  }

  Widget _buildLocationCard(TaskModel task, bool isDark) {
    final isActive    = _c.isActive;
    final isCompleted = task.status == 'completed';

    return _Card(isDark: isDark, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('EMPLOYEE LOCATION'),
        const SizedBox(height: 12),
        Row(children: [
          // Live location button (only while in_progress)
          if (isActive)
            Expanded(child: _LocationButton(
              icon: Icons.location_searching_rounded,
              label: 'Live Location',
              sublabel: 'Current position',
              color: Pallete.kGreen,
              onTap: () => TaskLocationMapSheet.show(
                context,
                controller: _c,
                isLiveMode: true,
              ),
            )),

          // if (isActive && isCompleted)
            const SizedBox(width: 5),

          // Route trace button (always available once task started)
          if (isActive || isCompleted)
            Expanded(child: _LocationButton(
              icon: Icons.route_rounded,
              label: 'Full Route',
              sublabel: 'GPS trace history',
              color: Pallete.primaryColor,
              onTap: () => TaskLocationMapSheet.show(
                context,
                controller: _c,
                isLiveMode: false,
              ),
            )),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded,
                size: 13, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Expanded(child: Text(
              isActive
                  ? 'GPS pings will update while the task is active.'
                  : 'The task is complete. View the full recorded route below.',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.withValues(alpha: 0.6),
                  height: 1.4),
            )),
          ]),
        ),
      ],
    ));
  }

  Widget _buildNoteCard(TaskModel task, bool isDark) {
    return _Card(isDark: isDark, child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.sticky_note_2_rounded,
            size: 18, color: Pallete.kAmber),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Label('TASK NOTE'),
            const SizedBox(height: 4),
            Text(task.note!,
                style: const TextStyle(fontSize: 13, height: 1.5)),
          ],
        )),
      ],
    ));
  }

  Widget _buildStepsCard(TaskModel task, bool isDark) {
    final steps = task.steps ?? [];
    if (steps.isEmpty) return const SizedBox.shrink();

    return _Card(isDark: isDark, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const _Label('STEPS'),
          const Spacer(),
          Text('${task.completedSteps ?? 0}/${task.totalSteps ?? 0}',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: Pallete.primaryColor)),
        ]),
        const SizedBox(height: 12),
        ...List.generate(steps.length, (i) => _StepDetailTile(
          step:   steps[i],
          index:  i,
          isLast: i == steps.length - 1,
          c:      _c,
          isDark: isDark,
        )),
      ],
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  STEP DETAIL TILE  — rich view with submission evidence
// ═══════════════════════════════════════════════════════════════════════

class _StepDetailTile extends StatefulWidget {
  final TaskStep step;
  final int      index;
  final bool     isLast;
  final ManagerTaskDetailController c;
  final bool     isDark;

  const _StepDetailTile({
    required this.step, required this.index, required this.isLast,
    required this.c,    required this.isDark,
  });

  @override
  State<_StepDetailTile> createState() => _StepDetailTileState();
}

class _StepDetailTileState extends State<_StepDetailTile> {
  bool _expanded = false;

  TaskStep get s => widget.step;
  ManagerTaskDetailController get c => widget.c;

  @override
  void initState() {
    super.initState();
    // Auto-expand active or completed steps
    _expanded = s.status == 'in_progress' ||
        s.status == 'reached'     ||
        s.status == 'completed';
  }

  bool get _isDone   => s.status == 'completed' || s.status == 'skipped';
  bool get _isActive => s.status == 'in_progress' || s.status == 'reached';
  Color get _color   => c.stepColor(s.status);

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Timeline column ────────────────────────────────────────────
        Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _isDone ? _color : _color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: _color, width: _isActive ? 2 : 1.5),
              boxShadow: _isActive
                  ? [BoxShadow(
                  color: _color.withValues(alpha: 0.4),
                  blurRadius: 8)]
                  : null,
            ),
            child: Center(child: _isDone
                ? const Icon(Icons.check_rounded,
                size: 13, color: Colors.white)
                : Text('${widget.index + 1}',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: _isActive
                        ? _color
                        : Colors.grey))),
          ),
          if (!widget.isLast)
            Expanded(child: Container(
              width: 2,
              margin: const EdgeInsets.symmetric(vertical: 3),
              color: _isDone
                  ? _color.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.15),
            )),
        ]),

        const SizedBox(width: 12),

        // ── Card ────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: widget.isLast ? 0 : 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: _isActive
                    ? _color.withValues(alpha: widget.isDark ? 0.07 : 0.04)
                    : Colors.grey.withValues(
                    alpha: widget.isDark ? 0.05 : 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isActive
                      ? _color.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.1),
                ),
              ),
              child: Column(children: [

                // ── Header (always visible) ──────────────────────────
                GestureDetector(
                  onTap: ()=> setState(() => _expanded = !_expanded),
                  // onTap: s.status != 'pending'
                  //     ? () => setState(() => _expanded = !_expanded)
                  //     : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            if (s.isFieldWorkStep == true) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Pallete.kGreen
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text('Field',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Pallete.kGreen)),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(child: Text(
                              s.title ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _isDone
                                    ? Colors.grey
                                    : null,
                              ),
                            )),
                          ]),
                          const SizedBox(height: 3),
                          // Time range
                          Text(
                            '${c.fmtTime(s.startDatetime)} → ${c.fmtTime(s.endDatetime)}',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey
                                    .withValues(alpha: 0.55)),
                          ),
                        ],
                      )),
                      const SizedBox(width: 8),
                      _StepPill(status: s.status, color: _color),
                      // if (s.status != 'pending') ...[
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Colors.grey.withValues(alpha: 0.5)),
                        ),
                      // ],
                    ]),
                  ),
                ),

                // ── Expanded content ─────────────────────────────────
                // if (_expanded && s.status != 'pending')
                if (_expanded)
                  _StepExpandedContent(step: s, c: c, isDark: widget.isDark),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  EXPANDED STEP CONTENT — submission evidence
// ═══════════════════════════════════════════════════════════════════════

class _StepExpandedContent extends StatelessWidget {
  final TaskStep step;
  final ManagerTaskDetailController c;
  final bool isDark;

  const _StepExpandedContent(
      {required this.step, required this.c, required this.isDark});

  static const _kGreen = Pallete.kGreen;
  static const _kAmber = Pallete.kAmber;
  static const _kBlue  = Pallete.primaryColor;

  @override
  Widget build(BuildContext context) {
    final s = step;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Divider(height: 1, color: Colors.grey.withValues(alpha: 0.12)),
        const SizedBox(height: 12),

        // ── Destination (field work) ─────────────────────────────────
        if (s.isFieldWorkStep == true &&
            s.destinationLocation?.address != null)
          _EvidenceRow(
            icon: Icons.location_on_rounded,
            color: _kGreen,
            label: 'Destination',
            child: Row(
              children: [
                Expanded(
                  child: Text(s.destinationLocation!.address!,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: _kGreen)),
                ),
                GestureDetector(
                  onTap: () {
                    Helpers.openMap(
                      lat: s.destinationLocation!.coordinates?[1] ?? 0,
                      lng: s.destinationLocation!.coordinates?[0] ?? 0,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions,
                      size: 14,
                      color: _kGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── Timing timeline ──────────────────────────────────────────
        if (s.employeeStartTime   != null ||
            s.employeeReachTime   != null ||
            s.employeeCompleteTime != null)
          _TimingTimeline(step: s, c: c),

        // ── Overdue badge ────────────────────────────────────────────
        if (s.isOverdue == true) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Pallete.kRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Pallete.kRed.withValues(alpha: 0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 12, color: Pallete.kRed),
              const SizedBox(width: 5),
              const Text('Completed after deadline',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: Pallete.kRed)),
            ]),
          ),
        ],

        // ── Submitted photo ──────────────────────────────────────────
        if (s.submittedPhotoUrl?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _EvidenceRow(
            icon: Icons.camera_alt_rounded,
            color: _kAmber,
            label: 'Photo Proof',
            child: GestureDetector(
              onTap: () => _openPhoto(context, s.submittedPhotoUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  s.submittedPhotoUrl!,
                  height: 120, width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 60,
                    decoration: BoxDecoration(
                        color: _kAmber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Center(
                        child: Icon(Icons.broken_image_rounded,
                            color: _kAmber)),
                  ),
                ),
              ),
            ),
          ),
        ],

        // ── Signature ────────────────────────────────────────────────
        if (s.signatureData != null) ...[
          const SizedBox(height: 12),
          _EvidenceRow(
            icon: Icons.verified_rounded,
            color: _kBlue,
            label: 'Signature',
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _kBlue.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: _kBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Signature collected',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: _kBlue)),
                        if (s.signatureSignedBy?.isNotEmpty == true)
                          Text('Signed by: ${s.signatureSignedBy}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.withValues(alpha: 0.6))),
                      ]),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    SignatureViewSheet.show(
                      context,
                      base64: s.signatureData!,
                      signer: s.signatureSignedBy,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kBlue,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],

        // ── Submitted location ───────────────────────────────────────
        if (s.submittedLocation?.coordinates != null) ...[
          const SizedBox(height: 12),
          _EvidenceRow(
            icon: Icons.my_location_rounded,
            color: _kGreen,
            label: 'Submitted Location',
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kGreen.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _kGreen.withValues(alpha: 0.18)),
              ),
              child: Row(children: [
                const Icon(Icons.location_on_rounded,
                    size: 13, color: _kGreen),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  '${s.submittedLocation!.coordinates![1].toStringAsFixed(5)}, '
                      '${s.submittedLocation!.coordinates![0].toStringAsFixed(5)}',
                  style: TextStyle(
                      fontSize: 11, fontFamily: 'monospace',
                      color: Colors.grey.withValues(alpha: 0.7)),
                )),
                if (s.submittedLocation?.accuracyMeters != null)
                  Text('±${s.submittedLocation!.accuracyMeters!.round()}m',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: _kGreen)),
              ]),
            ),
          ),
        ],

        // ── Employee notes ───────────────────────────────────────────
        if (s.employeeNotes?.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _EvidenceRow(
            icon: Icons.notes_rounded,
            color: Colors.grey,
            label: 'Employee Note',
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.12)),
              ),
              child: Text(s.employeeNotes!,
                  style: TextStyle(
                      fontSize: 12, height: 1.55,
                      color: Colors.grey.withValues(alpha: 0.8))),
            ),
          ),
        ],

        // ── Required validations that were NOT submitted ─────────────
        if (s.status == 'completed') ...[
          _MissingValidations(step: s),
        ],
      ]),
    );
  }

  void _openPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(url, fit: BoxFit.contain),
          ),
          Positioned(top: 8, right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 18),
                ),
              )),
        ]),
      ),
    );
  }
}


class SignatureViewSheet {
  static void show(
      BuildContext context, {
        required String base64,
        String? signer,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SignatureViewContent(
        base64: base64,
        signer: signer,
      ),
    );
  }
}

class _SignatureViewContent extends StatelessWidget {
  final String base64;
  final String? signer;

  const _SignatureViewContent({
    required this.base64,
    this.signer,
  });

  Uint8List _decode() {
    return base64Decode(base64);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 80, 12, 0),
      decoration: const BoxDecoration(
        color: Color(0xFF12121E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    const Icon(Icons.draw_rounded, color: Colors.blueAccent),
                    const SizedBox(width: 10),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Signature",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (signer != null)
                          Text(
                            "Signed by: $signer",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),

                    const Spacer(),

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.white54),
                    )
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Signature Image
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.white,
                height: 220,
                width: double.infinity,
                child: Image.memory(
                  _decode(),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text("Close"),
            ),
          ),
        ],
      ),
    );
  }
}

// Horizontal timing row: Started → Reached → Completed
class _TimingTimeline extends StatelessWidget {
  final TaskStep step;
  final ManagerTaskDetailController c;
  const _TimingTimeline({required this.step, required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (step.employeeStartTime != null)
            _TimeChip(
              icon:  Icons.play_arrow_rounded,
              label: 'Started',
              time:  c.fmtTime(step.employeeStartTime),
              color: Pallete.primaryColor,
            ),
          if (step.employeeStartTime   != null &&
              step.employeeReachTime   != null)
            _Arrow(),
          if (step.isFieldWorkStep == true &&
              step.employeeReachTime != null)
            _TimeChip(
              icon:  Icons.where_to_vote_rounded,
              label: 'Reached',
              time:  c.fmtTime(step.employeeReachTime),
              color: Pallete.kAmber,
            ),
          if ((step.isFieldWorkStep == true &&
              step.employeeReachTime != null) ||
              step.employeeStartTime != null)
            if (step.employeeCompleteTime != null) _Arrow(),
          if (step.employeeCompleteTime != null)
            _TimeChip(
              icon:  Icons.check_circle_rounded,
              label: 'Done',
              time:  c.fmtTime(step.employeeCompleteTime),
              color: Pallete.kGreen,
            ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Icon(Icons.arrow_forward_rounded, size: 12,
        color: Colors.grey.withValues(alpha: 0.35)),
  );
}

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String   label, time;
  final Color    color;
  const _TimeChip({required this.icon, required this.label,
    required this.time, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.18)),
    ),
    child: Column(children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 8,
          fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.7))),
      Text(time,  style: TextStyle(fontSize: 10,
          fontWeight: FontWeight.w800, color: color)),
    ]),
  );
}

// Flags any required validations that appear missing after completion.
class _MissingValidations extends StatelessWidget {
  final TaskStep step;
  const _MissingValidations({required this.step});

  @override
  Widget build(BuildContext context) {
    final v = step.validations;
    if (v == null) return const SizedBox.shrink();

    final missing = <String>[];
    if (v.requirePhoto         == true &&
        (step.submittedPhotoUrl?.isEmpty ?? true)) {
      missing.add('Photo not submitted');
    }
    if (v.requireSignature     == true &&
        step.signatureData     == null) {
      missing.add('Signature missing');
    }
    if (v.requireLocationCheck == true &&
        step.submittedLocation?.coordinates == null) {
      missing.add('Location not submitted');
    }

    if (missing.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Pallete.kRed.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Pallete.kRed.withValues(alpha: 0.18)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Missing validations',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                  color: Pallete.kRed)),
          const SizedBox(height: 4),
          ...missing.map((m) => Row(children: [
            const Icon(Icons.circle, size: 5, color: Pallete.kRed),
            const SizedBox(width: 6),
            Text(m, style: TextStyle(fontSize: 11,
                color: Pallete.kRed.withValues(alpha: 0.8))),
          ])),
        ]),
      ),
    );
  }
}

// Evidence row widget — icon + label + content
class _EvidenceRow extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final Widget   child;
  const _EvidenceRow({required this.icon, required this.color,
    required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w800,
                letterSpacing: 0.6, color: color.withValues(alpha: 0.8))),
      ]),
      const SizedBox(height: 6),
      child,
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
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
      border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06)),
      boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: child,
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: Colors.grey.withValues(alpha: 0.5)));
}

class _HeroPill extends StatelessWidget {
  final String text;
  const _HeroPill(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
    child: Text(text,
        style: const TextStyle(color: Colors.white,
            fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

class _StepPill extends StatelessWidget {
  final String? status;
  final Color   color;
  const _StepPill({this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'completed'   => 'Done',
      'in_progress' => 'Active',
      'reached'     => 'Reached',
      'skipped'     => 'Skipped',
      _             => 'Pending',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _LocationButton extends StatelessWidget {
  final IconData icon;
  final String   label, sublabel;
  final Color    color;
  final VoidCallback onTap;
  const _LocationButton({required this.icon, required this.label,
    required this.sublabel, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: color)),
            Text(sublabel,
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.withValues(alpha: 0.6))),
          ],
        )),
        Icon(Icons.chevron_right_rounded, size: 16,
            color: color.withValues(alpha: 0.5)),
      ]),
    ),
  );
}

class _TimeBlock extends StatelessWidget {
  final String label;
  final DateTime? dt;
  final IconData icon;
  final Color color;
  final bool isDeadline;
  const _TimeBlock({required this.label, required this.dt,
    required this.icon, required this.color, this.isDeadline = false});

  @override
  Widget build(BuildContext context) {
    final overdue = isDeadline && dt != null && dt!.isBefore(DateTime.now());
    final c       = overdue ? Pallete.kRed : color;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800,
              color: c.withValues(alpha: 0.7))),
        ]),
        const SizedBox(height: 5),
        if (dt != null) ...[
          Text(_fmtDate(dt!),
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: c)),
          Text(_fmtTime(dt!),
              style: TextStyle(
                  fontSize: 11, color: c.withValues(alpha: 0.7))),
        ] else
          const Text('—',
              style: TextStyle(fontWeight: FontWeight.w700,
                  color: Colors.grey)),
      ]),
    );
  }

  String _fmtDate(DateTime dt) {
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
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
  const _TimelineRow({required this.label, this.dt,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 6),
    Text(label, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: Colors.grey.withValues(alpha: 0.7))),
    const Spacer(),
    if (dt != null)
      Text(_fmt(dt!), style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  ]);

  String _fmt(DateTime dt) {
    final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m  = dt.minute.toString().padLeft(2, '0');
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${mo[dt.month-1]}, $h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}