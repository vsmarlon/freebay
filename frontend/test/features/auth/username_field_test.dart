import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/username_field.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class _LookupRepository extends AuthRepository {
  final requests = <String, Completer<Either<Failure, UsernameAvailability>>>{};

  @override
  Future<Either<Failure, UsernameAvailability>> checkUsernameAvailable(
    String username,
  ) {
    final request = Completer<Either<Failure, UsernameAvailability>>();
    requests[username] = request;
    return request.future;
  }
}

void main() {
  testWidgets('a slow lookup cannot replace the current username result', (
    tester,
  ) async {
    final repository = _LookupRepository();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Scaffold(
            body: Form(child: UsernameField(controller: controller)),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'alpha1');
    await tester.pump(usernameAvailabilityDebounce);
    expect(repository.requests.keys, contains('alpha1'));
    await tester.enterText(find.byType(TextFormField), 'bravo2');
    await tester.pump(usernameAvailabilityDebounce);
    expect(repository.requests.keys, contains('bravo2'));

    repository.requests['bravo2']!.complete(
      const Right((available: true, suggestions: [])),
    );
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    repository.requests['alpha1']!.complete(
      const Right((available: false, suggestions: [])),
    );
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsNothing);
  });

  testWidgets('a taken username offers selectable available alternatives', (
    tester,
  ) async {
    final repository = _LookupRepository();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Scaffold(
            body: Form(child: UsernameField(controller: controller)),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'alpha1');
    await tester.pump(usernameAvailabilityDebounce);
    repository.requests['alpha1']!.complete(
      const Right((available: false, suggestions: ['alpha1_1', 'alpha1_2'])),
    );
    await tester.pump();

    expect(find.text('@alpha1_1'), findsOneWidget);
    await tester.tap(find.text('@alpha1_1'));
    expect(controller.text, 'alpha1_1');
    await tester.pump(usernameAvailabilityDebounce);
    expect(repository.requests.keys, contains('alpha1_1'));
  });
}
