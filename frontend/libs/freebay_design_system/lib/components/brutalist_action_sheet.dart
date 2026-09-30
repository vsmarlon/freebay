import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/theme_extension.dart';

Future<T?> showBrutalistActionSheet<T>({
  required BuildContext context,
  String? title,
  String? message,
  required List<Widget> actions,
  Widget? cancelAction,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (BuildContext context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors
              .transparent, // Digital brutalist doesn't use standard iOS sheet blur
        ),
        child: CupertinoActionSheet(
          title: title != null
              ? Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppTypography.headlineFontFamily,
                    color: context.textPrimary,
                  ),
                )
              : null,
          message: message != null
              ? Text(
                  message,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    color: context.textSecondary,
                  ),
                )
              : null,
          actions: actions,
          cancelButton: cancelAction,
        ),
      );
    },
  );
}

class BrutalistActionSheetAction extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final bool isDestructiveAction;
  final bool isDefaultAction;

  const BrutalistActionSheetAction({
    super.key,
    required this.title,
    required this.onPressed,
    this.isDestructiveAction = false,
    this.isDefaultAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheetAction(
      onPressed: onPressed,
      isDestructiveAction: isDestructiveAction,
      isDefaultAction: isDefaultAction,
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppTypography.headlineFontFamily,
          fontWeight: isDefaultAction ? FontWeight.bold : FontWeight.normal,
          color: isDestructiveAction ? AppColors.error : context.textPrimary,
        ),
      ),
    );
  }
}
