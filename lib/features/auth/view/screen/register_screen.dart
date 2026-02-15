import 'package:field_work/features/auth/controller/register_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_pallete.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterController _controller;

  @override
  void initState() {
    _controller = RegisterController(context: context, reloadData: reloadData);
    super.initState();
  }

  void reloadData() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Create Account',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w700,
            )
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Title
              Text(
                'Join Your Team',
                style: textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Enter your organization code and select your role to get started.',
                style: textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Organization Code Label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Organization Code',
                  style: textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ORG Prefix Display
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Pallete.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Pallete.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Format: ORG + 6 characters',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Code Input Row with ORG prefix
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ORG Label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'ORG',
                        style: textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Pallete.primaryColor,
                        )
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Code Input Fields
                    ...List.generate(6, (index) {
                      return Padding(
                        padding: EdgeInsets.only(right: index < 5 ? 8 : 0),
                        child: SizedBox(
                          width: 42,
                          height: 55,
                          child: KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: (event) {
                              if (event is KeyDownEvent &&
                                  event.logicalKey == LogicalKeyboardKey.backspace) {
                                if (_controller.codeControllers[index].text.isEmpty && index > 0) {
                                  _controller.focusNodes[index - 1].requestFocus();
                                  _controller.codeControllers[index - 1].clear();
                                }
                              }
                            },
                            child: TextField(
                              controller: _controller.codeControllers[index],
                              focusNode: _controller.focusNodes[index],
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: textTheme.bodyLarge!.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Pallete.primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.characters,
                              onChanged: (value) {
                                setState(() {});
                                if (value.isNotEmpty && index < 5) {
                                  _controller.focusNodes[index + 1].requestFocus();
                                }
                                if (value.isEmpty && index > 0) {
                                  _controller.focusNodes[index - 1].requestFocus();
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Select Role Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Your Role',
                  style: textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Role Selection Cards
              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Manager',
                      subtitle: 'Control rooms\n& tasks',
                      isSelected: _controller.selectedRole == 'manager',
                      onTap: () {
                        setState(() {
                          _controller.selectedRole = 'manager';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.badge_outlined,
                      title: 'Employee',
                      subtitle: 'Execute task\nitems',
                      isSelected: _controller.selectedRole == 'employee',
                      onTap: () {
                        setState(() {
                          _controller.selectedRole = 'employee';
                        });
                      },
                      // isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _controller.isFormValid() ? _controller.handleContinue : null,
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
                          'Continue',
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Link
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w400,
                      color: Pallete.textPrimaryLight,
                    ),
                    children: [
                      TextSpan(
                        text: 'Login',
                        style: textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Pallete.primaryColor,
                        )
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Pallete.primaryColor.withValues(alpha: 0.05)
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Pallete.primaryColor
                : Pallete.surfaceDark,
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Pallete.primaryColor.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? Pallete.primaryColor.withValues(alpha: 0.15)
                    // : (isDark ? Pallete.borderDark : Pallete.borderLight),
                    : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 36,
                color: isSelected
                    ? Pallete.primaryColor
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Pallete.primaryColor
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}