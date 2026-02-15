import 'dart:convert';
import 'package:field_work/config/data/local/app_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import '../../../config/constant/http_constants.dart';
import '../../../config/routes/api_routes.dart';
import '../../../core/http_client/http_client.dart';
import '../model/profile_data_response.dart';

class ProfileDatasource {
  final Client _client = kHttpClient;
  final token = AppData().getAccessToken();

  Future<UserProfileResponse?> geUserProfile() async {
    try {
      final url = Uri.parse(
          '${HttpConstants.getBaseURL}$APIRouteProfile'
      );

      final response = await _client.get(
          url,
          headers: HttpConstants.getHttpHeaders(token),
      );

      // if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return UserProfileResponse.fromJson(jsonResponse);
      // }

    } catch(e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<UserProfileResponse?> updateProfile(dynamic data) async {
    try {
      final url = Uri.parse(
          '${HttpConstants.getBaseURL}$APIRouteProfile'
      );

      final response = await _client.put(
        url,
        headers: HttpConstants.getHttpHeaders(token),
        body: jsonEncode(data),
      );

      // if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return UserProfileResponse.fromJson(jsonResponse);
      // }

    } catch(e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<UserProfileResponse?> changePassword(dynamic data) async {
    try {
      final url = Uri.parse(
          '${HttpConstants.getBaseURL}$APIRouteChangePassword'
      );

      final response = await _client.put(
        url,
        headers: HttpConstants.getHttpHeaders(token),
        body: jsonEncode(data),
      );

      // if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return UserProfileResponse.fromJson(jsonResponse);
      // }

    } catch(e) {
      debugPrint(e.toString());
      return null;
    }
  }

}