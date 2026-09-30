import 'package:flutter/material.dart';
import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/providers/theme_provider.dart';
import 'package:freebay/core/ui.dart';

class GuestProfileView extends ConsumerWidget {
  const GuestProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          ShellScrollHeader(
            child: PageHeader(
              text: 'PERFIL',
              actions: [
                GestureDetector(
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).toggleTheme(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: context.borderColor, width: 2),
                    ),
                    child: Icon(
                      context.isDark ? Icons.light_mode : Icons.brightness_6,
                      color: context.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 80,
                      color: AppColors.mediumGray,
                    ),
                    Spacing.vLg,
                    Text(
                      'Bem-vindo ao FreeBay!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Faça login ou cadastre-se para\nter acesso completo ao app',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.mediumGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Spacing.vXl,
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'Entrar',
                        onPressed: () => context.push(loginPathFrom(context)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: InkWell(
                        onTap: () => context.push(AppRoutes.register),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Cadastrar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryContainer,
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
          ),
        ],
      ),
    );
  }
}
