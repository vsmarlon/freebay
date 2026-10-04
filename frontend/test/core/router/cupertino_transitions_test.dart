import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/router/route_helpers.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import '../../support/auth_test_doubles.dart';

Future<GoRouter> _pumpRoutes(
  WidgetTester tester, {
  required TargetPlatform platform,
  required bool disableAnimations,
  Widget Function(BuildContext context, GoRouterState state)? detailBuilder,
  ValueNotifier<int>? refreshListenable,
  PageTransitionsTheme? pageTransitionsTheme,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: AppRoutes.feed,
    refreshListenable: refreshListenable,
    routes: [
      appCupertinoRoute(
        AppRoutes.feed,
        (context, state) => const Scaffold(body: Text('Feed page')),
      ),
      appCupertinoRoute(
        AppRoutes.postDetails,
        detailBuilder ??
            (context, state) => const Scaffold(body: Text('Post details')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light.copyWith(
        platform: platform,
        pageTransitionsTheme:
            pageTransitionsTheme ?? AppTheme.pageTransitionsTheme,
      ),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _pushDetail(WidgetTester tester, GoRouter router) async {
  router.push(AppRoutes.postPath('fixture'));
  await tester.pumpAndSettle();
  expect(router.canPop(), isTrue);
  expect(find.text('Post details'), findsOneWidget);
}

Future<void> _commitEdgeSwipe(WidgetTester tester) async {
  final drag = await tester.startGesture(const Offset(10, 420));
  await drag.moveTo(const Offset(80, 420));
  await tester.pump(const Duration(milliseconds: 100));
  await drag.moveTo(const Offset(310, 420));
  await tester.pump(const Duration(milliseconds: 100));
  await drag.up();
  await tester.pumpAndSettle();
}

class _FadingThemeTransitions extends PageTransitionsBuilder {
  const _FadingThemeTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(
    key: const ValueKey('theme-owned-transition'),
    opacity: animation,
    child: child,
  );
}

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    for (final disableAnimations in [false, true]) {
      testWidgets(
        'edge swipe pops on $platform with disableAnimations=$disableAnimations',
        (tester) async {
          final router = await _pumpRoutes(
            tester,
            platform: platform,
            disableAnimations: disableAnimations,
          );
          await _pushDetail(tester, router);

          await _commitEdgeSwipe(tester);

          expect(router.canPop(), isFalse);
          expect(find.text('Feed page'), findsOneWidget);
        },
      );
    }
  }

  testWidgets('a short, slow edge drag cancels and keeps detail open', (
    tester,
  ) async {
    final router = await _pumpRoutes(
      tester,
      platform: TargetPlatform.iOS,
      disableAnimations: false,
    );
    await _pushDetail(tester, router);

    final drag = await tester.startGesture(const Offset(10, 420));
    await drag.moveTo(const Offset(80, 420));
    await tester.pump(const Duration(milliseconds: 400));
    await drag.up();
    await tester.pumpAndSettle();

    expect(router.canPop(), isTrue);
    expect(find.text('Post details'), findsOneWidget);
  });

  testWidgets('reduced-motion push and pop settle on their first pump', (
    tester,
  ) async {
    final router = await _pumpRoutes(
      tester,
      platform: TargetPlatform.iOS,
      disableAnimations: true,
    );

    router.push(AppRoutes.postPath('fixture'));
    await tester.pump();
    expect(router.canPop(), isTrue);
    final detail = find.text('Post details');
    expect(detail, findsOneWidget);
    expect(tester.getTopLeft(detail).dx, closeTo(0, 0.01));

    router.pop();
    await tester.pump();
    expect(router.canPop(), isFalse);
    expect(find.text('Post details'), findsNothing);
    final feed = find.text('Feed page');
    expect(feed, findsOneWidget);
    expect(tester.getTopLeft(feed).dx, closeTo(0, 0.01));
  });

  testWidgets('edge drag at the root cannot dismiss the root page', (
    tester,
  ) async {
    final router = await _pumpRoutes(
      tester,
      platform: TargetPlatform.iOS,
      disableAnimations: false,
    );
    expect(router.canPop(), isFalse);

    await _commitEdgeSwipe(tester);

    expect(router.canPop(), isFalse);
    expect(find.text('Feed page'), findsOneWidget);
  });

  testWidgets('edge drag at the five-branch app shell root cannot pop it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const labels = ['ALPHA', 'BRAVO', 'CHARLIE', 'DELTA', 'ECHO'];
    final router = GoRouter(
      initialLocation: '/branch-0',
      routes: [
        StatefulShellRoute(
          builder: (context, state, shell) => shell,
          navigatorContainerBuilder: (context, shell, branches) =>
              AppShell(navigationShell: shell, branches: branches),
          branches: [
            for (var i = 0; i < labels.length; i++)
              appShellBranch(
                '/branch-$i',
                (context, state) => Scaffold(body: Text(labels[i])),
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => TestAuthController(null)),
        ],
        child: MaterialApp.router(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light.copyWith(platform: TargetPlatform.iOS),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.canPop(), isFalse);
    expect(find.text('ALPHA'), findsOneWidget);

    await _commitEdgeSwipe(tester);

    expect(find.text('ALPHA'), findsOneWidget);
    expect(find.text('BRAVO'), findsNothing);
  });

  testWidgets('PopScope veto prevents an edge gesture from popping detail', (
    tester,
  ) async {
    final router = await _pumpRoutes(
      tester,
      platform: TargetPlatform.iOS,
      disableAnimations: false,
      detailBuilder: (context, state) => const PopScope(
        canPop: false,
        child: Scaffold(body: Text('Post details')),
      ),
    );
    await _pushDetail(tester, router);

    await _commitEdgeSwipe(tester);

    expect(router.canPop(), isTrue);
    expect(find.text('Post details'), findsOneWidget);
  });

  testWidgets('horizontal carousel drag pages content without popping route', (
    tester,
  ) async {
    final router = await _pumpRoutes(
      tester,
      platform: TargetPlatform.iOS,
      disableAnimations: false,
      detailBuilder: (context, state) => Scaffold(
        body: PageView(
          children: [
            const Center(child: Text('Carousel page one')),
            const Center(child: Text('Carousel page two')),
          ],
        ),
      ),
    );
    router.push(AppRoutes.postPath('fixture'));
    await tester.pumpAndSettle();
    expect(router.canPop(), isTrue);
    expect(find.text('Carousel page one'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-260, 0));
    await tester.pumpAndSettle();

    expect(router.canPop(), isTrue);
    expect(find.text('Carousel page two'), findsOneWidget);
  });

  testWidgets('same-key route refresh displays the latest page child', (
    tester,
  ) async {
    final childVersion = ValueNotifier<int>(1);
    addTearDown(childVersion.dispose);
    final router = await _pumpRoutes(
      tester,
      platform: TargetPlatform.iOS,
      disableAnimations: true,
      refreshListenable: childVersion,
      detailBuilder: (context, state) =>
          Scaffold(body: Text('Post details ${childVersion.value}')),
    );
    router.push(AppRoutes.postPath('fixture'));
    await tester.pumpAndSettle();
    expect(find.text('Post details 1'), findsOneWidget);

    childVersion.value++;
    await tester.pumpAndSettle();

    expect(router.canPop(), isTrue);
    expect(find.text('Post details 2'), findsOneWidget);
  });

  testWidgets('page route honors the owning theme transition builder', (
    tester,
  ) async {
    const transitionTheme = PageTransitionsTheme(
      builders: {TargetPlatform.iOS: _FadingThemeTransitions()},
    );
    final router = await _pumpRoutes(
      tester,
      platform: TargetPlatform.iOS,
      disableAnimations: false,
      pageTransitionsTheme: transitionTheme,
    );

    router.push(AppRoutes.postPath('fixture'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final transitions = tester.widgetList<FadeTransition>(
      find.byKey(const ValueKey('theme-owned-transition')),
    );
    expect(
      transitions.any(
        (transition) =>
            transition.opacity.value > 0 && transition.opacity.value < 1,
      ),
      isTrue,
    );
  });
}
