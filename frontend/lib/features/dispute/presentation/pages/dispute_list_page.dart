import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/features/dispute/presentation/providers/dispute_providers.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/brutalist_box.dart';
import 'package:freebay/core/components/brutalist_breadcrumb.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/components/spacing.dart';

class DisputeListPage extends ConsumerStatefulWidget {
  const DisputeListPage({super.key});

  @override
  ConsumerState<DisputeListPage> createState() => _DisputeListPageState();
}

class _DisputeListPageState extends ConsumerState<DisputeListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(disputeListProvider.notifier).loadDisputes());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(disputeListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Disputas')),
      body: Column(
        children: [
          BrutalistBreadcrumb(items: [
            BreadcrumbItem(label: 'Perfil', onTap: () => context.pop()),
            const BreadcrumbItem(label: 'Minhas Disputas'),
          ]),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(DisputeListState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error!, style: TextStyle(color: AppColors.error)),
            Spacing.vMd,
            Container(
              color: AppColors.primaryContainer,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => ref.read(disputeListProvider.notifier).loadDisputes(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Text('Tentar novamente', style: AppTypography.button),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.disputes.isEmpty) {
      return const EmptyState(
        icon: Icons.verified_user_outlined,
        title: 'Nenhuma disputa',
        subtitle: 'Você ainda não abriu nenhuma disputa',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(disputeListProvider.notifier).loadDisputes(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.disputes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final dispute = state.disputes[index];
          return BrutalistBox(
            child: ListTile(
              title: Text('Disputa #${dispute.id.split('-').first}', style: AppTypography.bodyMedium),
              subtitle: Text(
                dispute.status,
                style: AppTypography.bodySmall.copyWith(
                  color: dispute.isOpen ? AppColors.warning : dispute.isResolved ? AppColors.success : AppColors.onSurfaceVariant,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/disputes/${dispute.id}'),
            ),
          );
        },
      ),
    );
  }
}
