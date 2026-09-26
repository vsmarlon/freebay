import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';

class FeedHeader extends StatelessWidget {
  const FeedHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: context.appBarColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.5),
        child: Container(color: context.borderColor.withAlpha(50), height: 1.5),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: BrutalistIconButton(
            icon: Icons.menu,
            size: 38,
            onTap: () => appShellScaffoldKey.currentState?.openDrawer(),
          ),
        ),
      ),
      title: RichText(
        text: TextSpan(
          text: 'FREEBAY',
          style: TextStyle(
            fontFamily: AppTypography.headlineFontFamily,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.5,
            color: context.textPrimary,
          ),
          children: const [
            TextSpan(
              text: '!',
              style: TextStyle(
                color: AppColors.primaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      actions: const [
        FeedHeaderIcon(
          icon: Icons.person_search_outlined,
          route: AppRoutes.peopleSearch,
        ),
        SizedBox(width: 8),
        FeedHeaderIcon(
          icon: Icons.notifications_outlined,
          route: AppRoutes.notifications,
        ),
        SizedBox(width: 8),
        FeedHeaderIcon(
          icon: Icons.account_balance_wallet_outlined,
          route: AppRoutes.wallet,
          useGo: true,
        ),
        SizedBox(width: 12),
      ],
    );
  }
}

class FeedHeaderIcon extends StatelessWidget {
  final IconData icon;
  final String route;
  final bool useGo;

  const FeedHeaderIcon({
    super.key,
    required this.icon,
    required this.route,
    this.useGo = false,
  });

  @override
  Widget build(BuildContext context) {
    return BrutalistIconButton(
      icon: icon,
      size: 38,
      onTap: () => useGo ? context.go(route) : context.push(route),
    );
  }
}
