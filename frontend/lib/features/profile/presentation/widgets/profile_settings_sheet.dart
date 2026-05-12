import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/brutalist_bottom_sheet.dart';
import 'package:freebay/core/providers/theme_provider.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/shared/services/biometry_service.dart';

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
                trailing: PopupMenuButton<ThemeMode>(
                  icon: const Icon(Icons.chevron_right,
                      color: AppColors.mediumGray),
                  onSelected: (mode) {
                    consumerRef
                        .read(themeModeProvider.notifier)
                        .setTheme(mode);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: ThemeMode.system, child: Text('Sistema')),
                    const PopupMenuItem(
                        value: ThemeMode.light, child: Text('Claro')),
                    const PopupMenuItem(
                        value: ThemeMode.dark, child: Text('Escuro')),
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
                  future:
                      consumerRef.read(biometryServiceProvider).isEnabled(),
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
                        activeTrackColor: AppColors.primaryPurple,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              const SizedBox(height: 16),
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
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Ajuda e suporte'),
                      content: const Text(
                        'Em caso de dúvidas ou problemas, entre em contato:\n\nmarlonstein260404@gmail.com',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      );
    },
  );
}