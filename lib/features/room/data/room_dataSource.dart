import 'dart:convert';
import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/core/http_client/http_client.dart';
import 'package:field_work/features/room/model/create_room_response.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../../../config/constant/http_constants.dart';
import '../../../config/routes/api_routes.dart';
import '../model/room_detail_response.dart';

class RoomDataSource {
  final Client _client = kHttpClient;
  final token = AppData().getAccessToken();

  Future<Map<String, dynamic>?> joinRoom({required String roomCode}) async {
    try {
      final url = Uri.parse('${HttpConstants.getBaseURL}$APIRouteJoinRoom');
      final body = {"roomCode": roomCode};
      final response = await _client.post(
          url,
          headers: HttpConstants.getHttpHeaders(token),
          body: jsonEncode(body)
      );
      debugPrint('body: ${jsonEncode(body).toString()}');
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse;

    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<RoomDetailResponse?> getRoomDetail({required String roomId}) async {
    try {
      final url = Uri.parse('${HttpConstants.getBaseURL}$APIRouteRoom/$roomId');

      final response = await _client.get(
          url,
          headers: HttpConstants.getHttpHeaders(token),
      );

      final jsonResponse = jsonDecode(response.body);
      return RoomDetailResponse.fromJson(jsonResponse);

    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<CreateRoomResponse?> createRoom({
    required String name,
    required String desc,
    required String category,
    required bool autoAcceptMember,
    required bool allowMembersToSeeEachOther,
    required int maxMembers,
  }) async {
    try {
      final url = Uri.parse('${HttpConstants.getBaseURL}$APIRouteRoom');
      final body = {
        "name": name,
        "description": desc,
        "category": category,
        "settings": {
          "autoAcceptMembers": autoAcceptMember,
          "allowMembersToSeeEachOther": allowMembersToSeeEachOther,
          "maxMembers": maxMembers
        }
      };
      final response = await _client.post(
          url,
          headers: HttpConstants.getHttpHeaders(token),
          body: jsonEncode(body)
      );
      debugPrint('body: ${jsonEncode(body).toString()}');
      final jsonResponse = jsonDecode(response.body);
      return CreateRoomResponse.fromJson(jsonResponse);

    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<CreateRoomResponse?> updateRoom({
    required String roomId,
    required String name,
    required String desc,
    required String category,
    required bool autoAcceptMember,
    required bool allowMembersToSeeEachOther,
    required int maxMembers,
  }) async {
    try {
      final url = Uri.parse('${HttpConstants.getBaseURL}$APIRouteRoom/$roomId');
      final body = {
        "name": name,
        "description": desc,
        "category": category,
        "settings": {
          "autoAcceptMembers": autoAcceptMember,
          "allowMembersToSeeEachOther": allowMembersToSeeEachOther,
          "maxMembers": maxMembers
        }
      };
      final response = await _client.put(
          url,
          headers: HttpConstants.getHttpHeaders(token),
          body: jsonEncode(body)
      );
      debugPrint('body: ${jsonEncode(body).toString()}');
      final jsonResponse = jsonDecode(response.body);
      return CreateRoomResponse.fromJson(jsonResponse);

    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}