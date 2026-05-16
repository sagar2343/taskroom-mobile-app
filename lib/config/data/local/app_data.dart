import 'dart:convert';
import 'package:field_work/features/auth/model/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../constant/sp_constants.dart';

class AppData {
  static AppData _instance = AppData._internal();

  factory AppData() {
    return _instance;
  }

  AppData._internal();
  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _accessToken;
  bool? _isDark;
  UserModel? _userData;

  // cred details
  String? _keyOrgCode;
  String? _keyUserName;

  void setKeyOrdCode(String code) {
    _keyOrgCode = code;
    _saveThisInstance();
  }

  void setKeyUserName(String name) {
    _keyUserName = name;
    _saveThisInstance();
  }

  String? getKeyOrdCode() {
    return _keyOrgCode;
  }

  String? getKeyUserName() {
    return _keyUserName;
  }

  void setUserData(UserModel user) {
    _userData = user;
    _saveThisInstance();
  }

  UserModel? getUserData() {
    return _userData;
  }

  void updateOnlineStatus(bool isOnline) {
    if (_userData == null) return;

    _userData = _userData!.copyWith(isOnline: isOnline);
    _saveThisInstance();
  }

  void setDarkTheme(bool isDark) {
    _isDark = isDark;
    _saveThisInstance();
  }

  bool? getIsDarkTheme() {
    return _isDark;
  }

  void setAccessToken(String accessToken) {
    _accessToken = accessToken;
    _saveThisInstance();
  }

  String? getAccessToken() {
    return _accessToken;
  }

  void clearAll() {
    storage.deleteAll();
    _accessToken = null;
    _userData = null;
    _saveThisInstance();
  }

  void _saveThisInstance() {
    storage.write(
        key: SPConstants.appData.name, value: json.encode(AppData().toJson()));
  }

  Future<void> restoreInstance() async {
    String? storedResult = await storage.read(key: SPConstants.appData.name);
    if (storedResult != null) {
      _instance = AppData.fromJson(
        json.decode(
          storedResult,
        ),
      );
    }
  }

  AppData.fromJson(Map<String, dynamic> json) {
    _isDark = json['isDark'];
    _accessToken = json['AccessToken'];
    _keyOrgCode = json['KeyOrgCode'];
    _keyUserName = json['KeyUserName'];
    _userData = json['UserData'] != null
        ? UserModel.fromJson(json['UserData'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['isDark'] = _isDark;
    data['AccessToken'] = _accessToken;
    data['KeyOrgCode'] = _keyOrgCode;
    data['KeyUserName'] = _keyUserName;
    data['UserData'] = _userData?.toJson();
    return data;
  }
}
