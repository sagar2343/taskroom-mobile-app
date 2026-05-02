// lib/features/attendance/view/screen/attendance_screen.dart

import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/attendance/controller/attendance_controller.dart';
import 'package:field_work/features/attendance/model/attendance_model.dart';
import 'package:field_work/features/widgets/animated_screen_wrapper.dart';
import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late final AttendanceController _ctrl;
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _ctrl    = AttendanceController(
      context:    context,
      reloadData: () { if (mounted) setState(() {}); },
    );
    _ctrl.init();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _tabCtrl.dispose();
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
        title: Text('My Attendance',
            style: Theme.of(context).textTheme.titleMedium!
                .copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor:       Pallete.primaryColor,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          indicatorColor:   Pallete.primaryColor,
          indicatorWeight:  3,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _ctrl.isLoading
          ? const Center(child: CircularProgressIndicator(color: Pallete.primaryColor))
          : TabBarView(
        controller: _tabCtrl,
        children: [
          _TodayTab(ctrl: _ctrl),
          _HistoryTab(ctrl: _ctrl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TODAY TAB
// ─────────────────────────────────────────────────────────────────────────────

class _TodayTab extends StatelessWidget {
  final AttendanceController ctrl;
  const _TodayTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedScreenWrapper(
      child: RefreshIndicator(
        onRefresh: ctrl.loadToday,
        color: Pallete.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _OnlineStatusCard(ctrl: ctrl),
              const SizedBox(height: 16),
              _TaskStatsRow(ctrl: ctrl),
              const SizedBox(height: 16),
              _SessionsCard(ctrl: ctrl),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Online Status / Toggle Card ───────────────────────────────────────────────

class _OnlineStatusCard extends StatelessWidget {
  final AttendanceController ctrl;
  const _OnlineStatusCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final tt      = Theme.of(context).textTheme;
    final isOnline= ctrl.todayData?.isOnline ?? false;
    final color   = isOnline ? Pallete.kGreen : Colors.redAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.06)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        children: [
          // Status dot + label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color:  color,
                  shape:  BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 2)],
                ),
              ),
              const SizedBox(width: 8),
              Text(isOnline ? 'ONLINE' : 'OFFLINE',
                  style: tt.titleMedium!.copyWith(
                      color: color, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ],
          ),

          const SizedBox(height: 16),

          // Live timer or total
          Text(
            isOnline ? ctrl.liveSessionFormatted : ctrl.todayData?.totalFormatted ?? '0m',
            style: tt.headlineMedium!.copyWith(fontWeight: FontWeight.w900, color: color),
          ),
          Text(
            isOnline ? 'Current session' : 'Total today',
            style: tt.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
          ),

          if (!isOnline && (ctrl.todayData?.totalMinutes ?? 0) > 0) ...[
            const SizedBox(height: 4),
            Text('Total worked today: ${ctrl.todayData?.totalFormatted ?? '0m'}',
                style: tt.bodySmall!.copyWith(color: color.withValues(alpha: 0.8))),
          ],

          const SizedBox(height: 20),

          // Action button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: ctrl.isActionInProgress
                  ? null
                  : (isOnline ? ctrl.goOffline : ctrl.goOnline),
              style: ElevatedButton.styleFrom(
                backgroundColor:         color,
                disabledBackgroundColor: color.withValues(alpha: 0.4),
                foregroundColor:         Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: ctrl.isActionInProgress
                  ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(isOnline ? Icons.power_settings_new : Icons.power_settings_new),
              label: Text(
                ctrl.isActionInProgress ? 'Please wait…'
                    : (isOnline ? 'Go Offline' : 'Go Online'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task Stats Row ────────────────────────────────────────────────────────────

class _TaskStatsRow extends StatelessWidget {
  final AttendanceController ctrl;
  const _TaskStatsRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final stats = ctrl.todayData?.taskStats;
    return Row(
      children: [
        _StatBox(label: 'Assigned',   value: '${stats?.assigned   ?? 0}', color: Pallete.primaryColor),
        const SizedBox(width: 10),
        _StatBox(label: 'In Progress', value: '${stats?.inProgress ?? 0}', color: Pallete.kAmber),
        const SizedBox(width: 10),
        _StatBox(label: 'Completed',  value: '${stats?.completed  ?? 0}', color: Pallete.kGreen),
        const SizedBox(width: 10),
        _StatBox(label: 'Done %',
            value: '${stats?.completionRate ?? 0}%',
            color: Pallete.infoColor),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(value,
                style: Theme.of(context).textTheme.titleMedium!
                    .copyWith(fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Sessions Card ─────────────────────────────────────────────────────────────

class _SessionsCard extends StatelessWidget {
  final AttendanceController ctrl;
  const _SessionsCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final sessions = ctrl.todayData?.sessions ?? [];
    final tt       = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
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
          Text("Today's Sessions",
              style: tt.titleSmall!.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('No sessions today',
                    style: tt.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
              ),
            )
          else
            ...sessions.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              return _SessionRow(index: i + 1, session: s);
            }),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final int i;
  final AttendanceSession session;
  const _SessionRow({required int index, required this.session}) : i = index;

  String _fmt(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = session.isOpen;
    final color  = isOpen ? Pallete.kGreen : Pallete.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Center(
              child: Text('$i',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_fmt(session.startTime)} → ${session.endTime != null ? _fmt(session.endTime!) : "Now"}',
                    style: Theme.of(context).textTheme.bodySmall!
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  session.method == 'auto_task_start' ? '⚡ Auto (task started)' : '👤 Manual',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isOpen ? '● ACTIVE' : session.durationFormatted,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HISTORY TAB
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final AttendanceController ctrl;
  const _HistoryTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedScreenWrapper(
      child: Column(
        children: [
          _HistoryFilterBar(ctrl: ctrl),
          if (ctrl.historySummary != null) _SummaryBanner(summary: ctrl.historySummary!),
          Expanded(
            child: ctrl.isLoadingHistory && ctrl.historyRecords.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Pallete.primaryColor))
                : ctrl.historyRecords.isEmpty
                ? const Center(child: Text('No records for this period'))
                : RefreshIndicator(
              onRefresh: () => ctrl.loadHistory(refresh: true),
              color: Pallete.primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: ctrl.historyRecords.length,
                itemBuilder: (_, i) =>
                    _AttendanceHistoryCard(record: ctrl.historyRecords[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryFilterBar extends StatelessWidget {
  final AttendanceController ctrl;
  const _HistoryFilterBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isMonth = ctrl.filterMode == 'month';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Month navigation
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
                    context:      context,
                    initialDate:  ctrl.selectedMonth,
                    firstDate:    DateTime(2024),
                    lastDate:     DateTime.now(),
                    initialDatePickerMode: DatePickerMode.year,
                  );
                  if (picked != null) {
                    ctrl.selectedMonth = DateTime(picked.year, picked.month);
                    ctrl.loadHistory(refresh: true);
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

          // Toggle mode
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune, size: 20),
            onSelected: (v) {
              if (v == 'month') ctrl.setFilterMode('month');
              else if (v == 'range') ctrl.pickDateRange();
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

  String _monthLabel(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _shortDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year.toString().substring(2)}';
}

class _SummaryBanner extends StatelessWidget {
  final AttendanceSummary summary;
  const _SummaryBanner({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Pallete.primaryColor.withValues(alpha: 0.12),
          Pallete.primaryColor.withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Pallete.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem('Present', '${summary.presentDays}d',  Pallete.kGreen),
          _SummaryItem('Hours',   summary.totalFormatted,     Pallete.primaryColor),
          _SummaryItem('Avg/Day', '${summary.avgHoursPerDay.toStringAsFixed(1)}h', Pallete.infoColor),
          _SummaryItem('Tasks✓',  '${summary.tasksCompleted}',Pallete.kAmber),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _SummaryItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value,
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 2),
      Text(label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
          )),
    ],
  );
}

class _AttendanceHistoryCard extends StatelessWidget {
  final AttendanceModel record;
  const _AttendanceHistoryCard({required this.record});

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
    // BUG-FIX: totalMinutes is 0 while session is still open. Use isOnline
    // to detect this so employee's own history card never shows "Absent" for today.
    final hasWork   = record.totalMinutes > 0;
    final isActive  = record.isOnline && !hasWork;
    final isPresent = hasWork || isActive;
    final isWeekend = record.workDate.weekday >= 6;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPresent
              ? Pallete.kGreen.withValues(alpha: 0.25)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Date column
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color:        (isPresent ? Pallete.kGreen : Colors.grey).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text('${record.workDate.day}',
                    style: tt.titleLarge!.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isPresent ? Pallete.kGreen : Colors.grey)),
                Text(_fmtDate(record.workDate).split(',')[0],
                    style: tt.bodySmall!.copyWith(
                        fontSize: 10,
                        color: isPresent ? Pallete.kGreen : Colors.grey)),
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
                        style: tt.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:        (isPresent ? Pallete.kGreen : Colors.grey).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isActive  ? '● Active'
                            : hasWork ? record.totalFormatted
                            : (isWeekend ? 'Weekend' : 'Absent'),
                        style: TextStyle(
                          color:      isPresent ? Pallete.kGreen : Colors.grey,
                          fontWeight: FontWeight.w700,
                          fontSize:   11,
                        ),
                      ),
                    ),
                  ],
                ),
                if (record.sessions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${record.sessions.length} session${record.sessions.length > 1 ? 's' : ''}  '
                        '· In: ${_fmtTime(record.sessions.first.startTime)}'
                        '${record.sessions.last.endTime != null ? '  · Out: ${_fmtTime(record.sessions.last.endTime!)}' : ''}',
                    style: tt.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
                if (record.tasksCompleted > 0) ...[
                  const SizedBox(height: 4),
                  Text('✓ ${record.tasksCompleted} task${record.tasksCompleted > 1 ? 's' : ''} completed',
                      style: tt.bodySmall!.copyWith(
                          color: Pallete.kAmber, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}