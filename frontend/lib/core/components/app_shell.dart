import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/chat/presentation/providers/chat_socket_provider.dart';
import 'package:freebay/features/social/presentation/pages/feed_page.dart';
import 'package:freebay/features/product/presentation/pages/product_list_page.dart';
import 'package:freebay/features/wallet/presentation/pages/wallet_page.dart';
import 'package:freebay/features/chat/presentation/pages/chat_list_page.dart';
import 'package:freebay/features/profile/presentation/pages/profile_page.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/brutalist_fab.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  late final PageController _pageController;

  static const _pages = [
    FeedPage(),
    ProductListPage(),
    WalletPage(),
    ChatListPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
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

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/feed')) return 0;
    if (location.startsWith('/post')) return 0;
    if (location.startsWith('/products') || location.startsWith('/explore')) {
      return 1;
    }
    if (location.startsWith('/wallet')) return 2;
    if (location.startsWith('/chat')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
    switch (index) {
      case 0:
        context.go('/feed');
      case 1:
        context.go('/products');
      case 2:
        context.go('/wallet');
      case 3:
        context.go('/chat');
      case 4:
        context.go('/profile');
    }
  }

  void _onPageChanged(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/feed');
      case 1:
        context.go('/products');
      case 2:
        context.go('/wallet');
      case 3:
        context.go('/chat');
      case 4:
        context.go('/profile');
    }
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
    final selectedIndex = _getSelectedIndex(context);

    if (_pageController.hasClients &&
        _pageController.page?.round() != selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients &&
            _pageController.page?.round() != selectedIndex) {
          _pageController.jumpToPage(selectedIndex);
        }
      });
    }

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

        return Scaffold(
          body: PageView(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (index) => _onPageChanged(context, index),
            children: _pages,
          ),
          bottomNavigationBar: _BrutalistNavBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                _onDestinationSelected(context, index),
          ),
          floatingActionButton: _fabFor(context, selectedIndex),
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
        border: Border(
          top: BorderSide(
            color: AppColors.onSurface,
            width: 2,
          ),
        ),
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
          color: isSelected
              ? (isWallet ? AppColors.success : AppColors.primaryContainer)
              : Colors.transparent,
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
