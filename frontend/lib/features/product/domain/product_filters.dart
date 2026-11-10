import 'package:json_annotation/json_annotation.dart';

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

  static ProductCondition fromWire(String value) => values.firstWhere(
    (condition) => condition.wireValue == value,
    orElse: () => ProductCondition.used,
  );

  static ProductCondition fromLegacy(String? value) {
    switch (value?.toUpperCase()) {
      case 'NEW':
      case 'NOVO':
        return ProductCondition.isNew;
      case 'USED':
      case 'USADO':
      default:
        return ProductCondition.used;
    }
  }
}

class ProductConditionConverter
    implements JsonConverter<ProductCondition, String> {
  const ProductConditionConverter();

  @override
  ProductCondition fromJson(String value) => ProductCondition.fromWire(value);

  @override
  String toJson(ProductCondition condition) => condition.wireValue;
}

enum ProductStatus {
  active('ACTIVE', 'Ativo'),
  sold('SOLD', 'Vendido'),
  paused('PAUSED', 'Pausado'),
  deleted('DELETED', 'Excluído');

  const ProductStatus(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static ProductStatus fromWire(String value) => values.firstWhere(
    (status) => status.wireValue == value,
    orElse: () => ProductStatus.deleted,
  );
}

class ProductStatusConverter implements JsonConverter<ProductStatus, String> {
  const ProductStatusConverter();

  @override
  ProductStatus fromJson(String value) => ProductStatus.fromWire(value);

  @override
  String toJson(ProductStatus status) => status.wireValue;
}

class ProductFilterLimits {
  ProductFilterLimits._();

  static const double maxPriceReais = 5000;
}
