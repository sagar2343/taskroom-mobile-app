import '../../home/models/room_model.dart';

class CreateRoomResponse {
  final bool? success;
  final String? message;
  final CreateRoomData? data;

  CreateRoomResponse({
    this.success,
    this.message,
    this.data,
  });

  factory CreateRoomResponse.fromJson(Map<String, dynamic> json) {
    return CreateRoomResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? CreateRoomData.fromJson(json['data'])
          : null,
    );
  }
}

class CreateRoomData {
  final RoomModel? room;

  CreateRoomData({this.room});

  factory CreateRoomData.fromJson(Map<String, dynamic> json) {
    return CreateRoomData(
      room: json['room'] != null
          ? RoomModel.fromJson(json['room'])
          : null,
    );
  }
}

