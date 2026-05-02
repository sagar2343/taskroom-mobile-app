import 'dart:convert';
import 'package:field_work/config/constant/http_constants.dart';
import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/core/http_client/http_client.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import '../../../config/routes/api_routes.dart';

class AttendanceDatasource {
  final Client _client = kHttpClient;

  String get _base => HttpConstants.getBaseURL;
  Map<String, String> get _headers => HttpConstants.getHttpHeaders(AppData().getAccessToken());

  Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _client.post(
        Uri.parse('$_base$path'),
        headers: _headers,
        body:    jsonEncode(body),
      );
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('POST $path error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _get(String path, [Map<String, String>? params]) async {
    try {
      final uri = Uri.parse('$_base$path').replace(queryParameters: params);
      final res = await _client.get(uri, headers: _headers);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('GET $path error: $e');
      return null;
    }
  }

  // ── Employee ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> goOnline({List<double>? coordinates}) =>
      _post(APIRouteAttendanceGoOnline, {
        if (coordinates != null) 'coordinates': coordinates,
      });

  Future<Map<String, dynamic>?> goOffline({List<double>? coordinates}) =>
      _post(APIRouteAttendanceGoOffline, {
        if (coordinates != null) 'coordinates': coordinates,
      });

  Future<Map<String, dynamic>?> getToday() => _get(APIRouteAttendanceToday);

  Future<Map<String, dynamic>?> getHistory({
    int page    = 1,
    int limit   = 31,
    String? from,
    String? to,
    String? month,
    String? employeeId,
  }) =>
      _get(APIRouteAttendanceHistory, {
        'page':  page.toString(),
        'limit': limit.toString(),
        if (from       != null) 'from':       from,
        if (to         != null) 'to':         to,
        if (month      != null) 'month':      month,
        if (employeeId != null) 'employeeId': employeeId,
      });

  // ── Manager ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getOrgToday() => _get(APIRouteAttendanceOrgToday);

  Future<Map<String, dynamic>?> getEmployeeDetail(
      String employeeId, {
        String? from,
        String? to,
        String? month,
      }) =>
      _get('$APIRouteAttendaceOfEmployee$employeeId', {
        if (from  != null) 'from':  from,
        if (to    != null) 'to':    to,
        if (month != null) 'month': month,
      });
}