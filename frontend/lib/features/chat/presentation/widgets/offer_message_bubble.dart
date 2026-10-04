import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class OfferMessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMe;

  const OfferMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final meta = message.metadata ?? {};
    final title = meta['title'] as String? ?? strings.productTitle;
    final originalPrice = meta['originalPrice'] as int?;
    final offerPrice = meta['offerPrice'] as int? ?? 0;
    final note = meta['message'] as String?;
    final productId = meta['productId'] as String?;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceMidColor,
        border: Border.all(color: AppColors.primaryContainer, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer,
                size: 16,
                color: AppColors.primaryContainer,
              ),
              Spacing.hSm,
              Text(
                strings.chatPurchaseOffer,
                style: const TextStyle(
                  fontFamily: AppTypography.headlineFontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryContainer,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Spacing.vSm,
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          Spacing.vXs,
          Row(
            children: [
              if (originalPrice != null) ...[
                Text(
                  CurrencyUtils.formatCents(originalPrice),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Spacing.hSm,
              ],
              Text(
                CurrencyUtils.formatCents(offerPrice),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryContainer,
                ),
              ),
            ],
          ),
          if (note != null && note.isNotEmpty) ...[
            Spacing.vXs,
            Text(
              '"$note"',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: context.textSecondary,
              ),
            ),
          ],
          if (!isMe) ...[
            Spacing.vMd,
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: strings.chatOfferAccept,
                    size: AppButtonSize.compact,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      if (productId != null) {
                        context.push(
                          '/profile/payment?productId=$productId&offerPrice=$offerPrice',
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
