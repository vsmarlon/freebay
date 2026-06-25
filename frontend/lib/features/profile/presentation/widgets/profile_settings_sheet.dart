import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/brutalist_bottom_sheet.dart';
import 'package:freebay/core/providers/theme_provider.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/shared/services/biometry_service.dart';
import 'package:freebay/core/components/spacing.dart';

final biometryServiceProvider = Provider<BiometryService>((ref) {
  return BiometryService();
});

void showProfileSettingsSheet(BuildContext context) {
  showBrutalistSheet(
    context: context,
    title: 'Configurações',
    builder: (sheetContext) {
      return Consumer(
        builder: (consumerContext, consumerRef, _) {
          final currentThemeMode = consumerRef.watch(themeModeProvider);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(
                  currentThemeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : currentThemeMode == ThemeMode.light
                          ? Icons.light_mode
                          : Icons.brightness_auto,
                  color: consumerContext.textPrimary,
                ),
                title: Text(
                  'Tema',
                  style: TextStyle(
                    color: consumerContext.textPrimary,
                  ),
                ),
                subtitle: Text(
                  currentThemeMode == ThemeMode.dark
                      ? 'Escuro'
                      : currentThemeMode == ThemeMode.light
                          ? 'Claro'
                          : 'Sistema',
                  style: const TextStyle(color: AppColors.mediumGray),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ThemeOption(
                      label: 'S',
                      isSelected: currentThemeMode == ThemeMode.system,
                      onTap: () => consumerRef
                          .read(themeModeProvider.notifier)
                          .setTheme(ThemeMode.system),
                    ),
                    const SizedBox(width: 4),
                    _ThemeOption(
                      label: 'L',
                      isSelected: currentThemeMode == ThemeMode.light,
                      onTap: () => consumerRef
                          .read(themeModeProvider.notifier)
                          .setTheme(ThemeMode.light),
                    ),
                    const SizedBox(width: 4),
                    _ThemeOption(
                      label: 'D',
                      isSelected: currentThemeMode == ThemeMode.dark,
                      onTap: () => consumerRef
                          .read(themeModeProvider.notifier)
                          .setTheme(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.fingerprint,
                  color: consumerContext.textPrimary,
                ),
                title: Text(
                  'Biometria',
                  style: TextStyle(
                    color: consumerContext.textPrimary,
                  ),
                ),
                subtitle: FutureBuilder<bool>(
                  future:
                      consumerRef.read(biometryServiceProvider).isAvailable(),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return const Text(
                        'Usar biometria para login',
                        style: TextStyle(color: AppColors.mediumGray),
                      );
                    }
                    return const Text(
                      'Não disponível no dispositivo',
                      style: TextStyle(color: AppColors.mediumGray),
                    );
                  },
                ),
                trailing: FutureBuilder<bool>(
                  future: consumerRef.read(biometryServiceProvider).isEnabled(),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return Switch(
                        value: snapshot.data ?? false,
                        onChanged: (value) async {
                          await consumerRef
                              .read(biometryServiceProvider)
                              .setEnabled(value);
                          consumerRef.invalidate(biometryServiceProvider);
                        },
                        activeTrackColor: AppColors.primaryContainer,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              Spacing.vMd,
              ListTile(
                leading: Icon(
                  Icons.edit,
                  color: consumerContext.textPrimary,
                ),
                title: Text(
                  'Editar perfil',
                  style: TextStyle(
                    color: consumerContext.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(consumerContext);
                  context.push('/profile/edit');
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.help_outline,
                  color: consumerContext.textPrimary,
                ),
                title: Text(
                  'Ajuda e suporte',
                  style: TextStyle(
                    color: consumerContext.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(consumerContext);
                  showBrutalistSheet(
                    context: context,
                    title: 'Ajuda e suporte',
                    builder: (sheetContext) {
                      return Consumer(
                        builder: (consumerContext, consumerRef, _) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Em caso de dúvidas ou problemas, acesse o centro de ajuda:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.mediumGray,
                                  ),
                                ),
                                Spacing.vLg,
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    context.push('/faq');
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      gradient: AppColors.brutalistGradient,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Central de ajuda',
                                        style: TextStyle(
                                          color: AppColors.onPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Spacing.vSm,
                                InkWell(
                                  onTap: () => Navigator.pop(sheetContext),
                                  child: Container(
                                    width: double.infinity,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.onSurface,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Fechar',
                                        style: TextStyle(
                                          color: AppColors.onSurface,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              Spacing.vMd,
            ],
          );
        },
      );
    },
  );
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          border: Border.all(
            color:
                isSelected ? AppColors.primaryContainer : context.borderColor,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.onPrimary : context.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
