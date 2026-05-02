// lib/features/attendance/view/screen/employee_attendance_detail_screen.dart

import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/attendance/controller/manager_attendance_controller.dart';
import 'package:field_work/features/attendance/model/attendance_model.dart';
import 'package:field_work/features/widgets/animated_screen_wrapper.dart';
import 'package:field_work/features/widgets/avatar_initials.dart';
import 'package:flutter/material.dart';

import '../../../widgets/image_preview.dart';

class EmployeeAttendanceDetailScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeAttendanceDetailScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<EmployeeAttendanceDetailScreen> createState() =>
      _EmployeeAttendanceDetailScreenState();
}

class _EmployeeAttendanceDetailScreenState
    extends State<EmployeeAttendanceDetailScreen> {
  late final EmployeeAttendanceDetailController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = EmployeeAttendanceDetailController(
      context:    context,
      reloadData: () { if (mounted) setState(() {}); },
      employeeId: widget.employeeId,
    );
    _ctrl.init();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding:    const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 18,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.employeeName,
            style: Theme.of(context).textTheme.titleMedium!
                .copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _ctrl.isLoading
          ? const Center(child: CircularProgressIndicator(color: Pallete.primaryColor))
          : _ctrl.errorMsg != null
          ? Center(child: Text(_ctrl.errorMsg!))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return AnimatedScreenWrapper(
      child: Column(
        children: [
          // Filter bar (month nav + date range toggle)
          _DetailFilterBar(ctrl: _ctrl),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _ctrl.loadDetail,
              color: Pallete.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _EmployeeInfoCard(ctrl: _ctrl),
                    const SizedBox(height: 12),
                    _PeriodSummaryCard(ctrl: _ctrl),
                    const SizedBox(height: 12),
                    _TaskStatsCard(ctrl: _ctrl),
                    const SizedBox(height: 16),
                    _DailyRecordsList(ctrl: _ctrl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Bar (month nav + date range toggle) ────────────────────────────────

class _DetailFilterBar extends StatelessWidget {
  final EmployeeAttendanceDetailController ctrl;
  const _DetailFilterBar({required this.ctrl});

  String _monthLabel(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _shortDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year.toString().substring(2)}';

  @override
  Widget build(BuildContext context) {
    final isMonth = ctrl.filterMode == 'month';

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          if (isMonth) ...[
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: ctrl.prevMonth,
              padding: EdgeInsets.zero,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context:               context,
                    initialDate:           ctrl.selectedMonth,
                    firstDate:             DateTime(2024),
                    lastDate:              DateTime.now(),
                    initialDatePickerMode: DatePickerMode.year,
                  );
                  if (picked != null) {
                    ctrl.selectedMonth = DateTime(picked.year, picked.month);
                    ctrl.filterMode    = 'month';
                    ctrl.loadDetail();
                  }
                },
                child: Center(
                  child: Text(
                    _monthLabel(ctrl.selectedMonth),
                    style: Theme.of(context).textTheme.titleSmall!
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: ctrl.nextMonth,
              padding: EdgeInsets.zero,
            ),
          ] else ...[
            Expanded(
              child: Text(
                ctrl.rangeFrom != null && ctrl.rangeTo != null
                    ? '${_shortDate(ctrl.rangeFrom!)} – ${_shortDate(ctrl.rangeTo!)}'
                    : 'Select range',
                style: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],

          // Toggle popup
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune, size: 20),
            onSelected: (v) {
              if (v == 'month') {
                ctrl.setFilterMode('month');
              } else {
                ctrl.pickDateRange();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'month', child: Text('By Month')),
              const PopupMenuItem(value: 'range', child: Text('Date Range')),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Employee Info ─────────────────────────────────────────────────────────────

class _EmployeeInfoCard extends StatelessWidget {
  final EmployeeAttendanceDetailController ctrl;
  const _EmployeeInfoCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final emp    = ctrl.employeeInfo;
    if (emp == null) return const SizedBox.shrink();
    final tt     = Theme.of(context).textTheme;
    final online = emp['isOnline'] == true;
    final color  = online ? Pallete.kGreen : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Pallete.primaryColor.withValues(alpha: 0.1),
          Pallete.primaryColor.withValues(alpha: 0.03),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Pallete.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Hero(
                tag: 'profile_${emp['profilePicture']}',
                child: GestureDetector(
                  onTap: () => ImagePreview.show(
                    context,
                    url:   emp['profilePicture']!,
                    label: emp['fullName'] ?? '',
                    heroTag: 'profile_${emp['profilePicture']}',
                  ),
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [
                        Pallete.primaryColor, Pallete.primaryLightColor,
                      ]),
                    ),
                    child: emp['profilePicture'] != null
                        ? ClipOval(child: Image.network(emp['profilePicture']!, fit: BoxFit.cover))
                        : AvatarInitials(fullName: emp['fullName']),
                  ),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color:  color, shape: BoxShape.circle,
                    border: Border.all(
                        color: Theme.of(context).colorScheme.surface, width: 2),
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
                Text(emp['fullName']?.toString() ?? emp['username']?.toString() ?? '',
                    style: tt.titleSmall!.copyWith(fontWeight: FontWeight.w700)),
                if (emp['department'] != null || emp['designation'] != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    [emp['department'], emp['designation']]
                        .where((v) => v != null && v.toString().isNotEmpty)
                        .join(' · '),
                    style: tt.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
                if (emp['employeeId'] != null) ...[
                  const SizedBox(height: 2),
                  Text('ID: ${emp['employeeId']}',
                      style: tt.bodySmall!.copyWith(
                          color: Pallete.primaryColor.withValues(alpha: 0.7),
                          fontSize: 11)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(online ? '● Online' : '● Offline',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Period Summary ────────────────────────────────────────────────────────────

class _PeriodSummaryCard extends StatelessWidget {
  final EmployeeAttendanceDetailController ctrl;
  const _PeriodSummaryCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final s = ctrl.periodSummary;
    if (s == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Period Summary',
              style: Theme.of(context).textTheme.titleSmall!
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              _PeriodStat('Present',   '${s.presentDays}d',                 Pallete.kGreen),
              _PeriodStat('Absent',    '${s.absentDays}d',                  Colors.redAccent),
              _PeriodStat('Hours',     s.totalFormatted,                     Pallete.primaryColor),
              _PeriodStat('Avg/Day',   '${s.avgHoursPerDay.toStringAsFixed(1)}h', Pallete.infoColor),
            ],
          ),
          // Mini bar chart
          const SizedBox(height: 14),
          _AttendanceBar(
            present: s.presentDays,
            absent:  s.absentDays,
            total:   s.totalDays > 0 ? s.totalDays : 1,
          ),
        ],
      ),
    );
  }
}

class _PeriodStat extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _PeriodStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall!
                .copyWith(fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
      ],
    ),
  );
}

class _AttendanceBar extends StatelessWidget {
  final int present;
  final int absent;
  final int total;
  const _AttendanceBar({required this.present, required this.absent, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              Flexible(
                flex: present,
                child: Container(height: 10, color: Pallete.kGreen),
              ),
              Flexible(
                flex: absent > 0 ? absent : 0,
                child: Container(height: 10, color: Colors.redAccent.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _dot(Pallete.kGreen), const SizedBox(width: 4),
            Text('Present', style: _small(context)),
            const SizedBox(width: 12),
            _dot(Colors.redAccent.withValues(alpha: 0.6)), const SizedBox(width: 4),
            Text('Absent', style: _small(context)),
          ],
        ),
      ],
    );
  }

  Widget _dot(Color c) => Container(width: 8, height: 8,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  TextStyle _small(BuildContext ctx) =>
      Theme.of(ctx).textTheme.bodySmall!.copyWith(fontSize: 10);
}

// ── Task Stats ────────────────────────────────────────────────────────────────

class _TaskStatsCard extends StatelessWidget {
  final EmployeeAttendanceDetailController ctrl;
  const _TaskStatsCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final t = ctrl.taskStats;
    if (t == null) return const SizedBox.shrink();

    final total     = (t['total']     as num?)?.toInt() ?? 0;
    final completed = (t['completed'] as num?)?.toInt() ?? 0;
    final active    = (t['active']    as num?)?.toInt() ?? 0;
    final pending   = (t['pending']   as num?)?.toInt() ?? 0;
    final rate      = (t['completionRate'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Task Productivity',
                  style: Theme.of(context).textTheme.titleSmall!
                      .copyWith(fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Pallete.kAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$rate% done',
                    style: const TextStyle(
                        color: Pallete.kAmber, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _TaskStat('Total',    '$total',     Pallete.primaryColor),
              _TaskStat('Done',     '$completed', Pallete.kGreen),
              _TaskStat('Active',   '$active',    Pallete.kAmber),
              _TaskStat('Pending',  '$pending',   Colors.grey),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: rate / 100,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(Pallete.kGreen),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskStat extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _TaskStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall!
                .copyWith(fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
      ],
    ),
  );
}

// ── Daily Records ─────────────────────────────────────────────────────────────

class _DailyRecordsList extends StatelessWidget {
  final EmployeeAttendanceDetailController ctrl;
  const _DailyRecordsList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('No attendance records for this period',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Breakdown',
            style: Theme.of(context).textTheme.titleSmall!
                .copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...ctrl.records.map((r) => _DayRow(record: r)),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final AttendanceModel record;
  const _DayRow({required this.record});

  String _fmtDate(DateTime d) {
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }

  String _fmtTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final tt      = Theme.of(context).textTheme;
    // BUG-FIX: totalMinutes is 0 while the session is still open (goOffline
    // hasn't been called yet). Use isOnline as the secondary check so that
    // an employee who is currently online is never shown as "Absent".
    final hasWork    = record.totalMinutes > 0;
    final isActive   = record.isOnline && !hasWork; // online but no closed time yet
    final isPresent  = hasWork || isActive;
    final color      = isPresent ? Pallete.kGreen : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: color.withValues(alpha: hasWork ? 0.2 : 0.1)),
      ),
      child: Row(
        children: [
          // Day number box
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${record.workDate.day}',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w900, fontSize: 16)),
                Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][record.workDate.weekday - 1],
                    style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmtDate(record.workDate),
                        style: tt.bodySmall!.copyWith(fontWeight: FontWeight.w600)),
                    // BUG-FIX: show 'Active 🟢' for open sessions, time for closed, Absent otherwise
                    Text(
                      isActive  ? '● Active'
                          : hasWork ? record.totalFormatted
                          : 'Absent',
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ],
                ),
                if (record.sessions.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${record.sessions.length} session(s)  '
                        '·  In: ${_fmtTime(record.sessions.first.startTime)}'
                        '${record.sessions.last.endTime != null ? '  Out: ${_fmtTime(record.sessions.last.endTime!)}' : ''}',
                    style: tt.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                        fontSize: 11),
                  ),
                ],
                if (record.tasksCompleted > 0) ...[
                  const SizedBox(height: 2),
                  Text('✓ ${record.tasksCompleted} task${record.tasksCompleted > 1 ? 's' : ''} completed',
                      style: tt.bodySmall!.copyWith(
                          color: Pallete.kAmber, fontWeight: FontWeight.w600, fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}