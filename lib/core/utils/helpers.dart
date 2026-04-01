import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme/app_pallete.dart';

enum SnackType { normal, success, error }

class Helpers {

  static void showSnackBar(BuildContext context, String message, {
        SnackType type = SnackType.normal,
      }) {
    final theme = Theme.of(context);

    Color backgroundColor;

    switch (type) {
      case SnackType.success:
        backgroundColor = Pallete.successColor;
        break;
      case SnackType.error:
        backgroundColor = Pallete.errorColor;
        break;
      case SnackType.normal:
      backgroundColor = theme.colorScheme.primary;
    }

    Flushbar(
      message: message,
      messageSize: 15,
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: backgroundColor,
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(14),
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 450),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      icon: _iconForType(type),
      boxShadows: [
        BoxShadow(
          color: backgroundColor.withValues(alpha: 0.35),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ).show(context);
  }

  static IconData getRoomIcon(String? category, bool? isArchived) {
    if (isArchived ?? false) return Icons.archive;
    if (category?.toLowerCase() == 'it') return Icons.computer;
    if (category?.toLowerCase() == 'sales') return Icons.trending_up;
    if (category?.toLowerCase() == 'delivery') return Icons.local_shipping;
    if (category?.toLowerCase() == 'inspection') return Icons.search;
    if (category?.toLowerCase() == 'survey') return Icons.poll;
    if (category?.toLowerCase() == 'maintenance') return Icons.build;
    return Icons.meeting_room;
  }

  static Icon _iconForType(SnackType type) {
    switch (type) {
      case SnackType.success:
        return const Icon(Icons.check_circle_outline, color: Colors.white);
      case SnackType.error:
        return const Icon(Icons.error_outline, color: Colors.white);
      case SnackType.normal:
      return const Icon(Icons.info_outline, color: Colors.white);
    }
  }

}
