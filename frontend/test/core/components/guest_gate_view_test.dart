import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

void main() {
  testWidgets('guest gate keeps its content inside a brutalist card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GuestGateView(
            icon: Icons.person_outline,
            title: 'PERFIL',
            description: 'Faça login para continuar.',
          ),
        ),
      ),
    );

    expect(find.text('PERFIL'), findsOneWidget);
    expect(find.byType(BrutalistBox), findsOneWidget);
  });
}
