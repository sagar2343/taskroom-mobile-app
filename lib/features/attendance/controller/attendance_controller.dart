import 'dart:async';
import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/attendance/data/attendance_datasource.dart';
import 'package:field_work/features/attendance/model/attendance_model.dart';
import 'package:flutter/material.dart';

class AttendanceController {
  final BuildContext context;
  final VoidCallback reloadData;

  final _ds = AttendanceDatasource();

  // ── State ────────────────────────────────────────────────────────────────
  bool isLoading         = true;
  bool isActionInProgress = false;
  String? errorMsg;

  // Today
  AttendanceTodayData? todayData;

  // History tab
  List<AttendanceModel> historyRecords = [];
  AttendanceSummary?    historySummary;
  bool  isLoadingHistory  = false;
  int   historyPage       = 1;
  bool  historyHasMore    = true;

  // Filter mode: 'month' | 'range'
  String filterMode  = 'month';
  DateTime selectedMonth  = DateTime.now();
  DateTime? rangeFrom;
  DateTime? rangeTo;

  // Live timer for current open session
  Timer?    _timer;
  Duration  liveSessionDuration = Duration.zero;

  AttendanceController({required this.context, required this.reloadData});

  Future<void> init() async {
    await loadToday();
    await loadHistory();
    _startTimer();
  }

  // ── Live Timer ────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final open = todayData?.attendance?.openSession;
      if (open != null) {
        liveSessionDuration = DateTime.now().difference(open.startTime);
        reloadData();
      }
    });
  }

  String get liveSessionFormatted {
    final s = liveSessionDuration.inSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2,'0')}m ${sec.toString().padLeft(2,'0')}s';
    return '${m.toString().padLeft(2,'0')}m ${sec.toString().padLeft(2,'0')}s';
  }

  // ── Data Loaders ──────────────────────────────────────────────────────────

  Future<void> loadToday() async {
    isLoading = true;
    reloadData();

    final res = await _ds.getToday();
    if (res?['success'] == true) {
      todayData = AttendanceTodayData.fromJson(
          res!['data'] as Map<String, dynamic>);
      // Reset live timer
      liveSessionDuration = Duration.zero;
      final open = todayData?.attendance?.openSession;
      if (open != null) {
        liveSessionDuration = DateTime.now().difference(open.startTime);
      }
    } else {
      errorMsg = res?['message']?.toString();
    }

    isLoading = false;
    reloadData();
  }

  Future<void> loadHistory({bool refresh = false}) async {
    if (isLoadingHistory) return;
    if (refresh) {
      historyPage    = 1;
      historyRecords = [];
      historyHasMore = true;
    }
    if (!historyHasMore) return;

    isLoadingHistory = true;
    reloadData();

    final params = _buildHistoryParams();
    final res    = await _ds.getHistory(
      page:  historyPage,
      from:  params['from'],
      to:    params['to'],
      month: params['month'],
    );

    if (res?['success'] == true) {
      final data    = res!['data'] as Map<String, dynamic>;
      final records = (data['records'] as List)
          .map((r) => AttendanceModel.fromJson(r as Map<String, dynamic>))
          .toList();
      final pag     = data['pagination'] as Map<String, dynamic>;

      if (refresh || historyPage == 1) historyRecords = records;
      else historyRecords.addAll(records);

      historySummary = AttendanceSummary.fromJson(
          data['summary'] as Map<String, dynamic>);

      historyHasMore = historyPage < (pag['totalPages'] as num).toInt();
      historyPage++;
    }

    isLoadingHistory = false;
    reloadData();
  }

  Map<String, String?> _buildHistoryParams() {
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
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> goOnline() async {
    if (isActionInProgress) return;
    isActionInProgress = true;
    reloadData();

    final res = await _ds.goOnline();

    isActionInProgress = false;
    if (res?['success'] == true) {
      await loadToday();
      _snack('You are now online 🟢', success: true);
    } else {
      _snack(res?['message']?.toString() ?? 'Failed to go online');
    }
    reloadData();
  }

  Future<void> goOffline() async {
    if (isActionInProgress) return;

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Go Offline?'),
        content: const Text('You will be marked as offline. Make sure you have no active tasks.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Go Offline'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    isActionInProgress = true;
    reloadData();

    final res = await _ds.goOffline();

    isActionInProgress = false;
    if (res?['success'] == true) {
      _timer?.cancel();
      liveSessionDuration = Duration.zero;
      await loadToday();
      await loadHistory(refresh: true);
      _snack('You are now offline 🔴', success: true);
    } else {
      _snack(res?['message']?.toString() ?? 'Failed to go offline');
    }
    reloadData();
  }

  // ── Filter helpers ────────────────────────────────────────────────────────

  void setFilterMode(String mode) {
    filterMode = mode;
    loadHistory(refresh: true);
  }

  void prevMonth() {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    loadHistory(refresh: true);
  }

  void nextMonth() {
    final now = DateTime.now();
    if (selectedMonth.year == now.year && selectedMonth.month == now.month) return;
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    loadHistory(refresh: true);
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context:        context,
      firstDate:      DateTime(2024),
      lastDate:       DateTime.now(),
      initialDateRange: rangeFrom != null && rangeTo != null
          ? DateTimeRange(start: rangeFrom!, end: rangeTo!)
          : null,
    );
    if (picked != null) {
      rangeFrom  = picked.start;
      rangeTo    = picked.end;
      filterMode = 'range';
      loadHistory(refresh: true);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _snack(String msg, {bool success = false}) {
    if (!context.mounted) return;
    Helpers.showSnackBar(context, msg,
        type: success ? SnackType.success : SnackType.error);
  }

  void dispose() {
    _timer?.cancel();
  }
}