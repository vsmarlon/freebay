import '../tokens/app_motion.dart';
import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/theme_extension.dart';
import '../tokens/spacing.dart';

Future<T?> showBrutalistSheet<T>({
  required BuildContext context,
  String? title,
  Widget Function(BuildContext)? builder,
  Widget? child,
  Color? backgroundColor,
  bool useSafeArea = true,
  bool showDragHandle = true,
  bool useRootNavigator = true,
  EdgeInsetsGeometry? padding,
}) {
  final Widget Function(BuildContext) effectiveBuilder =
      builder ?? ((_) => child ?? const SizedBox.shrink());

  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      return AnimatedPadding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        duration: AppMotion.base,
        curve: AppMotion.enterCurve,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
          child: Material(
            color: sheetContext.isDark
                ? AppColors.surfaceDark
                : AppColors.white,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: BrutalistSheetScaffold(
                title: title,
                builder: effectiveBuilder,
                useSafeArea: useSafeArea,
                showDragHandle: showDragHandle,
                padding: padding,
              ),
            ),
          ),
        ),
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
                  color: dragHandleColor ?? context.textSecondary.withAlpha(77),
                ),
              ),
            ),
            if (title != null) Spacing.vLg,
          ],
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            Spacing.vLg,
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

class BrutalistBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const BrutalistBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    Widget? action,
    bool useRootNavigator = true,
  }) {
    return showBrutalistSheet<T>(
      context: context,
      title: title,
      child: child,
      useRootNavigator: useRootNavigator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.borderColor, width: 1.5)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: AppTypography.h3.copyWith(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                color: context.textPrimary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Container(
            height: 1.5,
            color: AppColors.outlineVariant,
            margin: const EdgeInsets.symmetric(vertical: 12),
          ),
          child,
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
