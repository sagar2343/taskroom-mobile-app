import 'package:field_work/features/auth/controller/register_detail_controller.dart';
import 'package:field_work/features/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:field_work/config/theme/app_pallete.dart';

class RegisterDetailsScreen extends StatefulWidget {
  final String organizationCode;
  final String role;
  final String organizationName;

  const RegisterDetailsScreen({
    super.key,
    required this.organizationCode,
    required this.role,
    required this.organizationName,
  });

  @override
  State<RegisterDetailsScreen> createState() => _RegisterDetailsScreenState();
}

class _RegisterDetailsScreenState extends State<RegisterDetailsScreen> {
  late final RegisterDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RegisterDetailController(
      context: context,
      reloadData: reloadData,
      organizationCode: widget.organizationCode,
      role: widget.role,
      organizationName: widget.organizationName,
    );
  }

  void reloadData() => setState(() {});

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Complete Registration',
          style: textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role and Organization Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Pallete.primaryColor.withValues(alpha: 0.15),
                      Pallete.primaryColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Pallete.primaryColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Pallete.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.role == 'manager'
                            ? Icons.admin_panel_settings_outlined
                            : Icons.badge_outlined,
                        size: 28,
                        color: Pallete.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _controller.organizationName,
                            style: textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Pallete.primaryColor,
                            ),
                          ),
                          Text(
                            _controller.role == 'manager' ? 'Manager' : 'Employee',
                            style: textTheme.titleSmall!.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Pallete.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _controller.organizationCode,
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Section: Basic Information
              _SectionHeader(title: 'Basic Information', icon: Icons.person),
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

              const SizedBox(height: 16),

              CustomTextField(
                controller: _controller.usernameController,
                label: 'Username',
                hint: 'Choose a username',
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
                controller: _controller.passwordController,
                label: 'Password',
                hint: 'Create a strong password',
                prefixIcon: Icons.lock_outline,
                obscureText: _controller.obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _controller.obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _controller.obscurePassword = !_controller.obscurePassword;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Section: Contact Information
              _SectionHeader(title: 'Contact Information', icon: Icons.contact_phone),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _controller.emailController,
                label: 'Email Address',
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
                hint: 'Enter 10-digit mobile number',
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

              const SizedBox(height: 32),

              // Section: Work Information
              _SectionHeader(title: 'Work Information', icon: Icons.work_outline),
              const SizedBox(height: 16),

              CustomTextField(
                controller: widget.role == 'employee'
                    ? _controller.employeeIdController
                    : _controller.managerIdController,
                label: widget.role == 'employee' ? 'Employee ID' : 'Manager ID',
                hint: 'Enter your ${widget.role} ID',
                prefixIcon: Icons.badge_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '${widget.role == 'employee' ? 'Employee' : 'Manager'} ID is required';
                  }
                  return null;
                },
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
                prefixIcon: Icons.work_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Designation is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _controller.isLoading ? null : _controller.handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Pallete.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _controller.isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                      : Text(
                        'Create Account',
                        style: textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: Pallete.primaryColor,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
