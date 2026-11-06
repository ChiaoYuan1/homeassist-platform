
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Future<bool> showHomeAssistConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final accentColor = destructive
      ? const Color(0xFFDC2626)
      : AppTheme.primary;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          24, 28, 24, 24,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                destructive
                    ? Icons.warning_amber_rounded
                    : Icons.help_outline_rounded,
                color: accentColor,
                size: 36,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 26),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    child: const Text('Cancel'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  return confirmed ?? false;
}

Future<void> showHomeAssistSuccessDialog({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          24, 28, 24, 24,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primary,
                size: 38,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 26),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

enum HomeAssistMessageType {
  information,
  warning,
  error,
}

Future<void> showHomeAssistMessageDialog({
  required BuildContext context,
  required String title,
  required String message,
  HomeAssistMessageType type = HomeAssistMessageType.information,
  String buttonLabel = 'OK',
}) async {
  final isError = type == HomeAssistMessageType.error;

  final accentColor = isError
      ? const Color(0xFFDC2626)
      : AppTheme.primary;

  final IconData icon;

  switch (type) {
    case HomeAssistMessageType.information:
      icon = Icons.info_outline_rounded;
      break;

    case HomeAssistMessageType.warning:
      icon = Icons.warning_amber_rounded;
      break;

    case HomeAssistMessageType.error:
      icon = Icons.error_outline_rounded;
      break;
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          24, 28, 24, 24,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 38,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 26),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      );
    },
  );
}