import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/features/orders/presentation/widgets/order_status_timeline.dart';
import 'package:freebay/features/orders/presentation/widgets/escrow_status_card.dart';
import 'package:freebay/features/orders/presentation/widgets/order_actions.dart';
import 'package:freebay/shared/services/http_client.dart';

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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Pedido #${widget.orderId.length > 8 ? widget.orderId.substring(0, 8) : widget.orderId}',
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: _buildBody(state, currentUserId),
    );
  }

  Widget _buildBody(OrderDetailState state, String? currentUserId) {
    if (state.isLoading && state.order == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryContainer),
      );
    }

    if (state.error != null && state.order == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outlined,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildRetryButton(),
          ],
        ),
      );
    }

    final order = state.order;
    if (order == null) {
      return const Center(
        child: Text(
          'Pedido não encontrado',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }

    final isBuyer = currentUserId == order.buyerId;

    return RefreshIndicator(
      color: AppColors.primaryContainer,
      onRefresh: () async {
        await ref.read(orderDetailProvider(widget.orderId).notifier).loadOrder();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            OrderStatusTimeline(currentStatus: order.status),
            const SizedBox(height: 2),
            _buildProductSection(order),
            const SizedBox(height: 2),
            _buildParticipantSection(order, isBuyer),
            const SizedBox(height: 2),
            EscrowStatusCard(
              escrowStatus: order.escrowStatus,
              amount: order.amount,
              platformFee: order.platformFee,
              sellerAmount: order.sellerAmount,
              isBuyer: isBuyer,
            ),
            const SizedBox(height: 2),
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
            const SizedBox(height: 2),
            _buildOrderInfo(order),
            const SizedBox(height: 48),
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
                  fontFamily: 'Inter',
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
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRODUTO',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                color: AppColors.surfaceContainerHighest,
                child: product?.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product!.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.image_outlined,
                          color: AppColors.onSurfaceVariant,
                        ),
                      )
                    : const Icon(
                        Icons.image_outlined,
                        color: AppColors.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product?.title ?? 'Produto',
                      style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: AppColors.surfaceContainerHighest,
                      child: Text(
                        order.formattedAmount,
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
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
      color: AppColors.surfaceContainer,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              UserAvatar(
                imageUrl: participant?.avatarUrl,
                isVerified: participant?.isVerified ?? false,
                size: AppAvatarSize.medium,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant?.displayNameOrDefault ?? 'Usuário',
                      style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (participant?.isVerified == true) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            color: AppColors.primaryContainer,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Verificado',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
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
                    child: const Icon(
                      Icons.chevron_right,
                      color: AppColors.onSurfaceVariant,
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
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INFORMAÇÕES',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
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
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
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
            backgroundColor: success ? AppColors.success : AppColors.error,
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
      backgroundColor: AppColors.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
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
                        fontFamily: 'Inter',
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
                  color: AppColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Center(
                    child: Text(
                      cancelLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
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
