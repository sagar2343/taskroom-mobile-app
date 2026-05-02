import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/attendance/data/attendance_datasource.dart';
import 'package:field_work/features/attendance/model/attendance_model.dart';
import 'package:flutter/material.dart';

class ManagerAttendanceController {
  final BuildContext context;
  final VoidCallback reloadData;

  final _ds = AttendanceDatasource();

  bool isLoading = true;
  String? errorMsg;

  // Today's org view
  List<OrgEmployeeAttendance> employees = [];
  int summaryTotal   = 0;
  int summaryOnline  = 0;
  int summaryOffline = 0;

  // Search / filter
  String search     = '';
  String filterStatus = 'all'; // 'all' | 'online' | 'offline'

  List<OrgEmployeeAttendance> get filteredEmployees {
    var list = employees.where((e) {
      if (filterStatus == 'online'  && !e.isOnline) return false;
      if (filterStatus == 'offline' &&  e.isOnline) return false;
      if (search.isNotEmpty) {
        final q = search.toLowerCase();
        return (e.fullName?.toLowerCase().contains(q) ?? false) ||
            e.username.toLowerCase().contains(q) ||
            (e.department?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();
    return list;
  }

  ManagerAttendanceController({required this.context, required this.reloadData});

  Future<void> init() => loadOrgToday();

  Future<void> loadOrgToday() async {
    isLoading = true;
    errorMsg  = null;
    reloadData();

    final res = await _ds.getOrgToday();

    if (res?['success'] == true) {
      final data  = res!['data'] as Map<String, dynamic>;
      final list  = data['employees'] as List;
      employees   = list.map((e) => OrgEmployeeAttendance.fromJson(e as Map<String, dynamic>)).toList();
      final summ  = data['summary'] as Map<String, dynamic>;
      summaryTotal   = (summ['total']   as num?)?.toInt() ?? 0;
      summaryOnline  = (summ['online']  as num?)?.toInt() ?? 0;
      summaryOffline = (summ['offline'] as num?)?.toInt() ?? 0;
    } else {
      errorMsg = res?['message']?.toString() ?? 'Failed to load attendance';
    }

    isLoading = false;
    reloadData();
  }

  void onSearchChanged(String q) {
    search = q;
    reloadData();
  }

  void setFilter(String f) {
    filterStatus = f;
    reloadData();
  }

  void _snack(String msg, {bool success = false}) {
    if (!context.mounted) return;
    Helpers.showSnackBar(context, msg,
        type: success ? SnackType.success : SnackType.error);
  }

  void dispose() {}
}

// ─────────────────────────────────────────────────────────────────────────────
//  Employee detail (for manager to drill into one employee)
// ─────────────────────────────────────────────────────────────────────────────

class EmployeeAttendanceDetailController {
  final BuildContext context;
  final VoidCallback reloadData;
  final String employeeId;

  final _ds = AttendanceDatasource();

  bool isLoading = true;
  String? errorMsg;

  Map<String, dynamic>? employeeInfo;
  List<AttendanceModel> records        = [];
  AttendanceSummary?    periodSummary;
  Map<String, dynamic>? taskStats;

  // ── Filter state (matches employee's own history screen) ─────────────────
  String   filterMode    = 'month'; // 'month' | 'range'
  DateTime selectedMonth = DateTime.now();
  DateTime? rangeFrom;
  DateTime? rangeTo;

  EmployeeAttendanceDetailController({
    required this.context,
    required this.reloadData,
    required this.employeeId,
  });

  Future<void> init() => loadDetail();

  Future<void> loadDetail() async {
    isLoading = true;
    errorMsg  = null;
    reloadData();

    final params = _buildParams();
    final res    = await _ds.getEmployeeDetail(
      employeeId,
      month: params['month'],
      from:  params['from'],
      to:    params['to'],
    );

    if (res?['success'] == true) {
      final data   = res!['data'] as Map<String, dynamic>;
      employeeInfo = data['employee'] as Map<String, dynamic>;
      records      = (data['records'] as List)
          .map((r) => AttendanceModel.fromJson(r as Map<String, dynamic>))
          .toList();
      periodSummary = AttendanceSummary.fromJson(
          data['periodSummary'] as Map<String, dynamic>);
      taskStats = data['taskStats'] as Map<String, dynamic>;
    } else {
      errorMsg = res?['message']?.toString() ?? 'Failed to load';
    }

    isLoading = false;
    reloadData();
  }

  Map<String, String?> _buildParams() {
    if (filterMode == 'month') {
      final m = '${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}';
      return {'month': m, 'from': null, 'to': null};
    } else {
      return {
        'month': null,
        'from': rangeFrom != null ? _fmt(rangeFrom!) : null,
        'to':   rangeTo   != null ? _fmt(rangeTo!)   : null,
      };
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Navigation ────────────────────────────────────────────────────────────

  void prevMonth() {
    filterMode    = 'month';
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    loadDetail();
  }

  void nextMonth() {
    final now = DateTime.now();
    if (selectedMonth.year == now.year && selectedMonth.month == now.month) return;
    filterMode    = 'month';
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    loadDetail();
  }

  void setFilterMode(String mode) {
    filterMode = mode;
    if (mode == 'month') loadDetail();
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context:          context,
      firstDate:        DateTime(2024),
      lastDate:         DateTime.now(),
      initialDateRange: rangeFrom != null && rangeTo != null
          ? DateTimeRange(start: rangeFrom!, end: rangeTo!)
          : null,
    );
    if (picked != null) {
      rangeFrom  = picked.start;
      rangeTo    = picked.end;
      filterMode = 'range';
      loadDetail();
    }
  }

  void dispose() {}
}