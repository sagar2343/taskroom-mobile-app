import 'dart:convert';
import 'package:field_work/config/constant/http_constants.dart';
import 'package:field_work/config/data/local/app_data.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../config/routes/api_routes.dart';
import '../../../core/http_client/http_client.dart';
import '../../task/model/TaskDetailResponse.dart';

class TaskActionDataSource {
  final Client _client = kHttpClient;
  String get _token => AppData().getAccessToken() ?? '';

  Map<String, String> get _headers => HttpConstants.getHttpHeaders(_token);
  String get _base => HttpConstants.getBaseURL;

  // ── Private HTTP helpers ──────────────────────────────────────────────

  Future<Map<String, dynamic>?> _post(String path, [Map<String, dynamic>? body]) async {
    try {
      final url = Uri.parse('$_base$path');
      final response = await _client.post(
        url,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('POST $path error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final url = Uri.parse('$_base$path');
      final response = await _client.get(url, headers: _headers);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('GET $path error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _patch(String path, [Map<String, dynamic>? body]) async {
    try {
      final url = Uri.parse('$_base$path');
      final response = await _client.patch(
        url,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('PATCH $path error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _put(String path, [Map<String, dynamic>? body]) async {
    try {
      final url = Uri.parse('$_base$path');
      final response = await _client.put(
        url,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('PUT $path error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _delete(String path, [Map<String, dynamic>? body]) async {
    try {
      final url = Uri.parse('$_base$path');
      final request = Request('DELETE', url);
      request.headers.addAll(_headers);
      if (body != null) request.body = jsonEncode(body);
      final streamedResponse = await _client.send(request);
      final response = await Response.fromStream(streamedResponse);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('DELETE $path error: $e');
      return null;
    }
  }

  // ── Manager: Task list & dashboard ───────────────────────────────────

  Future<Map<String, dynamic>?> getTasks({
    String? status,
    String? priority,
    String? roomId,
    String? assignedTo,
    String? date,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = {
      'page': '$page',
      'limit': '$limit',
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (roomId != null) 'roomId': roomId,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (date != null) 'date': date,
    };
    final uri = Uri.parse('$_base$APIRouteTasks').replace(queryParameters: queryParams);
    try {
      final response = await _client.get(uri, headers: _headers);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('GET $APIRouteTasks error: $e');
      return null;
    }
  }

  // Future<Map<String, dynamic>?> getDashboard() =>
  //     _get('$APIRouteTasks/dashboard');

  // ── Shared: Task detail ───────────────────────────────────────────────
  // POST /api/tasks/detail  →  body: { taskId }

  Future<TaskDetailResponse?> getTaskDetail(String taskId) async {
    try {
      final result = await _post(APIRouteTaskDetail, {'taskId': taskId});
      if (result == null) return null;
      return TaskDetailResponse.fromJson(result);
    } catch (e) {
      debugPrint('getTaskDetail error: $e');
      return null;
    }
  }

  // ── Manager: Edit task ────────────────────────────────────────────────
  // PUT /api/tasks/edit  →  body: { taskId, ...fields }

  Future<Map<String, dynamic>?> editTask(
      String taskId, {
        String? title,
        String? note,
        String? priority,
        String? startDatetime,
        String? endDatetime,
        String? assignedTo,
      }) =>
      _put(APIRouteTaskEdit, {
        'taskId': taskId,
        if (title != null) 'title': title,
        if (note != null) 'note': note,
        if (priority != null) 'priority': priority,
        if (startDatetime != null) 'startDatetime': startDatetime,
        if (endDatetime != null) 'endDatetime': endDatetime,
        if (assignedTo != null) 'assignedTo': assignedTo,
      });

  // ── Manager: Cancel task ──────────────────────────────────────────────
  // PATCH /api/tasks/cancel  →  body: { taskId, reason? }

  Future<Map<String, dynamic>?> cancelTask(String taskId, {String? reason}) =>
      _patch(APIRouteTaskCancel, {
        'taskId': taskId,
        if (reason != null) 'reason': reason,
      });

  // ── Manager: Live location ────────────────────────────────────────────
  // POST /api/tasks/live-location  →  body: { taskId }

  // Future<Map<String, dynamic>?> getLiveLocation(String taskId) =>
  //     _post(APIRouteTaskLiveLocation, {'taskId': taskId});

  // ── Manager: Full location trace ──────────────────────────────────────
  // POST /api/tasks/location-trace  →  body: { taskId, stepId? }

  // Future<Map<String, dynamic>?> getLocationTrace(String taskId, {String? stepId}) =>
  //     _post(APIRouteTaskLocationTrace, {
  //       'taskId': taskId,
  //       if (stepId != null) 'stepId': stepId,
  //     });

  // ── Manager: Add step ─────────────────────────────────────────────────
  // POST /api/tasks/steps/add  →  body: { taskId, title, ... }

  // Future<Map<String, dynamic>?> addStep(
  //     String taskId, {
  //       required String title,
  //       String? description,
  //       required String startDatetime,
  //       required String endDatetime,
  //       bool isFieldWorkStep = false,
  //       Map<String, dynamic>? destinationLocation,
  //       int? locationRadiusMeters,
  //       Map<String, dynamic>? validations,
  //     }) =>
  //     _post(APIRouteTaskStepsAdd, {
  //       'taskId': taskId,
  //       'title': title,
  //       'startDatetime': startDatetime,
  //       'endDatetime': endDatetime,
  //       'isFieldWorkStep': isFieldWorkStep,
  //       if (description != null) 'description': description,
  //       if (destinationLocation != null) 'destinationLocation': destinationLocation,
  //       if (locationRadiusMeters != null) 'locationRadiusMeters': locationRadiusMeters,
  //       if (validations != null) 'validations': validations,
  //     });

  // ── Manager: Edit step ────────────────────────────────────────────────
  // PUT /api/tasks/steps/edit  →  body: { taskId, stepId, ...fields }

  // Future<Map<String, dynamic>?> editStep(
  //     String taskId,
  //     String stepId, {
  //       String? title,
  //       String? description,
  //       String? startDatetime,
  //       String? endDatetime,
  //       bool? isFieldWorkStep,
  //       Map<String, dynamic>? destinationLocation,
  //       int? locationRadiusMeters,
  //       Map<String, dynamic>? validations,
  //     }) =>
  //     _put(APIRouteTaskStepsEdit, {
  //       'taskId': taskId,
  //       'stepId': stepId,
  //       if (title != null) 'title': title,
  //       if (description != null) 'description': description,
  //       if (startDatetime != null) 'startDatetime': startDatetime,
  //       if (endDatetime != null) 'endDatetime': endDatetime,
  //       if (isFieldWorkStep != null) 'isFieldWorkStep': isFieldWorkStep,
  //       if (destinationLocation != null) 'destinationLocation': destinationLocation,
  //       if (locationRadiusMeters != null) 'locationRadiusMeters': locationRadiusMeters,
  //       if (validations != null) 'validations': validations,
  //     });

  // ── Manager: Remove step ──────────────────────────────────────────────
  // DELETE /api/tasks/steps/remove  →  body: { taskId, stepId }

  // Future<Map<String, dynamic>?> removeStep(String taskId, String stepId) =>
  //     _delete(APIRouteTaskStepsRemove, {
  //       'taskId': taskId,
  //       'stepId': stepId,
  //     });

  // ── Employee: Get my tasks ────────────────────────────────────────────

  // Future<Map<String, dynamic>?> getMyTasks({
  //   String filter = 'today',
  //   int page = 1,
  //   int limit = 10,
  // }) async {
  //   final queryParams = {
  //     'filter': filter,
  //     'page': '$page',
  //     'limit': '$limit',
  //   };
  //   final uri = Uri.parse('$_base$APIRouteGetMyTasks').replace(queryParameters: queryParams);
  //   try {
  //     final response = await _client.get(uri, headers: _headers);
  //     return jsonDecode(response.body) as Map<String, dynamic>;
  //   } catch (e) {
  //     debugPrint('GET $APIRouteGetMyTasks error: $e');
  //     return null;
  //   }
  // }

//  ── Employee: Start task ──────────────────────────────────────────────
//   POST /api/tasks/start  →  body: { taskId, coordinates? }

  Future<Map<String, dynamic>?> startTask(
      String taskId, {List<double>? coordinates}) async {
    try {
      final url = Uri.parse('$_base$APIRouteTaskStart');
      final body = {
        'taskId': taskId,
        if (coordinates != null) 'coordinates': coordinates,
      };
      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // ── Employee: Start step ──────────────────────────────────────────────
  // POST /api/tasks/steps/start  →  body: { taskId, stepId }
  Future<Map<String, dynamic>?> startStep(String taskId, String stepId) async {
    try {
      final url = Uri.parse('$_base$APIRouteTaskStepsStart');
      final body = {
        'taskId': taskId,
        'stepId': stepId,
      };
      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // ── Employee: Mark reached ────────────────────────────────────────────
  // POST /api/tasks/steps/reached  →  body: { taskId, stepId, coordinates }

  Future<Map<String, dynamic>?> markReached(
      String taskId, String stepId, List<double> coordinates) async {
    try {
      final url = Uri.parse('$_base$APIRouteTaskStepsReached');
      final body = {
        'taskId': taskId,
        'stepId': stepId,
        'coordinates': coordinates,
      };
      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // ── Employee: Complete step ───────────────────────────────────────────
  // POST /api/tasks/steps/complete  →  body: { taskId, stepId, ...fields }

  Future<Map<String, dynamic>?> completeStep(
      String taskId,
      String stepId,
      {
        String? photoUrl,
        String? signatureData,
        String? signatureSignedBy,
        String? signatureRole,
        Map<String, dynamic>? currentLocation,
        String? employeeNotes,
      }) async {
    try {
      final url = Uri.parse('$_base$APIRouteTaskStepsComplete');
      final body = {
        'taskId': taskId,
        'stepId': stepId,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (signatureData != null) 'signatureData': signatureData,
        if (signatureSignedBy != null) 'signatureSignedBy': signatureSignedBy,
        if (signatureRole != null) 'signatureRole': signatureRole,
        if (currentLocation != null) 'currentLocation': currentLocation,
        if (employeeNotes != null) 'employeeNotes': employeeNotes,
      };
      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // ── Employee: Location ping ───────────────────────────────────────────
  // POST /api/tasks/location/ping  →  body: { taskId, stepId, coordinates, ... }

  Future<Map<String, dynamic>?> pingLocation({
    required String taskId,
    required String stepId,
    required List<double> coordinates,
    double? accuracy,
    int? battery,
  }) async {
    try {
      final url = Uri.parse('$_base$APIRouteTaskLocationPing');
      final body = {
        'taskId': taskId,
        'stepId': stepId,
        'coordinates': coordinates,
        if (accuracy != null) 'accuracyMeters': accuracy,
        if (battery != null) 'batteryLevel': battery,
      };

      final response = await _client.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;

    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }


  // ── Attendance ────────────────────────────────────────────────────────

  // Future<Map<String, dynamic>?> punchIn({List<double>? coordinates}) =>
  //     _post(APIRouteAttendancePunchIn, {
  //       if (coordinates != null) 'coordinates': coordinates,
  //     });

  // Future<Map<String, dynamic>?> punchOut({List<double>? coordinates}) =>
  //     _post(APIRouteAttendancePunchOut, {
  //       if (coordinates != null) 'coordinates': coordinates,
  //     });

  // Future<Map<String, dynamic>?> getAttendanceToday() =>
  //     _get(APIRouteAttendanceToday);
  //
  // Future<Map<String, dynamic>?> getAttendanceHistory({
  //   int page = 1,
  //   int limit = 30,
  //   String? month,
  //   String? employeeId,
  // }) async {
  //   final queryParams = {
  //     'page': '$page',
  //     'limit': '$limit',
  //     if (month != null) 'month': month,
  //     if (employeeId != null) 'employeeId': employeeId,
  //   };
  //   final uri = Uri.parse('$_base$APIRouteAttendanceHistory')
  //       .replace(queryParameters: queryParams);
  //   try {
  //     final response = await _client.get(uri, headers: _headers);
  //     return jsonDecode(response.body) as Map<String, dynamic>;
  //   } catch (e) {
  //     debugPrint('GET $APIRouteAttendanceHistory error: $e');
  //     return null;
  //   }
  // }
}