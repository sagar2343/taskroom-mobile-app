import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/features/auth/model/user_model.dart';
import 'package:field_work/features/home/view/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import '../../auth/view/screen/login_screen.dart';
import '../../location_tracking/service/location_background_service.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class SplashController {
  final BuildContext context;
  final VoidCallback reloadData;

  UserModel? user;

  SplashController({required this.context, required this.reloadData});

  Future<void> startSplash() async {
    final minimumDelay = Future.delayed(const Duration(seconds: 2));

    user = AppData().getUserData();

    if (user != null) await checkActiveTask();

    await requestNotificationPermission();
    await _checkForLocationPermission();
    await _requestBatteryOptimizationPermission();
    await _backgroundPermissionGranted();
    await minimumDelay;

    _navigateToHome();
  }

  Future<void> checkActiveTask() async {
    await LocationBackgroundService.instance.syncWithActiveTask();
  }

  Future<void> requestNotificationPermission() async {
    final status = await ph.Permission.notification.request();
    debugPrint('[Permission] Notification: $status');
  }

  Future<bool> _requestBatteryOptimizationPermission() async {
    final isIgnoring = await ph.Permission.ignoreBatteryOptimizations.isGranted;
    if (!isIgnoring) {
      await ph.Permission.ignoreBatteryOptimizations.request();
      if (await ph.Permission.ignoreBatteryOptimizations.isGranted) {
        return true;
      } else {
        return false;
      }
    } else {
      debugPrint("Already ignoring battery optimization");
      return true;
    }
  }

  Future<bool> _checkForLocationPermission() async {
    if (!await Location.instance.serviceEnabled()) {
      if (!await Location.instance.requestService()) {
        return false;
      }
    }

    PermissionStatus permissionGranted = await Location.instance.hasPermission();

    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await Location.instance.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  Future<bool> _backgroundPermissionGranted() async {
    // Then request background location (needed separately on Android 10+)
    final backgroundStatus = await ph.Permission.locationAlways.request();

    if (!backgroundStatus.isGranted) {
      _showPermissionDialog(context);
      return false;
    }

    return true;
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Permission Required"),
          content: const Text(
            "This app needs background location permission.\n\nPlease go to app settings and select 'Allow all the time' under Location permission.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await ph.openAppSettings();
                Navigator.pop(context);
              },
              child: const Text("Open Settings"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToHome() {
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => user == null ? LoginScreen() : HomeScreen(),
      ),
          (route) => false,
    );
  }
}