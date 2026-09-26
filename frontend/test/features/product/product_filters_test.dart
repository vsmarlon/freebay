import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/product/domain/product_filters.dart';

void main() {
  test(
    'keeps product condition and status wire values aligned with backend',
    () {
      expect(ProductCondition.isNew.wireValue, 'NEW');
      expect(ProductCondition.used.wireValue, 'USED');
      expect(ProductStatus.values.map((status) => status.wireValue), [
        'ACTIVE',
        'SOLD',
        'PAUSED',
        'DELETED',
      ]);
    },
  );

  test('preserves legacy card labels at the compatibility seam', () {
    expect(ProductCondition.fromLegacy('new'), ProductCondition.isNew);
    expect(ProductCondition.fromLegacy('NOVO'), ProductCondition.isNew);
    expect(ProductCondition.fromLegacy('unknown'), ProductCondition.used);
  });
}
