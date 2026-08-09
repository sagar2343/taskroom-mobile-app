import 'package:field_work/features/attendance/data/attendance_datasource.dart';
import 'package:field_work/features/attendance/model/attendance_model.dart';
import 'package:flutter/material.dart';

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

  // ── Task Productivity scope toggle ──────────────────────────────────────
  // false (default) = Task Productivity card is scoped to the same
  // month/range as everything else on this screen.
  // true = Task Productivity card shows all-time stats since the
  // employee's account was created, ignoring the month/range filter.
  // Independent of filterMode — toggling this does NOT change what the
  // Daily Breakdown / Period Summary show, only the Task Productivity card.
  bool showAllTimeTasks = false;

  EmployeeAttendanceDetailController({
    required this.context,
    required this.reloadData,
    required this.employeeId,
  });

  Future<void> init() => loadDetail();

  void toggleAllTimeTasks() {
    showAllTimeTasks = !showAllTimeTasks;
    loadDetail();
  }

  /// Explicit setter — used by the segmented "This Month / All Time" pill
  /// so tapping the already-active option is a no-op instead of re-fetching.
  void setAllTimeTasks(bool value) {
    if (showAllTimeTasks == value) return;
    showAllTimeTasks = value;
    loadDetail();
  }

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
      allTimeTasks: showAllTimeTasks,
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

  // ── Human-readable label for whatever period is currently selected ───────
  // Used by the Task Productivity scope toggle so it never says a stale
  // "This Month" while a different month (or a custom date range) is
  // actually selected — e.g. shows "Jul 2026" after navigating to last
  // month, or "7 Aug" / "3 Aug – 7 Aug" for a date-range selection.
  static const _monthNames = ['Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'];

  String get periodLabel {
    if (filterMode == 'month') {
      final now = DateTime.now();
      final isCurrentMonth =
          selectedMonth.year == now.year && selectedMonth.month == now.month;
      return isCurrentMonth
          ? 'This Month'
          : '${_monthNames[selectedMonth.month - 1]} ${selectedMonth.year}';
    }

    if (rangeFrom == null || rangeTo == null) return 'Selected Range';
    final f = rangeFrom!, t = rangeTo!;
    final sameDay = f.year == t.year && f.month == t.month && f.day == t.day;
    return sameDay ? _shortLabel(f) : '${_shortLabel(f)} – ${_shortLabel(t)}';
  }

  String _shortLabel(DateTime d) => '${d.day} ${_monthNames[d.month - 1]}';

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