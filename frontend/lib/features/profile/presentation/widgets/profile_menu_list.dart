import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/brutalist_box.dart';
import 'package:freebay/core/components/menu_list_tile.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

class ProfileMenuList extends ConsumerWidget {
  const ProfileMenuList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BrutalistBox(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          MenuListTile(icon: Icons.grid_view_rounded, label: 'Meus posts', onTap: () => context.push('/profile/posts')),
          MenuListTile(icon: Icons.auto_awesome, label: 'Meus stories', onTap: () => context.push('/profile/stories')),
          MenuListTile(icon: Icons.shopping_bag_outlined, label: 'Meus anúncios', onTap: () => context.push('/profile/products')),
          MenuListTile(icon: Icons.favorite_outline, label: 'Favoritos', onTap: () => context.push('/profile/favorites')),
          MenuListTile(icon: Icons.favorite_border, label: 'Posts curtidos', onTap: () => context.push('/profile/liked')),
          MenuListTile(icon: Icons.bookmark_outline, label: 'Salvos', onTap: () => context.push('/profile/saved')),
          SizedBox(height: 16),
          MenuListTile(icon: Icons.shopping_cart_outlined, label: 'Carrinho', onTap: () => context.push('/cart')),
          MenuListTile(icon: Icons.bookmark_border, label: 'Favoritos', onTap: () => context.push('/profile/favorites')),
          SizedBox(height: 16),
          MenuListTile(icon: Icons.history, label: 'Histórico de compras', onTap: () => context.push('/profile/purchases')),
          MenuListTile(icon: Icons.account_balance_wallet_outlined, label: 'Carteira e custódia', onTap: () => context.push('/wallet')),
          MenuListTile(icon: Icons.notifications_outlined, label: 'Notificações', onTap: () => context.push('/notifications')),
          SizedBox(height: 16),
          MenuListTile(icon: Icons.block, label: 'Usuários bloqueados', onTap: () => context.push('/profile/blocked')),
          MenuListTile(
            icon: Icons.logout,
            label: 'Sair',
            isDestructive: true,
            onTap: () {
              ref.read(authControllerProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
