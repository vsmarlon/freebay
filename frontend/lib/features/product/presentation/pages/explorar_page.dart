import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_card.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/product/data/entities/category_entity.dart';
import 'package:freebay/features/product/domain/usecases/get_products_usecase.dart';
import 'package:freebay/features/product/presentation/controllers/product_controller.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';
import 'package:freebay/features/social/presentation/widgets/user_search_list.dart';

class ExplorarPage extends ConsumerStatefulWidget {
  const ExplorarPage({super.key});

  @override
  ConsumerState<ExplorarPage> createState() => _ExplorarPageState();
}

class _ExplorarPageState extends ConsumerState<ExplorarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _showFilters = false;
  Timer? _debounceTimer;
  final Map<String, bool> _followingMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchDebounced(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_tabController.index == 1) {
        ref
            .read(userSearchProvider.notifier)
            .search(query: query, refresh: true);
      } else {
        ref.read(searchQueryProvider.notifier).state = query;
      }
    });
  }

  void _onSearch() {
    _debounceTimer?.cancel();
    final query = _searchController.text;
    if (_tabController.index == 1) {
      ref.read(userSearchProvider.notifier).search(query: query, refresh: true);
    } else {
      ref.read(searchQueryProvider.notifier).state = query;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

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
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.isDark ? AppColors.white : AppColors.primaryPurple,
          unselectedLabelColor: AppColors.mediumGray,
          indicatorColor: AppColors.primaryPurple,
          tabs: const [
            Tab(text: 'Produtos'),
            Tab(text: 'Pessoas'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: context.isDark ? AppColors.white : AppColors.primaryPurple,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            icon: Icon(
              Icons.add_box_outlined,
              color: AppColors.primaryPurpleDark,
            ),
            onPressed: () => context.push('/products/create'),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppTextField(
              controller: _searchController,
              label: '',
              hint: _tabController.index == 1
                  ? 'Buscar pessoas...'
                  : 'Buscar produtos...',
              prefixIcon: Icons.search,
              onFieldSubmitted: (_) => _onSearch(),
              onChanged: _onSearchDebounced,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProdutosTab(selectedCategory, categoriesAsync),
                _buildPessoasTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProdutosTab(
      String? selectedCategory,
      AsyncValue<List<CategoryEntity>> categoriesAsync) {
    final searchQuery = ref.watch(searchQueryProvider);

    final productsAsync = ref.watch(productsFeedProvider(
      GetProductsParams(
        search: searchQuery.isEmpty ? null : searchQuery,
        category: selectedCategory,
      ),
    ));

    return Column(
      children: [
        if (_showFilters)
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
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EmptyState(
                      icon: Icons.search_off,
                      title: 'NENHUM PRODUTO',
                      subtitle: 'Nenhum produto encontrado.',
                    ),
                    if (searchQuery.isNotEmpty || selectedCategory != null) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                          ref.read(selectedCategoryProvider.notifier).state = null;
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          color: context.surfaceColor,
                          child: Text(
                            'Limpar filtros',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar\nerro: $err',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => ref.invalidate(productsFeedProvider(
                      GetProductsParams(
                        search: searchQuery.isEmpty ? null : searchQuery,
                        category: selectedCategory,
                      ),
                    )),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: const BoxDecoration(
                          gradient: AppColors.brutalistGradient),
                      child: const Center(
                        child: Text(
                          'Tentar novamente',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPessoasTab() {
    final searchState = ref.watch(userSearchProvider);
    final searchQuery = _searchController.text;

    if (searchQuery.isEmpty && searchState.users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: AppColors.mediumGray),
            SizedBox(height: 16),
            Text(
              'Busque por pessoas...',
              style: TextStyle(color: AppColors.mediumGray, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return UserSearchList(
      users: searchState.users,
      isLoading: searchState.isLoading,
      onLoadMore: () {
        if (searchState.hasMore && !searchState.isLoading) {
          ref.read(userSearchProvider.notifier).search(query: searchQuery);
        }
      },
      onFollow: (userId) async {
        await ref.read(socialRepositoryProvider).followUser(userId);
        setState(() => _followingMap[userId] = true);
      },
      onUnfollow: (userId) async {
        await ref.read(socialRepositoryProvider).unfollowUser(userId);
        setState(() => _followingMap[userId] = false);
      },
    );
  }
}
