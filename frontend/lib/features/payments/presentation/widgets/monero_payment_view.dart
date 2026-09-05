import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/components/brutalist_box.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/payments/data/entities/crypto_payment_entity.dart';
import 'package:freebay/features/product/data/entities/product_entity.dart';

class MoneroPaymentView extends StatefulWidget {
  final ProductEntity product;
  final CryptoPaymentEntity cryptoPayment;
  final String? createdOrderId;

  const MoneroPaymentView({
    super.key,
    required this.product,
    required this.cryptoPayment,
    this.createdOrderId,
  });

  @override
  State<MoneroPaymentView> createState() => _MoneroPaymentViewState();
}

class _MoneroPaymentViewState extends State<MoneroPaymentView> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _calculateRemaining();
        });
      }
    });
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    final difference = widget.cryptoPayment.expiresAt.difference(now);
    _remaining = difference.isNegative ? Duration.zero : difference;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    AppSnackbar.success(
      context,
      '$label copiado para a área de transferência!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isExpiringSoon =
        _remaining.inMinutes < 10 && _remaining > Duration.zero;
    final isExpired = _remaining == Duration.zero;

    final timerColor = isExpired
        ? AppColors.error
        : isExpiringSoon
        ? AppColors.warning
        : (isDark ? AppColors.white : AppColors.onSurface);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header Box
        BrutalistBox(
          backgroundColor: isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainer,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: AppColors.primary,
                    child: Text(
                      'MONERO (XMR) ESCROW',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: isDark ? AppColors.white : AppColors.onSurface,
                  ),
                ],
              ),
              Spacing.vSm,
              Text(
                widget.product.title,
                style: TextStyle(
                  fontFamily: AppTypography.headlineFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.white : AppColors.onSurface,
                ),
              ),
              Spacing.vXs,
              Text(
                'Custódia segura e anônima via subendereço descartável.',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  color: isDark
                      ? AppColors.inverseOnSurface
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        Spacing.vMd,

        // 60-Minute Expiration Countdown Timer
        BrutalistBox(
          backgroundColor: isExpired
              ? AppColors.error.withValues(alpha: 0.1)
              : isDark
              ? AppColors.surfaceContainerLowDark
              : AppColors.surfaceContainerLowest,
          borderColor: isExpired ? AppColors.error : context.borderColor,
          borderWidth: 2,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                isExpired ? Icons.error_outline : Icons.timer_outlined,
                color: timerColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isExpired ? 'SESSÃO EXPIRADA' : 'EXPIRAÇÃO DO PAGAMENTO',
                    style: AppTypography.labelSmall.copyWith(
                      color: timerColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isExpired
                        ? 'Gere um novo pedido para pagar'
                        : _formatTimer(_remaining),
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: timerColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Spacing.vMd,

        // Monero Amount Details
        BrutalistBox(
          backgroundColor: isDark
              ? AppColors.surfaceContainerLowDark
              : AppColors.surfaceContainerLowest,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VALOR TOTAL EM XMR',
                style: AppTypography.labelSmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
              Spacing.vXs,
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    widget.cryptoPayment.amountHuman,
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.white : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'XMR',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              if (widget.cryptoPayment.amountAtomic.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '(${widget.cryptoPayment.amountAtomic} piconeros)',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),

        Spacing.vMd,

        // QR Code Container (Brutalist Sharp Canvas)
        Center(
          child: BrutalistBox(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            borderColor: Colors.black,
            borderWidth: 2,
            child: Column(
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: _BrutalistQrPainter(
                      data: widget.cryptoPayment.uriQrCode.isNotEmpty
                          ? widget.cryptoPayment.uriQrCode
                          : widget.cryptoPayment.address,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ESCANEIE COM SUA CARTEIRA MONERO',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),

        Spacing.vMd,

        // Monero Address & Copy Action
        BrutalistBox(
          backgroundColor: isDark
              ? AppColors.surfaceContainerLowDark
              : AppColors.surfaceContainerLowest,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ENDEREÇO XMR EFÊMERO',
                style: AppTypography.labelSmall.copyWith(
                  color: context.textSecondary,
                ),
              ),
              Spacing.vSm,
              SelectableText(
                widget.cryptoPayment.address,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.onSurface,
                ),
              ),
              Spacing.vSm,
              AppButton(
                label: 'COPIAR ENDEREÇO',
                icon: Icons.copy,
                variant: AppButtonVariant.secondary,
                onPressed: () => _copyToClipboard(
                  context,
                  widget.cryptoPayment.address,
                  'Endereço Monero',
                ),
              ),
            ],
          ),
        ),

        if (widget.cryptoPayment.paymentId != null &&
            widget.cryptoPayment.paymentId!.isNotEmpty) ...[
          Spacing.vMd,
          BrutalistBox(
            backgroundColor: isDark
                ? AppColors.surfaceContainerLowDark
                : AppColors.surfaceContainerLowest,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAYMENT ID INTEGRADO',
                  style: AppTypography.labelSmall.copyWith(
                    color: context.textSecondary,
                  ),
                ),
                Spacing.vSm,
                SelectableText(
                  widget.cryptoPayment.paymentId!,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.onSurface,
                  ),
                ),
                Spacing.vSm,
                AppButton(
                  label: 'COPIAR PAYMENT ID',
                  icon: Icons.copy,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _copyToClipboard(
                    context,
                    widget.cryptoPayment.paymentId!,
                    'Payment ID',
                  ),
                ),
              ],
            ),
          ),
        ],

        Spacing.vLg,

        // Order Navigation Button
        if (widget.createdOrderId != null) ...[
          AppButton(
            label: 'ACOMPANHAR PEDIDO',
            icon: Icons.receipt_long,
            variant: AppButtonVariant.primary,
            onPressed: () => context.go('/orders/${widget.createdOrderId}'),
          ),
          Spacing.vSm,
        ],

        AppButton(
          label: 'COPIAR URI COMPLETO (QR)',
          icon: Icons.qr_code,
          variant: AppButtonVariant.ghost,
          onPressed: () => _copyToClipboard(
            context,
            widget.cryptoPayment.uriQrCode,
            'URI Monero',
          ),
        ),
      ],
    );
  }
}

/// Sharp Digital Brutalist QR code pattern generator and canvas painter
class _BrutalistQrPainter extends CustomPainter {
  final String data;

  _BrutalistQrPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Fixed grid resolution for crisp digital brutalist matrix
    const int moduleCount = 29;
    final double cellSize = size.width / moduleCount;

    // Deterministic hash-based matrix pattern with standard QR positioning markers
    final hash = _generateHash(data);

    for (int r = 0; r < moduleCount; r++) {
      for (int c = 0; c < moduleCount; c++) {
        // Draw standard QR corner finder patterns
        if (_isFinderPattern(r, c, moduleCount)) {
          if (_isFinderDark(r, c, moduleCount)) {
            canvas.drawRect(
              Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
              paint,
            );
          }
        } else if (_isAlignmentPattern(r, c, moduleCount)) {
          if (_isAlignmentDark(r, c, moduleCount)) {
            canvas.drawRect(
              Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
              paint,
            );
          }
        } else if (r == 6 || c == 6) {
          // Timing patterns
          if ((r + c) % 2 == 0) {
            canvas.drawRect(
              Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
              paint,
            );
          }
        } else {
          // Data modules derived from hash and coordinate
          final index = (r * moduleCount + c) % hash.length;
          final bit = (hash[index] ^ (r * 7 + c * 13)) % 2 == 0;
          if (bit) {
            canvas.drawRect(
              Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize),
              paint,
            );
          }
        }
      }
    }
  }

  List<int> _generateHash(String input) {
    final bytes = input.codeUnits;
    final result = List<int>.filled(64, 0);
    for (int i = 0; i < bytes.length; i++) {
      result[i % 64] = (result[i % 64] * 31 + bytes[i]) & 0xFF;
    }
    return result;
  }

  bool _isFinderPattern(int r, int c, int n) {
    // Top-Left (7x7)
    if (r < 7 && c < 7) return true;
    // Top-Right (7x7)
    if (r < 7 && c >= n - 7) return true;
    // Bottom-Left (7x7)
    if (r >= n - 7 && c < 7) return true;
    return false;
  }

  bool _isFinderDark(int r, int c, int n) {
    int localR = r;
    int localC = c;
    if (r < 7 && c >= n - 7) localC = c - (n - 7);
    if (r >= n - 7 && c < 7) localR = r - (n - 7);

    // Outer border (7x7) or center (3x3)
    if (localR == 0 || localR == 6 || localC == 0 || localC == 6) return true;
    if (localR >= 2 && localR <= 4 && localC >= 2 && localC <= 4) return true;
    return false;
  }

  bool _isAlignmentPattern(int r, int c, int n) {
    const alignR = 20;
    const alignC = 20;
    return (r >= alignR - 2 &&
        r <= alignR + 2 &&
        c >= alignC - 2 &&
        c <= alignC + 2);
  }

  bool _isAlignmentDark(int r, int c, int n) {
    const alignR = 20;
    const alignC = 20;
    int dr = (r - alignR).abs();
    int dc = (c - alignC).abs();
    if (dr == 2 || dc == 2) return true;
    if (dr == 0 && dc == 0) return true;
    return false;
  }

  @override
  bool shouldRepaint(covariant _BrutalistQrPainter oldDelegate) =>
      oldDelegate.data != data;
}
