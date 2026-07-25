import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../config/constant/http_constants.dart';
import '../../../config/routes/api_routes.dart';
import '../../../config/data/local/app_data.dart';
import '../../../core/http_client/http_client.dart';
import '../../../core/utils/helpers.dart';

class ExportService {
  static final _instance = ExportService._();
  ExportService._();
  factory ExportService() => _instance;
  final Client _client = kHttpClient;

  bool isExporting = false;

  Future<File> _getSaveFile(String filename) async {
    if (Platform.isAndroid) {
      // Save to Downloads folder — visible in file manager
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        return File('${downloadsDir.path}/$filename');
      }
    }
    // iOS or fallback — use app documents directory
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$filename');
  }

  Future<void> _download({
    required BuildContext context,
    required String url,
    required String filename,
    required String mimeLabel,
  }) async {
    isExporting = true;
    if (context.mounted) {
      Helpers.showSnackBar(
        context,
        'Generating $mimeLabel report…',
        type: SnackType.normal,
      );
    }
    try {
      final token = AppData().getAccessToken();
      if (token == null) throw Exception('Not authenticated');

      final res = await _client.get(
        Uri.parse(url),
        headers: HttpConstants.getHttpHeaders(token),
      );

      if (res.statusCode == 403) {
        final body   = jsonDecode(res.body);
        final needed = body['neededPlan'] ?? 'higher';
        throw Exception(
          'This feature requires the $needed plan. Please upgrade to access exports.',
        );
      }
      if (res.statusCode != 200) {
        throw Exception('Export failed (${res.statusCode})');
      }

      // Save file to correct location
      final file = await _getSaveFile(filename);
      await file.writeAsBytes(res.bodyBytes);

      if (!context.mounted) return;

      // Try to open the file
      final result = await OpenFilex.open(
        file.path,
        type: filename.endsWith('.pdf')
            ? 'application/pdf'
            : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (context.mounted) {
        if (result.type == ResultType.done) {
          // File opened successfully — no extra message needed
        } else if (result.type == ResultType.noAppToOpen) {
          // No app to open Excel — tell user where to find it
          Helpers.showSnackBar(
            context,
            Platform.isAndroid
                ? 'Saved to Downloads folder. Open with Excel or Sheets app.'
                : 'Saved to app files. Open with Files app.',
            type: SnackType.normal,
          );
        } else {
          Helpers.showSnackBar(
            context,
            Platform.isAndroid
                ? 'Saved to Downloads folder: $filename'
                : 'File saved successfully: $filename',
            type: SnackType.success,
          );
        }
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
    String? employeeId,
    DateTime? from,
    DateTime? to,
    String? status,
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

  Future<void> attendancePdf({
    required BuildContext context,
    String? employeeId, DateTime? from, DateTime? to,
  }) => _download(
    context:  context,
    url:      _buildUrl(APIRouteExportAttendancePdf, employeeId: employeeId, from: from, to: to),
    filename: 'attendance_${_stamp()}.pdf',
    mimeLabel: 'PDF',
  );

  Future<void> attendanceExcel({
    required BuildContext context,
    String? employeeId, DateTime? from, DateTime? to,
  }) => _download(
    context:  context,
    url:      _buildUrl(APIRouteExportAttendanceExcel, employeeId: employeeId, from: from, to: to),
    filename: 'attendance_${_stamp()}.xlsx',
    mimeLabel: 'Excel',
  );

  Future<void> tasksPdf({
    required BuildContext context,
    String? employeeId, DateTime? from, DateTime? to, String? status,
  }) => _download(
    context:  context,
    url:      _buildUrl(APIRouteExportTasksPdf, employeeId: employeeId, from: from, to: to, status: status),
    filename: 'tasks_${_stamp()}.pdf',
    mimeLabel: 'PDF',
  );

  Future<void> tasksExcel({
    required BuildContext context,
    String? employeeId, DateTime? from, DateTime? to, String? status,
  }) => _download(
    context:  context,
    url:      _buildUrl(APIRouteExportTasksExcel, employeeId: employeeId, from: from, to: to, status: status),
    filename: 'tasks_${_stamp()}.xlsx',
    mimeLabel: 'Excel',
  );

  Future<void> teamSummaryPdf({
    required BuildContext context,
    DateTime? from, DateTime? to,
  }) => _download(
    context:  context,
    url:      _buildUrl(APIRouteExportTeamSummaryPdf, from: from, to: to),
    filename: 'team_summary_${_stamp()}.pdf',
    mimeLabel: 'PDF',
  );

  Future<void> teamSummaryExcel({
    required BuildContext context,
    DateTime? from, DateTime? to,
  }) => _download(
    context:  context,
    url:      _buildUrl(APIRouteExportTeamSummaryExcel, from: from, to: to),
    filename: 'team_summary_${_stamp()}.xlsx',
    mimeLabel: 'Excel',
  );

  String _stamp() =>
      DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');
}