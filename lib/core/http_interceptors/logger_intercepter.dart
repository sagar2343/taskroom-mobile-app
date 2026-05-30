import 'dart:convert';

import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/features/auth/view/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http_interceptor/http_interceptor.dart';

import '../../main.dart';

bool _isSessionDialogShowing = false;

// These paths are public — never treat their 401s as session expiry
const _publicPaths = {
  '/api/auth/login',
  '/api/auth/register',
  '/api/auth/check-username',
  '/api/organization/check',
};

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
      debugPrint(response.body);

      if (response.statusCode == 401) {
        // Skip session handling for public/auth endpoints
        final path = response.request?.url.path ?? '';
        final isPublicPath = _publicPaths.any((p) => path.endsWith(p));

        if (!isPublicPath) {
          _handleSessionExpired(response.body);
        }
      }
    }

    return response;
  }

  void _handleSessionExpired(String rawBody) {
    if (_isSessionDialogShowing) return;

    // Parse the message from backend
    String message = 'Your session has expired. Please login again.';
    try {
      final body = jsonDecode(rawBody);
      final code = body['code'];

      if (code == 'SESSION_EXPIRED') {
        message = 'Your account was logged in on another device. Please login again.';
      } else {
        message = body['message'] as String? ?? message;
      }
    } catch (_) {}

    final context = navigatorKey.currentContext;
    if (context == null) return;

    _isSessionDialogShowing = true;
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