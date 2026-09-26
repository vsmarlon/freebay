import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/theme_extension.dart';

Future<T?> showBrutalistCupertinoDialog<T>({
  required BuildContext context,
  required String title,
  String? content,
  required List<Widget> actions,
  bool preventBack = false,
}) {
  return showCupertinoDialog<T>(
    context: context,
    builder: (BuildContext context) {
      return PopScope(
        canPop: !preventBack,
        child: Container(
          // Override the blur with brutalist background
          decoration: const BoxDecoration(color: Colors.transparent),
          child: CupertinoAlertDialog(
            title: Text(
              title,
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                color: context.textPrimary,
              ),
            ),
            content: content != null
                ? Text(
                    content,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: context.textSecondary,
                    ),
                  )
                : null,
            actions: actions,
          ),
        ),
      );
    },
  );
}

class BrutalistDialogAction extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isDestructiveAction;
  final bool isDefaultAction;

  const BrutalistDialogAction({
    super.key,
    required this.text,
    required this.onPressed,
    this.isDestructiveAction = false,
    this.isDefaultAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoDialogAction(
      onPressed: onPressed,
      isDestructiveAction: isDestructiveAction,
      isDefaultAction: isDefaultAction,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTypography.headlineFontFamily,
          fontWeight: isDefaultAction ? FontWeight.bold : FontWeight.normal,
          color: isDestructiveAction ? AppColors.error : context.textPrimary,
        ),
      ),
    );
  }
}
