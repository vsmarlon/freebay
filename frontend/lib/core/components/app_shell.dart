import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/chat/presentation/providers/chat_socket_provider.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/brutalist_fab.dart';
import 'package:freebay/core/components/app_shell_scaffold_key.dart';
import 'package:freebay/core/components/hide_on_scroll.dart';
import 'package:freebay/features/social/presentation/widgets/feed_drawer.dart';

const double kNavBarContentHeight = 64;

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final HideOnScrollController _navHide;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navHide = HideOnScrollController(vsync: this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _navHide.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authControllerProvider);
      final user = authState.valueOrNull;
      final socketService = container.read(chatSocketServiceProvider);
      if (user != null && !user.isGuest && !socketService.isConnected) {
        socketService.connect();
      }
    }
  }

  void _onDestinationSelected(int index) {
    HapticFeedback.lightImpact();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  Widget? _fabFor(BuildContext context, int selectedIndex) {
    switch (selectedIndex) {
      case 1:
        return BrutalistFab(onTap: () => context.push('/products/create'));
      case 3:
        return BrutalistFab(onTap: () => context.push('/chat/new'));
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navigationShell.currentIndex;

    return Consumer(
      builder: (context, ref, _) {
        ref.listen<AsyncValue<UserEntity?>>(authControllerProvider, (_, next) {
          final user = next.valueOrNull;
          final socketService = ref.read(chatSocketServiceProvider);
          if (user != null && !user.isGuest) {
            socketService.connect();
          } else {
            socketService.disconnect();
          }
        });

        final navBarHeight =
            kNavBarContentHeight + MediaQuery.of(context).padding.bottom;
        final fab = _fabFor(context, selectedIndex);

        return Scaffold(
          key: appShellScaffoldKey,
          drawer: const FeedDrawer(),
          drawerEnableOpenDragGesture: selectedIndex == 0,
          drawerEdgeDragWidth: 48,
          body: Stack(
            children: [
              Positioned.fill(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _navHide.handleNotification,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      padding: MediaQuery.of(
                        context,
                      ).padding.copyWith(bottom: navBarHeight),
                    ),
                    child: widget.navigationShell,
                  ),
                ),
              ),
              if (fab != null)
                Positioned(right: 16, bottom: navBarHeight + 16, child: fab),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ScrollAwareBar(
                  animation: _navHide.animation,
                  height: navBarHeight,
                  edge: ScrollBarEdge.bottom,
                  child: _BrutalistNavBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) =>
                        _onDestinationSelected(index),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BrutalistNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _BrutalistNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.onSurface, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'FREEBAY!',
                isSelected: selectedIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              _NavItem(
                icon: Icons.search,
                selectedIcon: Icons.search,
                label: 'EXPLORAR',
                isSelected: selectedIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),
              _NavItem(
                icon: Icons.account_balance_wallet_outlined,
                selectedIcon: Icons.account_balance_wallet,
                label: 'CARTEIRA',
                isSelected: selectedIndex == 2,
                onTap: () => onDestinationSelected(2),
                isWallet: true,
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline,
                selectedIcon: Icons.chat_bubble,
                label: 'MENSAGENS',
                isSelected: selectedIndex == 3,
                onTap: () => onDestinationSelected(3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'PERFIL',
                isSelected: selectedIndex == 4,
                onTap: () => onDestinationSelected(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isWallet;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isWallet = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 64,
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected
                    ? AppColors.onPrimary
                    : (isDark
                          ? AppColors.inverseOnSurface
                          : AppColors.onSurface),
                size: 24,
              ),
              Spacing.vXs,
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isSelected
                      ? AppColors.onPrimary
                      : (isDark
                            ? AppColors.inverseOnSurface
                            : AppColors.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
