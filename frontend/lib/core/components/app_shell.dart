import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/social/presentation/pages/feed_page.dart';
import 'package:freebay/features/product/presentation/pages/product_list_page.dart';
import 'package:freebay/features/wallet/presentation/pages/wallet_page.dart';
import 'package:freebay/features/chat/presentation/pages/chat_list_page.dart';
import 'package:freebay/features/profile/presentation/pages/profile_page.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late PageController _pageController;

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
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

    _pageController.jumpToPage(index);
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

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_pageController.hasClients &&
        _pageController.page?.round() != selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(selectedIndex);
        }
      });
    }

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
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
        },
        children: _pages,
      ),
      bottomNavigationBar: _BrutalistNavBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            _onDestinationSelected(context, index),
        isDark: isDark,
      ),
      floatingActionButton: (selectedIndex == 0 || selectedIndex == 1)
          ? _CreateProductFab(onTap: () => context.push('/products/create'))
          : null,
    );
  }
}

class _BrutalistNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isDark;

  const _BrutalistNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.surfaceDark : AppColors.surfaceContainerLowest,
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
                label: 'HOME',
                isSelected: selectedIndex == 0,
                onTap: () => onDestinationSelected(0),
                isDark: isDark,
              ),
              _NavItem(
                icon: Icons.search,
                selectedIcon: Icons.search,
                label: 'SEARCH',
                isSelected: selectedIndex == 1,
                onTap: () => onDestinationSelected(1),
                isDark: isDark,
              ),
              _NavItem(
                icon: Icons.account_balance_wallet_outlined,
                selectedIcon: Icons.account_balance_wallet,
                label: 'WALLET',
                isSelected: selectedIndex == 2,
                onTap: () => onDestinationSelected(2),
                isDark: isDark,
                isWallet: true,
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline,
                selectedIcon: Icons.chat_bubble,
                label: 'CHAT',
                isSelected: selectedIndex == 3,
                onTap: () => onDestinationSelected(3),
                isDark: isDark,
              ),
              _NavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'PERFIL',
                isSelected: selectedIndex == 4,
                onTap: () => onDestinationSelected(4),
                isDark: isDark,
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
  final bool isDark;
  final bool isWallet;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.isWallet = false,
  });

  @override
  Widget build(BuildContext context) {
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
              ? (isWallet ? AppColors.accentGreen : AppColors.primaryContainer)
              : Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.inverseOnSurface
                        : AppColors.onSurface),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isSelected
                      ? Colors.white
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

class _CreateProductFab extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateProductFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.brutalistGradient,
          border: Border.all(
            color: AppColors.onSurface,
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
