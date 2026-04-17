import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/components/app_card.dart';
import '../../../../core/components/app_dialog.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/entities/category_entity.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../controllers/product_controller.dart';

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
    final query = _searchController.text;
    ref.read(searchQueryProvider.notifier).state = query;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Explorar',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.primaryPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: isDark ? AppColors.white : AppColors.primaryPurple,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar produtos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : AppColors.white,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _onSearch(),
              onChanged: _onSearchDebounced,
            ),
          ),

          // Category filters
          if (_showFilters)
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nenhuma categoria disponível'),
                  );
                }
                return _buildCategoryTree(categories, selectedCategory, isDark);
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

          // Products grid
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return _buildEmptyState(
                    isDark,
                    message: 'Nenhum produto encontrado.',
                    subtitle: searchQuery.isNotEmpty || selectedCategory != null
                        ? 'Tente limpar os filtros'
                        : null,
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

                return _buildEmptyState(isDark,
                    message: 'Não há nenhum produto',
                    subtitle: 'Tente novamente mais tarde');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, {String? message, String? subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'Nenhum produto encontrado.',
            style: TextStyle(
              color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
              fontSize: 16,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryTree(
      List<CategoryEntity> categories, String? selectedCategory, bool isDark) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.mediumGray.withValues(alpha: 0.2)
                : AppColors.lightGray,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected: selectedCategory == null,
                onSelected: (_) {
                  ref.read(selectedCategoryProvider.notifier).state = null;
                },
                selectedColor: AppColors.primaryPurple.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primaryPurple,
              ),
              ..._flattenCategories(categories),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _flattenCategories(List<CategoryEntity> categories,
      {int indent = 0}) {
    final widgets = <Widget>[];

    for (final cat in categories) {
      final isSelected = ref.watch(selectedCategoryProvider) == cat.id;

      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: indent * 12.0),
          child: FilterChip(
            label: Text(cat.name),
            selected: isSelected,
            onSelected: (_) {
              ref.read(selectedCategoryProvider.notifier).state =
                  isSelected ? null : cat.id;
            },
            selectedColor: AppColors.primaryPurple.withValues(alpha: 0.2),
            checkmarkColor: AppColors.primaryPurple,
          ),
        ),
      );

      if (cat.children.isNotEmpty) {
        widgets.addAll(_flattenCategories(cat.children, indent: indent + 1));
      }
    }

    return widgets;
  }
}
