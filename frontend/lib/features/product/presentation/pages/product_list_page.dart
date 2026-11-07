import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/product/presentation/widgets/product_results_grid.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/product/domain/usecases/get_products_usecase.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/features/product/presentation/widgets/category_filter_panel.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

const productSearchDebounce = Duration(milliseconds: 300);

class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final _searchController = TextEditingController();
  bool _showFilters = false;
  Timer? _debounceTimer;
  late final HideOnScrollController _headerHide;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _headerHide = HideOnScrollController(vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _headerHide.dispose();
    super.dispose();
  }

  void _onSearchDebounced(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(productSearchDebounce, () {
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
    final strings = l10n(context);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final params = GetProductsParams(
      search: searchQuery.isEmpty ? null : searchQuery,
      category: selectedCategory,
    );
    final feedState = ref.watch(productsFeedProvider(params));

    final headerHeight = MediaQuery.paddingOf(context).top + 66;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(top: headerHeight),
                child: NotificationListener<ScrollNotification>(
                  onNotification: _headerHide.handleNotification,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: AppTextField(
                          controller: _searchController,
                          label: strings.productSearchHint,
                          hint: strings.productSearchHint,
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
                                title: strings.productNoCategories,
                                subtitle: strings.productNoCategoriesBody,
                              );
                            }
                            return CategoryFilterPanel(
                              categories: categories,
                              selectedCategory: selectedCategory,
                              onCategorySelected: (id) =>
                                  ref
                                          .read(
                                            selectedCategoryProvider.notifier,
                                          )
                                          .state =
                                      id,
                            );
                          },
                          loading: () => const SizedBox(
                            height: 52,
                            child: ShimmerScope(
                              child: ShimmerBlock(height: 36),
                            ),
                          ),
                          error: (err, _) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(localizedFailureMessage(context, err)),
                          ),
                        ),
                      Expanded(
                        child: _buildProducts(
                          context,
                          params,
                          feedState,
                          searchQuery,
                          selectedCategory,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: ScrollAwareBar(
                animation: _headerHide.animation,
                height: headerHeight,
                edge: ScrollBarEdge.top,
                child: PageHeader(
                  text: strings.navExplore.toUpperCase(),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _showFilters
                            ? Icons.filter_list_off
                            : Icons.filter_list,
                        color: context.isDark
                            ? AppColors.white
                            : AppColors.primaryContainer,
                      ),
                      onPressed: () =>
                          setState(() => _showFilters = !_showFilters),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProducts(
    BuildContext context,
    GetProductsParams params,
    ProductsFeedState feedState,
    String searchQuery,
    String? selectedCategory,
  ) {
    final strings = l10n(context);
    if (feedState.isLoading) {
      return const ProductResultsGrid.skeleton();
    }

    if (feedState.error != null && feedState.products.isEmpty) {
      return EmptyState.error(
        message: strings.errorUnknown,
        onRetry: () => ref.read(productsFeedProvider(params).notifier).load(),
      );
    }

    if (feedState.products.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: strings.productNoProducts,
        subtitle: searchQuery.isNotEmpty || selectedCategory != null
            ? strings.productClearFiltersHint
            : strings.productNoProductsBody,
      );
    }

    return AppRefreshIndicator(
      onRefresh: () => ref.read(productsFeedProvider(params).notifier).load(),
      child: ProductResultsGrid(
        products: feedState.products,
        isLoadingMore: feedState.isLoadingMore,
        onLoadMore: () =>
            ref.read(productsFeedProvider(params).notifier).loadMore(),
      ),
    );
  }
}
