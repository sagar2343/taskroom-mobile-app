import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class InAppUpdateService {
  InAppUpdateService._();
  static final InAppUpdateService instance = InAppUpdateService._();

  /// Checks Play Store for an update and handles it.
  /// [forceImmediate] -> true forces a blocking full-screen update
  /// (use this only for critical/breaking updates).
  Future<void> checkForUpdate({
    required BuildContext context,
    bool forceImmediate = false,
  }) async {
    // In-App Update API is Android-only. Skip silently on other platforms.
    if (!defaultTargetPlatform.isAndroidPlatform) return;

    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return; // No update available
      }

      final bool canImmediate = info.immediateUpdateAllowed;
      final bool canFlexible = info.flexibleUpdateAllowed;

      if (forceImmediate && canImmediate) {
        await _startImmediateUpdate();
      } else if (canFlexible) {
        await _startFlexibleUpdate(context);
      } else if (canImmediate) {
        // Fallback if flexible isn't allowed but immediate is
        await _startImmediateUpdate();
      }
    } catch (e) {
      // Fail silently — update check should never block app usage
      debugPrint('InAppUpdate check failed: $e');
    }
  }

  Future<void> _startImmediateUpdate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
      // On success, Play Store restarts the app automatically.
    } catch (e) {
      debugPrint('Immediate update failed: $e');
    }
  }

  Future<void> _startFlexibleUpdate(BuildContext context) async {
    try {
      await InAppUpdate.startFlexibleUpdate();

      // Listen for download completion, then prompt restart.
      InAppUpdate.completeFlexibleUpdate().then((_) {
        // App restarts automatically once user confirms via snackbar/dialog
      });

      if (context.mounted) {
        _showRestartSnackbar(context);
      }
    } catch (e) {
      debugPrint('Flexible update failed: $e');
    }
  }

  void _showRestartSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(days: 1), // stays until dismissed/acted
        content: const Text('An update has been downloaded.'),
        action: SnackBarAction(
          label: 'RESTART',
          onPressed: () async {
            await InAppUpdate.completeFlexibleUpdate();
          },
        ),
      ),
    );
  }
}

extension on TargetPlatform {
  bool get isAndroidPlatform => this == TargetPlatform.android;
}