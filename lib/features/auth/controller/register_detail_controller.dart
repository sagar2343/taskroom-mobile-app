import 'package:field_work/config/data/local/app_data.dart';
import 'package:field_work/features/auth/data/auth_data.dart';
import 'package:field_work/features/home/view/screen/home_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/helpers.dart';

class RegisterDetailController {
  final BuildContext context;
  final VoidCallback reloadData;

  final String organizationCode;
  final String role;
  final String organizationName;

  final formKey = GlobalKey<FormState>();

  // Common fields
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final mobileController = TextEditingController();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final departmentController = TextEditingController();
  final designationController = TextEditingController();

  // Role-specific fields
  final employeeIdController = TextEditingController();
  final managerIdController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  RegisterDetailController({
    required this.context,
    required this.reloadData,
    required this.organizationCode,
    required this.role,
    required this.organizationName,
  });

  void handleRegister() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final data = {
      'username': usernameController.text.trim(),
      'password': passwordController.text,
      'mobile': mobileController.text.trim(),
      'role': role,
      'fullName': fullNameController.text.trim(),
      'email': emailController.text.trim(),
      'department': departmentController.text.trim(),
      'designation': designationController.text.trim(),
      'organizationCode': organizationCode,
    };

    if (role == 'employee') {
      data['employeeId'] = employeeIdController.text.trim();
    } else {
      data['managerId'] = managerIdController.text.trim();
    }
    isLoading = true;
    reloadData();

    try {
      final response = await AuthDataSource().registerNewUser(data);
      if (response == null) {
        Helpers.showSnackBar(
          context,
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
        Future.delayed(const Duration(milliseconds: 500),() {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
              // role == 'employee'
              //     ? const EmployeeHomeScreen()
              //     : const ManagerHomeScreen(),
            ), (route) => false,
          );
        });
      } else {
        Helpers.showSnackBar(context, response.message ?? 'Something went wrong');
      }

    } catch (e) {
      debugPrint(e.toString());
      Helpers.showSnackBar(
        context,
        'Unexpected error occurred:${e.toString()}',
        type: SnackType.error,
      );
    } finally {
      isLoading = false;
      reloadData();
    }
  }


  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    mobileController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    departmentController.dispose();
    designationController.dispose();
    employeeIdController.dispose();
    managerIdController.dispose();
  }
}