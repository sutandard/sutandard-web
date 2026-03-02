import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum SnackBarType { info, success, error }

void showAppSnackBar(
  BuildContext context, {
  required String message,
  SnackBarType type = SnackBarType.info,
  Duration duration = const Duration(seconds: 2),
}) {
  final (Color bg, Color fg, IconData icon) = switch (type) {
    SnackBarType.info => (AppColors.primary, Colors.white, Icons.info_outline),
    SnackBarType.success =>
      (const Color(0xFF059669), Colors.white, Icons.check_circle_outline),
    SnackBarType.error =>
      (AppColors.error, Colors.white, Icons.error_outline),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontFamily: 'SUITE',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
}
