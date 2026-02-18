import 'dart:io';

class HttpConstants {

  // static String getBaseURL() {
  //   return const String.fromEnvironment("ROOT_URL");
  // }
  // static String baseURL = 'https://musicapp-backend-5zk7.onrender.com';
  static String get getBaseURL {
    if (Platform.isAndroid) {
      // Android Emulator
      // return 'http://10.0.2.2:3000';
      // return 'http://192.168.0.167:3000'; // wifi hotspot
      return 'http://10.239.79.88:3000'; // own hotspot
    } else if (Platform.isIOS) {
      // iOS Simulator
      return 'http://localhost:3000';
    } else {
      // Real device / fallback
      return 'http://192.168.0.167:3000';
    }
  }

  // static String getBaseURL = Platform.isAndroid
  //     ? 'http://10.0.2.2:3000'
  //     // ? 'http://192.168.0.167:3000' // real android device
  //     : 'http://localhost:3000';

  // static Map<String, String> getHttpHeaders([String? token]) {
  //   final headers = {
  //     'content-Type': 'application/json',
  //   };
  //   if (token != null && token.isNotEmpty) {
  //     headers['x-auth-token'] = token;
  //   }
  //   return headers;
  // }
  static Map<String, String> getHttpHeaders([String? token]) {
    Map<String, String> headers = {};
    if (token != null) {
      headers.putIfAbsent('Authorization', () => 'Bearer $token');
    }
    headers.putIfAbsent('Content-Type', () => 'application/json');
    return headers;
  }
}