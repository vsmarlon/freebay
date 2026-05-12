import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/components/app_card.dart';
import '../../../../core/components/app_dialog.dart';
import '../../../../core/components/app_text_field.dart';
import '../../../../core/components/empty_state.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../controllers/product_controller.dart';
import '../widgets/category_filter_panel.dart';

class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  final _searchController = TextEditingController();
  bool _showFilters = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchDebounced(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = query;
    });
  }

  void _onSearch() {
    _debounceTimer?.cancel();
    ref.read(searchQueryProvider.notifier).state = _searchController.text;
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final productsAsync = ref.watch(productsFeedProvider(
      GetProductsParams(
        search: searchQuery.isEmpty ? null : searchQuery,
        category: selectedCategory,
      ),
    ));

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(
          'Explorar',
          style: TextStyle(
            color: context.isDark ? AppColors.white : AppColors.primaryPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.appBarColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: context.isDark ? AppColors.white : AppColors.primaryPurple,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppTextField(
              controller: _searchController,
              label: '',
              hint: 'Buscar produtos...',
              prefixIcon: Icons.search,
              onFieldSubmitted: (_) => _onSearch(),
              onChanged: _onSearchDebounced,
            ),
          ),
          if (_showFilters)
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return EmptyState(
                    icon: Icons.category_outlined,
                    title: 'SEM CATEGORIAS',
                    subtitle: 'Nenhuma categoria disponível',
                  );
                }
                return CategoryFilterPanel(
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onCategorySelected: (id) =>
                      ref.read(selectedCategoryProvider.notifier).state = id,
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Erro ao carregar categorias: $err'),
              ),
            ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: 'NENHUM PRODUTO',
                    subtitle: searchQuery.isNotEmpty || selectedCategory != null
                        ? 'Tente limpar os filtros'
                        : 'Nenhum produto encontrado.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(productsFeedProvider(
                    GetProductsParams(
                      search: searchQuery.isEmpty ? null : searchQuery,
                      category: selectedCategory,
                    ),
                  ).future),
                  color: AppColors.primaryPurple,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return AppCard(
                        imageUrl: product.imageUrl,
                        title: product.title,
                        priceInCents: product.price,
                        variant: AppCardVariant.compact,
                        onTap: () => context.push('/products/${product.id}'),
                      );
                    },
                  ),
                );
              },
              loading: () => GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 6,
                itemBuilder: (context, index) => const AppCard.skeleton(),
              ),
              error: (err, stack) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  AppDialog.showError(
                    context: context,
                    title: 'Erro ao carregar',
                    subtitle: err.toString(),
                    onOk: () => ref.invalidate(productsFeedProvider(
                      GetProductsParams(
                        search: searchQuery.isEmpty ? null : searchQuery,
                        category: selectedCategory,
                      ),
                    )),
                  );
                });
                return EmptyState(
                  icon: Icons.search_off,
                  title: 'ERRO',
                  subtitle: 'Tente novamente mais tarde',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
