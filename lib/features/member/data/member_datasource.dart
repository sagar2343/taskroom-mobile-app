import 'dart:convert';

import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/core/http_client/http_client.dart';
import 'package:field_work/features/member/model/room_member_response.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../config/constant/http_constants.dart';
import '../../../config/routes/api_routes.dart';

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
}