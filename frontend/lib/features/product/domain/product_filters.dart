enum ProductSort {
  recent('recent', 'Recentes'),
  priceAsc('price_asc', 'Menor preço'),
  priceDesc('price_desc', 'Maior preço'),
  popular('popular', 'Populares');

  const ProductSort(this.wireValue, this.label);

  final String wireValue;
  final String label;
}

enum ProductCondition {
  isNew('NEW', 'Novo'),
  used('USED', 'Usado');

  const ProductCondition(this.wireValue, this.label);

  final String wireValue;
  final String label;
}

class ProductFilterLimits {
  ProductFilterLimits._();

  static const double maxPriceReais = 5000;
}
