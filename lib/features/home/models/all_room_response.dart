import 'package:field_work/features/home/models/room_model.dart';

class AllRoomResponse {
  final bool? success;
  final String? message;
  final AllRoomData? data;

  AllRoomResponse({
    this.success,
    this.message,
    this.data,
  });

  factory AllRoomResponse.fromJson(Map<String, dynamic> json) {
    return AllRoomResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? AllRoomData.fromJson(json['data'])
          : null,
    );
  }
}

class AllRoomData {
  final List<RoomModel>? rooms;
  final PaginationModel? pagination;

  AllRoomData({
    this.rooms,
    this.pagination,
  });

  factory AllRoomData.fromJson(Map<String, dynamic> json) {
    return AllRoomData(
      rooms: json['rooms'] != null
          ? List<RoomModel>.from(
        json['rooms'].map((e) => RoomModel.fromJson(e)),
      )
          : [],
      pagination: json['pagination'] != null
          ? PaginationModel.fromJson(json['pagination'])
          : null,
    );
  }
}

class PaginationModel {
  final int? currentPage;
  final int? totalPages;
  final int? totalRooms;
  final int? limit;

  PaginationModel({
    this.currentPage,
    this.totalPages,
    this.totalRooms,
    this.limit,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      currentPage: json['currentPage'],
      totalPages: json['totalPages'],
      totalRooms: json['totalRooms'],
      limit: json['limit'],
    );
  }
}