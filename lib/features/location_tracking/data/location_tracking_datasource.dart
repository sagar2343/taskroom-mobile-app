// lib/features/location_tracking/data/location_tracking_datasource.dart
//
// Two responsibilities:
//   1. REST  – GET /api/tasks/active-status
//   2. REST  – POST /api/tasks/location/ping  (route trace persistence)
//
// WebSocket is handled separately in LocationBackgroundService.

import 'dart:convert';
import 'package:field_work/config/constant/http_constants.dart';
import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/config/routes/api_routes.dart';
import 'package:field_work/core/http_client/http_client.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import '../model/active_task_status.dart';


class LocationTrackingDatasource {
  final Client _client = kHttpClient;

  String get _token   => AppData().getAccessToken() ?? '';
  Map<String, String> get _headers => HttpConstants.getHttpHeaders(_token);
  String get _base    => HttpConstants.getBaseURL;

  // ── GET /api/tasks/active-status ──────────────────────────────────────────
  Future<ActiveTaskStatus?> getActiveStatus() async {
    try {
      final uri = Uri.parse('$_base$APIRouteTaskActiveStatus');
      final res = await _client.get(uri, headers: _headers);
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        return ActiveTaskStatus.fromJson(json);
      }
      return null;
    } catch (e) {
      debugPrint('[ActiveStatus] error: $e');
      return null;
    }
  }

  // ── POST /api/tasks/location/ping ─────────────────────────────────────────
  // Called by background service on a timer to persist the route trace.
  Future<bool> pingLocation({
    required String taskId,
    required String stepId,
    required double lat,
    required double lng,
    double? accuracy,
    int? battery,
  }) async {
    try {
      final uri  = Uri.parse('$_base$APIRouteTaskLocationPing');
      final body = jsonEncode({
        'taskId':      taskId,
        'stepId':      stepId,
        'coordinates': [lng, lat],   // GeoJSON: [longitude, latitude]
        if (accuracy != null) 'accuracyMeters': accuracy,
        if (battery  != null) 'batteryLevel':   battery,
      });
      final res = await _client.post(uri, headers: _headers, body: body);
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json['success'] == true;
    } catch (e) {
      debugPrint('[Ping] error: $e');
      return false;
    }
  }
}