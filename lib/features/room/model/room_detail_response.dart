import '../../home/models/room_model.dart';

class RoomDetailResponse {
  final bool? success;
  final String? message;
  final RoomDetailData? data;

  RoomDetailResponse({
    this.success,
    this.message,
    this.data,
  });

  factory RoomDetailResponse.fromJson(Map<String, dynamic> json) {
    return RoomDetailResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? RoomDetailData.fromJson(json['data'])
          : null,
    );
  }
}

class RoomDetailData {
  final RoomModel? room;

  RoomDetailData({this.room});

  factory RoomDetailData.fromJson(Map<String, dynamic> json) {
    return RoomDetailData(
      room: json['room'] != null
          ? RoomModel.fromJson(json['room'])
          : null,
    );
  }
}
