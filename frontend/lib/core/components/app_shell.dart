import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/chat/presentation/providers/chat_socket_provider.dart';
import 'package:freebay/core/components/brutalist_fab.dart';
import 'package:freebay/core/components/app_shell_scaffold_key.dart';
import 'package:freebay/core/components/hide_on_scroll.dart';
import 'package:freebay/features/social/presentation/widgets/feed_drawer.dart';

const double kNavBarContentHeight = 64;

const Duration kShellPageDuration = Duration(milliseconds: 150);
const double kDrawerOverswipeThreshold = 56;

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget> branches;

  const AppShell({
    super.key,
    required this.navigationShell,
    required this.branches,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final HideOnScrollController _navHide;
  late final PageController _pageController;
  double _overscrolledLeft = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navHide = HideOnScrollController(vsync: this);
    _pageController = PageController(
      initialPage: widget.navigationShell.currentIndex,
    );
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.navigationShell.currentIndex;
    if (_pageController.hasClients &&
        _pageController.page?.round() != index &&
        !_pageController.position.isScrollingNotifier.value) {
      _pageController.jumpToPage(index);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _navHide.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authControllerProvider);
      final user = authState.value;
      final socketService = container.read(chatSocketServiceProvider);
      if (user != null && !socketService.isConnected) {
        socketService.connect();
      }
    }
  }

  void _onDestinationSelected(int index) {
    if (index < 0 || index >= widget.branches.length) return;
    HapticFeedback.lightImpact();

    if (index == widget.navigationShell.currentIndex) {
      widget.navigationShell.goBranch(index, initialLocation: true);
      return;
    }

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: kShellPageDuration,
        curve: AppMotion.baseCurve,
      );
    } else {
      widget.navigationShell.goBranch(index);
    }
  }

  void _onPageChanged(int index) {
    if (index == widget.navigationShell.currentIndex) return;
    widget.navigationShell.goBranch(index);
  }

  bool _handleShellScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.horizontal) {
      if (notification is OverscrollNotification &&
          notification.overscroll < 0 &&
          widget.navigationShell.currentIndex == 0) {
        _overscrolledLeft -= notification.overscroll;
        if (_overscrolledLeft > kDrawerOverswipeThreshold) {
          _overscrolledLeft = 0;
          appShellScaffoldKey.currentState?.openDrawer();
        }
      } else if (notification is ScrollEndNotification) {
        _overscrolledLeft = 0;
      }
      return false;
    }
    return _navHide.handleNotification(notification);
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
          final user = next.value;
          final socketService = ref.read(chatSocketServiceProvider);
          if (user != null) {
            socketService.connect();
          } else {
            socketService.disconnect();
          }
        });

        final navBarHeight =
            kNavBarContentHeight + MediaQuery.of(context).padding.bottom;
        final fab = _fabFor(context, selectedIndex);

        final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

        return Scaffold(
          key: appShellScaffoldKey,
          drawer: const FeedDrawer(),
          drawerEnableOpenDragGesture: selectedIndex == 0,
          drawerEdgeDragWidth: 32,
          drawerScrimColor: Colors.black54,
          body: Stack(
            children: [
              Positioned.fill(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _handleShellScroll,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      padding: MediaQuery.of(context).padding.copyWith(
                        bottom: isKeyboardOpen ? 0 : navBarHeight,
                      ),
                    ),
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      physics: const ClampingScrollPhysics(),
                      children: widget.branches,
                    ),
                  ),
                ),
              ),
              if (fab != null && !isKeyboardOpen)
                Positioned(right: 16, bottom: navBarHeight + 16, child: fab),
              if (!isKeyboardOpen)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 8,
                  child: ScrollAwareBar(
                    animation: _navHide.animation,
                    height: navBarHeight,
                    edge: ScrollBarEdge.bottom,
                    child: _BrutalistNavBar(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: _onDestinationSelected,
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
    final isDark = context.isDark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withAlpha(220)
                : AppColors.white.withAlpha(230),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(30)
                  : Colors.black.withAlpha(20),
              width: 1.5,
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
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected
                    ? AppColors.primaryContainer
                    : (isDark
                          ? AppColors.inverseOnSurface
                          : AppColors.onSurface),
                size: 22,
              ),
              if (isSelected)
                Container(
                  width: 24,
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 2, top: 2),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                  ),
                )
              else
                Spacing.vXs,
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.headlineFontFamily,
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isSelected
                      ? AppColors.primaryContainer
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
