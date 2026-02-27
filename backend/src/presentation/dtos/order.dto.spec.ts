import { createOrderSchema, processPaymentSchema } from './order.dto';

describe('Order DTOs', () => {
  describe('createOrderSchema', () => {
    it('should validate a correct payload', () => {
      const result = createOrderSchema.safeParse({
        productId: '550e8400-e29b-41d4-a716-446655440000',
      });
      expect(result.success).toBe(true);
    });

    it('should reject non-uuid productId', () => {
      const result = createOrderSchema.safeParse({
        productId: 'not-a-uuid',
      });
      expect(result.success).toBe(false);
    });

    it('should reject missing productId', () => {
      const result = createOrderSchema.safeParse({});
      expect(result.success).toBe(false);
    });
  });

  describe('processPaymentSchema', () => {
    it('should validate PIX payment', () => {
      const result = processPaymentSchema.safeParse({
        orderId: '550e8400-e29b-41d4-a716-446655440000',
        paymentMethod: 'PIX',
      });
      expect(result.success).toBe(true);
    });

    it('should validate CREDIT_CARD payment with provider', () => {
      const result = processPaymentSchema.safeParse({
        orderId: '550e8400-e29b-41d4-a716-446655440000',
        paymentMethod: 'CREDIT_CARD',
        provider: 'WOOVI',
      });
      expect(result.success).toBe(true);
    });

    it('should default provider to PAGARME', () => {
      const result = processPaymentSchema.safeParse({
        orderId: '550e8400-e29b-41d4-a716-446655440000',
        paymentMethod: 'PIX',
      });
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.provider).toBe('PAGARME');
      }
    });

    it('should reject invalid payment method', () => {
      const result = processPaymentSchema.safeParse({
        orderId: '550e8400-e29b-41d4-a716-446655440000',
        paymentMethod: 'BOLETO',
      });
      expect(result.success).toBe(false);
    });
  });
});
