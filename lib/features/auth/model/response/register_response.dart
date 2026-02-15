import 'package:field_work/features/auth/model/user_model.dart';

class RegisterResponse {
  final bool? success;
  final String? message;
  final RegisterData? data;

  RegisterResponse({
    this.success,
    this.message,
    this.data,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? RegisterData.fromJson(json['data'])
          : null,
    );
  }
}

class RegisterData {
  final UserModel? user;
  final String? token;

  RegisterData({
    this.user,
    this.token,
  });

  factory RegisterData.fromJson(Map<String, dynamic> json) {
    return RegisterData(
      user: json['user'] != null
          ? UserModel.fromJson(json['user'])
          : null,
      token: json['token'],
    );
  }
}
