import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme/app_pallete.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int? maxLines;
  final TextInputFormatter? textInputFormatter;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.validator,
    this.keyboardType,
    this.maxLines,
    this.textInputFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Pallete.textPrimaryDark : Pallete.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          keyboardType: keyboardType,
          controller: controller,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          maxLength: maxLength,
          maxLines: maxLines ?? 1,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Pallete.textPrimaryDark : Pallete.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: GoogleFonts.inter(
              fontSize: 15,
              color: isDark ? Pallete.textSecondaryDark : Pallete.textSecondaryLight,
            ),
            prefixIcon: prefixIcon != null ?
            Icon(
              prefixIcon,
              color: isDark ? Pallete.textSecondaryDark : Pallete.textSecondaryLight,
              size: 22,
            ) : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? Pallete.surfaceDark : Pallete.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Pallete.borderDark : Pallete.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Pallete.borderDark : Pallete.borderLight,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Pallete.errorColor,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Pallete.errorColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}