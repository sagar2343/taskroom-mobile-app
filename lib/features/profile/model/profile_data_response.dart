import '../../auth/model/user_model.dart';

class UserProfileResponse {
  final bool? success;
  final String? message;
  final UserProfileData? data;

  UserProfileResponse({
    this.success,
    this.message,
    this.data,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? UserProfileData.fromJson(json['data'])
          : null,
    );
  }
}

class UserProfileData {
  final UserModel? user;

  UserProfileData({this.user});

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      user: json['user'] != null
          ? UserModel.fromJson(json['user'])
          : null,
    );
  }
}
