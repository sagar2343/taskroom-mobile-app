import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/profile/data/profile_datasource.dart';
import 'package:field_work/features/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:field_work/config/theme/app_pallete.dart';
import '../../auth/model/user_model.dart';

class EditProfileController {
  final BuildContext context;
  final VoidCallback reloadData;
  final UserModel userData;

  final formKey = GlobalKey<FormState>();

  bool isLoading = false;

  // Text Controllers
  TextEditingController usernameController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController departmentController = TextEditingController();
  TextEditingController designationController = TextEditingController();

  EditProfileController({
    required this.context,
    required this.reloadData,
    required this.userData,
  }) {
    // Initialize controllers with existing data
    usernameController.text = userData.username ?? '';
    fullNameController.text = userData.fullName ?? '';
    emailController.text = userData.email ?? '';
    mobileController.text = userData.mobile ?? '';
    departmentController.text = userData.department ?? '';
    designationController.text = userData.designation ?? '';
    reloadData();
  }

  void init() async {
    // Any initialization logic
  }

  /// Handle save button press
  void handleSave() {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final updateData = {
      'username': usernameController.text.trim(),
      'mobile': mobileController.text.trim(),
      'fullName': fullNameController.text.trim(),
      'email': emailController.text.trim(),
      'department': departmentController.text.trim(),
      'designation': designationController.text.trim(),
    };

    updateProfile(updateData);
  }

  /// Update profile API call
  Future<void> updateProfile(Map<String, dynamic> data) async {
    isLoading = true;
    reloadData();

    try {
      // TODO: Replace with actual API call
      final response = await ProfileDatasource().updateProfile(data);

      if (response == null) {
        Helpers.showSnackBar(
          context,
          'Something went wrong!',
          type: SnackType.error,
        );
        return;
      }

      if (response.success ?? false) {
        if (context.mounted) {
          Navigator.pop(context, true);
        }
        Helpers.showSnackBar(
          context,
          'Profile updated successfully!',
          type: SnackType.success,
        );
      } else {
        Helpers.showSnackBar(
          context,
          response.message ?? 'Failed to update profile',
          type: SnackType.error,
        );
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      Helpers.showSnackBar(
        context,
        'Failed to update profile. Please try again.',
        type: SnackType.error,
      );
    } finally {
      isLoading = false;
      reloadData();
    }
  }

  /// Show password change dialog
  void showPasswordChangeDialog() async {
    final parentContext = context;
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      useSafeArea: true,
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final textTheme = Theme.of(context).textTheme;
            /// Change password API call
            Future<void> changePassword(Map<String, dynamic> passwordData) async {
              try {
                final response = await ProfileDatasource().changePassword(passwordData);

                if (response == null) {
                  throw Exception('Something went wrong!');
                }

                if (response.success ?? false) {
                  Navigator.of(dialogContext).pop();
                  Helpers.showSnackBar(
                    parentContext,
                    response.message ?? 'Password changed successfully!',
                    type: SnackType.success,
                  );
                } else {
                  Helpers.showSnackBar(
                    parentContext,
                    response.message ?? 'Failed to change password',
                    type: SnackType.error,
                  );
                }
              } catch (e) {
                debugPrint('Change password error: $e');
                Helpers.showSnackBar(
                  parentContext,
                  'Something went wrong',
                  type: SnackType.error,
                );
              }
            }

            Future<void> handlePasswordChange() async {
              if (!formKey.currentState!.validate()) {
                return;
              }
              if (newPasswordController.text != confirmPasswordController.text) {
                Helpers.showSnackBar(
                  parentContext,
                  'Passwords do not match',
                  type: SnackType.error,
                );
                return;
              }
              setState(() {
                isLoading = true;
              });

              try {
                final passwordData = {
                  'currentPassword': currentPasswordController.text,
                  'newPassword': newPasswordController.text,
                };
                await changePassword(passwordData);
              } catch (e) {
                debugPrint(e.toString());
              } finally {
                if (context.mounted) {
                  setState(() {
                  isLoading = false;
                  });
              }
            }

            }

            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              content: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Pallete.warningColor.withValues(alpha: 0.2),
                                  Pallete.warningColor.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.lock_reset,
                              color: Pallete.warningColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Change Password',
                              style: textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(dialogContext).pop(),
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Current Password
                      CustomTextField(
                        controller: currentPasswordController,
                        label: 'Current Password',
                        hint: 'Enter your current password',
                        // prefixIcon: prefixIcon,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Current password is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Current Password
                      CustomTextField(
                        controller: newPasswordController,
                        label: 'New Password',
                        hint: 'Enter your new password',
                        // prefixIcon: prefixIcon,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'New password is required';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      CustomTextField(
                        controller: confirmPasswordController,
                        label: 'Confirm New Password',
                        hint: 'Re-enter your new password',
                        // prefixIcon: prefixIcon,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                              isLoading ? null : handlePasswordChange,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Pallete.warningColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isLoading
                                  ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                  : Text('Change'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );

          }
        );
      }
    );

  }

  /// Dispose all controllers
  void dispose() {
    usernameController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    departmentController.dispose();
    designationController.dispose();
  }
}