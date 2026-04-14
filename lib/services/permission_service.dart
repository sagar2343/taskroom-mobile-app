// lib/services/permission_service.dart
//
// Changes from your current version:
//   1. requestNotificationPermission() is REMOVED from requestAllPermissions().
//      Reason: FcmService.initialize() (called in main.dart) already calls
//      FirebaseMessaging.requestPermission() which handles both iOS and
//      Android 13+ notification permission. Requesting it a second time via
//      permission_handler is redundant and can confuse the OS permission flow.
//
//      The method itself is kept (commented out) in case you ever need to
//      re-request permission from a settings screen.
//
// Everything else (location, battery optimization, background location)
// is identical to your existing permission_service.dart.

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionService {
  PermissionService._();

  /// Request all permissions needed at app startup.
  /// Call this ONCE from SplashController only.
  static Future<void> requestAllPermissions(BuildContext context) async {
    // NOTE: Notification permission is requested inside FcmService.initialize()
    // via FirebaseMessaging.requestPermission(). Do NOT call
    // requestNotificationPermission() here — it would duplicate the request.

    await requestLocationPermission();
    await requestBatteryOptimizationPermission();
    await requestBackgroundLocationPermission(context);
  }

  // Kept for reference — call from a settings screen if needed,
  // but NOT from requestAllPermissions().
  static Future<void> requestNotificationPermission() async {
    var status = await ph.Permission.notification.status;
    if (status.isPermanentlyDenied) {
      await ph.openAppSettings();
    } else if (!status.isGranted) {
      status = await ph.Permission.notification.request();
    }
    debugPrint('[Permission] Notification: $status');
  }

  static Future<bool> requestLocationPermission() async {
    if (!await Location.instance.serviceEnabled()) {
      if (!await Location.instance.requestService()) return false;
    }

    PermissionStatus status = await Location.instance.hasPermission();
    if (status == PermissionStatus.denied) {
      status = await Location.instance.requestPermission();
      if (status != PermissionStatus.granted) return false;
    }

    debugPrint('[Permission] Location: $status');
    return true;
  }

  static Future<bool> requestBatteryOptimizationPermission() async {
    final isIgnoring = await ph.Permission.ignoreBatteryOptimizations.isGranted;
    if (isIgnoring) {
      debugPrint('[Permission] Battery optimization: already ignoring');
      return true;
    }

    await ph.Permission.ignoreBatteryOptimizations.request();
    final granted = await ph.Permission.ignoreBatteryOptimizations.isGranted;
    debugPrint('[Permission] Battery optimization: $granted');
    return granted;
  }

  static Future<bool> requestBackgroundLocationPermission(
      BuildContext context,
      ) async {
    final status = await ph.Permission.locationAlways.request();
    if (!status.isGranted) {
      if (context.mounted) _showPermissionDialog(context);
      return false;
    }
    debugPrint('[Permission] Background location: granted');
    return true;
  }

  static void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'This app needs background location permission.\n\n'
              "Please go to app settings and select 'Allow all the time' "
              'under Location permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ph.openAppSettings();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}