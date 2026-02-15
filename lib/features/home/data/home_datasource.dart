import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../config/constant/http_constants.dart';
import '../../../config/data/local/app_data.dart';
import '../../../config/routes/api_routes.dart';
import '../../../core/http_client/http_client.dart';
import '../models/all_room_response.dart';

class HomeDataSource{
  final Client _client = kHttpClient;
  final token = AppData().getAccessToken();

  Future<AllRoomResponse?> getMyRoom({
    required int page,
    required int limit,
    required String category,
    required String search
  }) async {
    try {
      final queryParameter = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (category.isNotEmpty) 'category': category,
        if (search.isNotEmpty) 'search': search,
      };

      final url = Uri.parse('${HttpConstants.getBaseURL}$APIRouteGetMyRooms')
          .replace(queryParameters: queryParameter);

      final response = await _client.get(
        url,
        headers: HttpConstants.getHttpHeaders(token),
      );

      final jsonResponse = jsonDecode(response.body);
      return AllRoomResponse.fromJson(jsonResponse);

    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

}