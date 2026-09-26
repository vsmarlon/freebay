import 'package:flutter/material.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

/// Static escrow reassurance banner shown on the product detail page.
class EscrowTrustBanner extends StatelessWidget {
  const EscrowTrustBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withAlpha(20),
        border: Border.all(color: AppColors.primaryContainer, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: AppColors.primaryContainer,
            size: 20,
          ),
          Spacing.hSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CUSTÓDIA FREEBAY GARANTIDA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryContainer,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Seu pagamento só é liberado para o vendedor após você receber o produto e confirmar a entrega.',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textPrimary,
                    height: 1.3,
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
