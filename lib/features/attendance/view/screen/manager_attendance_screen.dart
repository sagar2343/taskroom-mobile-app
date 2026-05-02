// lib/features/attendance/view/screen/manager_attendance_screen.dart

import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/attendance/controller/manager_attendance_controller.dart';
import 'package:field_work/features/attendance/model/attendance_model.dart';
import 'package:field_work/features/attendance/view/screen/employee_attendance_detail_screen.dart';
import 'package:field_work/features/widgets/animated_screen_wrapper.dart';
import 'package:field_work/features/widgets/avatar_initials.dart';
import 'package:flutter/material.dart';

class ManagerAttendanceScreen extends StatefulWidget {
  const ManagerAttendanceScreen({super.key});

  @override
  State<ManagerAttendanceScreen> createState() => _ManagerAttendanceScreenState();
}

class _ManagerAttendanceScreenState extends State<ManagerAttendanceScreen> {
  late final ManagerAttendanceController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ManagerAttendanceController(
      context:    context,
      reloadData: () { if (mounted) setState(() {}); },
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
        title: Text("Team Attendance",
            style: Theme.of(context).textTheme.titleMedium!
                .copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _ctrl.loadOrgToday,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _ctrl.isLoading
          ? const Center(child: CircularProgressIndicator(color: Pallete.primaryColor))
          : _ctrl.errorMsg != null
          ? Center(child: Text(_ctrl.errorMsg!))
          : AnimatedScreenWrapper(
        child: Column(
          children: [
            _OrgSummaryRow(ctrl: _ctrl),
            _SearchFilterBar(ctrl: _ctrl),
            Expanded(child: _EmployeeList(ctrl: _ctrl)),
          ],
        ),
      ),
    );
  }
}

// ── Org Summary ───────────────────────────────────────────────────────────────

class _OrgSummaryRow extends StatelessWidget {
  final ManagerAttendanceController ctrl;
  const _OrgSummaryRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Pallete.primaryColor.withValues(alpha: 0.12),
          Pallete.primaryColor.withValues(alpha: 0.04),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Pallete.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _SummaryBox('Total',   '${ctrl.summaryTotal}',   Pallete.primaryColor),
          _vDivider(),
          _SummaryBox('Online',  '${ctrl.summaryOnline}',  Pallete.kGreen),
          _vDivider(),
          _SummaryBox('Offline', '${ctrl.summaryOffline}', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1, height: 36, margin: const EdgeInsets.symmetric(horizontal: 12),
    color: Pallete.primaryColor.withValues(alpha: 0.2),
  );
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  const _SummaryBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 22)),
        const SizedBox(height: 2),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
              fontSize: 11,
            )),
      ],
    ),
  );
}

// ── Search + Filter Bar ───────────────────────────────────────────────────────

class _SearchFilterBar extends StatelessWidget {
  final ManagerAttendanceController ctrl;
  const _SearchFilterBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          // Search field
          TextField(
            onChanged: ctrl.onSearchChanged,
            decoration: InputDecoration(
              hintText:     'Search by name or department…',
              prefixIcon:   const Icon(Icons.search, size: 20),
              filled:       true,
              fillColor:    Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border:       OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:   BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:   BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:   BorderSide(color: Pallete.primaryColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Filter chips
          Row(
            children: [
              _FilterChip(label: 'All',     value: 'all',     ctrl: ctrl),
              const SizedBox(width: 8),
              _FilterChip(label: '🟢 Online',  value: 'online',  ctrl: ctrl),
              const SizedBox(width: 8),
              _FilterChip(label: '🔴 Offline', value: 'offline', ctrl: ctrl),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final ManagerAttendanceController ctrl;
  const _FilterChip({required this.label, required this.value, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final selected = ctrl.filterStatus == value;
    return GestureDetector(
      onTap: () => ctrl.setFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:        selected ? Pallete.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Pallete.primaryColor
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color:      selected ? Colors.white
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              fontSize:   13,
            )),
      ),
    );
  }
}

// ── Employee List ─────────────────────────────────────────────────────────────

class _EmployeeList extends StatelessWidget {
  final ManagerAttendanceController ctrl;
  const _EmployeeList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final list = ctrl.filteredEmployees;
    if (list.isEmpty) {
      return const Center(child: Text('No employees found'));
    }
    return RefreshIndicator(
      onRefresh: ctrl.loadOrgToday,
      color: Pallete.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: list.length,
        itemBuilder: (_, i) => _EmployeeAttendanceCard(
          emp: list[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmployeeAttendanceDetailScreen(
                employeeId:   list[i].id,
                employeeName: list[i].fullName ?? list[i].username,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmployeeAttendanceCard extends StatelessWidget {
  final OrgEmployeeAttendance emp;
  final VoidCallback onTap;
  const _EmployeeAttendanceCard({required this.emp, required this.onTap});

  String _fmtTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    final tt     = Theme.of(context).textTheme;
    final color  = emp.isOnline ? Pallete.kGreen : Colors.redAccent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:  const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Avatar + online dot
            Stack(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      Pallete.primaryColor, Pallete.primaryLightColor,
                    ]),
                  ),
                  child: emp.profilePicture != null
                      ? ClipOval(child: Image.network(emp.profilePicture!, fit: BoxFit.cover))
                      : AvatarInitials(fullName: emp.fullName),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color:  color,
                      shape:  BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                      boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(emp.fullName ?? emp.username,
                            style: tt.bodyMedium!.copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:        color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          emp.attendanceTotalMinutes > 0
                              ? emp.attendanceTotalFormatted : (emp.isOnline ? 'Just Online' : '0m'),
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (emp.department != null) emp.department!,
                      if (emp.designation != null) emp.designation!,
                    ].join(' · '),
                    style: tt.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _miniStat('Tasks', '${emp.taskTotal}',     Pallete.primaryColor),
                      const SizedBox(width: 8),
                      _miniStat('Done',  '${emp.taskCompleted}', Pallete.kGreen),
                      const SizedBox(width: 8),
                      _miniStat('Rate',  '${emp.completionRate}%', Pallete.kAmber),
                      if (emp.firstOnline != null) ...[
                        const Spacer(),
                        Text('Since ${_fmtTime(emp.firstOnline!)}',
                            style: tt.bodySmall!.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                fontSize: 10)),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10)),
        const SizedBox(width: 3),
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
      ],
    );
  }
}