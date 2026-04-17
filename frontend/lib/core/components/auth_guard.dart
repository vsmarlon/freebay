import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

class AuthGuard extends ConsumerWidget {
  final Widget child;
  final String featureName;

  const AuthGuard({
    super.key,
    required this.child,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;

    if (user == null || user.isGuest) {
      return _buildWithSkeleton(context);
    }

    return child;
  }

  Widget _buildWithSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        AbsorbPointer(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.5),
              BlendMode.srcOver,
            ),
            child: Opacity(
              opacity: 0.3,
              child: child,
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  _getFeatureIcon(),
                  color: isDark ? AppColors.white : AppColors.darkGray,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Faça login para acessar $featureName',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.white : AppColors.darkGray,
                        ),
                      ),
                      Text(
                        'Entre ou cadastre-se',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.brutalistGradient,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/login'),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Entrar',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getFeatureIcon() {
    switch (featureName.toLowerCase()) {
      case 'carteira':
        return Icons.account_balance_wallet_outlined;
      case 'chat':
        return Icons.chat_bubble_outline;
      default:
        return Icons.lock_outline;
    }
  }
}
