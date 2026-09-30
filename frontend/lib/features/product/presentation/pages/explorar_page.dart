import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/product/presentation/widgets/product_results_grid.dart';
import 'package:freebay/features/product/presentation/widgets/category_filter_panel.dart';
import 'package:freebay/features/product/presentation/widgets/product_filter_bar.dart';
import 'package:freebay/features/product/domain/usecases/get_products_usecase.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/features/product/domain/product_filters.dart';
import 'package:freebay/core/utils/currency_utils.dart';
import 'package:freebay/core/router/app_routes.dart';

const explorarSearchDebounce = Duration(milliseconds: 300);

class ExplorarPage extends ConsumerStatefulWidget {
  const ExplorarPage({super.key});

  @override
  ConsumerState<ExplorarPage> createState() => _ExplorarPageState();
}

class _ExplorarPageState extends ConsumerState<ExplorarPage>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
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
    _debounceTimer = Timer(explorarSearchDebounce, () {
      ref.read(searchQueryProvider.notifier).state = query;
    });
  }

  void _onSearch() {
    _debounceTimer?.cancel();
    ref.read(searchQueryProvider.notifier).state = _searchController.text;
  }

  void _openFilters() {
    showBrutalistSheet(
      context: context,
      title: 'FILTROS',
      builder: (_) => Consumer(
        builder: (context, ref, _) => ProductFilterBar(
          sort: ref.watch(productSortProvider),
          condition: ref.watch(productConditionProvider),
          priceRange: ref.watch(productPriceRangeProvider),
          onSortChanged: (value) =>
              ref.read(productSortProvider.notifier).state = value,
          onConditionChanged: (value) =>
              ref.read(productConditionProvider.notifier).state = value,
          onPriceRangeChanged: (value) {
            ref.read(productPriceRangeProvider.notifier).state = value;
            Navigator.of(context).pop();
          },
          onClear: () {
            ref.read(productSortProvider.notifier).state = ProductSort.recent;
            ref.read(productConditionProvider.notifier).state = null;
            ref.read(productPriceRangeProvider.notifier).state = null;
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final hasActiveFilters =
        ref.watch(productSortProvider) != ProductSort.recent ||
        ref.watch(productConditionProvider) != null ||
        ref.watch(productPriceRangeProvider) != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          ShellScrollHeader(
            child: PageHeader(
              text: 'EXPLORAR',
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        color: context.isDark
                            ? AppColors.white
                            : AppColors.primaryContainer,
                      ),
                      onPressed: _openFilters,
                    ),
                    if (hasActiveFilters)
                      const Positioned(
                        right: 10,
                        top: 10,
                        child: SizedBox(
                          width: 8,
                          height: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_box_outlined,
                    color: AppColors.primaryContainer,
                  ),
                  onPressed: () => context.push(AppRoutes.createProduct),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: AppTextField(
              controller: _searchController,
              label: '',
              hint: 'Buscar produtos...',
              prefixIcon: Icons.search,
              onFieldSubmitted: (_) => _onSearch(),
              onChanged: _onSearchDebounced,
            ),
          ),
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return CategoryFilterPanel(
                categories: categories,
                selectedCategory: selectedCategory,
                onCategorySelected: (id) =>
                    ref.read(selectedCategoryProvider.notifier).state = id,
              );
            },
            loading: () =>
                const SizedBox(height: 52, child: ShimmerBlock(height: 36)),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(userMessageOf(err)),
            ),
          ),
          Expanded(child: _buildProdutosTab(selectedCategory)),
        ],
      ),
    );
  }

  Widget _buildProdutosTab(String? selectedCategory) {
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
      maxPrice:
          priceRange == null ||
              priceRange.end >= ProductFilterLimits.maxPriceReais
          ? null
          : CurrencyUtils.reaisToCents(priceRange.end),
    );
    final feedState = ref.watch(productsFeedProvider(params));

    final hasActiveFilters =
        searchQuery.isNotEmpty ||
        selectedCategory != null ||
        condition != null ||
        priceRange != null;

    return _buildResults(params, feedState, hasActiveFilters);
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
        message: feedState.error ?? kGenericErrorMessage,
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

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(productsFeedProvider(params).notifier).load(),
            color: AppColors.primaryContainer,
            child: ProductResultsGrid(
              products: feedState.products,
              isLoadingMore: feedState.isLoadingMore,
              onLoadMore: () {
                if (feedState.error == null) {
                  ref.read(productsFeedProvider(params).notifier).loadMore();
                }
              },
            ),
          ),
        ),
        if (feedState.error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    feedState.error!,
                    style: AppTypography.bodyMedium,
                  ),
                ),
                Spacing.hSm,
                AppButton(
                  label: 'TENTAR NOVAMENTE',
                  size: AppButtonSize.compact,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => ref
                      .read(productsFeedProvider(params).notifier)
                      .loadMore(),
                ),
              ],
            ),
          ),
      ],
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
