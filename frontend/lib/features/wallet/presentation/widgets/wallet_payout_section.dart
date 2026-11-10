import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/wallet/data/entities/connect_status_entity.dart';

class WalletPayoutSection extends StatelessWidget {
  const WalletPayoutSection({
    super.key,
    required this.status,
    required this.isLoading,
    required this.onStartOnboarding,
    required this.onOpenDashboard,
  });

  final ConnectStatusEntity? status;
  final bool isLoading;
  final Future<void> Function() onStartOnboarding;
  final Future<void> Function() onOpenDashboard;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ShimmerScope(child: ShimmerBlock(height: 56));
    }

    final current = status;
    final effectiveStatus = current?.status ?? ConnectStatus.onboardingRequired;
    final onboarding = effectiveStatus == ConnectStatus.onboardingRequired;
    final copy = switch (effectiveStatus) {
      ConnectStatus.onboardingRequired =>
        'Cadastre seus dados de recebimento para receber suas vendas.',
      ConnectStatus.requirementsDue =>
        'Há informações pendentes para liberar o recebimento das vendas.',
      ConnectStatus.restricted =>
        'O Stripe restringiu seus recebimentos. Abra o painel para corrigir o cadastro.',
      ConnectStatus.transferReady =>
        'Recebimentos habilitados. O saldo permanece na carteira até a transferência.',
    };
    final action = onboarding ? onStartOnboarding : onOpenDashboard;
    final label = onboarding
        ? 'CONFIGURAR RECEBIMENTOS'
        : effectiveStatus == ConnectStatus.transferReady
        ? 'ABRIR PAINEL DE PAGAMENTOS'
        : 'CORRIGIR CADASTRO NO STRIPE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy,
          style: TextStyle(fontSize: 13, color: context.textSecondary),
        ),
        if (current?.requirementsDue.isNotEmpty ?? false) ...[
          Spacing.vSm,
          Text(
            'PENDÊNCIAS: ${current!.requirementsDue.join(', ')}',
            style: TextStyle(fontSize: 12, color: context.textSecondary),
          ),
        ],
        Spacing.vSm,
        AppButton(label: label, onPressed: action),
      ],
    );
  }
}
