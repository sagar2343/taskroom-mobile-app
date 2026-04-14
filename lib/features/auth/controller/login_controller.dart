import 'package:field_work/config/constant/http_constants.dart';
import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/auth/data/auth_data.dart';
import 'package:field_work/features/home/view/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/data/local/app_data.dart';
import '../../../config/theme/app_pallete.dart';
import '../../../services/fcm_service.dart';

class LoginController {
  final BuildContext context;
  final VoidCallback reloadData;

  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final orgCodeController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  LoginController({required this.context, required this.reloadData});


  Future<void> handleLogin() async {
    if (!formKey.currentState!.validate()) return;

    isLoading = true;
    reloadData();

    final payload = {
      'username': usernameController.text.trim(),
      'password': passwordController.text,
      'organizationCode': orgCodeController.text.trim(),
    };

    try {
      final response = await AuthDataSource().loginUser(payload);

      if (response == null) {
        Helpers.showSnackBar(
          context,
          'Something went wrong!',
          type: SnackType.error,
        );
        return;
      }

      if (response.success ?? false) {
        final token = response.data?.token;
        if (token != null && token.isNotEmpty) {
          AppData().setAccessToken(token);
        }

        final user = response.data?.user;
        if (user != null) {
          AppData().setUserData(user);
        }

        Helpers.showSnackBar(
          context,
          response.message ?? 'Logged in successfully',
          type: SnackType.success,
        );

        FcmService.instance.registerToken();

        if (user?.role != null && user!.role!.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
                  (route) => false,
            );
          }
        }
      } else {
        Helpers.showSnackBar(
          context,
          response.message ?? 'Something went wrong',
          type: SnackType.error,
        );
      }
    } catch (e) {
      debugPrint('[Login] Error: $e');
      Helpers.showSnackBar(
        context,
        'Unexpected error: ${e.toString()}',
        type: SnackType.error,
      );
    } finally {
      isLoading = false;
      reloadData();
    }
  }

  Future<void> launchURL() async {
    final uri = Uri.parse(HttpConstants.getBaseURL);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not launch website'),
            backgroundColor: Pallete.errorColor,
          ),
        );
      }
    }
  }

  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    orgCodeController.dispose();
  }
}