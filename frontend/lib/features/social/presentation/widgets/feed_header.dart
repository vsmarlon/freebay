import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class FeedHeader extends StatelessWidget {
  const FeedHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
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
            semanticLabel: strings.accessibilityOpenMenu,
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
      actions: [
        FeedHeaderIcon(
          icon: Icons.person_search_outlined,
          semanticLabel: strings.socialPeopleSearchTitle,
          route: AppRoutes.peopleSearch,
        ),
        const SizedBox(width: 8),
        FeedHeaderIcon(
          icon: Icons.notifications_outlined,
          semanticLabel: strings.notificationsTitle,
          route: AppRoutes.notifications,
        ),
        const SizedBox(width: 8),
        FeedHeaderIcon(
          icon: Icons.account_balance_wallet_outlined,
          semanticLabel: strings.walletTitle,
          route: AppRoutes.wallet,
          useGo: true,
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

class FeedHeaderIcon extends StatelessWidget {
  final IconData icon;
  final String route;
  final String semanticLabel;
  final bool useGo;

  const FeedHeaderIcon({
    super.key,
    required this.icon,
    required this.route,
    required this.semanticLabel,
    this.useGo = false,
  });

  @override
  Widget build(BuildContext context) {
    return BrutalistIconButton(
      icon: icon,
      semanticLabel: semanticLabel,
      size: 38,
      onTap: () => useGo ? context.go(route) : context.push(route),
    );
  }
}
