import 'package:flutter/material.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/providers/background_provider.dart';

/// App-level background that honors the user's "Fundo animado" preference
/// from Configurações. Renders the animated aurora shader when enabled,
/// or one frozen aurora frame (same look, no per-frame cost) when disabled.
class AppBackground extends ConsumerWidget {
  final Widget child;
  final bool? forceDark;

  const AppBackground({required this.child, this.forceDark, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animated = ref.watch(backgroundAnimatedProvider);
    return BrutalistBackground(
      forceDark: forceDark,
      mode: animated
          ? BrutalistBackgroundMode.animated
          : BrutalistBackgroundMode.staticAurora,
      child: child,
    );
  }
}
