import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/core/utils/currency_utils.dart';

enum AppCardVariant { compact, full, skeleton }

class AppCard extends StatefulWidget {
  final String? imageUrl;
  final String title;
  final int priceInCents;
  final double? score;
  final String? condition;
  final String? category;
  final AppCardVariant variant;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.title,
    required this.priceInCents,
    this.imageUrl,
    this.score,
    this.condition,
    this.category,
    this.variant = AppCardVariant.full,
    this.onTap,
  });

  const AppCard.skeleton({super.key})
    : variant = AppCardVariant.skeleton,
      title = '',
      priceInCents = 0,
      imageUrl = null,
      score = null,
      condition = null,
      category = null,
      onTap = null;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.variant == AppCardVariant.skeleton) {
      return _buildSkeleton(context);
    }

    final isDark = context.isDark;
    final price = CurrencyUtils.formatCents(widget.priceInCents);
    final isNew = widget.condition == 'new' || widget.condition == 'NOVO';

    return AnimatedContainer(
      duration: AppMotion.tap,
      transform: Matrix4.translationValues(
        _isPressed ? AppDepth.pressOffset : 0.0,
        _isPressed ? AppDepth.pressOffset : 0.0,
        0.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border.all(
            color: context.borderColor,
            width: AppDepth.borderThick,
          ),
          boxShadow: _isPressed ? null : AppDepth.hard(context.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (_) {
              HapticFeedback.lightImpact();
              setState(() => _isPressed = true);
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              widget.onTap?.call();
            },
            onTapCancel: () => setState(() => _isPressed = false),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    _buildImage(),

                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isNew
                              ? AppColors.primaryContainer
                              : context.textPrimary,
                          border: Border.all(
                            color: isNew
                                ? AppColors.primaryContainer
                                : context.textPrimary,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          isNew ? 'NOVO' : 'USADO',
                          style: TextStyle(
                            fontFamily: AppTypography.headlineFontFamily,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: isNew
                                ? AppColors.white
                                : context.surfaceColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontFamily: AppTypography.headlineFontFamily,
                          fontSize: widget.variant == AppCardVariant.compact
                              ? 13
                              : 15,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primaryContainer.withAlpha(35)
                              : AppColors.primaryContainer.withAlpha(20),
                          border: Border.all(
                            color: AppColors.primaryContainer.withAlpha(120),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              price,
                              style: TextStyle(
                                fontFamily: AppTypography.headlineFontFamily,
                                fontSize:
                                    widget.variant == AppCardVariant.compact
                                    ? 14
                                    : 16,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: context.colors.primary,
                              ),
                            ),
                            if (widget.score != null) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    widget.score!.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final height = widget.variant == AppCardVariant.compact ? 120.0 : 160.0;

    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return _buildPlaceholder(height);
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl!,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      memCacheWidth: 400,
      memCacheHeight: 400,
      placeholder: (context, url) => _buildPlaceholder(height),
      errorWidget: (context, url, error) => _buildPlaceholder(height),
    );
  }

  Widget _buildPlaceholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.surfaceMidColor, context.surfaceHighColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.primaryContainer,
              size: 32,
            ),
            SizedBox(height: 4),
            Text(
              'FREEBAY',
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: AppColors.primaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final height = widget.variant == AppCardVariant.compact ? 120.0 : 160.0;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.all(color: context.borderSoftColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: height, color: context.surfaceHighColor),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 100,
                  color: context.surfaceHighColor,
                ),
                Spacing.vSm,
                Container(
                  height: 20,
                  width: double.infinity,
                  color: context.surfaceHighColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
