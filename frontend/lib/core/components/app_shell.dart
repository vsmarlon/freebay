import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/chat/presentation/providers/chat_socket_provider.dart';
import 'package:freebay/core/components/app_background.dart';
import 'package:freebay/core/components/brutalist_fab.dart';
import 'package:freebay/core/components/app_shell_scaffold_key.dart';
import 'package:freebay/core/components/hide_on_scroll.dart';
import 'package:freebay/core/components/shell_scroll_chrome.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/social/presentation/widgets/feed_drawer.dart';
import 'package:freebay/shared/providers/connectivity_status_provider.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

const double kNavBarContentHeight = 64;

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
  late final AnimationController _drawer;
  LocalHistoryEntry? _drawerHistory;
  double _dragStartPage = 0;
  bool _dragging = false;
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    _visitedTabs.add(widget.navigationShell.currentIndex);
    WidgetsBinding.instance.addObserver(this);
    _navHide = HideOnScrollController(vsync: this);
    _pageController = PageController(
      initialPage: widget.navigationShell.currentIndex,
    );
    _drawer = AnimationController(vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.navigationShell.currentIndex;
    if (oldWidget.navigationShell.currentIndex != index) {
      _navHide.showImmediately();
    }
    _visitedTabs.add(index);
    if (_pageController.hasClients &&
        _pageController.page?.round() != index &&
        !_dragging &&
        !_pageController.position.isScrollingNotifier.value) {
      _pageController.jumpToPage(index);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _navHide.dispose();
    _pageController.dispose();
    final history = _drawerHistory;
    _drawerHistory = null;
    history?.remove();
    _drawer.dispose();
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
    _visitedTabs.add(index);

    if (index == widget.navigationShell.currentIndex) {
      widget.navigationShell.goBranch(index, initialLocation: true);
      return;
    }

    if (_pageController.hasClients) {
      final duration = AppMotion.forContext(context, AppMotion.base);
      if (duration == Duration.zero) {
        _pageController.jumpToPage(index);
      } else {
        _pageController.animateToPage(
          index,
          duration: duration,
          curve: AppMotion.baseCurve,
        );
      }
    } else {
      widget.navigationShell.goBranch(index);
    }
  }

  void _onPageChanged(int index) {
    if (index == widget.navigationShell.currentIndex) return;
    _visitedTabs.add(index);
    widget.navigationShell.goBranch(index);
  }

  bool _handleShellScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.horizontal) {
      return false;
    }
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      _navHide.showImmediately();
      return false;
    }
    return _navHide.handleNotification(notification);
  }

  void _rememberDrawer() {
    if (_drawerHistory != null) return;
    _drawerHistory = LocalHistoryEntry(
      onRemove: () {
        if (_drawerHistory == null) return;
        _drawerHistory = null;
        if (mounted) _settleDrawer(false);
      },
    );
    ModalRoute.of(context)?.addLocalHistoryEntry(_drawerHistory!);
  }

  void _settleDrawer(bool open) {
    if (open) _rememberDrawer();
    _drawer
        .animateTo(
          open ? 1 : 0,
          duration: AppMotion.forContext(context, AppMotion.base),
        )
        .whenCompleteOrCancel(() {
          if (!mounted || _drawer.value != 0) return;
          final history = _drawerHistory;
          _drawerHistory = null;
          history?.remove();
        });
  }

  void _startDrag(DragStartDetails details) {
    // ponytail: page swiping moved to inner pagers; only the left edge opens the drawer.
    if (details.globalPosition.dx > 24) {
      _dragging = false;
      return;
    }
    _dragging = true;
    _drawer.stop();
    _dragStartPage =
        _pageController.page ?? widget.navigationShell.currentIndex.toDouble();
  }

  void _updateDrag(DragUpdateDetails details) {
    if (!_dragging || !_pageController.hasClients) return;
    final width = MediaQuery.sizeOf(context).width;
    final delta = details.primaryDelta ?? 0;
    final neighborIndex = _dragStartPage.round() + (delta < 0 ? 1 : -1);
    if (neighborIndex >= 0 && neighborIndex < widget.branches.length) {
      if (_visitedTabs.add(neighborIndex)) setState(() {});
    }
    final pixels = _pageController.position.pixels;
    if (_drawer.value > 0 || (pixels <= 0 && delta > 0)) {
      _rememberDrawer();
      _drawer.value = (_drawer.value + delta / (width * 0.78)).clamp(0, 1);
      return;
    }
    _pageController.jumpTo(
      (pixels - delta).clamp(0, _pageController.position.maxScrollExtent),
    );
  }

  void _endDrag([DragEndDetails? details]) {
    if (!_dragging) return;
    _dragging = false;
    final velocity = details?.primaryVelocity ?? 0;
    if (_drawer.value > 0 || _drawerHistory != null) {
      _settleDrawer(
        details != null &&
            (velocity.abs() >= kMinFlingVelocity
                ? velocity > 0
                : _drawer.value >= 0.5),
      );
      return;
    }
    if (!_pageController.hasClients) return;
    final page = _pageController.page ?? _dragStartPage;
    final target =
        (velocity.abs() >= kMinFlingVelocity
                ? _dragStartPage.round() + (velocity < 0 ? 1 : -1)
                : page.round())
            .clamp(0, widget.branches.length - 1);
    _pageController.animateToPage(
      target,
      duration: AppMotion.forContext(context, AppMotion.base),
      curve: AppMotion.baseCurve,
    );
  }

  BrutalistFab? _fabFor(BuildContext context, int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return BrutalistFab(
          icon: Icons.edit_outlined,
          semanticLabel: l10n(context).feedCreatePost,
          onTap: () => context.push(AppRoutes.createPost),
        );
      case 1:
        return BrutalistFab(
          semanticLabel: l10n(context).productCreateListing,
          onTap: () => context.push(AppRoutes.createProduct),
        );
      case 3:
        return BrutalistFab(
          semanticLabel: l10n(context).chatNewTitle,
          onTap: () => context.push(AppRoutes.chatNew),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navigationShell.currentIndex;
    final shellIsCurrent = ModalRoute.isCurrentOf(context) ?? true;

    return Consumer(
      builder: (context, ref, _) {
        ref.listen<AsyncValue<UserEntity?>>(authControllerProvider, (
          previous,
          next,
        ) {
          final user = next.value;
          final socketService = ref.read(chatSocketServiceProvider);
          if (user != null) {
            if (previous?.value != null && previous?.value?.id != user.id) {
              socketService.disconnect();
            }
            socketService.connect();
          } else {
            socketService.disconnect();
          }
        });

        final navBarHeight = kNavBarContentHeight;
        final navBottom = MediaQuery.paddingOf(context).bottom + 8;
        final fab = _fabFor(context, selectedIndex);
        final connectivity = ref.watch(connectivityStatusProvider);

        final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
        if (isKeyboardOpen || !shellIsCurrent) _navHide.showImmediately();

        return GestureDetector(
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragStart: _startDrag,
          onHorizontalDragUpdate: _updateDrag,
          onHorizontalDragEnd: _endDrag,
          onHorizontalDragCancel: _endDrag,
          child: _DrawerScaffold(
            open: () => _settleDrawer(true),
            close: () => _settleDrawer(false),
            opened: _drawer.value == 1,
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            key: appShellScaffoldKey,
            body: AppBackground(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _handleShellScroll,
                      child: Builder(
                        builder: (mediaContext) => MediaQuery(
                          data: MediaQuery.of(mediaContext).copyWith(
                            padding: MediaQuery.paddingOf(mediaContext)
                                .copyWith(
                                  bottom: isKeyboardOpen
                                      ? 0
                                      : navBarHeight + navBottom,
                                ),
                          ),
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: _onPageChanged,
                            physics: const NeverScrollableScrollPhysics(),
                            // The custom PageView must mute kept-alive branches,
                            // including when a root route covers the entire shell.
                            children: [
                              for (final (index, branch)
                                  in widget.branches.indexed)
                                RepaintBoundary(
                                  child: Offstage(
                                    offstage: !_visitedTabs.contains(index),
                                    child: TickerMode(
                                      enabled:
                                          shellIsCurrent &&
                                          index == selectedIndex,
                                      child: ShellScrollChromeScope(
                                        animation: _navHide.animation,
                                        child: branch,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (connectivity.asData?.value == false)
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      left: 16,
                      right: 16,
                      child: Semantics(
                        liveRegion: true,
                        label: l10n(context).commonOffline,
                        child: Container(
                          color: context.surfaceColor,
                          padding: const EdgeInsets.all(8),
                          child: ExcludeSemantics(
                            child: Text(
                              l10n(context).commonOffline.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: AppTypography.labelSmall.copyWith(
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (fab != null && !isKeyboardOpen)
                    Positioned(
                      right: 16,
                      bottom: navBarHeight + navBottom + 16,
                      child: ScrollAwareBar(
                        animation: _navHide.animation,
                        height: navBarHeight + navBottom + 16 + fab.size,
                        edge: ScrollBarEdge.bottom,
                        child: fab,
                      ),
                    ),
                  if (!isKeyboardOpen)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: navBottom,
                      child: ScrollAwareBar(
                        animation: _navHide.animation,
                        height: navBarHeight + navBottom,
                        edge: ScrollBarEdge.bottom,
                        child: _BrutalistNavBar(
                          selectedIndex: selectedIndex,
                          onDestinationSelected: _onDestinationSelected,
                        ),
                      ),
                    ),
                  if (_drawer.value > 0) ...[
                    Positioned.fill(
                      child: ModalBarrier(
                        color: Colors.black.withValues(
                          alpha: 0.54 * _drawer.value,
                        ),
                        onDismiss: () => _settleDrawer(false),
                        semanticsLabel: MaterialLocalizations.of(
                          context,
                        ).modalBarrierDismissLabel,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left:
                          -(1 - _drawer.value) *
                          MediaQuery.sizeOf(context).width *
                          0.78,
                      width: MediaQuery.sizeOf(context).width * 0.78,
                      child: const BlockSemantics(child: FeedDrawer()),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ponytail: Scaffold exposes open/close but no drag progress. Keep its existing
// caller API while one shell-owned animation drives all drawer entry points.
class _DrawerScaffold extends Scaffold {
  const _DrawerScaffold({
    required this.open,
    required this.close,
    required this.opened,
    super.key,
    super.backgroundColor,
    super.resizeToAvoidBottomInset,
    super.body,
  });

  final VoidCallback open;
  final VoidCallback close;
  final bool opened;

  @override
  ScaffoldState createState() => _DrawerScaffoldState();
}

class _DrawerScaffoldState extends ScaffoldState {
  // ScaffoldState exposes its widget as Scaffold; this state is created only
  // by _DrawerScaffold.
  _DrawerScaffold get _configuration => widget as _DrawerScaffold;

  @override
  void openDrawer() => _configuration.open();

  @override
  void closeDrawer() => _configuration.close();

  @override
  bool get isDrawerOpen => _configuration.opened;
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
        color: context.surfaceColor,
        border: Border.all(color: context.borderColor, width: 1.5),
      ),
      child: SizedBox(
        height: kNavBarContentHeight,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: l10n(context).navHome,
              isSelected: selectedIndex == 0,
              onTap: () => onDestinationSelected(0),
            ),
            _NavItem(
              icon: Icons.search,
              selectedIcon: Icons.search,
              label: l10n(context).navExplore,
              isSelected: selectedIndex == 1,
              onTap: () => onDestinationSelected(1),
            ),
            _NavItem(
              icon: Icons.account_balance_wallet_outlined,
              selectedIcon: Icons.account_balance_wallet,
              label: l10n(context).walletTitleBrutalist,
              isSelected: selectedIndex == 2,
              onTap: () => onDestinationSelected(2),
              isWallet: true,
            ),
            _NavItem(
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              label: l10n(context).navMessages,
              isSelected: selectedIndex == 3,
              onTap: () => onDestinationSelected(3),
            ),
            _NavItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: l10n(context).navProfile,
              isSelected: selectedIndex == 4,
              onTap: () => onDestinationSelected(4),
            ),
          ],
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
                    ? context.colors.primary
                    : context.textPrimary,
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
                      ? context.colors.primary
                      : context.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
