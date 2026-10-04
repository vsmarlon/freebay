import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay_design_system/components/brutalist_icon_button.dart';
import 'package:freebay_design_system/components/shimmer_skeleton.dart';
import 'package:freebay_design_system/tokens/app_colors.dart';
import 'package:freebay_design_system/tokens/app_theme.dart';

void main() {
  testWidgets('a skeleton list shares one repeating animation ticker', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SkeletonList(itemCount: 4, itemBuilder: _buildSkeleton),
      ),
    );

    expect(tester.binding.transientCallbackCount, 1);
  });

  testWidgets('nested skeleton page and list reuse the page clock', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SkeletonPage(
          child: SkeletonList(itemCount: 3, itemBuilder: _buildSkeleton),
        ),
      ),
    );

    expect(tester.binding.transientCallbackCount, 1);
  });

  testWidgets('a skeleton outside a scope does not animate', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShimmerBlock(height: 12)));

    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('reduced motion disables the shared shimmer clock', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: SkeletonList(itemCount: 3, itemBuilder: _buildSkeleton),
        ),
      ),
    );

    expect(tester.binding.transientCallbackCount, 0);
  });

  test('dark primary foreground and action fill keep separate roles', () {
    expect(AppTheme.dark.colorScheme.primary, AppColors.primaryForeground);
    expect(
      AppTheme.dark.colorScheme.primaryContainer,
      AppColors.primaryContainer,
    );
    expect(AppTheme.dark.colorScheme.onPrimaryContainer, AppColors.white);
  });

  testWidgets('icon button is exposed as an accessible button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: Row(
            children: [
              BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: 'Voltar',
                size: 24,
                onTap: _noop,
              ),
              BrutalistIconButton(icon: Icons.close, semanticLabel: 'Fechar'),
            ],
          ),
        ),
      ),
    );

    final enabled = tester.getSemantics(find.byType(BrutalistIconButton).first);
    expect(enabled.flagsCollection.isButton, isTrue);
    expect(enabled.label, 'Voltar');
    expect(enabled.flagsCollection.isEnabled, Tristate.isTrue);
    expect(enabled.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(tester.getSize(find.byType(BrutalistIconButton).first).width, 48);

    final disabled = tester.getSemantics(find.byType(BrutalistIconButton).last);
    expect(disabled.label, 'Fechar');
    expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
    expect(disabled.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
  });
}

Widget _buildSkeleton(BuildContext context, int index) {
  return const ShimmerBlock(height: 12);
}

void _noop() {}
