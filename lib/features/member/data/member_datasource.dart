import 'dart:convert';

import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/core/http_client/http_client.dart';
import 'package:field_work/features/member/model/room_member_response.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../config/constant/http_constants.dart';
import '../../../config/routes/api_routes.dart';
import '../model/org_member_response.dart';

class MemberDatasource {
  final Client _client = kHttpClient;
  final token = AppData().getAccessToken();

  Future<RoomMemberResponse?> getRoomMembers(String roomId) async {
    try {
      final url = Uri.parse('${HttpConstants.getBaseURL}$APIRouteRoomMember/$roomId');
      final response = await _client.get(
        url,
        headers: HttpConstants.getHttpHeaders(token),
      );

      final jsonResponse = jsonDecode(response.body);
      return RoomMemberResponse.fromJson(jsonResponse);

    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<Map<String, dynamic>?> removeMember(String roomId, String userId) async {
    try {
      final url = Uri.parse('${HttpConstants.getBaseURL}$APIRouteRemoveMember');
      final body = {
        "userId": userId,
        "roomId": roomId
      };
      final response = await _client.delete(
        url,
        headers: HttpConstants.getHttpHeaders(token),
        body: jsonEncode(body)
      );

      final jsonResponse = jsonDecode(response.body);
      return jsonResponse;

    } catch(e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<OrgAllMemberResponse?> getOrgAllMembers({
    required int page,
    required int limit,
    required String role,
    required String search
  }) async {
    try {
      final queryParameter = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (role.isNotEmpty) 'role': role,
        if (search.isNotEmpty) 'search': search,
      };

      final url = Uri.parse('${HttpConstants.getBaseURL}$APIRouteGetAllOrgMembers')
          .replace(queryParameters: queryParameter);

      final response = await _client.get(
        url,
        headers: HttpConstants.getHttpHeaders(token),
      );

      final jsonResponse = jsonDecode(response.body);
      return OrgAllMemberResponse.fromJson(jsonResponse);

    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}