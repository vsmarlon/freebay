import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay_design_system/components/app_button.dart';

void main() {
  testWidgets('narrow labels ellipsize without losing their semantic label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.1)),
          child: Scaffold(
            body: Column(
              children: [
                AppButton(label: 'MELHORES AMIGOS', width: 180),
                AppButton(
                  label: 'MELHORES AMIGOS',
                  icon: Icons.send,
                  width: 180,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('MELHORES AMIGOS'), findsNWidgets(2));
  });
}
