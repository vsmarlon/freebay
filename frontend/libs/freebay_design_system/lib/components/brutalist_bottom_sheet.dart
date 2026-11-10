import '../tokens/app_motion.dart';
import 'package:flutter/material.dart';
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
  bool scrollable = true,
}) {
  final Widget Function(BuildContext) effectiveBuilder =
      builder ?? ((_) => child ?? const SizedBox.shrink());

  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      return LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight =
              (constraints.maxHeight - media.viewInsets.bottom)
                  .clamp(0.0, constraints.maxHeight)
                  .toDouble();
          return AnimatedPadding(
            padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
            duration: AppMotion.base,
            curve: AppMotion.enterCurve,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: availableHeight * 0.9),
              child: Material(
                color: backgroundColor ?? context.colors.surface,
                child: BrutalistSheetScaffold(
                  title: title,
                  builder: effectiveBuilder,
                  useSafeArea: useSafeArea,
                  showDragHandle: showDragHandle,
                  padding: padding,
                  scrollable: scrollable,
                ),
              ),
            ),
          );
        },
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
  final bool scrollable;

  const BrutalistSheetScaffold({
    super.key,
    this.title,
    required this.builder,
    this.useSafeArea = true,
    this.showDragHandle = true,
    this.dragHandleColor,
    this.padding,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final contentPadding = padding ?? const EdgeInsets.all(24);
    Widget content = Padding(
      padding: contentPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDragHandle)
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dragHandleColor ?? context.textSecondary.withAlpha(77),
                ),
              ),
            ),
          if (showDragHandle && title != null) Spacing.vLg,
          if (title != null) ...[
            Text(
              title!,
              style: AppTypography.h3.copyWith(color: context.textPrimary),
            ),
            Spacing.vLg,
          ],
          Flexible(
            child: scrollable
                ? SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: builder(context),
                  )
                : builder(context),
          ),
        ],
      ),
    );

    if (useSafeArea) {
      return SafeArea(top: false, child: content);
    }
    return content;
  }
}
