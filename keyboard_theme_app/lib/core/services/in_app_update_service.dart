import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing Google Play In-App Updates
///
/// Provides both flexible and immediate update flows:
/// - Flexible: User can continue using the app while downloading
/// - Immediate: Blocks app usage until update is installed
class InAppUpdateService {
  static const String _keyLastUpdateCheck = 'last_update_check';
  static const String _keyUpdatePromptCount = 'update_prompt_count';
  static const Duration _updateCheckInterval = Duration(hours: 24);

  /// Check if an update is available and handle accordingly
  ///
  /// [context] - BuildContext for showing dialogs
  /// [forceImmediate] - If true, forces immediate update for critical versions
  /// [showNoUpdateSnackbar] - If true, shows a message when no update is available
  Future<void> checkForUpdate({
    required BuildContext context,
    bool forceImmediate = false,
    bool showNoUpdateSnackbar = false,
  }) async {
    // Only check on Android
    if (!Platform.isAndroid) {
      debugPrint('In-app updates are only supported on Android');
      return;
    }

    try {
      // Check if enough time has passed since last check
      if (!forceImmediate && !await _shouldCheckForUpdate()) {
        debugPrint('Skipping update check - checked recently');
        return;
      }

      // Check for available updates
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateNotAvailable) {
        debugPrint('No update available');
        if (showNoUpdateSnackbar && context.mounted) {
          _showSnackbar(context, 'You are using the latest version');
        }
        return;
      }

      debugPrint('Update available: ${updateInfo.availableVersionCode}');

      // Save update check time
      await _saveUpdateCheckTime();

      // Determine update type based on priority
      final bool isImmediate = forceImmediate ||
                               updateInfo.updatePriority >= 4 ||
                               updateInfo.immediateUpdateAllowed;

      if (isImmediate && updateInfo.immediateUpdateAllowed) {
        await _performImmediateUpdate(context);
      } else if (updateInfo.flexibleUpdateAllowed) {
        await _performFlexibleUpdate(context);
      }
    } catch (e) {
      debugPrint('Error checking for update: $e');
    }
  }

  /// Performs immediate update flow (blocks app usage)
  Future<void> _performImmediateUpdate(BuildContext context) async {
    try {
      debugPrint('Starting immediate update...');

      final result = await InAppUpdate.performImmediateUpdate();

      if (result == AppUpdateResult.success) {
        debugPrint('Immediate update completed successfully');
      } else if (result == AppUpdateResult.userDeniedUpdate) {
        debugPrint('User cancelled immediate update');
        if (context.mounted) {
          _showUpdateRequiredDialog(context);
        }
      } else {
        debugPrint('Immediate update failed: $result');
      }
    } catch (e) {
      debugPrint('Error performing immediate update: $e');
    }
  }

  /// Performs flexible update flow (downloads in background)
  Future<void> _performFlexibleUpdate(BuildContext context) async {
    try {
      debugPrint('Starting flexible update...');

      // Show user-friendly dialog first
      final shouldUpdate = await _showFlexibleUpdateDialog(context);
      if (!shouldUpdate) {
        await _incrementUpdatePromptCount();
        return;
      }

      final result = await InAppUpdate.startFlexibleUpdate();

      if (result == AppUpdateResult.success) {
        debugPrint('Flexible update download started');
        if (context.mounted) {
          _showSnackbar(context, 'Downloading update...');
        }

        // Listen for download completion
        InAppUpdate.completeFlexibleUpdate().then((_) {
          debugPrint('Flexible update completed');
        }).catchError((error) {
          debugPrint('Error completing flexible update: $error');
        });
      } else if (result == AppUpdateResult.userDeniedUpdate) {
        debugPrint('User cancelled flexible update');
        await _incrementUpdatePromptCount();
      } else {
        debugPrint('Flexible update failed: $result');
      }
    } catch (e) {
      debugPrint('Error performing flexible update: $e');
    }
  }

  /// Shows dialog asking user to update (flexible)
  Future<bool> _showFlexibleUpdateDialog(BuildContext context) async {
    final promptCount = await _getUpdatePromptCount();

    return await showDialog<bool>(
      context: context,
      barrierDismissible: promptCount < 3, // Force after 3 prompts
      builder: (context) => AlertDialog(
        title: const Text('New Update Available'),
        content: const Text(
          'A new version is available!\n'
          'Update now to enjoy better performance and new features.',
        ),
        actions: [
          if (promptCount < 3)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Later'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Shows dialog when immediate update is required
  Future<void> _showUpdateRequiredDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Required'),
        content: const Text(
          'This version is no longer supported.\n'
          'Please update to continue using the app.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              checkForUpdate(context: context, forceImmediate: true);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  /// Shows a snackbar message
  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Check if enough time has passed since last update check
  Future<bool> _shouldCheckForUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_keyLastUpdateCheck);

      if (lastCheck == null) return true;

      final lastCheckTime = DateTime.fromMillisecondsSinceEpoch(lastCheck);
      final now = DateTime.now();

      return now.difference(lastCheckTime) >= _updateCheckInterval;
    } catch (e) {
      debugPrint('Error checking last update time: $e');
      return true;
    }
  }

  /// Save the current time as last update check time
  Future<void> _saveUpdateCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastUpdateCheck, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving update check time: $e');
    }
  }

  /// Get number of times user was prompted for update
  Future<int> _getUpdatePromptCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyUpdatePromptCount) ?? 0;
    } catch (e) {
      debugPrint('Error getting update prompt count: $e');
      return 0;
    }
  }

  /// Increment update prompt counter
  Future<void> _incrementUpdatePromptCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = await _getUpdatePromptCount();
      await prefs.setInt(_keyUpdatePromptCount, count + 1);
    } catch (e) {
      debugPrint('Error incrementing update prompt count: $e');
    }
  }

  /// Reset update prompt counter (call after successful update)
  Future<void> resetUpdatePromptCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUpdatePromptCount);
    } catch (e) {
      debugPrint('Error resetting update prompt count: $e');
    }
  }
}
