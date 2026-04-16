// lib/services/notification_helper.dart
//
// Responsibilities:
//   1. Create the Android notification channel on app start (initialize())
//   2. Show a local notification banner (showNotification()) — used by both:
//        • FcmService for foreground messages (the OS hides them by default)
//        • The background isolate handler in fcm_service.dart
//
// KEEP this file. It works alongside FcmService — they don't overlap.

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Single shared plugin instance — accessed from both the main isolate
// and the background isolate (background handler re-calls initialize()).
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// ── Channel constants — MUST match the server's channelId ────────────────────
const _kChannelId   = 'fieldwork_tasks';
const _kChannelName = 'FieldWork Tasks';
const _kChannelDesc = 'Task and step update notifications';

class NotificationHelper {

  // ── Call once in main() and once inside the background isolate handler ──────
  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[NotificationHelper] Local tap: ${response.payload}');
      },
      // Required for background local-notification taps — must be top-level fn
      onDidReceiveBackgroundNotificationResponse: _backgroundTapHandler,
    );

    // Create (or update) the high-importance Android channel.
    // Safe to call multiple times — Android ignores duplicate creates.
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kChannelId,
        _kChannelName,
        description:      _kChannelDesc,
        importance:       Importance.high,
        playSound:        true,
        enableVibration:  true,
        showBadge:        true,
      ),
    );

    debugPrint('[NotificationHelper] Channels initialized ✅');
  }

  // ── Show a local notification banner ─────────────────────────────────────────
  // Called from FcmService._handleForegroundMessage() so that foreground
  // FCM messages get a visible heads-up banner (the OS suppresses them
  // by default while the app is open).
  //
  // Also called from the background isolate handler so that data-only messages
  // (no notification payload) still show a banner in the background.
  //
  // [id]      — unique per-notification; reuse the same id to replace an
  //             existing banner rather than stacking duplicates.
  // [payload] — string passed back in onDidReceiveNotificationResponse tap.
  static Future<void> showNotification({
    required int    id,
    required String title,
    required String body,
    String?         payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: _kChannelDesc,
      importance:         Importance.high,
      priority:           Priority.high,
      playSound:          true,
      enableVibration:    true,
      icon:               '@drawable/ic_notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );
  }

  // ── Convenience: derive a stable notification id from a type string ──────────
  // Ensures that repeated "step_completed" notifications replace each other
  // rather than stacking up as dozens of banners.
  static int idForType(String type) {
    const ids = {
      'task_assigned':  1001,
      'task_updated':   1002,
      'task_cancelled': 1003,
      'step_added':     1004,
      'step_updated':   1005,
      'task_started':   2001,
      'step_started':   2002,
      'step_reached':   2003,
      'step_completed': 2004,
      'task_completed': 2005,
    };
    return ids[type] ?? 9999;
  }
}

// Must be top-level + annotated for the background callback
@pragma('vm:entry-point')
void _backgroundTapHandler(NotificationResponse response) {
  debugPrint('[NotificationHelper:BG] Tap: ${response.payload}');
}