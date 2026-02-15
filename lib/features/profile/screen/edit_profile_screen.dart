import 'package:field_work/features/profile/controller/edit_profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:field_work/config/theme/app_pallete.dart';
import 'package:field_work/features/auth/model/user_model.dart';
import '../../widgets/avatar_initials.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/icon_box_header.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel userData;

  const EditProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final EditProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EditProfileController(
      context: context,
      reloadData: () => setState(() {}),
      userData: widget.userData,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Pallete.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Pallete.primaryColor,
                              Pallete.primaryLightColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Pallete.primaryColor.withValues(alpha: 0.5),
                            width: 3,
                          ),
                        ),
                        child: widget.userData.profilePicture != null
                            ? ClipOval(
                          child: Image.network(
                            widget.userData.profilePicture!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return AvatarInitials(fullName: widget.userData.fullName);
                            },
                          ),
                        )
                            : AvatarInitials(fullName: widget.userData.fullName),
                      ),
                    ),
                    // Positioned(
                    //   bottom: 0,
                    //   right: 0,
                    //   child: Container(
                    //     padding: const EdgeInsets.all(8),
                    //     decoration: BoxDecoration(
                    //       gradient: LinearGradient(
                    //         colors: [
                    //           Pallete.primaryColor,
                    //           Pallete.primaryLightColor,
                    //         ],
                    //       ),
                    //       shape: BoxShape.circle,
                    //       border: Border.all(
                    //         color: Theme.of(context).scaffoldBackgroundColor,
                    //         width: 3,
                    //       ),
                    //       boxShadow: [
                    //         BoxShadow(
                    //           color:
                    //           Pallete.primaryColor.withValues(alpha: 0.3),
                    //           blurRadius: 8,
                    //           offset: const Offset(0, 2),
                    //         ),
                    //       ],
                    //     ),
                    //     child: Icon(
                    //       Icons.camera_alt,
                    //       color: Colors.white,
                    //       size: 20,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Basic Information Section
              IconBoxHeader(
                icon: Icons.person,
                title: 'Basic Information',
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _controller.usernameController,
                label: 'Username',
                hint: 'Enter your username',
                prefixIcon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username is required';
                  }
                  if (value.length < 4) {
                    return 'Username must be at least 4 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _controller.fullNameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                prefixIcon: Icons.account_circle_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Contact Information Section
              IconBoxHeader(
                icon: Icons.contact_phone,
                title: 'Contact Information',
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _controller.emailController,
                label: 'Email',
                hint: 'Enter your email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _controller.mobileController,
                label: 'Mobile Number',
                hint: 'Enter your mobile number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mobile number is required';
                  }
                  if (value.length != 10) {
                    return 'Enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Work Information Section
              IconBoxHeader(
                icon: Icons.work_outline,
                title: 'Work Information',
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _controller.departmentController,
                label: 'Department',
                hint: 'e.g., Sales, Marketing, IT',
                prefixIcon: Icons.business_center_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Department is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _controller.designationController,
                label: 'Designation',
                hint: 'Enter your job title',
                prefixIcon: Icons.work_history_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Designation is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Password Change Button
              GestureDetector(
                onTap: _controller.showPasswordChangeDialog,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Pallete.warningColor.withValues(alpha: 0.15),
                        Pallete.warningColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Pallete.warningColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Pallete.warningColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          color: Pallete.warningColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Change Password',
                              style: textTheme.bodyLarge!.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Update your password for security',
                              style: textTheme.bodySmall!.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Pallete.warningColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _controller.isLoading ? null : _controller.handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Pallete.primaryColor,
                    disabledBackgroundColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _controller.isLoading
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Save Changes',
                        style: textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}