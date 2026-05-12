import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';

Future<T?> showBrutalistSheet<T>({
  required BuildContext context,
  String? title,
  required Widget Function(BuildContext) builder,
  Color? backgroundColor,
  bool useSafeArea = true,
  bool showDragHandle = true,
  EdgeInsetsGeometry? padding,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: backgroundColor ?? (context.isDark ? AppColors.surfaceDark : AppColors.white),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    builder: (sheetContext) {
      return BrutalistSheetScaffold(
        title: title,
        builder: builder,
        useSafeArea: useSafeArea,
        showDragHandle: showDragHandle,
        padding: padding,
      );
    },
  );
}

class BrutalistSheetScaffold extends StatelessWidget {
  final String? title;
  final Widget Function(BuildContext) builder;
  final bool useSafeArea;
  final bool showDragHandle;
  final Color? dragHandleColor;
  final EdgeInsetsGeometry? padding;

  const BrutalistSheetScaffold({
    super.key,
    this.title,
    required this.builder,
    this.useSafeArea = true,
    this.showDragHandle = true,
    this.dragHandleColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDragHandle) ...[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dragHandleColor ?? AppColors.mediumGray.withAlpha(77),
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
            if (title != null) const SizedBox(height: 24),
          ],
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
          ],
          builder(context),
        ],
      ),
    );

    if (useSafeArea) {
      return SafeArea(child: content);
    }
    return content;
  }
}