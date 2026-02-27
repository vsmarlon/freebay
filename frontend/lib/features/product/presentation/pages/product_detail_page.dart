import 'package:flutter/material.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/theme/app_colors.dart';

class ProductDetailPage extends StatelessWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryPurpleLight,
                          AppColors.accentGreenLight
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.image, size: 64, color: Colors.white54),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.photo_library,
                              color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('4', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black38 : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back,
                    color: isDark ? Colors.white : Colors.black),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black38 : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.share,
                      color: isDark ? Colors.white : Colors.black),
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black38 : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.favorite_border,
                      color: isDark ? Colors.white : Colors.black),
                ),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'iPhone 14 Pro Max 256GB',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NOVO',
                          style: TextStyle(
                            color: AppColors.accentGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.location_on,
                          size: 16,
                          color: isDark
                              ? AppColors.mediumGray
                              : AppColors.mediumGray),
                      const SizedBox(width: 4),
                      Text(
                        'São Paulo, SP',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.mediumGray
                              : AppColors.mediumGray,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'R\$ 4.500,00',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.accentGreenLight
                          : AppColors.accentGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Você recebe: R\$ 4.140,00 após a taxa de 8%',
                    style: TextStyle(
                      color:
                          isDark ? AppColors.mediumGray : AppColors.mediumGray,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Descrição',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.white : AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'iPhone 14 Pro Max em perfeito estado. Bateria com 95% de saúde, sem riscos ou batidas. Acompanha caixa original, carregador e cabo. '
                    'Produto Lacrado. Qualidade garantida!',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.white.withAlpha(204)
                          : AppColors.darkGray.withAlpha(204),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryPurple.withAlpha(25),
                        child: const Icon(Icons.person,
                            color: AppColors.primaryPurple),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Maria Silva',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.white
                                        : AppColors.darkGray,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.verified,
                                    color: AppColors.primaryPurple, size: 16),
                              ],
                            ),
                            Text(
                              '4.8 ★ (120 vendas)',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.mediumGray
                                    : AppColors.mediumGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Ver perfil'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Comprar agora',
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
