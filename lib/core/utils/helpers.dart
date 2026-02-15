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

  static DateTime? _lastBackPressed;

  static Future<bool> handleDoubleBackPress(
      BuildContext context, {
        String message = "Press back again to exit",
        Duration duration = const Duration(seconds: 1),
      }) async {
    final now = DateTime.now();
    if (_lastBackPressed == null || now.difference(_lastBackPressed!) > duration) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message), duration: duration));
      return false;
    }
    return true;
  }

  // Convert String time (e.g., "07:30 PM") to TimeOfDay
  static TimeOfDay? parseTimeToView(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;

    try {
      final DateTime dateTime = DateFormat('HH:mm:ss').parse(timeString);
      return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    } catch (e) {
      debugPrint("Error parsing time: $e");
      return null;
    }
  }

  static DateTime? parseTimeToDateTime(String timeStr) {
    try {
      return DateFormat("HH:mm:ss").parse(timeStr);
    } catch (_) {
      return null;
    }
  }


  static String formatTimeWithSeconds(DateTime? time) {
    if (time == null) return 'Select Time';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }



  static String formatTime(TimeOfDay? time) {
    if (time == null) return 'Select Time';
    final DateTime now = DateTime.now();
    final DateTime formattedTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(formattedTime); // Converts to AM/PM format
  }


  static String formatSecondsToMinSec(int seconds) {
    final int hour = (seconds / 3600).floor();
    final int minute = ((seconds / 3600 - hour) * 60).floor();
    final int second = ((((seconds / 3600 - hour) * 60) - minute) * 60).floor();

    final String setTime = [
      minute.toString().padLeft(2, '0'),
      second.toString().padLeft(2, '0'),
    ].join(':');
    return setTime;
  }

  static String formatTimeToMin(String? apiTime) {
    if (apiTime == null || apiTime.isEmpty) {
      return '';
    }
    final date = DateFormat('HH:mm:ss').parse(apiTime);
    return DateFormat('mm').format(date);
  }

  static String formatAPITime(String? apiTime) {
    if (apiTime == null) {
      return '';
    }
    final date = DateFormat('yyyy-MM-dd HH:mm:ss').parse(apiTime);
    return DateFormat('dd MMM, yyyy hh:mm a').format(date);
  }

  static String formatAPIDateTimeToTime(String? apiTime) {
    if (apiTime == null) {
      return '';
    }
    final date = DateFormat('yyyy-MM-dd HH:mm:ss').parse(apiTime);
    return DateFormat('hh:mm a').format(date);
  }

  static String getStringFromDateToDisplay(DateTime dateTime) {
    return DateFormat('dd MMM, yyyy').format(dateTime);
  }

  static String formatMinsToHrsAndMins(int? mins) {
    if (mins == null) {
      return '';
    }
    final int hour = (mins / 60).floor();
    final int minute = ((mins / 60 - hour) * 60).floor();

    return '${(hour > 0) ? hour.toString().padLeft(2, "0") : hour.toString()} Hr. ${minute.toString().padLeft(2, "0")} Mins';
  }
}
