import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/stat_column.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';

class ProfileStatsRow extends ConsumerWidget {
  const ProfileStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(profileStatsProvider);

    return statsAsync.when(
      data: (stats) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StatColumn(label: 'Reputação', value: '${stats.followersCount} ★', usePrimaryColor: true),
          StatColumn(label: 'Vendas', value: '${stats.salesCount}', usePrimaryColor: true),
          StatColumn(label: 'Compras', value: '${stats.purchasesCount}', usePrimaryColor: true),
        ],
      ),
      loading: () => const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
      error: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StatColumn(label: 'Reputação', value: '0 ★', usePrimaryColor: true),
          StatColumn(label: 'Vendas', value: '0', usePrimaryColor: true),
          StatColumn(label: 'Compras', value: '0', usePrimaryColor: true),
        ],
      ),
    );
  }
}

class ProfileFollowRow extends ConsumerWidget {
  const ProfileFollowRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(profileStatsProvider);

    return statsAsync.when(
      data: (stats) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StatColumn(
            value: '${stats.followersCount}',
            label: 'seguidores',
            onTap: () => context.push('/profile/followers'),
          ),
          const SizedBox(width: 32),
          StatColumn(
            value: '${stats.followingCount}',
            label: 'seguindo',
            onTap: () => context.push('/profile/following'),
          ),
        ],
      ),
      loading: () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StatColumn(value: '...', label: 'seguidores', onTap: () {}),
          const SizedBox(width: 32),
          StatColumn(value: '...', label: 'seguindo', onTap: () {}),
        ],
      ),
      error: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StatColumn(value: '0', label: 'seguidores', onTap: () {}),
          const SizedBox(width: 32),
          StatColumn(value: '0', label: 'seguindo', onTap: () {}),
        ],
      ),
    );
  }
}
