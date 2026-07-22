import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_refresh_indicator.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/components/brutalist_bottom_sheet.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/components/wallet_card.dart';
import 'package:freebay/core/components/section_title.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/wallet/data/entities/wallet_transaction_entity.dart';
import 'package:freebay/features/wallet/data/entities/withdrawal_entity.dart';
import 'package:freebay/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/app_snackbar.dart';

const _minWithdrawalCents = 2000;

String _formatCents(int cents) {
  return (cents / 100).toStringAsFixed(2).replaceAll('.', ',');
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}

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
      final authState = ref.read(authControllerProvider);
      final user = authState.valueOrNull;
      if (user != null && !user.isGuest) {
        ref.read(walletProvider.notifier).loadWallet();
        ref.read(walletHistoryProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = context.isDark;
    final authState = ref.watch(authControllerProvider);
    final walletState = ref.watch(walletProvider);
    final historyState = ref.watch(walletHistoryProvider);
    final user = authState.valueOrNull;
    final isGuest = user == null || user.isGuest;

    final availableBalance = walletState.valueOrNull?.availableBalance ?? 0;
    final pendingBalance = walletState.valueOrNull?.pendingBalance ?? 0;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'CARTEIRA',
            actions: [
              IconButton(
                icon: Icon(
                  Icons.help_outline,
                  color: isDark ? AppColors.white : AppColors.darkGray,
                ),
                onPressed: () => context.push('/faq'),
              ),
            ],
          ),
          Expanded(
            child: walletState.isLoading && !isGuest
                ? const WalletSkeleton()
                : walletState.hasError && !isGuest
                ? _buildBalanceError(isDark)
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
                          _WithdrawAction(availableBalance: availableBalance),
                          Spacing.vLg,
                          SectionTitle.compact(
                            text: 'Visão da carteira',
                            isDark: isDark,
                          ),
                          Container(
                            width: double.infinity,
                            color: isDark
                                ? AppColors.surfaceContainerDark
                                : AppColors.surfaceContainerLow,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoLine(
                                  label: 'Disponível',
                                  value: 'Saldo já liberado para saque.',
                                ),
                                Spacing.vMd,
                                _buildInfoLine(
                                  label: 'Em custódia',
                                  value:
                                      'Valor aguardando confirmação do pedido.',
                                ),
                                Spacing.vMd,
                                _buildInfoLine(
                                  label: 'Saques',
                                  value:
                                      'Saque via PIX a partir de R\$ ${_formatCents(_minWithdrawalCents)}.',
                                ),
                              ],
                            ),
                          ),
                          Spacing.vLg,
                          _buildSectionLabel('Histórico', isDark),
                          const SizedBox(height: 12),
                          if (historyState.isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: ShimmerBlock(height: 60),
                            )
                          else if (historyState.transactions.isEmpty)
                            const EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'SEM TRANSAÇÕES',
                              subtitle:
                                  'Realize uma compra ou venda para visualizar suas transações aqui.',
                            )
                          else
                            _TransactionList(
                              transactions: historyState.transactions,
                            ),
                          if (historyState.withdrawals.isNotEmpty) ...[
                            Spacing.vLg,
                            _buildSectionLabel('Saques', isDark),
                            const SizedBox(height: 12),
                            _WithdrawalList(
                              withdrawals: historyState.withdrawals,
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

  Widget _buildBalanceError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: AppColors.error,
            ),
            Spacing.vMd,
            Text(
              'Não foi possível carregar o saldo.',
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.white : AppColors.darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTypography.headlineFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.white : AppColors.darkGray,
      ),
    );
  }

  Widget _buildInfoLine({required String label, required String value}) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.onPrimaryContainer : AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            color: AppColors.mediumGray,
          ),
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<WalletTransactionEntity> transactions;

  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      children: [
        for (var i = 0; i < transactions.length; i++)
          Container(
            color: i.isEven
                ? (isDark
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerLow)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: _TransactionRow(transaction: transactions[i]),
          ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final WalletTransactionEntity transaction;

  const _TransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final signColor = isCredit ? AppColors.success : AppColors.error;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          color: signColor.withValues(alpha: 0.12),
          child: Icon(
            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            size: 18,
            color: signColor,
          ),
        ),
        Spacing.hMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              Text(
                _formatDate(transaction.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mediumGray,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${isCredit ? '+' : '-'} R\$ ${_formatCents(transaction.amount.abs())}',
          style: TextStyle(
            fontFamily: AppTypography.headlineFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: signColor,
          ),
        ),
      ],
    );
  }
}

class _WithdrawalList extends StatelessWidget {
  final List<WithdrawalEntity> withdrawals;

  const _WithdrawalList({required this.withdrawals});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      children: [
        for (var i = 0; i < withdrawals.length; i++)
          Container(
            color: i.isEven
                ? (isDark
                      ? AppColors.surfaceContainerDark
                      : AppColors.surfaceContainerLow)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saque PIX',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        '${_formatDate(withdrawals[i].createdAt)} · ${withdrawals[i].statusLabel}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'R\$ ${_formatCents(withdrawals[i].amount)}',
                  style: TextStyle(
                    fontFamily: AppTypography.headlineFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WithdrawAction extends ConsumerStatefulWidget {
  final int availableBalance;

  const _WithdrawAction({required this.availableBalance});

  @override
  ConsumerState<_WithdrawAction> createState() => _WithdrawActionState();
}

class _WithdrawActionState extends ConsumerState<_WithdrawAction> {
  final _amountController = TextEditingController();
  final _pixKeyController = TextEditingController();
  String _pixKeyType = 'CPF';
  bool _isSending = false;
  String? _idempotencyKey;

  bool get _canWithdraw => widget.availableBalance >= _minWithdrawalCents;

  @override
  void dispose() {
    _amountController.dispose();
    _pixKeyController.dispose();
    super.dispose();
  }

  String _newIdempotencyKey() {
    final random = Random().nextInt(0x7fffffff);
    return '${DateTime.now().microsecondsSinceEpoch}-$random';
  }

  int? _parseAmountCents(String raw) {
    final normalized = raw.trim().replaceAll('.', '').replaceAll(',', '.');
    final reais = double.tryParse(normalized);
    if (reais == null) return null;
    return (reais * 100).round();
  }

  void _showWithdrawSheet() {
    _idempotencyKey = _newIdempotencyKey();
    showBrutalistSheet(
      context: context,
      title: 'SOLICITAR SAQUE',
      builder: (sheetContext) => StatefulBuilder(
        builder: (builderContext, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Disponível: R\$ ${_formatCents(widget.availableBalance)}',
              style: const TextStyle(fontSize: 13, color: AppColors.mediumGray),
            ),
            Spacing.vMd,
            AppTextField(
              label: 'Valor (R\$)',
              hint: '0,00',
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
            ),
            Spacing.vSm,
            _PixKeyTypeSelector(
              selected: _pixKeyType,
              onChanged: (value) => setSheetState(() => _pixKeyType = value),
            ),
            Spacing.vSm,
            AppTextField(label: 'Chave PIX', controller: _pixKeyController),
            Spacing.vLg,
            AppButton(
              label: 'CONFIRMAR SAQUE',
              width: double.infinity,
              isLoading: _isSending,
              onPressed: () => _submit(sheetContext, setSheetState),
            ),
            Spacing.vMd,
          ],
        ),
      ),
    );
  }

  Future<void> _submit(
    BuildContext sheetContext,
    StateSetter setSheetState,
  ) async {
    final amountCents = _parseAmountCents(_amountController.text);
    final pixKey = _pixKeyController.text.trim();

    if (amountCents == null || pixKey.isEmpty) {
      AppSnackbar.error(context, 'Preencha todos os campos');
      return;
    }
    if (amountCents < _minWithdrawalCents) {
      AppSnackbar.error(
        context,
        'Valor mínimo de saque: R\$ ${_formatCents(_minWithdrawalCents)}',
      );
      return;
    }
    if (amountCents > widget.availableBalance) {
      AppSnackbar.error(context, 'Saldo insuficiente');
      return;
    }

    setSheetState(() => _isSending = true);
    final result = await ref
        .read(walletRepositoryProvider)
        .withdraw(
          amountCents: amountCents,
          pixKey: pixKey,
          pixKeyType: _pixKeyType,
          idempotencyKey: _idempotencyKey ?? _newIdempotencyKey(),
        );
    if (!mounted) return;
    setSheetState(() => _isSending = false);

    result.fold((failure) => AppSnackbar.error(context, failure.message), (_) {
      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
      AppSnackbar.success(context, 'Saque solicitado com sucesso!');
      _amountController.clear();
      _pixKeyController.clear();
      _idempotencyKey = null;
      ref.read(walletProvider.notifier).loadWallet();
      ref.read(walletHistoryProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'SACAR',
      icon: Icons.account_balance_outlined,
      variant: AppButtonVariant.secondary,
      width: double.infinity,
      onPressed: _canWithdraw ? _showWithdrawSheet : null,
    );
  }
}

class _PixKeyTypeSelector extends StatelessWidget {
  static const _types = {
    'CPF': 'CPF',
    'EMAIL': 'E-mail',
    'PHONE': 'Telefone',
    'RANDOM': 'Aleatória',
  };

  final String selected;
  final ValueChanged<String> onChanged;

  const _PixKeyTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TIPO DE CHAVE PIX',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _types.entries.map((entry) {
            final isSelected = entry.key == selected;
            return Expanded(
              child: Material(
                color: isSelected
                    ? AppColors.primaryContainer
                    : (isDark
                          ? AppColors.surfaceContainerDark
                          : AppColors.surfaceContainerLow),
                child: InkWell(
                  onTap: () => onChanged(entry.key),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.onPrimary
                              : context.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
