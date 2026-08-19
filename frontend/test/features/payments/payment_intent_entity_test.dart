import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/payments/data/entities/payment_intent_entity.dart';

void main() {
  group('PaymentIntentEntity', () {
    test('fromJson parses the backend output payload', () {
      final entity = PaymentIntentEntity.fromJson({
        'orderId': 'order-123',
        'paymentIntentClientSecret': 'pi_test_123_secret_abc',
      });

      expect(entity.orderId, 'order-123');
      expect(entity.paymentIntentClientSecret, 'pi_test_123_secret_abc');
    });

    test('toJson round-trips the parsed payload', () {
      final entity = PaymentIntentEntity.fromJson({
        'orderId': 'order-123',
        'paymentIntentClientSecret': 'pi_test_123_secret_abc',
      });

      expect(entity.toJson(), {
        'orderId': 'order-123',
        'paymentIntentClientSecret': 'pi_test_123_secret_abc',
      });
    });

    test('throws TypeError when a required field is missing', () {
      expect(
        () => PaymentIntentEntity.fromJson({'orderId': 'order-123'}),
        throwsA(isA<TypeError>()),
      );
    });

    test('copyWith replaces the client secret', () {
      const entity = PaymentIntentEntity(
        orderId: 'order-123',
        paymentIntentClientSecret: 'pi_test_old_secret',
      );

      final updated = entity.copyWith(
        paymentIntentClientSecret: 'pi_test_new_secret',
      );

      expect(updated.paymentIntentClientSecret, 'pi_test_new_secret');
      expect(updated.orderId, 'order-123');
    });
  });
}
