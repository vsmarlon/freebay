import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';

class ProductPreviewCard extends StatelessWidget {
  final String title;
  final String description;
  final String pricePreview;
  final String? categoryName;
  final String? imagePath;
  final bool isNew;
  final String userName;
  final String? userAvatarUrl;

  const ProductPreviewCard({
    super.key,
    required this.title,
    required this.description,
    required this.pricePreview,
    required this.categoryName,
    required this.imagePath,
    required this.isNew,
    required this.userName,
    required this.userAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      color: isDark
          ? AppColors.surfaceContainerDark
          : AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PREVIEW DO ANÚNCIO',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.onPrimaryContainer : AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border.all(color: context.borderColor, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: imagePath != null
                      ? Image.file(File(imagePath!), fit: BoxFit.cover)
                      : Container(
                          color: isDark
                              ? AppColors.surfaceContainerLowDark
                              : AppColors.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.mediumGray,
                              size: 40,
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          UserAvatar(
                            imageUrl: userAvatarUrl,
                            size: AppAvatarSize.small,
                          ),
                          Spacing.hSm,
                          Text(
                            userName,
                            style: TextStyle(
                              fontFamily: AppTypography.headlineFontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.brutalistGradient,
                              border: Border.all(
                                color: context.borderColor,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              isNew ? 'NOVO' : 'USADO',
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Spacing.vSm,
                      Text(
                        title.isEmpty ? 'Seu título aparece aqui' : title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.headlineFontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.white : AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        color: isDark
                            ? AppColors.surfaceContainerLowDark
                            : AppColors.surfaceContainerHighest,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          pricePreview,
                          style: TextStyle(
                            fontFamily: AppTypography.headlineFontFamily,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? AppColors.white : AppColors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        categoryName ?? 'Categoria obrigatória',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.onPrimaryContainer
                              : AppColors.primary,
                        ),
                      ),
                      Spacing.vSm,
                      Text(
                        description.isEmpty
                            ? 'A descrição do produto aparece aqui.'
                            : description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: isDark
                              ? AppColors.mediumGray
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
