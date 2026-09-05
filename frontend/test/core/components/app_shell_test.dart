import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_shell.dart';
import 'package:freebay/core/components/app_shell_scaffold_key.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

class _SignedOutAuth extends AuthController {
  @override
  AsyncValue<UserEntity?> build() => const AsyncValue.data(null);
}

const _labels = ['ALPHA', 'BRAVO', 'CHARLIE', 'DELTA', 'ECHO'];

StatefulShellBranch _branch(String path, String label) => StatefulShellBranch(
  routes: [
    GoRoute(
      path: path,
      builder: (_, _) => Scaffold(body: Center(child: Text(label))),
    ),
  ],
);

Widget _app() {
  final router = GoRouter(
    initialLocation: '/b0',
    routes: [
      StatefulShellRoute(
        builder: (context, state, navigationShell) => navigationShell,
        navigatorContainerBuilder: (context, navigationShell, children) =>
            AppShell(navigationShell: navigationShell, branches: children),
        branches: [
          for (var i = 0; i < _labels.length; i++) _branch('/b$i', _labels[i]),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [authControllerProvider.overrideWith(_SignedOutAuth.new)],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('starts on the first branch', (tester) async {
    await tester.pumpWidget(_app());
    await _settle(tester);

    expect(find.text('ALPHA'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('dragging left advances one branch, not several', (tester) async {
    await tester.pumpWidget(_app());
    await _settle(tester);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await _settle(tester);

    expect(find.text('BRAVO'), findsOneWidget);
    expect(find.text('ALPHA'), findsNothing);
  });

  testWidgets('a slow drag right goes back, never forward', (tester) async {
    await tester.pumpWidget(_app());
    await _settle(tester);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await _settle(tester);
    expect(find.text('BRAVO'), findsOneWidget);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    for (var i = 0; i < 20; i++) {
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 40));
    }
    await gesture.up();
    await _settle(tester);

    expect(find.text('ALPHA'), findsOneWidget);
    expect(find.text('CHARLIE'), findsNothing);
  });

  testWidgets('tapping a nav destination switches branch', (tester) async {
    await tester.pumpWidget(_app());
    await _settle(tester);

    await tester.tap(find.text('CARTEIRA'));
    await _settle(tester);

    expect(find.text('CHARLIE'), findsOneWidget);
  });

  testWidgets('over-swiping right on the first branch opens the drawer', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await _settle(tester);

    expect(appShellScaffoldKey.currentState?.isDrawerOpen, isFalse);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await _settle(tester);

    expect(appShellScaffoldKey.currentState?.isDrawerOpen, isTrue);
  });
}
