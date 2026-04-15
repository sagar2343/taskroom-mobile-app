// lib/services/fcm_service.dart
//
// Single source of truth for all FCM push notification logic.
//
// ── What this replaces ───────────────────────────────────────────────────────
// DELETE lib/services/notification_service.dart entirely.
// That file had a stub sendTokenToServer() that did nothing.
// Everything it did (or tried to do) is now done properly here.
//
// ── What this works alongside ────────────────────────────────────────────────
// KEEP lib/services/notification_helper.dart — it owns channel setup and
// showNotification(). This file calls into it; they don't overlap.
//
// ── Call sites (summary) ─────────────────────────────────────────────────────
//   main.dart              → FcmService.initialize()           once on start
//   login_controller.dart  → FcmService.instance.registerToken()  after login
//   splash_controller.dart → FcmService.instance.registerToken()  if user saved
//   logout (home_controller / wherever you sign out)
//                          → FcmService.instance.unregisterToken() on logout
//
// ── pubspec.yaml dependencies needed ────────────────────────────────────────
//   firebase_core: ^3.6.0
//   firebase_messaging: ^15.1.3
//   (flutter_local_notifications is already in your project)

import 'dart:convert';
import 'dart:io';

import 'package:field_work/config/constant/http_constants.dart';
import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/services/notification_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/http_client/http_client.dart';

// ── Background isolate entry point ────────────────────────────────────────────
// Rules:
//   • Must be a TOP-LEVEL function (not inside a class).
//   • Must be annotated @pragma('vm:entry-point').
//   • Firebase MUST be re-initialised inside this isolate.
//   • Cannot access any singleton state from the main isolate (AppData, etc.)
//     because this runs in a completely separate Dart isolate.
//   • flutter_local_notifications CAN be used here after re-initialising it.
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  // Step 1: re-init Firebase in this isolate (mandatory)
  await Firebase.initializeApp();

  // Step 2: re-init local notifications so we can show a banner
  await NotificationHelper.initialize();

  final title   = message.notification?.title ?? 'FieldWork';
  final body    = message.notification?.body  ?? '';
  final type    = message.data['type']        ?? '';
  final taskId  = message.data['taskId']      ?? '';

  debugPrint('[FCM Background] type=$type title=$title');

  // Step 3: show local banner if the message carried a visible notification
  // (data-only messages have no notification payload — show one manually)
  if (message.notification == null && title.isNotEmpty) {
    await NotificationHelper.showNotification(
      id:      NotificationHelper.idForType(type),
      title:   title,
      body:    body,
      payload: taskId,   // passed back to tap handler
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  FcmService  — singleton
// ═══════════════════════════════════════════════════════════════════════════════

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final _fm = FirebaseMessaging.instance;

  // Guards against registering the onTokenRefresh listener more than once.
  // Without this, calling registerToken() from both splash + login creates
  // duplicate listeners that each send the token to the server on refresh.
  bool _tokenRefreshListenerAttached = false;
  String? _currentToken;

  String? get currentToken => _currentToken;

  // ── initialize() ─────────────────────────────────────────────────────────────
  // Call ONCE in main(), after Firebase.initializeApp() and
  // NotificationHelper.initialize().
  // Sets up background handler, foreground listener, and tap handlers.
  // Does NOT request the token — that happens in registerToken() after login.
  static Future<void> initialize() async {
    // Register background handler FIRST — before any await in main()
    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

    // iOS only: show banners even when app is foregrounded
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // ── Foreground: app is open and a push arrives ────────────────────────────
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM Foreground] ${message.notification?.title}');
      _handleForegroundMessage(message);
    });

    // ── Background tap: app was in background, user tapped the notification ───
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM Tap (background)] type=${message.data['type']}');
      _handleNotificationTap(message);
    });

    // ── Terminated tap: app was closed, user tapped the notification ──────────
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM Tap (terminated)] type=${initialMessage.data['type']}');
      // Small delay so the widget tree is fully built before navigating
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _handleNotificationTap(initialMessage);
    }

    debugPrint('[FCM] Service initialized ✅');
  }

  // ── registerToken() ──────────────────────────────────────────────────────────
  // Call after:
  //   • Successful login (in LoginController)
  //   • Splash screen when user is already logged in (in SplashController)
  //
  // Safe to call multiple times — the guard prevents duplicate listeners.
  Future<void> registerToken() async {
    try {
      // On Android 13+ and iOS, permission must be granted before getToken()
      // works. We request it here in case PermissionService hasn't run yet,
      // or the user dismissed it at splash and granted it later.
      final settings = await _fm.requestPermission(
        alert:  true,
        badge:  true,
        sound:  true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] Notification permission denied — token not requested');
        return;
      }

      // iOS: wait for APNS token (required before FCM token is available)
      if (Platform.isIOS) {
        String? apnsToken;
        for (int attempt = 0; attempt < 5 && apnsToken == null; attempt++) {
          apnsToken = await _fm.getAPNSToken();
          if (apnsToken == null) {
            await Future<void>.delayed(const Duration(seconds: 1));
          }
        }
        if (apnsToken == null) {
          debugPrint('[FCM] Could not obtain APNS token after 5 attempts');
          return;
        }
        debugPrint('[FCM] APNS token obtained ✅');
      }

      final token = await _fm.getToken();
      if (token == null) {
        debugPrint('[FCM] getToken() returned null');
        return;
      }

      _currentToken = token;
      debugPrint('[FCM] Token: ${token.substring(0, 20)}…');
      await _sendTokenToServer(token);

      // Attach the refresh listener only once across the app lifetime
      if (!_tokenRefreshListenerAttached) {
        _tokenRefreshListenerAttached = true;
        _fm.onTokenRefresh.listen((newToken) async {
          _currentToken = newToken;
          debugPrint('[FCM] Token rotated — sending new token to server');
          await _sendTokenToServer(newToken);
        });
      }
    } catch (e) {
      debugPrint('[FCM] registerToken error: $e');
    }
  }

  // ── unregisterToken() ────────────────────────────────────────────────────────
  // Call on logout so this device stops receiving notifications.
  final http.Client _client = kHttpClient;
  final accessToken = AppData().getAccessToken();
  Future<void> unregisterToken() async {
    try {
      if (accessToken == null) {
        // Tell the server to clear the stored FCM token for this user
        await _client.delete(
          Uri.parse('${HttpConstants.getBaseURL}/api/fcm/fcm-token'),
          headers: HttpConstants.getHttpHeaders(accessToken),
          // headers: {
          //   'Authorization': 'Bearer $authToken',
          //   'Content-Type':  'application/json',
          // },
        ).timeout(const Duration(seconds: 5));
      }

      // Delete the token on-device so Firebase stops delivering to this install
      await _fm.deleteToken();
      _currentToken = null;
      debugPrint('[FCM] Token unregistered ✅');
    } catch (e) {
      // Non-critical — user is already being logged out
      debugPrint('[FCM] unregisterToken error (non-critical): $e');
    }
  }

  // ── _sendTokenToServer() ─────────────────────────────────────────────────────
  Future<void> _sendTokenToServer(String token) async {
    try {
      if (accessToken == null) {
        // User isn't logged in yet — registerToken() will be called again
        // from LoginController right after login, so this is expected.
        debugPrint('[FCM] No auth token yet — will register after login');
        return;
      }

        final res = await _client.post(
        Uri.parse('${HttpConstants.getBaseURL}/api/fcm/fcm-token'),
        headers: HttpConstants.getHttpHeaders(accessToken),
        // headers: {
        //   'Authorization': 'Bearer $authToken',
        //   'Content-Type':  'application/json',
        // },
        body: jsonEncode({'token': token}),
      ).timeout(const Duration(seconds: 8));

      final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
      if (responseBody['success'] == true) {
        debugPrint('[FCM] Token registered on server ✅');
      } else {
        debugPrint('[FCM] Server rejected token: ${responseBody['message']}');
      }
    } catch (e) {
      debugPrint('[FCM] _sendTokenToServer error: $e');
    }
  }

  // ── _handleForegroundMessage() ───────────────────────────────────────────────
  // The OS suppresses FCM notification banners while the app is open.
  // We show a local notification manually so the user still sees it.
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title  = message.notification?.title ?? '';
    final body   = message.notification?.body  ?? '';
    final type   = message.data['type']        ?? '';
    final taskId = message.data['taskId']      ?? '';

    if (title.isEmpty) return; // data-only message with no visible content

    await NotificationHelper.showNotification(
      id:      NotificationHelper.idForType(type),
      title:   title,
      body:    body,
      payload: taskId,
    );
  }

  // ── _handleNotificationTap() ─────────────────────────────────────────────────
  // Called when the user taps a notification while the app is backgrounded
  // or was terminated. Navigate to the relevant screen.
  //
  // To navigate you need a GlobalKey<NavigatorState> accessible from here.
  // Add this to main.dart:
  //   final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  // Then pass it to MaterialApp:   navigatorKey: navigatorKey,
  // Then uncomment the navigation code below.
  static void _handleNotificationTap(RemoteMessage message) {
    final type   = message.data['type']   ?? '';
    final taskId = message.data['taskId'] ?? '';

    debugPrint('[FCM] Notification tapped — type=$type  taskId=$taskId');

    if (taskId.isEmpty) return;

    // ── Uncomment and wire up once you add navigatorKey to main.dart ──────────
    //
    // import 'package:field_work/main.dart' show navigatorKey;
    // import '../features/task/view/screen/manager_task_details_screen.dart';
    // import '../features/employee_task/view/screen/employee_task_detail_screen.dart';
    //
    // final ctx = navigatorKey.currentContext;
    // if (ctx == null) return;
    //
    // final userRole = AppData().getUserData()?.role ?? '';
    //
    // switch (type) {
    //   // Both manager and employee events → open task detail for the right role
    //   case 'task_assigned':
    //   case 'task_updated':
    //   case 'task_cancelled':
    //   case 'step_added':
    //   case 'step_updated':
    //     // Employee received these — open employee task detail
    //     navigatorKey.currentState?.push(MaterialPageRoute(
    //       builder: (_) => EmployeeTaskDetailScreen(taskId: taskId),
    //     ));
    //     break;
    //
    //   case 'task_started':
    //   case 'step_started':
    //   case 'step_reached':
    //   case 'step_completed':
    //   case 'task_completed':
    //     // Manager received these — open manager task detail
    //     navigatorKey.currentState?.push(MaterialPageRoute(
    //       builder: (_) => ManagerTaskDetailScreen(taskId: taskId),
    //     ));
    //     break;
    // }
  }
}