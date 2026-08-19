import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

/// Helper to create a fast 150ms slide + fade transition for brutalist pages.
Page<T> buildSlidePage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 150),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.linear,
      );
      final curvedSecondary = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.linear,
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
  return CupertinoPage<T>(key: state.pageKey, child: child);
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
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
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
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final curvedSecondary = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
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
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
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
