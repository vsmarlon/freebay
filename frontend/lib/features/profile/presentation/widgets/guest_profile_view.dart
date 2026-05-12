import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/providers/theme_provider.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';

class GuestProfileView extends ConsumerWidget {
  const GuestProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.appBarColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              context.isDark ? Icons.light_mode : Icons.brightness_6,
              color: context.textPrimary,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: Center(
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
              const SizedBox(height: 24),
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
                style: TextStyle(fontSize: 16, color: AppColors.mediumGray),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: InkWell(
                  onTap: () => context.go('/login'),
                  child: Container(
                    height: 52,
                    decoration:
                        const BoxDecoration(gradient: AppColors.brutalistGradient),
                    child: const Center(
                      child: Text(
                        'Entrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: InkWell(
                  onTap: () => context.go('/register'),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primaryPurple),
                    ),
                    child: const Center(
                      child: Text(
                        'Cadastrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPurple,
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
    );
  }
}
