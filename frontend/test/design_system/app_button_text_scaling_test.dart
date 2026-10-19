import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay_design_system/components/app_button.dart';

void main() {
  testWidgets('button sizes and tap behavior remain unchanged', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppButton(label: 'Standard', onPressed: () => tapped = true),
              const AppButton(label: 'Compact', size: AppButtonSize.compact),
              const AppButton(label: 'Large', size: AppButtonSize.large),
            ],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AppButton).at(0)).height, 48);
    expect(tester.getSize(find.byType(AppButton).at(1)).height, 36);
    expect(tester.getSize(find.byType(AppButton).at(2)).height, 56);
    await tester.tap(find.text('Standard'));
    expect(tapped, isTrue);
  });

  testWidgets('large text keeps button labels visible without overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Column(
              children: [
                AppButton(label: 'MELHORES AMIGOS'),
                AppButton(label: 'MELHORES AMIGOS', size: AppButtonSize.large),
                AppButton(
                  label: 'MELHORES AMIGOS',
                  size: AppButtonSize.compact,
                ),
                AppButton(label: 'MELHORES AMIGOS', icon: Icons.send),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('MELHORES AMIGOS'), findsNWidgets(4));
    for (final text in tester.widgetList<Text>(find.text('MELHORES AMIGOS'))) {
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      expect(text.maxLines, isNull);
    }
    expect(find.text('MELHORES AMIGOS'), findsNWidgets(4));
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
