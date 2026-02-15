import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/auth/data/auth_data.dart';
import 'package:flutter/material.dart';

import '../view/screen/register_detail_screen.dart';

class RegisterController {
  final BuildContext context;
  final VoidCallback reloadData;

  String? selectedRole;
  final List<TextEditingController> codeControllers = List.generate(
    6, (index) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  bool isLoading = false;

  RegisterController({required this.context, required this.reloadData});

  String getOrganizationCode() {
    final mainCode = codeControllers.map((c) => c.text).join('');
    return 'ORG$mainCode';
  }

  bool isFormValid() {
    final code = codeControllers.map((c) => c.text).join('');
    return code.length == 6 && selectedRole != null;
  }

  void handleContinue() async {
    if (!isFormValid()) {
      Helpers.showSnackBar(
        context,
        'Please enter organization code and select your role',
        type: SnackType.error
      );
      return;
    }
    isLoading = true;
    reloadData();

    try {
      final orgCode = getOrganizationCode();
      final response = await AuthDataSource().checkOrgAvailability(orgCode);
      if (response == null) {
        Helpers.showSnackBar(
            context,
            'Something went wrong!',
            type: SnackType.error
        );
        return;
      }

      if (!response.success) {
        Helpers.showSnackBar(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Something went wrong',
          type: SnackType.error,
        );
        return;
      }

      if (!response.exists) {
        Helpers.showSnackBar(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'Organization not found',
          type: SnackType.error,
        );
        return;
      }

      if (!response.move) {
        Helpers.showSnackBar(
          context,
          response.message.isNotEmpty
              ? response.message
              : 'You cannot proceed with this organization',
          type: SnackType.normal,
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterDetailsScreen(
            organizationCode: orgCode,
            role: selectedRole!,
            organizationName: response.organization?.name ?? '',
          ),
        ),
      );
    } catch(e) {
      Helpers.showSnackBar(
        context,
        'Unexpected error occurred',
        type: SnackType.error,
      );
    } finally {
      isLoading = false;
      reloadData();
    }
  }

  void dispose() {
    for (var controller in codeControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
  }
}