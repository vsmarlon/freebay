import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/features/orders/presentation/widgets/order_status_timeline.dart';
import 'package:freebay/features/orders/presentation/widgets/escrow_status_card.dart';
import 'package:freebay/features/orders/presentation/widgets/order_actions.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/page_header.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailPage({
    super.key,
    required this.orderId,
  });

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
    final authState = ref.watch(authControllerProvider);
    final currentUserId = authState.valueOrNull?.id;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'PEDIDO #${widget.orderId.length > 8 ? widget.orderId.substring(0, 8) : widget.orderId}',
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor, width: 2),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: context.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildBody(state, currentUserId),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(OrderDetailState state, String? currentUserId) {
    if (state.isLoading && state.order == null) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.primaryContainer),
      );
    }

    if (state.error != null && state.order == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outlined,
              color: context.colors.error,
              size: 48,
            ),
            Spacing.vMd,
            Text(
              state.error!,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            Spacing.vLg,
            _buildRetryButton(),
          ],
        ),
      );
    }

    final order = state.order;
    if (order == null) {
      return Center(
        child: Text(
          'Pedido não encontrado',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            color: context.textSecondary,
          ),
        ),
      );
    }

    final isBuyer = currentUserId == order.buyerId;

    return RefreshIndicator(
      color: context.colors.primaryContainer,
      onRefresh: () async {
        await ref.read(orderDetailProvider(widget.orderId).notifier).loadOrder();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            OrderStatusTimeline(currentStatus: order.status),
            Spacing.vXs,
            _buildProductSection(order),
            Spacing.vXs,
            _buildParticipantSection(order, isBuyer),
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
              onConfirmDelivery: () => _handleConfirmDelivery(),
              onReview: () => _handleReview(
                order,
                state.canReviewResponse?.reviewType,
                isBuyer,
              ),
              onChat: () => _handleChat(order, isBuyer),
              onDispute: () => _handleDispute(order),
              onCancel: () => _handleCancel(),
            ),
            Spacing.vXs,
            _buildOrderInfo(order),
            Spacing.vXxl,
          ],
        ),
      ),
    );
  }

  Widget _buildRetryButton() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        gradient: AppColors.brutalistGradient,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(orderDetailProvider(widget.orderId).notifier).loadOrder();
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: Text(
                'Tentar novamente',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductSection(OrderEntity order) {
    final product = order.product;

    return Container(
      color: context.surfaceColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRODUTO',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: context.textSecondary,
            ),
          ),
          Spacing.vMd,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                color: context.surfaceMidColor,
                child: product?.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product!.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colors.primaryContainer,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.image_outlined,
                          color: context.textSecondary,
                        ),
                      )
                    : Icon(
                        Icons.image_outlined,
                        color: context.textSecondary,
                      ),
              ),
              Spacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product?.title ?? 'Produto',
                      style: TextStyle(
                        fontFamily: AppTypography.headlineFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacing.vSm,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: context.surfaceMidColor,
                      child: Text(
                        order.formattedAmount,
                        style: TextStyle(
                          fontFamily: AppTypography.headlineFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantSection(OrderEntity order, bool isBuyer) {
    final participant = isBuyer ? order.seller : order.buyer;
    final label = isBuyer ? 'VENDEDOR' : 'COMPRADOR';

    return Container(
      color: context.surfaceMidColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: context.textSecondary,
            ),
          ),
          Spacing.vMd,
          Row(
            children: [
              UserAvatar(
                imageUrl: participant?.avatarUrl,
                isVerified: participant?.isVerified ?? false,
                size: AppAvatarSize.medium,
              ),
              Spacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant?.displayNameOrDefault ?? 'Usuário',
                      style: TextStyle(
                        fontFamily: AppTypography.headlineFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    if (participant?.isVerified == true) ...[
                      Spacing.vXs,
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            color: context.colors.primaryContainer,
                            size: 14,
                          ),
                          Spacing.hXs,
                          Text(
                            'Verificado',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (participant != null) {
                      context.push('/user/${participant.id}');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.chevron_right,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(OrderEntity order) {
    return Container(
      color: context.surfaceColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFORMAÇÕES',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: context.textSecondary,
            ),
          ),
          Spacing.vMd,
          _buildInfoRow('ID do pedido', order.id),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Data do pedido',
            _formatDate(order.createdAt),
          ),
          if (order.deliveryConfirmedAt != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Entrega confirmada',
              _formatDate(order.deliveryConfirmedAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              color: context.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year às $hour:$minute';
  }

  Future<void> _handleConfirmDelivery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _BrutalistDialog(
        title: 'Confirmar Recebimento',
        message:
            'Ao confirmar o recebimento, o pagamento será liberado para o vendedor. Deseja continuar?',
        confirmLabel: 'Confirmar',
        cancelLabel: 'Cancelar',
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(orderDetailProvider(widget.orderId).notifier)
          .confirmDelivery();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Recebimento confirmado com sucesso!'
                  : 'Erro ao confirmar recebimento',
            ),
            backgroundColor:
                success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  void _handleReview(OrderEntity order, String? reviewType, bool isBuyer) {
    if (reviewType == null) return;

    final reviewedUser = isBuyer ? order.seller : order.buyer;

    context.push(
      '/reviews/create',
      extra: {
        'orderId': widget.orderId,
        'reviewedId': isBuyer ? order.sellerId : order.buyerId,
        'reviewedName': reviewedUser?.displayNameOrDefault ?? 'Usuário',
        'reviewedAvatarUrl': reviewedUser?.avatarUrl,
        'reviewType': reviewType,
      },
    );
  }

  Future<void> _handleChat(OrderEntity order, bool isBuyer) async {
    final otherUserId = isBuyer ? order.sellerId : order.buyerId;
    final otherUser = isBuyer ? order.seller : order.buyer;

    try {
      final response = await HttpClient.instance.post(
        '/chat/conversations',
        data: {'targetUserId': otherUserId},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final conversationId = data['conversationId'] as String;

      if (!mounted) {
        return;
      }

      context.push(
        '/chat/$conversationId',
        extra: {
          'oderName': otherUser?.displayNameOrDefault ?? 'Chat',
          'oderAvatarUrl': otherUser?.avatarUrl,
          'chatType': 'direct',
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a conversa'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleDispute(OrderEntity order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abertura de disputa pela interface chega no próximo ajuste.'),
        backgroundColor: AppColors.onSurface,
      ),
    );
  }

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _BrutalistDialog(
        title: 'Cancelar Pedido',
        message:
            'Tem certeza que deseja cancelar este pedido? O valor será reembolsado.',
        confirmLabel: 'Cancelar Pedido',
        cancelLabel: 'Voltar',
        isDanger: true,
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(orderDetailProvider(widget.orderId).notifier)
          .cancelOrder();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Pedido cancelado com sucesso!'
                  : 'Erro ao cancelar pedido',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }
}

class _BrutalistDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;

  const _BrutalistDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: context.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            Spacing.vMd,
            Text(
              message,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                color: context.textSecondary,
                height: 1.5,
              ),
            ),
            Spacing.vLg,
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: isDanger ? null : AppColors.brutalistGradient,
                color: isDanger ? AppColors.error : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Center(
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.borderColor.withValues(alpha: 0.3),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Center(
                    child: Text(
                      cancelLabel,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
