import 'dart:convert';
import 'package:field_work/config/constant/http_constants.dart';
import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/config/routes/api_routes.dart';
import 'package:field_work/core/http_client/http_client.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../model/TaskDetailResponse.dart';

/// All manager-side task API calls live here.
/// TaskActionDataSource (employee-only) no longer contains any manager methods.
class ManagerTaskDatasource {
  final Client _client = kHttpClient;

  String get _token  => AppData().getAccessToken() ?? '';
  Map<String, String> get _headers => HttpConstants.getHttpHeaders(_token);
  String get _base   => HttpConstants.getBaseURL;

  // ── Private helpers ────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _post(String path,
      [Map<String, dynamic>? body]) async {
    try {
      final res = await _client.post(Uri.parse('$_base$path'),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('POST $path: $e'); return null; }
  }

  Future<Map<String, dynamic>?> _get(String path,
      {Map<String, String>? query}) async {
    try {
      final uri = Uri.parse('$_base$path')
          .replace(queryParameters: query);
      final res = await _client.get(uri, headers: _headers);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('GET $path: $e'); return null; }
  }

  Future<Map<String, dynamic>?> _patch(String path,
      [Map<String, dynamic>? body]) async {
    try {
      final res = await _client.patch(Uri.parse('$_base$path'),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('PATCH $path: $e'); return null; }
  }

  Future<Map<String, dynamic>?> _put(String path,
      [Map<String, dynamic>? body]) async {
    try {
      final res = await _client.put(Uri.parse('$_base$path'),
          headers: _headers,
          body: body != null ? jsonEncode(body) : null);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('PUT $path: $e'); return null; }
  }

  // ── Create task ─────────────────────────────────────────────────────────
  // POST /api/tasks

  Future<Map<String, dynamic>?> createTask(Map<String, dynamic> body) async {
    try {
      final res = await _client.post(Uri.parse('$_base$APIRouteTasks'),
          headers: _headers, body: jsonEncode(body));
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('createTask: $e'); return null; }
  }

  // ── Task list  GET /api/tasks ──────────────────────────────────────────

  Future<Map<String, dynamic>?> getTasks({
    String? status, String? priority, String? roomId,
    String? assignedTo, String? date, int page = 1, int limit = 20,
  }) => _get(APIRouteTasks, query: {
    'page': '$page', 'limit': '$limit',
    if (status     != null) 'status':     status,
    if (priority   != null) 'priority':   priority,
    if (roomId     != null) 'roomId':     roomId,
    if (assignedTo != null) 'assignedTo': assignedTo,
    if (date       != null) 'date':       date,
  });

  // ── Dashboard  GET /api/tasks/dashboard ───────────────────────────────

  Future<Map<String, dynamic>?> getDashboard() => _get(APIRouteTaskDashboard);

  // ── Task detail  POST /api/tasks/detail ───────────────────────────────

  Future<TaskDetailResponse?> getTaskDetail(String taskId) async {
    try {
      final raw = await _post(APIRouteTaskDetail, {'taskId': taskId});
      if (raw == null) return null;
      return TaskDetailResponse.fromJson(raw);
    } catch (e) { debugPrint('getTaskDetail: $e'); return null; }
  }

  // ── Edit task  PUT /api/tasks/edit ────────────────────────────────────

  Future<Map<String, dynamic>?> editTask(String taskId, {
    String? title, String? note, String? priority,
    String? startDatetime, String? endDatetime, String? assignedTo,
  }) => _put(APIRouteTaskEdit, {
    'taskId': taskId,
    if (title         != null) 'title':         title,
    if (note          != null) 'note':           note,
    if (priority      != null) 'priority':       priority,
    if (startDatetime != null) 'startDatetime':  startDatetime,
    if (endDatetime   != null) 'endDatetime':    endDatetime,
    if (assignedTo    != null) 'assignedTo':     assignedTo,
  });

  // ── Cancel task  PATCH /api/tasks/cancel ─────────────────────────────

  Future<Map<String, dynamic>?> cancelTask(String taskId,
      {String? reason}) =>
      _patch(APIRouteTaskCancel, {
        'taskId': taskId,
        if (reason != null) 'reason': reason,
      });

  // ── Live location  POST /api/tasks/live-location ──────────────────────

  Future<Map<String, dynamic>?> getLiveLocation(String taskId) =>
      _post(APIRouteTaskLiveLocation, {'taskId': taskId});

  // ── Full route trace  POST /api/tasks/location-trace ─────────────────

  Future<Map<String, dynamic>?> getLocationTrace(String taskId,
      {String? stepId}) =>
      _post(APIRouteTaskLocationTrace, {
        'taskId': taskId,
        if (stepId != null) 'stepId': stepId,
      });

  // ── Add step  POST /api/tasks/steps/add ──────────────────────────────

  Future<Map<String, dynamic>?> addStep(String taskId, {
    required String title, String? description,
    required String startDatetime, required String endDatetime,
    bool isFieldWorkStep = false,
    Map<String, dynamic>? destinationLocation,
    int? locationRadiusMeters, Map<String, dynamic>? validations,
  }) => _post(APIRouteTaskStepsAdd, {
    'taskId': taskId, 'title': title,
    'startDatetime': startDatetime, 'endDatetime': endDatetime,
    'isFieldWorkStep': isFieldWorkStep,
    if (description         != null) 'description':         description,
    if (destinationLocation != null) 'destinationLocation': destinationLocation,
    if (locationRadiusMeters!= null) 'locationRadiusMeters': locationRadiusMeters,
    if (validations         != null) 'validations':         validations,
  });

  // ── Edit step  PUT /api/tasks/steps/edit ──────────────────────────────

  Future<Map<String, dynamic>?> editStep(String taskId, String stepId, {
    String? title, String? description,
    String? startDatetime, String? endDatetime,
    bool? isFieldWorkStep, Map<String, dynamic>? destinationLocation,
    int? locationRadiusMeters, Map<String, dynamic>? validations,
  }) => _put(APIRouteTaskStepsEdit, {
    'taskId': taskId, 'stepId': stepId,
    if (title               != null) 'title':               title,
    if (description         != null) 'description':         description,
    if (startDatetime       != null) 'startDatetime':       startDatetime,
    if (endDatetime         != null) 'endDatetime':         endDatetime,
    if (isFieldWorkStep     != null) 'isFieldWorkStep':     isFieldWorkStep,
    if (destinationLocation != null) 'destinationLocation': destinationLocation,
    if (locationRadiusMeters!= null) 'locationRadiusMeters': locationRadiusMeters,
    if (validations         != null) 'validations':         validations,
  });

  // ── Remove step  DELETE /api/tasks/steps/remove ───────────────────────

  Future<Map<String, dynamic>?> removeStep(
      String taskId, String stepId) async {
    try {
      final url     = Uri.parse('$_base$APIRouteTaskStepsRemove');
      final request = Request('DELETE', url)
        ..headers.addAll(_headers)
        ..body = jsonEncode({'taskId': taskId, 'stepId': stepId});
      final streamed = await _client.send(request);
      final res      = await Response.fromStream(streamed);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) { debugPrint('removeStep: $e'); return null; }
  }
}