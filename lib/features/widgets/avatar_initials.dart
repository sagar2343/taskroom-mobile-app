import 'package:flutter/material.dart';

class AvatarInitials extends StatelessWidget {
  final String? fullName;
  final TextStyle? textStyle;
  final String fallback;

  const AvatarInitials({
    super.key,
    required this.fullName,
    this.textStyle,
    this.fallback = 'U',
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(fullName, fallback);

    return Center(
      child: Text(
        initials,
        style: textStyle ??
            Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
      ),
    );
  }

  String _getInitials(String? name, String fallback) {
    if (name == null || name.trim().isEmpty) {
      return fallback;
    }

    final parts = name.trim().split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return parts[0][0].toUpperCase();
  }
}
