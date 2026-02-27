import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/core/providers/theme_provider.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/shared/services/biometry_service.dart';

final biometryServiceProvider = Provider<BiometryService>((ref) {
  return BiometryService();
});

class ProfilePage extends HookConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final isGuest = authState.valueOrNull?.isGuest ?? false;

    if (isGuest) {
      return _buildGuestProfile(context, ref, isDark);
    }

    final profileAsync = ref.watch(profileFutureProvider('me'));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? AppColors.white : AppColors.darkGray,
            ),
            onPressed: () => _showSettingsSheet(context, ref, isDark),
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.brightness_6,
              color: isDark ? AppColors.white : AppColors.darkGray,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (user) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _showStoriesSheet(context, ref, isDark),
                  child: Stack(
                    children: [
                      UserAvatar(
                        imageUrl: user.avatarUrl,
                        isVerified: user.isVerified,
                        size: AppAvatarSize.large,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: AppColors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.displayName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.black,
                  ),
                ),
                if (user.city != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: isDark
                            ? AppColors.mediumGray
                            : AppColors.mediumGray,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.city!,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.mediumGray
                              : AppColors.mediumGray,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (user.bio != null)
                  Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.white.withAlpha(204)
                          : AppColors.darkGray.withAlpha(204),
                      fontSize: 16,
                    ),
                  ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCol(
                        'Reputação', '${user.reputationScore} ★', isDark),
                    _buildStatCol('Vendas', '12', isDark),
                    _buildStatCol('Compras', '5', isDark),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.grid_view_rounded,
                        label: 'Meus posts',
                        onTap: () => context.push('/profile/posts'),
                        isDark: isDark,
                      ),
                      _buildMenuItem(
                        icon: Icons.auto_awesome,
                        label: 'Meus stories',
                        onTap: () => context.push('/profile/stories'),
                        isDark: isDark,
                      ),
                      _buildMenuItem(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Meus anúncios',
                        onTap: () => context.push('/profile/products'),
                        isDark: isDark,
                      ),
                      _buildMenuItem(
                        icon: Icons.favorite_outline,
                        label: 'Favoritos',
                        onTap: () => context.push('/profile/favorites'),
                        isDark: isDark,
                      ),
                      _buildMenuItem(
                        icon: Icons.favorite_border,
                        label: 'Posts curtidos',
                        onTap: () => context.push('/profile/liked'),
                        isDark: isDark,
                      ),
                      _buildMenuItem(
                        icon: Icons.bookmark_outline,
                        label: 'Salvos',
                        onTap: () => context.push('/profile/saved'),
                        isDark: isDark,
                      ),
                      const Divider(),
                      _buildMenuItem(
                        icon: Icons.shopping_cart_outlined,
                        label: 'Carrinho',
                        onTap: () => context.push('/cart'),
                        isDark: isDark,
                      ),
                      _buildMenuItem(
                        icon: Icons.bookmark_border,
                        label: 'Lista de desejos',
                        onTap: () => context.push('/profile/wishlist'),
                        isDark: isDark,
                      ),
                      const Divider(),
                      _buildMenuItem(
                        icon: Icons.history,
                        label: 'Histórico de compras',
                        onTap: () => context.push('/profile/purchases'),
                        isDark: isDark,
                      ),
                      _buildMenuItem(
                        icon: Icons.credit_card,
                        label: 'Métodos de pagamento',
                        onTap: () => context.push('/profile/payment'),
                        isDark: isDark,
                      ),
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notificações',
                        onTap: () => context.push('/profile/notifications'),
                        isDark: isDark,
                      ),
                      const Divider(),
                      _buildMenuItem(
                        icon: Icons.logout,
                        label: 'Sair',
                        onTap: () {
                          ref.read(authControllerProvider.notifier).logout();
                          context.go('/login');
                        },
                        isDark: isDark,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
              color: isDark
                  ? AppColors.primaryPurpleLight
                  : AppColors.primaryPurple),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar perfil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Não foi possível carregar suas informações. Verifique sua conexão.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color:
                isDark ? AppColors.primaryPurpleLight : AppColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? AppColors.error
            : (isDark ? AppColors.white : AppColors.darkGray),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDestructive
              ? AppColors.error
              : (isDark ? AppColors.white : AppColors.darkGray),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
      ),
      onTap: onTap,
    );
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (consumerContext, consumerRef, _) {
            final currentThemeMode = consumerRef.watch(themeModeProvider);
            final sheetIsDark =
                Theme.of(consumerContext).brightness == Brightness.dark;

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.mediumGray.withAlpha(77),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Configurações',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          sheetIsDark ? AppColors.white : AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: Icon(
                      currentThemeMode == ThemeMode.dark
                          ? Icons.dark_mode
                          : currentThemeMode == ThemeMode.light
                              ? Icons.light_mode
                              : Icons.brightness_auto,
                      color:
                          sheetIsDark ? AppColors.white : AppColors.darkGray,
                    ),
                    title: Text(
                      'Tema',
                      style: TextStyle(
                        color:
                            sheetIsDark ? AppColors.white : AppColors.darkGray,
                      ),
                    ),
                    subtitle: Text(
                      currentThemeMode == ThemeMode.dark
                          ? 'Escuro'
                          : currentThemeMode == ThemeMode.light
                              ? 'Claro'
                              : 'Sistema',
                      style: const TextStyle(
                        color: AppColors.mediumGray,
                      ),
                    ),
                    trailing: PopupMenuButton<ThemeMode>(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: AppColors.mediumGray,
                      ),
                      onSelected: (mode) {
                        consumerRef
                            .read(themeModeProvider.notifier)
                            .setTheme(mode);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: ThemeMode.system,
                          child: Text('Sistema'),
                        ),
                        const PopupMenuItem(
                          value: ThemeMode.light,
                          child: Text('Claro'),
                        ),
                        const PopupMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Escuro'),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.fingerprint,
                      color:
                          sheetIsDark ? AppColors.white : AppColors.darkGray,
                    ),
                    title: Text(
                      'Biometria',
                      style: TextStyle(
                        color:
                            sheetIsDark ? AppColors.white : AppColors.darkGray,
                      ),
                    ),
                    subtitle: FutureBuilder<bool>(
                      future: consumerRef
                          .read(biometryServiceProvider)
                          .isAvailable(),
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
                      future: consumerRef
                          .read(biometryServiceProvider)
                          .isAvailable(),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return Switch(
                            value: false,
                            onChanged: (value) async {
                              await consumerRef
                                  .read(biometryServiceProvider)
                                  .setEnabled(value);
                            },
                            activeTrackColor: AppColors.primaryPurple,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.edit,
                      color:
                          sheetIsDark ? AppColors.white : AppColors.darkGray,
                    ),
                    title: Text(
                      'Editar perfil',
                      style: TextStyle(
                        color:
                            sheetIsDark ? AppColors.white : AppColors.darkGray,
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
                      color:
                          sheetIsDark ? AppColors.white : AppColors.darkGray,
                    ),
                    title: Text(
                      'Ajuda e suporte',
                      style: TextStyle(
                        color:
                            sheetIsDark ? AppColors.white : AppColors.darkGray,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(consumerContext);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStoriesSheet(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.mediumGray.withAlpha(77),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Suas histórias',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryPurple,
                        AppColors.primaryPurpleLight
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: AppColors.white,
                  ),
                ),
                title: Text(
                  'Criar história',
                  style: TextStyle(
                    color: isDark ? AppColors.white : AppColors.darkGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Compartilhe uma foto ou vídeo',
                  style: TextStyle(
                    color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/create-story');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuestProfile(BuildContext context, WidgetRef ref, bool isDark) {
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.brightness_6,
              color: isDark ? AppColors.white : AppColors.darkGray,
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
              Icon(
                Icons.person_outline,
                size: 80,
                color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
              ),
              const SizedBox(height: 24),
              Text(
                'Bem-vindo ao FreeBay!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Faça login ou cadastre-se para\nter acesso completo ao app',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Entrar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/register'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primaryPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cadastrar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
