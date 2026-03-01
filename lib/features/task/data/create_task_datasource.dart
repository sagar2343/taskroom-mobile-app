import 'dart:convert';

import 'package:field_work/config/constant/http_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../config/data/local/app_data.dart';
import '../../../config/routes/api_routes.dart';
import '../../../core/http_client/http_client.dart';

class CreateTaskDataSource {
  final Client _client = kHttpClient;
  final token = AppData().getAccessToken();

  Future<Map<String, dynamic>?> createTask(Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('${HttpConstants.getBaseURL}$APIRouteTasks');
      final response = await _client.post(
        url,
        body: jsonEncode(body),
        headers: HttpConstants.getHttpHeaders(token),
      );

      final jsonResponse = jsonDecode(response.body);
      return jsonResponse;

    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

}