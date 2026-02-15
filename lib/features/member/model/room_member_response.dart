import '../../home/models/room_model.dart';

class RoomMemberResponse {
  final bool? success;
  final RoomMemberData? data;

  RoomMemberResponse({
    this.success,
    this.data,
  });

  factory RoomMemberResponse.fromJson(Map<String, dynamic> json) {
    return RoomMemberResponse(
      success: json['success'],
      data: json['data'] != null
          ? RoomMemberData.fromJson(json['data'])
          : null,
    );
  }
}

class RoomMemberData {
  final List<RoomMemberItem>? members;
  final int? totalMembers;

  RoomMemberData({
    this.members,
    this.totalMembers,
  });

  factory RoomMemberData.fromJson(Map<String, dynamic> json) {
    return RoomMemberData(
      members: json['members'] != null
          ? List<RoomMemberItem>.from(
        json['members'].map((e) => RoomMemberItem.fromJson(e)),
      )
          : [],
      totalMembers: json['totalMembers'],
    );
  }
}

class RoomMemberItem {
  final RoomMemberUser? user;
  final String? status;
  final String? role;
  final String? id;
  final DateTime? joinedAt;

  RoomMemberItem({
    this.user,
    this.status,
    this.role,
    this.id,
    this.joinedAt,
  });

  factory RoomMemberItem.fromJson(Map<String, dynamic> json) {
    return RoomMemberItem(
      user: json['user'] != null
          ? RoomMemberUser.fromJson(json['user'])
          : null,
      status: json['status'],
      role: json['role'],
      id: json['_id'],
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'])
          : null,
    );
  }
}
