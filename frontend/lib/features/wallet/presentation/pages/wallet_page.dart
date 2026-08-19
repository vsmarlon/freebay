import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_refresh_indicator.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/components/brutalist_bottom_sheet.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/components/guest_gate_view.dart';
import 'package:freebay/core/components/wallet_card.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/features/wallet/domain/wallet_constants.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final user = ref.read(authControllerProvider).value;
      if (user != null && !user.isGuest) {
        ref.read(walletProvider.notifier).loadWallet();
        ref.read(walletHistoryProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = ref.watch(authControllerProvider).value;
    final isGuest = user == null || user.isGuest;
    final walletState = ref.watch(walletProvider);
    final historyState = ref.watch(walletHistoryProvider);

    if (isGuest) {
      return Scaffold(
        body: GuestGateView(
          icon: Icons.account_balance_wallet_outlined,
          title: 'CARTEIRA & CUSTÓDIA',
          description:
              'Gerencie seu saldo, realize saques instantâneos via PIX e negocie com garantia de custódia protegida.',
          benefits: const [
            '0% de taxa sobre compras e vendas',
            'Saques rápidos via PIX',
            'Custódia segura até a entrega do produto',
          ],
          onLoginPressed: () => context.push('/login'),
          onRegisterPressed: () => context.push('/register'),
        ),
      );
    }

    final availableBalance = walletState.value?.availableBalance ?? 0;
    final pendingBalance = walletState.value?.pendingBalance ?? 0;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'CARTEIRA',
            actions: [
              IconButton(
                icon: Icon(Icons.help_outline, color: context.textPrimary),
                onPressed: () => context.push('/faq'),
              ),
            ],
          ),
          Expanded(
            child: walletState.isLoading
                ? const SkeletonPage(
                    child: Column(
                      children: [
                        SizedBox(height: 16),
                        ShimmerBlock(height: 120),
                        SizedBox(height: 12),
                        ShimmerBlock(height: 60),
                      ],
                    ),
                  )
                : AppRefreshIndicator(
                    onRefresh: () async {
                      ref.read(walletProvider.notifier).loadWallet();
                      await ref.read(walletHistoryProvider.notifier).load();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          WalletCard(
                            availableBalanceInCents: availableBalance,
                            pendingBalanceInCents: pendingBalance,
                          ),
                          Spacing.vMd,
                          AppButton(
                            label: 'SOLICITAR SAQUE VIA PIX',
                            onPressed:
                                availableBalance >=
                                    WalletConstants.minWithdrawalCents
                                ? () => _showWithdrawSheet(
                                    context,
                                    availableBalance,
                                  )
                                : null,
                          ),
                          Spacing.vLg,
                          Text(
                            'TRANSAÇÕES RECENTES',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.textSecondary,
                            ),
                          ),
                          Spacing.vSm,
                          if (historyState.transactions.isEmpty)
                            const EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'SEM TRANSAÇÕES',
                              subtitle: 'Suas transações aparecerão aqui.',
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: historyState.transactions.length,
                              separatorBuilder: (context, index) => Container(
                                height: 1,
                                color: context.borderColor.withAlpha(30),
                              ),
                              itemBuilder: (context, i) {
                                final tx = historyState.transactions[i];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    tx.isCredit
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: tx.isCredit
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                  title: Text(
                                    tx.label,
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}',
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Text(
                                    '${tx.isCredit ? '+' : '-'}${CurrencyUtils.formatCents(tx.amount)}',
                                    style: TextStyle(
                                      color: tx.isCredit
                                          ? AppColors.success
                                          : AppColors.error,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (historyState.withdrawals.isNotEmpty) ...[
                            Spacing.vLg,
                            Text(
                              'SAQUES',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: context.textSecondary,
                              ),
                            ),
                            Spacing.vSm,
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: historyState.withdrawals.length,
                              separatorBuilder: (context, index) => Container(
                                height: 1,
                                color: context.borderColor.withAlpha(30),
                              ),
                              itemBuilder: (context, i) {
                                final w = historyState.withdrawals[i];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    CurrencyUtils.formatCents(w.amount),
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${w.createdAt.day}/${w.createdAt.month}/${w.createdAt.year}',
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Text(
                                    w.status.name.toUpperCase(),
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context, int availableBalance) {
    final amountController = TextEditingController();
    final pixController = TextEditingController();
    String pixType = 'CPF';

    showBrutalistSheet(
      context: context,
      title: 'SOLICITAR SAQUE',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: amountController,
              label: 'Valor (R\$)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            Spacing.vSm,
            AppTextField(controller: pixController, label: 'Chave PIX'),
            Spacing.vMd,
            AppButton(
              label: 'CONFIRMAR SAQUE',
              onPressed: () async {
                final text = amountController.text.replaceAll(',', '.');
                final val = double.tryParse(text);
                if (val == null || val <= 0) {
                  AppSnackbar.error(context, 'Valor inválido.');
                  return;
                }
                final cents = (val * 100).toInt();
                if (cents > availableBalance) {
                  AppSnackbar.error(context, 'Saldo insuficiente.');
                  return;
                }
                Navigator.pop(ctx);
                final res = await ref
                    .read(walletRepositoryProvider)
                    .withdraw(
                      amountCents: cents,
                      pixKey: pixController.text.trim(),
                      pixKeyType: pixType,
                      idempotencyKey: DateTime.now().millisecondsSinceEpoch
                          .toString(),
                    );
                if (mounted) {
                  res.fold((f) => AppSnackbar.error(context, f.message), (_) {
                    AppSnackbar.success(
                      context,
                      'Saque solicitado com sucesso!',
                    );
                    ref.read(walletHistoryProvider.notifier).load();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
