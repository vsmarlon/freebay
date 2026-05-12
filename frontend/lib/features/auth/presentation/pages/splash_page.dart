import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/core/theme/app_colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Timer? _animationTimer;
  Timer? _authCheckTimer;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.linear,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.linear,
    ));
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    _animationTimer = Timer(const Duration(milliseconds: 50), () {
      _fadeController.forward();
      _slideController.forward();
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    final tokenFuture = StorageService.getToken();
    final isGuestFuture = StorageService.getIsGuest();

    _authCheckTimer = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      final token = await tokenFuture;
      final isGuest = await isGuestFuture;
      if (!mounted) return;

      if (token != null || isGuest) {
        context.go('/feed');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _authCheckTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.brutalistGradient,
        ),
        child: Stack(
          children: [
            _BrutalistGrid(),
            _GridLines(),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildMainContent(),
                  ),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: const SizedBox(width: 80),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              'SYSTEM STATUS: ACTIVE',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.15,
                color: Colors.white.withAlpha(102),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE MARKETPLACE REBUILT',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: Colors.white.withAlpha(179),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.white, Colors.white.withAlpha(230)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: Text(
                      'freebay',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 72,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                        height: 0.9,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 2
                          ..color = Colors.white.withAlpha(204),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TRADE YOUR WORLD',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: Colors.white.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _BrutalistButton(
                label: 'GET STARTED',
                icon: Icons.arrow_forward,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.go('/login');
                },
              ),
            ),
          ),
          const SizedBox(height: 48),
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildStats(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        const Expanded(child: _StatBlock(value: '0%', label: 'Trading Fees')),
        Container(
          width: 1, height: 40,
          color: Colors.white.withAlpha(26),
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),
        const Expanded(child: _StatBlock(value: 'Instant', label: 'Verification')),
        Container(
          width: 1, height: 40,
          color: Colors.white.withAlpha(26),
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),
        const Expanded(child: _StatBlock(value: 'Global', label: 'Reach Access')),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withAlpha(51),
                border: Border.all(
                  color: Colors.white.withAlpha(51),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.token,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'v1.0.0',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
                color: Colors.white.withAlpha(77),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrutalistGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.03,
        child: CustomPaint(
          painter: _GridPainter(),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    const gridSize = 40.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridLines extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: MediaQuery.of(context).size.width * 0.25,
          top: 0,
          bottom: 0,
          child: Container(
            width: 1,
            color: Colors.white.withAlpha(13),
          ),
        ),
        Positioned(
          left: MediaQuery.of(context).size.width * 0.5,
          top: 0,
          bottom: 0,
          child: Container(
            width: 1,
            color: Colors.white.withAlpha(13),
          ),
        ),
        Positioned(
          left: MediaQuery.of(context).size.width * 0.75,
          top: 0,
          bottom: 0,
          child: Container(
            width: 1,
            color: Colors.white.withAlpha(13),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.33,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            color: Colors.white.withAlpha(13),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.66,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            color: Colors.white.withAlpha(13),
          ),
        ),
      ],
    );
  }
}

class _BrutalistButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _BrutalistButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_BrutalistButton> createState() => _BrutalistButtonState();
}

class _BrutalistButtonState extends State<_BrutalistButton> {
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
        duration: const Duration(milliseconds: 150),
        curve: Curves.linear,
        transform: Matrix4.translationValues(
          _isPressed ? 2 : 0,
          _isPressed ? 2 : 0,
          0,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: _isPressed ? Colors.black : Colors.white,
            border: Border.all(
              color: _isPressed ? Colors.white : Colors.black,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  color: _isPressed ? Colors.white : Colors.black,
                ),
              ),
              Icon(
                widget.icon,
                size: 20,
                color: _isPressed ? Colors.white : Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;

  const _StatBlock({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
            color: Colors.white.withAlpha(128),
          ),
        ),
      ],
    );
  }
}
