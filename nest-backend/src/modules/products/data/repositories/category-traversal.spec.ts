import { Test } from '@nestjs/testing';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ProductDatabaseRepository } from './product-database.repository';

describe('ProductDatabaseRepository category traversal', () => {
  it('includes the root and every descendant once in breadth-first order', async () => {
    const categoryFindMany = jest.fn().mockResolvedValue([
      { id: 'child-a', parentId: 'root' },
      { id: 'child-b', parentId: 'root' },
      { id: 'grandchild-a', parentId: 'child-a' },
      { id: 'great-grandchild', parentId: 'grandchild-a' },
      { id: 'root', parentId: 'great-grandchild' },
      { id: 'child-a', parentId: 'root' },
    ]);
    const productFindMany = jest.fn().mockResolvedValue([]);
    const module = await Test.createTestingModule({
      providers: [
        ProductDatabaseRepository,
        {
          provide: PrismaService,
          useValue: { category: { findMany: categoryFindMany }, product: { findMany: productFindMany } },
        },
      ],
    }).compile();

    const result = await module.get(ProductDatabaseRepository).findMany({ categoryId: 'root' });

    expect(result.isRight()).toBe(true);
    expect(productFindMany).toHaveBeenCalledWith(expect.objectContaining({
      where: expect.objectContaining({ categoryId: { in: ['root', 'child-a', 'child-b', 'grandchild-a', 'great-grandchild'] } }),
    }));
  });
});
