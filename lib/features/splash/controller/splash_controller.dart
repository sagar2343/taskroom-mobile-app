import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/features/auth/model/user_model.dart';
import 'package:field_work/features/home/view/screen/home_screen.dart';
import 'package:field_work/services/permission_service.dart';
import 'package:flutter/material.dart';
import '../../../services/fcm_service.dart';
import '../../auth/view/screen/login_screen.dart';
import '../../location_tracking/service/location_background_service.dart';

class SplashController {
  final BuildContext context;
  final VoidCallback reloadData;

  UserModel? _user;

  SplashController({required this.context, required this.reloadData});

  final minimumDelay = Future.delayed(const Duration(seconds: 2));

  Future<void> startSplash() async {
    _user = AppData().getUserData();

    // Sync active task only for authenticated users
    if (_user != null) {
      await LocationBackgroundService.instance.syncWithActiveTask();
    }

    // All permissions are requested here — ONLY here.
    await PermissionService.requestAllPermissions(context);

    // FCM only makes sense for an authenticated user
    if (_user != null) {
      await FcmService.instance.registerToken();
    }

    await minimumDelay;
    _navigateNext();
  }

  void _navigateNext() {
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => _user == null ? LoginScreen() : HomeScreen(),
      ),
          (route) => false,
    );
  }
}