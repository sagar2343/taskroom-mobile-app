import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/features/auth/model/user_model.dart';
import 'package:field_work/features/home/view/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../auth/view/screen/login_screen.dart';

class SplashController {
  final BuildContext context;
  final VoidCallback reloadData;

  UserModel? user;

  SplashController({required this.context, required this.reloadData});

  /// Start the splash screen timer and navigate after delay
  void startSplash() {
    user = AppData().getUserData();
    Timer(const Duration(seconds: 2), () {
      _navigateToHome();
    });
  }

  void _navigateToHome() {
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) =>
        user == null
            ? LoginScreen()
            : HomeScreen()
            // : user!.role?.toLowerCase() == 'manager'
            // ? ManagerHomeScreen()
            // : EmployeeHomeScreen(),
        ),
        (route) => false,
      );
    }
  }
}