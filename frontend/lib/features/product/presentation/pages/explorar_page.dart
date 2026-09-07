import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/product/presentation/widgets/product_results_grid.dart';
import 'package:freebay/features/product/presentation/widgets/category_filter_panel.dart';
import 'package:freebay/features/product/presentation/widgets/product_filter_bar.dart';
import 'package:freebay/features/product/data/entities/category_entity.dart';
import 'package:freebay/features/product/domain/usecases/get_products_usecase.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/features/product/domain/product_filters.dart';
import 'package:freebay/core/utils/currency_utils.dart';

class ExplorarPage extends ConsumerStatefulWidget {
  const ExplorarPage({super.key});

  @override
  ConsumerState<ExplorarPage> createState() => _ExplorarPageState();
}

class _ExplorarPageState extends ConsumerState<ExplorarPage>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  bool _showFilters = false;
  Timer? _debounceTimer;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'EXPLORAR',
            actions: [
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color: context.isDark
                      ? AppColors.white
                      : AppColors.primaryContainer,
                ),
                onPressed: () => setState(() => _showFilters = !_showFilters),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_box_outlined,
                  color: AppColors.primaryContainer,
                ),
                onPressed: () => context.push('/products/create'),
              ),
            ],
          ),
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  primary: false,
                  floating: true,
                  snap: true,
                  elevation: 0,
                  backgroundColor: context.surfaceColor,
                  surfaceTintColor: Colors.transparent,
                  toolbarHeight: 72,
                  titleSpacing: 0,
                  title: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: AppTextField(
                      controller: _searchController,
                      label: '',
                      hint: 'Buscar produtos...',
                      prefixIcon: Icons.search,
                      onFieldSubmitted: (_) => _onSearch(),
                      onChanged: _onSearchDebounced,
                    ),
                  ),
                ),
              ],
              body: _buildProdutosTab(selectedCategory, categoriesAsync),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProdutosTab(
    String? selectedCategory,
    AsyncValue<List<CategoryEntity>> categoriesAsync,
  ) {
    final searchQuery = ref.watch(searchQueryProvider);
    final sort = ref.watch(productSortProvider);
    final condition = ref.watch(productConditionProvider);
    final priceRange = ref.watch(productPriceRangeProvider);

    final params = GetProductsParams(
      search: searchQuery.isEmpty ? null : searchQuery,
      category: selectedCategory,
      sort: sort,
      condition: condition,
      minPrice: priceRange == null
          ? null
          : CurrencyUtils.reaisToCents(priceRange.start),
      maxPrice: priceRange == null
          ? null
          : CurrencyUtils.reaisToCents(priceRange.end),
    );
    final feedState = ref.watch(productsFeedProvider(params));

    final hasActiveFilters =
        searchQuery.isNotEmpty ||
        selectedCategory != null ||
        condition != null ||
        priceRange != null;

    return Column(
      children: [
        if (_showFilters) ...[
          ProductFilterBar(
            sort: sort,
            condition: condition,
            priceRange: priceRange,
            onSortChanged: (value) =>
                ref.read(productSortProvider.notifier).state = value,
            onConditionChanged: (value) =>
                ref.read(productConditionProvider.notifier).state = value,
            onPriceRangeChanged: (value) =>
                ref.read(productPriceRangeProvider.notifier).state = value,
          ),
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return const EmptyState(
                  icon: Icons.category_outlined,
                  title: 'NENHUMA CATEGORIA',
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
            loading: () => Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemCount: 6,
                itemBuilder: (_, _) => const AppCard.skeleton(),
                physics: const NeverScrollableScrollPhysics(),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Erro ao carregar categorias: $err'),
            ),
          ),
        ],
        Expanded(child: _buildResults(params, feedState, hasActiveFilters)),
      ],
    );
  }

  Widget _buildResults(
    GetProductsParams params,
    ProductsFeedState feedState,
    bool hasActiveFilters,
  ) {
    if (feedState.isLoading) {
      return const ProductResultsGrid.skeleton();
    }

    if (feedState.error != null && feedState.products.isEmpty) {
      return EmptyState.error(
        message: 'Erro ao carregar\n${feedState.error}',
        onRetry: () => ref.read(productsFeedProvider(params).notifier).load(),
      );
    }

    if (feedState.products.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmptyState(
                  icon: Icons.search_off,
                  title: 'NENHUM PRODUTO',
                  subtitle: 'Nenhum produto encontrado.',
                ),
                if (hasActiveFilters) ...[
                  Spacing.vSm,
                  InkWell(
                    onTap: _clearFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      color: context.surfaceColor,
                      child: Text(
                        'Limpar filtros',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(productsFeedProvider(params).notifier).load(),
      color: AppColors.primaryContainer,
      child: ProductResultsGrid(
        products: feedState.products,
        isLoadingMore: feedState.isLoadingMore,
        onLoadMore: () =>
            ref.read(productsFeedProvider(params).notifier).loadMore(),
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(selectedCategoryProvider.notifier).state = null;
    ref.read(productConditionProvider.notifier).state = null;
    ref.read(productPriceRangeProvider.notifier).state = null;
    ref.read(productSortProvider.notifier).state = ProductSort.recent;
  }
}
