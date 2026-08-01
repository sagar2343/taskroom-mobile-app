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

    // ── MANDATORY (Play Store Prominent Disclosure policy): the in-app
    // disclosure must appear BEFORE the very first location-related
    // runtime permission prompt (foreground included), not just before
    // background/"Allow all the time".
    if (!context.mounted) return;
    final locationConsented = await _showLocationDisclosureDialog(context);
    if (!locationConsented) {
      debugPrint('[Permission] User declined location disclosure — skipping all location requests');
    } else {
      await requestLocationPermission();
      if (context.mounted) {
        await requestBackgroundLocationPermission(context);
      }
    }

    if (context.mounted) {
      await requestBatteryOptimizationPermission(context);
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

  static Future<bool> requestBatteryOptimizationPermission(
      BuildContext context,
      ) async {
    final isIgnoring = await ph.Permission.ignoreBatteryOptimizations.isGranted;
    if (isIgnoring) return true;

    // ── Disclosure before requesting battery optimization exemption,
    // same policy requirement as location: an in-app explanation must
    // immediately precede the runtime permission prompt.
    if (!context.mounted) return false;
    final consented = await _showBatteryDisclosureDialog(context);
    if (!consented) {
      debugPrint('[Permission] User declined battery disclosure — not requesting');
      return false;
    }

    await ph.Permission.ignoreBatteryOptimizations.request();
    return await ph.Permission.ignoreBatteryOptimizations.isGranted;
  }

  static Future<bool> requestBackgroundLocationPermission(
      BuildContext context,
      ) async {
    // Check if already granted — no need to show disclosure/prompt again
    final current = await ph.Permission.locationAlways.status;
    if (current.isGranted) return true;

    // Safety net: if this is ever called without requestAllPermissions()
    // having shown the disclosure first, show it now so we're never
    // out of policy.
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

  /// Returns true if the currently logged-in user is an employee.
  /// Employees are the segment for whom location + battery-optimization
  /// exemption are core, non-optional to the app's function — Play Store
  /// policy permits mandatory consent (no "skip") for a user segment when
  /// the permission is essential to that segment's use case. Guests and
  /// non-employee roles (e.g. managers not being tracked) always get a
  /// real way to decline.
  static bool _isLoggedInEmployee() {
    final userData = AppData().getUserData();
    return userData != null && userData.role?.toLowerCase() == 'employee';
  }

  static Future<bool> _showLocationDisclosureDialog(BuildContext context) async {
    final isLoggedInEmployee = _isLoggedInEmployee();
    debugPrint('Is logged-in employee: $isLoggedInEmployee');

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
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
          content: Text(
            isLoggedInEmployee
                ? 'TaskRoom collects your device location, including in '
                'the background even when the app is closed or not in '
                'use, so your manager can track field activity, '
                'attendance, and task progress during work hours. '
                'This is required to use TaskRoom as an employee.'
                : 'TaskRoom collects device location, including in the '
                'background even when the app is closed or not in '
                'use, to enable field activity and attendance '
                'tracking. You can manage this anytime from your '
                'device settings.',
            style: const TextStyle(fontSize: 14, height: 1.5),
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
      ),
    );
    return result ?? false;
  }

  static Future<bool> _showBatteryDisclosureDialog(BuildContext context) async {
    final isLoggedInEmployee = _isLoggedInEmployee();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.battery_charging_full_rounded, color: Color(0xff137fec)),
              SizedBox(width: 8),
              Text('Run in Background', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Text(
            isLoggedInEmployee
                ? 'TaskRoom needs to be excluded from battery '
                'optimization so it can keep tracking your location '
                'reliably during work hours, even when your screen is '
                'off. This is required to use TaskRoom as an '
                'employee.'
                : 'Excluding TaskRoom from battery optimization lets it '
                'run reliably in the background for location '
                'tracking. You can manage this anytime from your '
                'device settings.',
            style: const TextStyle(fontSize: 14, height: 1.5),
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