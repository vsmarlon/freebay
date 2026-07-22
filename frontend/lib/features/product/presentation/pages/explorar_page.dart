import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_card.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/product/presentation/widgets/category_filter_panel.dart';
import 'package:freebay/features/product/presentation/widgets/product_filter_bar.dart';
import 'package:freebay/features/product/data/entities/category_entity.dart';
import 'package:freebay/features/product/domain/usecases/get_products_usecase.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/page_header.dart';

class ExplorarPage extends ConsumerStatefulWidget {
  const ExplorarPage({super.key});

  @override
  ConsumerState<ExplorarPage> createState() => _ExplorarPageState();
}

class _ExplorarPageState extends ConsumerState<ExplorarPage> {
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
                icon: Icon(
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
                  pinned: false,
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
      minPrice: priceRange == null ? null : (priceRange.start * 100).round(),
      maxPrice: priceRange == null ? null : (priceRange.end * 100).round(),
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
                return EmptyState(
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
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const AppCard.skeleton(),
      );
    }

    if (feedState.error != null && feedState.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            Spacing.vMd,
            Text(
              'Erro ao carregar\nerro: ${feedState.error}',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textPrimary),
            ),
            Spacing.vMd,
            AppButton(
              label: 'Tentar novamente',
              onPressed: () =>
                  ref.read(productsFeedProvider(params).notifier).load(),
            ),
          ],
        ),
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
                EmptyState(
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
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 400) {
            ref.read(productsFeedProvider(params).notifier).loadMore();
          }
          return false;
        },
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount:
              feedState.products.length + (feedState.isLoadingMore ? 2 : 0),
          itemBuilder: (context, index) {
            if (index >= feedState.products.length) {
              return const AppCard.skeleton();
            }
            final product = feedState.products[index];
            return RepaintBoundary(
              child: AppCard(
                imageUrl: product.imageUrl,
                title: product.title,
                priceInCents: product.price,
                variant: AppCardVariant.compact,
                onTap: () => context.push('/products/${product.id}'),
              ),
            );
          },
        ),
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(selectedCategoryProvider.notifier).state = null;
    ref.read(productConditionProvider.notifier).state = null;
    ref.read(productPriceRangeProvider.notifier).state = null;
    ref.read(productSortProvider.notifier).state = 'recent';
  }
}
