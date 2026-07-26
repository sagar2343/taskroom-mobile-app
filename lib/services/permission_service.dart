import 'package:field_work/config/data/local/app_data.dart';
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
    if (context.mounted) {
      await requestBackgroundLocationPermission(context);
    }
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
    if (isIgnoring) return true;

    await ph.Permission.ignoreBatteryOptimizations.request();
    return await ph.Permission.ignoreBatteryOptimizations.isGranted;
  }

  static Future<bool> requestBackgroundLocationPermission(
      BuildContext context,
      ) async {
    // Check if already granted — no need to show disclosure again
    final current = await ph.Permission.locationAlways.status;
    if (current.isGranted) return true;

    // ── MANDATORY: show prominent disclosure BEFORE system prompt ──
    if (!context.mounted) return false;
    final consented = await _showLocationDisclosureDialog(context);
    if (!consented) {
      debugPrint('[Permission] User declined disclosure — not requesting');
      return false;
    }

    final status = await ph.Permission.locationAlways.request();
    if (!status.isGranted) {
      if (context.mounted) _showPermissionDialog(context);
      return false;
    }
    debugPrint('[Permission] Background location: granted');
    return true;
  }

  static Future<bool> _showLocationDisclosureDialog(BuildContext context) async {
    final userData = AppData().getUserData();
    final isLoggedInEmployee = userData != null &&
        userData.role?.toLowerCase() == 'employee';
    debugPrint('Is logged-in employee: $isLoggedInEmployee');

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: Color(0xff137fec)),
            SizedBox(width: 8),
            Text('Location Access', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'TaskRoom tracks your location during work hours, '
              'even in the background, so your manager can monitor '
              'field activity and attendance.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          if (!isLoggedInEmployee)
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff137fec),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
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