import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/core/components/spacing.dart';

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
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(
        _isPressed ? 2.0 : 0.0,
        _isPressed ? 2.0 : 0.0,
        0.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF131B2E)
              : AppColors.surfaceContainerLowest,
          border: Border.all(
            color: isDark ? AppColors.outline.withAlpha(120) : AppColors.black,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _isPressed
                  ? Colors.transparent
                  : (isDark
                        ? AppColors.primaryContainer.withAlpha(100)
                        : AppColors.black),
              offset: const Offset(3.5, 3.5),
              blurRadius: 0,
            ),
          ],
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
                // Product Image Container with badges
                Stack(
                  children: [
                    _buildImage(),

                    // Condition Badge
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
                              : (isDark
                                    ? const Color(0xFF1E293B)
                                    : AppColors.darkGray),
                          border: Border.all(
                            color: isDark ? AppColors.white : AppColors.black,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          isNew ? 'NOVO' : 'USADO',
                          style: const TextStyle(
                            fontFamily: AppTypography.headlineFontFamily,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),

                    // 0% TAXA badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF064E3B)
                              : const Color(0xFFD1FAE5),
                          border: Border.all(
                            color: isDark
                                ? AppColors.success
                                : const Color(0xFF059669),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt,
                              size: 10,
                              color: isDark
                                  ? AppColors.success
                                  : const Color(0xFF059669),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '0% TAXA',
                              style: TextStyle(
                                fontFamily: AppTypography.headlineFontFamily,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AppColors.success
                                    : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Info body
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
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
                        maxLines: widget.variant == AppCardVariant.compact
                            ? 1
                            : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Price Tag Box
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
                                color: isDark
                                    ? AppColors.onPrimaryContainer
                                    : AppColors.primaryContainer,
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
    final isDark = context.isDark;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF1E1630), Color(0xFF13192B), Color(0xFF2A1538)]
              : const [Color(0xFFF3E8FF), Color(0xFFE0E7FF), Color(0xFFFCE7F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              color: isDark
                  ? AppColors.primaryContainer.withAlpha(180)
                  : AppColors.primaryContainer,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              'FREEBAY',
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: isDark
                    ? AppColors.primaryContainer.withAlpha(180)
                    : AppColors.primaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final isDark = context.isDark;
    final height = widget.variant == AppCardVariant.compact ? 120.0 : 160.0;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF131B2E)
            : AppColors.surfaceContainerLowest,
        border: Border.all(
          color: isDark
              ? AppColors.outline.withAlpha(80)
              : AppColors.outlineVariant,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: height,
            color: isDark
                ? AppColors.surfaceContainerDark
                : AppColors.surfaceContainerHigh,
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 100,
                  color: isDark
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerHigh,
                ),
                Spacing.vSm,
                Container(
                  height: 20,
                  width: double.infinity,
                  color: isDark
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerHigh,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
