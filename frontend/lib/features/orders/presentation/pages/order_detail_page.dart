import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/auth.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/features/orders/presentation/widgets/order_status_timeline.dart';
import 'package:freebay/features/orders/presentation/widgets/escrow_status_card.dart';
import 'package:freebay/features/orders/presentation/widgets/order_actions.dart';
import 'package:freebay/features/orders/presentation/widgets/order_cancellation_sheet.dart';
import 'package:freebay/features/orders/presentation/widgets/brutalist_confirm_dialog.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  bool _isCancelPending = false;
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
              text: l10n(context).ordersNumber(shortId),
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: l10n(context).accessibilityBack,
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
        message: l10n(context).ordersNotFound,
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
                  participant?.displayNameOrDefault ??
                      l10n(context).commonUnknownUser,
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
            l10n(context).ordersInformation.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.textSecondary,
            ),
          ),
          Spacing.vMd,
          _row(l10n(context).ordersOrderId, order.id),
          const SizedBox(height: 8),
          _row(
            l10n(context).ordersOrderDate,
            localizedShortDate(context, order.createdAt),
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
      builder: (_) => BrutalistConfirmDialog(
        title: l10n(context).ordersConfirmReceipt,
        message: l10n(context).ordersConfirmReceiptBody,
        confirmLabel: l10n(context).commonConfirm,
        cancelLabel: l10n(context).commonCancel,
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
        'reviewedName':
            user?.displayNameOrDefault ?? l10n(context).commonUnknownUser,
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
      (failure) => AppSnackbar.handleFailure(context, failure),
      (conversationId) => context.push(AppRoutes.chatPath(conversationId)),
    );
  }

  Future<void> _handleDispute(OrderEntity order) async {
    await context.push(AppRoutes.createDisputePath(order.id));
    if (mounted) {
      await ref.read(orderDetailProvider(widget.orderId).notifier).loadOrder();
    }
  }

  Future<void> _handleCancel() async {
    await showBrutalistSheet<void>(
      context: context,
      title: l10n(context).ordersCancel.toUpperCase(),
      scrollable: false,
      builder: (_) => OrderCancellationSheet(onConfirm: _cancelOrder),
    );
  }

  Future<bool> _cancelOrder(String reason) async {
    if (_isCancelPending) return false;
    _isCancelPending = true;
    try {
      final stepUpToken = await StepUpAuthenticator.authorize(
        context,
        ref,
        purpose: 'cancel_order',
        resourceId: widget.orderId,
      );
      if (stepUpToken == null || !mounted) return false;
      final outcome = await ref
          .read(orderDetailProvider(widget.orderId).notifier)
          .cancelOrder(reason, stepUpToken);
      if (!mounted) return false;
      if (outcome != null) {
        if (outcome == 'REFUND_PENDING') {
          AppSnackbar.info(context, l10n(context).ordersRefundPending);
        } else {
          AppSnackbar.success(context, l10n(context).ordersCancelledSuccess);
        }
        await ref
            .read(orderDetailProvider(widget.orderId).notifier)
            .loadOrder();
        return true;
      }
      final error = ref.read(orderDetailProvider(widget.orderId)).error;
      AppSnackbar.error(context, error ?? l10n(context).errorUnknown);
      return false;
    } catch (_) {
      if (mounted) AppSnackbar.error(context, l10n(context).errorUnknown);
      return false;
    } finally {
      _isCancelPending = false;
    }
  }
}
