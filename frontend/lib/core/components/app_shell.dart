import 'dart:ui';
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
  double _dragStartX = 0.0;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _navHide = HideOnScrollController(vsync: this);
    _previousIndex = widget.navigationShell.currentIndex;
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _previousIndex = oldWidget.navigationShell.currentIndex;
    }
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
      final user = authState.value;
      final socketService = container.read(chatSocketServiceProvider);
      if (user != null && !socketService.isConnected) {
        socketService.connect();
      }
    }
  }

  void _onDestinationSelected(int index) {
    if (index < 0 || index > 4) return;
    HapticFeedback.lightImpact();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final vx = details.primaryVelocity ?? 0;
    final currentIndex = widget.navigationShell.currentIndex;

    if (vx < -150 || (_dragStartX - details.velocity.pixelsPerSecond.dx > 60)) {
      if (currentIndex < 4) {
        _onDestinationSelected(currentIndex + 1);
      }
    } else if (vx > 150) {
      if (currentIndex > 0) {
        _onDestinationSelected(currentIndex - 1);
      }
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
    final selectedIndex = widget.navigationShell.currentIndex;
    final isForward = selectedIndex >= _previousIndex;

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
                child: GestureDetector(
                  onHorizontalDragStart: _handleHorizontalDragStart,
                  onHorizontalDragEnd: _handleHorizontalDragEnd,
                  behavior: HitTestBehavior.translucent,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _navHide.handleNotification,
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        padding: MediaQuery.of(context).padding.copyWith(
                          bottom: isKeyboardOpen ? 0 : navBarHeight,
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOutQuad,
                        switchOutCurve: Curves.easeInQuad,
                        transitionBuilder: (child, animation) {
                          final beginOffset = isForward
                              ? const Offset(0.20, 0.0)
                              : const Offset(-0.20, 0.0);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: beginOffset,
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<int>(selectedIndex),
                          child: widget.navigationShell,
                        ),
                      ),
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
    final isDark = context.isDark;

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withAlpha(220)
                : AppColors.white.withAlpha(230),
            borderRadius: BorderRadius.zero,
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
                    borderRadius: BorderRadius.zero,
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
