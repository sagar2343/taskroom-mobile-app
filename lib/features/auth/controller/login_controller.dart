import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/auth/data/auth_data.dart';
import 'package:field_work/features/home/view/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/data/local/app_data.dart';
import '../../../config/theme/app_pallete.dart';

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

  void handleLogin() async {

    if (!formKey.currentState!.validate()) {
      return;
    }
    isLoading = true;
    reloadData();
    final data = {
      'username': usernameController.text.trim(),
      'password': passwordController.text,
      'organizationCode': orgCodeController.text.trim(),
    };
    try {
      final response = await AuthDataSource().loginUser(data);
      if (response == null) {
        Helpers.showSnackBar(context,
          'Something went wrong!',
          type: SnackType.error,
        );
        return;
      }
      if (response.success ?? false) {
        if (response.data?.token != null && response.data!.token!.isNotEmpty) {
          AppData().setAccessToken(response.data!.token!);
        }
        if (response.data?.user != null) {
          AppData().setUserData(response.data!.user!);
        }
        Helpers.showSnackBar(context,
          response.message ?? 'Registered Successfully',
          type: SnackType.success,
        );
        if (response.data?.user?.role != null && response.data!.user!.role!.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 300),() {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(),
                // response.data?.user?.role == 'employee'
                //     ? const EmployeeHomeScreen()
                //     : const ManagerHomeScreen(),
              ),
              (route) => false,
            );
        });
        }
      } else {
        Helpers.showSnackBar(context, response.message ?? 'Something went wrong');
      }

    } catch(e) {
      debugPrint(e.toString());
      Helpers.showSnackBar(context,
        'Unexpected error occured: ${e.toString()}',
        type: SnackType.error,
      );
    } finally {
      isLoading = false;
      reloadData();
    }
  }

  Future<void> launchURL() async {
    final Uri url = Uri.parse('https://taskroom.com/create-organization');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not launch website',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Pallete.errorColor,
          ),
        );
      }
    }
  }


  dispose() {
    usernameController.dispose();
    passwordController.dispose();
    orgCodeController.dispose();
  }
}