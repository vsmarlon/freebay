import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialRouteTransitionMixin;
import 'package:go_router/go_router.dart';

/// Creates a role-based slide + fade transition for brutalist pages.
Page<T> buildSlidePage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.forContext(context, AppMotion.base),
    reverseTransitionDuration: AppMotion.forContext(context, AppMotion.base),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: AppMotion.baseCurve,
      );
      final curvedSecondary = CurvedAnimation(
        parent: secondaryAnimation,
        curve: AppMotion.baseCurve,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.3, 0.0),
            ).animate(curvedSecondary),
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 1.0,
                end: 0.7,
              ).animate(curvedSecondary),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

/// Helper to create a Cupertino page with native interactive edge-drag pop gesture.
Page<T> buildCupertinoPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return _ThemeTransitionPage<T>(
    key: state.pageKey,
    child: child,
    disableAnimations: MediaQuery.disableAnimationsOf(context),
  );
}

class _ThemeTransitionPage<T> extends Page<T> {
  const _ThemeTransitionPage({
    required this.child,
    required this.disableAnimations,
    super.key,
  });

  final Widget child;
  final bool disableAnimations;

  @override
  Route<T> createRoute(BuildContext context) =>
      _ThemeTransitionRoute<T>(page: this);
}

class _ThemeTransitionRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _ThemeTransitionRoute({required _ThemeTransitionPage<T> page})
    : super(settings: page);

  _ThemeTransitionPage<T>? get _page => switch (settings) {
    _ThemeTransitionPage<T> page => page,
    _ => null,
  };

  @override
  Duration get transitionDuration => _page?.disableAnimations == true
      ? Duration.zero
      : super.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _page?.disableAnimations == true
      ? Duration.zero
      : super.reverseTransitionDuration;

  @override
  bool get maintainState => true;

  @override
  bool get fullscreenDialog => false;

  @override
  Widget buildContent(BuildContext context) =>
      _page?.child ?? const SizedBox.shrink();
}

/// Creates a GoRoute with the default brutalist slide transition.
GoRoute appSlideRoute(
  String path,
  Widget Function(BuildContext context, GoRouterState state) builder, {
  List<RouteBase> routes = const <RouteBase>[],
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => buildSlidePage(
      context: context,
      state: state,
      child: builder(context, state),
    ),
    routes: routes,
  );
}

/// Creates a GoRoute with native Cupertino edge-drag-to-pop gesture.
GoRoute appCupertinoRoute(
  String path,
  Widget Function(BuildContext context, GoRouterState state) builder, {
  List<RouteBase> routes = const <RouteBase>[],
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => buildCupertinoPage(
      context: context,
      state: state,
      child: builder(context, state),
    ),
    routes: routes,
  );
}

/// Fade-only transition for auth screens (login, register, etc.).
Page<T> buildFadePage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.forContext(context, AppMotion.enter),
    reverseTransitionDuration: AppMotion.forContext(context, AppMotion.enter),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: AppMotion.enterCurve,
        ),
        child: child,
      );
    },
  );
}

/// Creates a GoRoute with fade-only transition.
GoRoute appFadeRoute(
  String path,
  Widget Function(BuildContext context, GoRouterState state) builder, {
  List<RouteBase> routes = const <RouteBase>[],
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => buildFadePage(
      context: context,
      state: state,
      child: builder(context, state),
    ),
    routes: routes,
  );
}

/// Shared-axis horizontal transition for sibling auth screens (login ↔ register).
Page<T> buildSharedAxisHorizontalPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.forContext(context, AppMotion.enter),
    reverseTransitionDuration: AppMotion.forContext(context, AppMotion.enter),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: AppMotion.enterCurve,
        reverseCurve: AppMotion.enterCurve,
      );
      final curvedSecondary = CurvedAnimation(
        parent: secondaryAnimation,
        curve: AppMotion.enterCurve,
        reverseCurve: AppMotion.enterCurve,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.3, 0.0),
            ).animate(curvedSecondary),
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 1.0,
                end: 0.0,
              ).animate(curvedSecondary),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

/// Shared-axis vertical transition for hierarchical auth screens (login → recovery).
Page<T> buildSharedAxisVerticalPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.forContext(context, AppMotion.enter),
    reverseTransitionDuration: AppMotion.forContext(context, AppMotion.enter),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: AppMotion.enterCurve,
        reverseCurve: AppMotion.enterCurve,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.15),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(opacity: curvedAnimation, child: child),
      );
    },
  );
}

/// Creates a GoRoute with shared-axis horizontal transition.
GoRoute appSharedAxisHRoute(
  String path,
  Widget Function(BuildContext context, GoRouterState state) builder, {
  List<RouteBase> routes = const <RouteBase>[],
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => buildSharedAxisHorizontalPage(
      context: context,
      state: state,
      child: builder(context, state),
    ),
    routes: routes,
  );
}

/// Creates a GoRoute with shared-axis vertical transition.
GoRoute appSharedAxisVRoute(
  String path,
  Widget Function(BuildContext context, GoRouterState state) builder, {
  List<RouteBase> routes = const <RouteBase>[],
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => buildSharedAxisVerticalPage(
      context: context,
      state: state,
      child: builder(context, state),
    ),
    routes: routes,
  );
}

/// Creates a shell branch with slide transition.
StatefulShellBranch appShellBranch(
  String path,
  Widget Function(BuildContext context, GoRouterState state) builder, {
  List<GoRoute> additionalRoutes = const [],
}) {
  return StatefulShellBranch(
    routes: [appSlideRoute(path, builder), ...additionalRoutes],
  );
}
