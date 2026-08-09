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

  void dispose() {}
}