import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../config/constant/http_constants.dart';
import '../../../config/routes/api_routes.dart';
import '../../../core/http_client/http_client.dart';
import '../model/response/org_availability_response.dart';
import '../model/response/register_response.dart';

class AuthDataSource {
  final Client _client = kHttpClient;

  Future<OrgAvailabilityResponse?> checkOrgAvailability(String orgCode) async {
    try {
      // final url = Uri.https(HttpConstants.getBaseURL, APIRouteCheckOrgAvailability);
      final url = Uri.parse(
          '${HttpConstants.getBaseURL}$APIRouteCheckOrgAvailability'
      );

      final body = {
        'code': orgCode
      };

      final response = await _client.post(
        url,
        headers: HttpConstants.getHttpHeaders(),
        body: jsonEncode(body),
      );
      debugPrint('body: ${jsonEncode(body).toString()}');
      if (response.statusCode == 200) {
       final jsonResponse = jsonDecode(response.body);
       return OrgAvailabilityResponse.fromJson(jsonResponse);
      }
    } catch (error, stacktrace) {
      debugPrintStack(stackTrace: stacktrace);
    }
    return null;
  }

  Future<RegisterResponse?> registerNewUser(dynamic data) async {
    try {
      // final url = Uri.https(HttpConstants.getBaseURL, APIRouteCheckOrgAvailability);
      final url = Uri.parse(
          '${HttpConstants.getBaseURL}$APIRouteRegisterNewUser'
      );

      final response = await _client.post(
        url,
        headers: HttpConstants.getHttpHeaders(),
        body: jsonEncode(data),
      );

      debugPrint('body: ${jsonEncode(data).toString()}');

      final jsonResponse = jsonDecode(response.body);
      return RegisterResponse.fromJson(jsonResponse);
      // if (response.statusCode == 200 || response.statusCode == 201) {
      //   return RegisterResponse.fromJson(jsonResponse);
      // } else {
      //   return RegisterResponse.fromJson(jsonResponse);
      // }
    } catch (error, stacktrace) {
      debugPrintStack(stackTrace: stacktrace);
    }
    return null;
  }

  Future<RegisterResponse?> loginUser(dynamic data) async {
    try {
      // final url = Uri.https(HttpConstants.getBaseURL, APIRouteCheckOrgAvailability);
      final url = Uri.parse('${HttpConstants.getBaseURL}$APIRouteLogin');

      final response = await _client.post(
        url,
        headers: HttpConstants.getHttpHeaders(),
        body: jsonEncode(data),
      );

      debugPrint('body: ${jsonEncode(data).toString()}');

      final jsonResponse = jsonDecode(response.body);
      return RegisterResponse.fromJson(jsonResponse);
      // if (response.statusCode == 200 || response.statusCode == 201) {
      //   return RegisterResponse.fromJson(jsonResponse);
      // } else {
      //   return RegisterResponse.fromJson(jsonResponse);
      // }
    } catch (error, stacktrace) {
      debugPrintStack(stackTrace: stacktrace);
    }
    return null;
  }

}