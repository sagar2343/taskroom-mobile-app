import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../config/constant/http_constants.dart';
import '../../../config/routes/api_routes.dart';
import '../../../config/data/local/app_data.dart';
import '../../../core/utils/helpers.dart';

class ExportService {
  static final _instance = ExportService._();
  ExportService._();
  factory ExportService() => _instance;

  bool isExporting = false;

  Future<void> _download({
    required BuildContext context,
    required String url,
    required String filename,
    required String mimeLabel,
  }) async {
    isExporting = true;
    if (context.mounted) {
      Helpers.showSnackBar(context, 'Generating $mimeLabel report…',
          type: SnackType.normal);
    }
    try {
      final token = AppData().getAccessToken();
      if (token == null) throw Exception('Not authenticated');

      final res = await http.get(
        Uri.parse(url),
        headers: HttpConstants.getHttpHeaders(token),
      );

      if (res.statusCode == 403) {
        throw Exception('This feature requires the Pro plan or higher.');
      }
      if (res.statusCode != 200) {
        throw Exception('Export failed (${res.statusCode})');
      }

      final dir    = await getTemporaryDirectory();
      final file   = File('${dir.path}/$filename');
      await file.writeAsBytes(res.bodyBytes);

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        throw Exception('Could not open file: ${result.message}');
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          type: SnackType.error,
        );
      }
    } finally {
      isExporting = false;
    }
  }

  String _buildUrl(String route, {
    String? employeeId, DateTime? from, DateTime? to, String? status,
  }) {
    final params = <String, String>{};
    if (employeeId != null) params['employeeId'] = employeeId;
    if (from != null) params['from'] = from.toIso8601String().substring(0, 10);
    if (to   != null) params['to']   = to.toIso8601String().substring(0, 10);
    if (status != null) params['status'] = status;
    return Uri.parse('${HttpConstants.getBaseURL}$route')
        .replace(queryParameters: params.isEmpty ? null : params)
        .toString();
  }

  Future<void> attendancePdf({required BuildContext context,
    String? employeeId, DateTime? from, DateTime? to}) =>
      _download(context: context,
          url: _buildUrl(APIRouteExportAttendancePdf, employeeId: employeeId, from: from, to: to),
          filename: 'attendance_${_stamp()}.pdf', mimeLabel: 'PDF');

  Future<void> attendanceExcel({required BuildContext context,
    String? employeeId, DateTime? from, DateTime? to}) =>
      _download(context: context,
          url: _buildUrl(APIRouteExportAttendanceExcel, employeeId: employeeId, from: from, to: to),
          filename: 'attendance_${_stamp()}.xlsx', mimeLabel: 'Excel');

  Future<void> tasksPdf({required BuildContext context,
    String? employeeId, DateTime? from, DateTime? to, String? status}) =>
      _download(context: context,
          url: _buildUrl(APIRouteExportTasksPdf, employeeId: employeeId, from: from, to: to, status: status),
          filename: 'tasks_${_stamp()}.pdf', mimeLabel: 'PDF');

  Future<void> tasksExcel({required BuildContext context,
    String? employeeId, DateTime? from, DateTime? to, String? status}) =>
      _download(context: context,
          url: _buildUrl(APIRouteExportTasksExcel, employeeId: employeeId, from: from, to: to, status: status),
          filename: 'tasks_${_stamp()}.xlsx', mimeLabel: 'Excel');

  Future<void> teamSummaryPdf({required BuildContext context,
    DateTime? from, DateTime? to}) =>
      _download(context: context,
          url: _buildUrl(APIRouteExportTeamSummaryPdf, from: from, to: to),
          filename: 'team_summary_${_stamp()}.pdf', mimeLabel: 'PDF');

  String _stamp() =>
      DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');
}
