import 'dart:convert';

import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/features/auth/view/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http_interceptor/http_interceptor.dart';

import '../../main.dart';

bool _isSessionDialogShowing = false;

class LoggerInterceptor extends InterceptorContract {
  @override
  Future<BaseRequest> interceptRequest({
    required BaseRequest request,
  }) async {
    debugPrint('----- Request -----');
    debugPrint(request.toString());
    debugPrint(request.headers.toString());
    return request;
  }

  @override
  Future<BaseResponse> interceptResponse({
    required BaseResponse response,
  }) async {
    debugPrint('----- Response -----');
    debugPrint('Code: ${response.statusCode}');
    if (response is Response) {
      debugPrint((response).body);

      if (response.statusCode == 401) {
        try {
          final body = jsonDecode(response.body);
          final code = body['code'];
          final message = body['message'] as String?;

          if (code == 'SESSION_EXPIRED') {
            _handleSessionExpired(
                'Your account was logged in on another device. Please login again.'
            );
          } else {
            // Covers: invalid token, token expired (7d), user not found
            _handleSessionExpired(
                message ?? 'Your session has expired. Please login again.'
            );
          }
        } catch (_) {
          _handleSessionExpired('Your session has expired. Please login again.');
        }
      }
    }
    return response;
  }

  void _handleSessionExpired(String message) {
    if (_isSessionDialogShowing) return;
    _isSessionDialogShowing = true;

    final context = navigatorKey.currentContext;
    if (context == null) {
      _isSessionDialogShowing = false;
      return;
    }

    // ✅ Clear immediately, not just on OK tap
    AppData().clearAll();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Session Expired'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              _isSessionDialogShowing = false;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

}
