import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/core/router/app_routes.dart';

/// Renders a PRODUCT_CARD message bubble inside the chat.
///
/// Displays the product image (full width, max 150px height), title, price in
/// accent colour, and a "Ver produto →" link. Tapping navigates to the product
/// detail page.
class ProductCardBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;

  const ProductCardBubble({
    super.key,
    required this.message,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    final meta = message.metadata;
    final productId = meta?['productId'] as String? ?? '';
    final title = meta?['title'] as String? ?? '';
    final price = meta?['price'] as num?;
    final imageUrl = meta?['imageUrl'] as String?;
    final priceStr = price != null
        ? 'R\$ ${(price / 100).toStringAsFixed(2)}'
        : '';

    return GestureDetector(
      onTap: productId.isNotEmpty
          ? () => context.push(AppRoutes.productPath(productId))
          : null,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        decoration: BoxDecoration(
          color: context.isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLow,
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product image
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRect(
                child: SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 150,
                      color: context.surfaceMidColor,
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTypography.headlineFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (priceStr.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      priceStr,
                      style: const TextStyle(
                        fontFamily: AppTypography.headlineFontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'Ver produto →',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
