import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/components/empty_state.dart';

void main() {
  testWidgets('error state invokes retry action', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(home: EmptyState.error(onRetry: () => retried = true)),
    );

    await tester.tap(find.text('TENTAR NOVAMENTE'));

    expect(retried, isTrue);
  });
}
