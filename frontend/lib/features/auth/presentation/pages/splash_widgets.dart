import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

class SplashGetStartedButton extends StatefulWidget {
  final VoidCallback onTap;
  const SplashGetStartedButton({super.key, required this.onTap});

  @override
  State<SplashGetStartedButton> createState() => _SplashGetStartedButtonState();
}

class _SplashGetStartedButtonState extends State<SplashGetStartedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: AppMotion.tap,
        transform: Matrix4.translationValues(
          _isPressed ? AppDepth.pressOffset : 0.0,
          _isPressed ? AppDepth.pressOffset : 0.0,
          0,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: _isPressed
              ? []
              : AppDepth.hard(AppColors.primaryContainer),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'GET STARTED',
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: Colors.black,
              ),
            ),
            Icon(Icons.arrow_forward, size: 22, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

class SplashStatBlock extends StatelessWidget {
  final String value;
  final String label;

  const SplashStatBlock({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTypography.headlineFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
        Spacing.vXs,
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.onSurfaceVariantDark,
          ),
        ),
      ],
    );
  }
}
