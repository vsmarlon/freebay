import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/product/presentation/widgets/product_results_grid.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/product/domain/usecases/get_products_usecase.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/features/product/presentation/widgets/category_filter_panel.dart';

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
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final params = GetProductsParams(
      search: searchQuery.isEmpty ? null : searchQuery,
      category: selectedCategory,
    );
    final feedState = ref.watch(productsFeedProvider(params));

    final headerHeight = MediaQuery.of(context).padding.top + 66;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
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
                            return const EmptyState(
                              icon: Icons.category_outlined,
                              title: 'SEM CATEGORIAS',
                              subtitle: 'Nenhuma categoria disponível',
                            );
                          }
                          return CategoryFilterPanel(
                            categories: categories,
                            selectedCategory: selectedCategory,
                            onCategorySelected: (id) =>
                                ref
                                        .read(selectedCategoryProvider.notifier)
                                        .state =
                                    id,
                          );
                        },
                        loading: () => Padding(
                          padding: const EdgeInsets.all(16),
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
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
                          child: Text(userMessageOf(err)),
                        ),
                      ),
                    Expanded(
                      child: _buildProducts(
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
                text: 'EXPLORAR',
                actions: [
                  IconButton(
                    icon: Icon(
                      _showFilters ? Icons.filter_list_off : Icons.filter_list,
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
    );
  }

  Widget _buildProducts(
    GetProductsParams params,
    ProductsFeedState feedState,
    String searchQuery,
    String? selectedCategory,
  ) {
    if (feedState.isLoading) {
      return const ProductResultsGrid.skeleton();
    }

    if (feedState.error != null && feedState.products.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppDialog.showError(
          context: context,
          title: 'Erro ao carregar',
          subtitle: feedState.error!,
          onOk: () => ref.read(productsFeedProvider(params).notifier).load(),
        );
      });
      return const EmptyState(
        icon: Icons.search_off,
        title: 'ERRO',
        subtitle: 'Tente novamente mais tarde',
      );
    }

    if (feedState.products.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'NENHUM PRODUTO',
        subtitle: searchQuery.isNotEmpty || selectedCategory != null
            ? 'Tente limpar os filtros'
            : 'Nenhum produto encontrado.',
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
