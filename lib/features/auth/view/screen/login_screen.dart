import 'package:field_work/core/utils/helpers.dart';
import 'package:field_work/features/auth/controller/login_controller.dart';
import 'package:field_work/features/auth/view/screen/register_screen.dart';
import 'package:field_work/features/widgets/animated_screen_wrapper.dart';
import 'package:field_work/features/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_pallete.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController(context: context, reloadData: reloadData);
  }

  void reloadData() => setState(() {});

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedScreenWrapper(
            child: Form(
              key: _controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.03),
                  // App Logo with Glow Effect
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Pallete.primaryColor.withValues(alpha: 0.4),
                          Pallete.primaryColor.withValues(alpha: 0.2),
                          Pallete.primaryColor.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Pallete.primaryColor.withValues(alpha: 0.5),
                            blurRadius: 25,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset('assets/icon/app_icon.png'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // App Name
                  Text(
                    'Task Room',
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                      
                  // Tagline
                  Text(
                    'Sign in to continue',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                      
                  // Organization Code Field
                  CustomTextField(
                    controller: _controller.orgCodeController,
                    label: 'Organization Code',
                    hint: 'Enter your organization code',
                    prefixIcon: Icons.business_outlined,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 9,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Organization code is required';
                      }
                      if (value.length < 6) {
                        return 'Enter a valid organization code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                      
                  // Username Field
                  CustomTextField(
                    controller: _controller.usernameController,
                    label: 'Username',
                    hint: 'Enter your username',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                      
                  // Password Field
                  CustomTextField(
                    controller: _controller.passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: _controller.obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _controller.obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 22,
                      ),
                      onPressed: (){
                        _controller.obscurePassword = !_controller.obscurePassword;
                        reloadData();
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 4),
                  // Forget Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password
                        Helpers.showSnackBar(
                          context,
                          'Forgot password feature coming soon!',
                          type: SnackType.normal,
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: textTheme.titleSmall!.
                        copyWith(
                          fontWeight: FontWeight.w600,
                          color: Pallete.primaryColor,
                        )
                      ),
                    ),
                  ),
                      
                  const SizedBox(height: 12),
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _controller.isLoading
                          ? null
                          : _controller.handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Pallete.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        shadowColor: Pallete.primaryColor.withValues(alpha: 0.3),
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
                            'Login',
                            style: textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                      
                  // Divider with OR
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                      
                  // Create Account Button
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: textTheme.bodyMedium!.
                        copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          TextSpan(
                            text: 'Create Account',
                            style: textTheme.bodyMedium!.
                            copyWith(
                              fontWeight: FontWeight.w700,
                              color: Pallete.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                      
                  // Organization Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Pallete.infoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Pallete.infoColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Pallete.infoColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Don't have an organization?",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Create your own organization and invite your team members to collaborate.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _controller.launchURL,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Pallete.infoColor,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.launch,
                                  color: Pallete.infoColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Visit taskroom.com',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Pallete.infoColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                      
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
