import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/features/orders/presentation/widgets/order_status_timeline.dart';
import 'package:freebay/features/orders/presentation/widgets/escrow_status_card.dart';
import 'package:freebay/features/orders/presentation/widgets/order_actions.dart';
import 'package:freebay/features/orders/presentation/widgets/brutalist_confirm_dialog.dart';
import 'package:freebay/core/router/app_routes.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderDetailProvider(widget.orderId).notifier).loadOrder();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderDetailProvider(widget.orderId));
    final currentUserId = ref.watch(authControllerProvider).value?.id;
    final shortId = widget.orderId.length > 8
        ? widget.orderId.substring(0, 8)
        : widget.orderId;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: 'PEDIDO #$shortId',
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(child: _buildContent(state, currentUserId)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(OrderDetailState state, String? currentUserId) {
    if (state.isLoading && state.order == null) {
      return const SkeletonPage(
        child: Column(
          children: [
            SizedBox(height: 16),
            ShimmerBlock(height: 100),
            SizedBox(height: 12),
            ShimmerBlock(height: 100),
            SizedBox(height: 12),
            ShimmerBlock(height: 100),
          ],
        ),
      );
    }
    final order = state.order;
    if (order == null) {
      return EmptyState.error(
        message: state.error ?? 'Pedido não encontrado',
        onRetry: () =>
            ref.read(orderDetailProvider(widget.orderId).notifier).loadOrder(),
      );
    }

    final isBuyer = currentUserId == order.buyerId;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(orderDetailProvider(widget.orderId).notifier).loadOrder(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            OrderStatusTimeline(currentStatus: order.status),
            Spacing.vXs,
            _buildProductCard(order),
            Spacing.vXs,
            _buildParticipantCard(order, isBuyer),
            Spacing.vXs,
            EscrowStatusCard(
              escrowStatus: order.escrowStatus,
              amount: order.amount,
              platformFee: order.platformFee,
              sellerAmount: order.sellerAmount,
              isBuyer: isBuyer,
            ),
            Spacing.vXs,
            OrderActions(
              order: order,
              canReview: state.canReview,
              reviewType: state.canReviewResponse?.reviewType,
              isBuyer: isBuyer,
              isLoading: state.isPerformingAction,
              onConfirmDelivery: _handleConfirmDelivery,
              onReview: () => _handleReview(
                order,
                state.canReviewResponse?.reviewType,
                isBuyer,
              ),
              onChat: () => _handleChat(order, isBuyer),
              onDispute: () => _handleDispute(order),
              onCancel: _handleCancel,
            ),
            Spacing.vXs,
            _buildInfoCard(order),
            Spacing.vXxl,
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(OrderEntity order) {
    final product = order.product;
    return Container(
      color: context.surfaceColor,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            color: context.surfaceMidColor,
            child: product?.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: product!.imageUrl!,
                    fit: BoxFit.cover,
                  )
                : Icon(Icons.image_outlined, color: context.textSecondary),
          ),
          Spacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.title ?? 'Produto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.vSm,
                Text(
                  order.formattedAmount,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(OrderEntity order, bool isBuyer) {
    final participant = isBuyer ? order.seller : order.buyer;
    final label = isBuyer ? 'VENDEDOR' : 'COMPRADOR';

    return Container(
      color: context.surfaceMidColor,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          UserAvatar(imageUrl: participant?.avatarUrl),
          Spacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
                  ),
                ),
                Text(
                  participant?.displayNameOrDefault ?? 'Usuário',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (participant != null)
            IconButton(
              icon: Icon(Icons.chevron_right, color: context.textSecondary),
              onPressed: () => context.push(AppRoutes.userPath(participant.id)),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(OrderEntity order) {
    return Container(
      color: context.surfaceColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFORMAÇÕES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.textSecondary,
            ),
          ),
          Spacing.vMd,
          _row('ID do pedido', order.id),
          const SizedBox(height: 8),
          _row(
            'Data do pedido',
            '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(k, style: TextStyle(fontSize: 13, color: context.textSecondary)),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          v,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
        ),
      ),
    ],
  );

  Future<void> _handleConfirmDelivery() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const BrutalistConfirmDialog(
        title: 'Confirmar Recebimento',
        message:
            'Ao confirmar o recebimento, o pagamento será liberado para o vendedor.',
        confirmLabel: 'Confirmar',
        cancelLabel: 'Cancelar',
      ),
    );
    if (ok == true) {
      await ref
          .read(orderDetailProvider(widget.orderId).notifier)
          .confirmDelivery();
    }
  }

  void _handleReview(OrderEntity order, String? reviewType, bool isBuyer) {
    if (reviewType == null) return;
    final user = isBuyer ? order.seller : order.buyer;
    context.push(
      AppRoutes.createReview,
      extra: {
        'orderId': widget.orderId,
        'reviewedId': isBuyer ? order.sellerId : order.buyerId,
        'reviewedName': user?.displayNameOrDefault ?? 'Usuário',
        'reviewedAvatarUrl': user?.avatarUrl,
        'reviewType': reviewType,
      },
    );
  }

  Future<void> _handleChat(OrderEntity order, bool isBuyer) async {
    final targetId = isBuyer ? order.sellerId : order.buyerId;
    final result = await ref
        .read(chatRepositoryProvider)
        .startDirectConversation(targetId);
    if (!mounted) return;
    result.fold(
      (failure) => AppSnackbar.error(context, failure.message),
      (conversationId) => context.push(AppRoutes.chatPath(conversationId)),
    );
  }

  void _handleDispute(OrderEntity order) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Disputa em breve')));
  }

  static const _cancelReasons = [
    'Mudei de ideia',
    'Encontrei um preço melhor',
    'Produto incorreto',
    'Demora na confirmação',
    'Problemas com o vendedor',
    'Outro motivo',
  ];

  Future<void> _handleCancel() async {
    String? selectedReason;

    selectedReason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.surfaceColor,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CANCELAR PEDIDO',
                style: TextStyle(
                  fontFamily: AppTypography.headlineFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(ctx).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecione o motivo do cancelamento:',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  color: AppColors.mediumGray,
                ),
              ),
              const SizedBox(height: 16),
              ..._cancelReasons.map(
                (reason) => InkWell(
                  onTap: () => Navigator.of(ctx).pop(reason),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    margin: const EdgeInsets.only(bottom: 4),
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? Colors.white.withAlpha(10)
                        : Colors.black.withAlpha(10),
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 15,
                        color: Theme.of(ctx).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Voltar',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(ctx).pop(),
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedReason == null || !mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => BrutalistConfirmDialog(
        title: 'Confirmar Cancelamento',
        message:
            'Tem certeza que deseja cancelar este pedido?\n\nMotivo: $selectedReason\n\nO valor será reembolsado se já tiver sido pago.',
        confirmLabel: 'Cancelar Pedido',
        cancelLabel: 'Voltar',
        isDanger: true,
      ),
    );
    if (ok != true || !mounted) return;

    final outcome = await ref
        .read(orderDetailProvider(widget.orderId).notifier)
        .cancelOrder(selectedReason);

    if (!mounted) return;
    if (outcome != null) {
      if (outcome == 'REFUND_PENDING') {
        AppSnackbar.info(
          context,
          'Reembolso solicitado. Aguarde a confirmação do pagamento.',
        );
      } else {
        AppSnackbar.success(context, 'Pedido cancelado com sucesso');
      }
      await ref.read(orderDetailProvider(widget.orderId).notifier).loadOrder();
    } else {
      final error = ref.read(orderDetailProvider(widget.orderId)).error;
      AppSnackbar.error(context, error ?? 'Erro ao cancelar pedido');
    }
  }
}
