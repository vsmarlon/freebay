import { Test } from '@nestjs/testing';
import { ProductStatus } from '@prisma/client';
import { left, right } from '@/shared/core/either';
import { EmailVerificationRequiredError } from '@/shared/core/errors';
import { EmailVerificationGateService } from '@/modules/auth/services/email-verification-gate.service';
import { ProductDatabaseRepository } from '../../data/repositories/product-database.repository';
import { CreateProductInput, CreateProductOutput } from '../../dtos/product.dto';
import { CreateProductUseCase } from './create-product.usecase';

describe('CreateProductUseCase email-verification gate', () => {
  const input: CreateProductInput = {
    sellerId: 'seller-1',
    title: 'Notebook',
    description: 'Works fine',
    price: 150000,
    condition: 'USED',
    categoryId: 'category-1',
    media: [],
  };

  const created: CreateProductOutput = {
    id: 'product-1',
    title: input.title,
    description: input.description,
    price: input.price,
    condition: 'USED',
    categoryId: input.categoryId,
    sellerId: input.sellerId,
    status: ProductStatus.ACTIVE,
    quantity: 1,
    soldCount: 0,
    createdAt: new Date('2026-01-15T10:30:00.000Z'),
    media: [],
  };

  async function compile(gate: { ensureVerified: jest.Mock }) {
    const products = { create: jest.fn().mockResolvedValue(right(created)) };
    const module = await Test.createTestingModule({
      providers: [
        CreateProductUseCase,
        { provide: ProductDatabaseRepository, useValue: products },
        { provide: EmailVerificationGateService, useValue: gate },
      ],
    }).compile();
    return { sut: module.get(CreateProductUseCase), products };
  }

  it('refuses to create a product for a seller whose email is unverified', async () => {
    const gate = { ensureVerified: jest.fn().mockResolvedValue(left(new EmailVerificationRequiredError())) };
    const { sut, products } = await compile(gate);

    const result = await sut.execute(input);

    expect(result).toEqual(left(new EmailVerificationRequiredError()));
    expect(gate.ensureVerified).toHaveBeenCalledWith('seller-1');
    expect(products.create).not.toHaveBeenCalled();
  });

  it('creates the product for a seller whose email is verified', async () => {
    const gate = { ensureVerified: jest.fn().mockResolvedValue(right(undefined)) };
    const { sut, products } = await compile(gate);

    const result = await sut.execute(input);

    expect(result.isRight()).toBe(true);
    expect(gate.ensureVerified).toHaveBeenCalledWith('seller-1');
    expect(products.create).toHaveBeenCalled();
  });
});
