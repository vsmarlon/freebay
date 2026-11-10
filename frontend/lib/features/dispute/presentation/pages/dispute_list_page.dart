import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/features/dispute/presentation/providers/dispute_providers.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/core/router/app_routes.dart';

class DisputeListPage extends ConsumerStatefulWidget {
  const DisputeListPage({super.key});

  @override
  ConsumerState<DisputeListPage> createState() => _DisputeListPageState();
}

class _DisputeListPageState extends ConsumerState<DisputeListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(disputeListProvider.notifier).loadDisputes(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final state = ref.watch(disputeListProvider);

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            text: strings.disputesMyTitle,
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              semanticLabel: strings.accessibilityBack,
              onTap: () => context.pop(),
            ),
          ),
          BrutalistBreadcrumb(items: context.breadcrumbs),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(DisputeListState state) {
    final strings = l10n(context);
    if (state.isLoading) {
      return SkeletonPage(
        child: SkeletonList(
          itemCount: 5,
          itemBuilder: (_, i) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                ShimmerBlock(width: 40, height: 40),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBlock(height: 16, width: 140),
                    SizedBox(height: 6),
                    ShimmerBlock(height: 14, width: 100),
                  ],
                ),
                Spacer(),
                ShimmerBlock(height: 14, width: 60),
              ],
            ),
          ),
        ),
      );
    }

    if (state.error != null) {
      return EmptyState.error(
        message: state.error,
        onRetry: () => ref.read(disputeListProvider.notifier).loadDisputes(),
      );
    }

    if (state.disputes.isEmpty) {
      return EmptyState(
        icon: Icons.verified_user_outlined,
        title: strings.ordersNoDisputes,
        subtitle: strings.ordersNoDisputesBody,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(disputeListProvider.notifier).loadDisputes(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.disputes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final dispute = state.disputes[index];
          return BrutalistBox(
            child: ListTile(
              title: Text(
                'Disputa #${dispute.id.split('-').first}',
                style: AppTypography.bodyMedium,
              ),
              subtitle: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  color: dispute.isOpen
                      ? AppColors.warning
                      : dispute.isResolved
                      ? AppColors.success
                      : context.textSecondary,
                  child: Text(
                    dispute.status.label,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.disputePath(dispute.id)),
            ),
          );
        },
      ),
    );
  }
}
