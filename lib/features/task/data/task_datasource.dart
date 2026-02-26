import 'dart:convert';

import 'package:field_work/config/constant/http_constants.dart';
import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/core/http_client/http_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import '../../../config/routes/api_routes.dart';
import '../model/task_list_response.dart';

class TaskDataSource {
  final Client _client = kHttpClient;
  final token = AppData().getAccessToken();

  // ── Manager: get all tasks (with filters)
  Future<TaskListResponse?> getManagerTasks({
    String? roomId,
    String? status,
    String? assignedTo,
    String? priority,
    String? date,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (roomId != null) 'roomId': roomId,
        if (status != null && status != 'all') 'status': status,
        if (assignedTo != null) 'assignedTo': assignedTo,
        if (priority != null && priority != 'all') 'priority': priority,
        if (date != null) 'date': date,
      };

      final url = Uri.parse('${HttpConstants.getBaseURL}$APIRouteGetTasks')
          .replace(queryParameters: queryParams);

      final response = await _client.get(
        url, 
        headers: HttpConstants.getHttpHeaders(token)
      );

      final jsonResponse = jsonDecode(response.body);
      return TaskListResponse.fromJson(jsonResponse);

    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  // ── Employee: get my tasks (with filter)
  Future<TaskListResponse?> getMyTasks({
    String filter = 'today', // today | upcoming | completed | active
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'filter': filter,
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null && status != 'all') 'status': status,
      };

      final url = Uri.parse(
        '${HttpConstants.getBaseURL}$APIRouteGetMyTasks',
      ).replace(queryParameters: queryParams);

      final response = await _client.get(
        url,
        headers: HttpConstants.getHttpHeaders(token),
      );

      final jsonResponse = jsonDecode(response.body);
      return TaskListResponse.fromJson(jsonResponse);
    } catch (e) {
      debugPrint('getMyTasks error: $e');
      return null;
    }
  }


}