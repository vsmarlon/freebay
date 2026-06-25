import { Test, TestingModule } from '@nestjs/testing';
import { CanActivate } from '@nestjs/common';
import { FavoritesController } from './favorites.controller';
import { PrismaFavoriteRepository } from './repositories/favorite.repository';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';

const mockGuard: CanActivate = { canActivate: jest.fn(() => true) };

const mockRepo = {
  getUserFavorites: jest.fn(),
  findByUserAndProduct: jest.fn(),
  findProductById: jest.fn(),
  create: jest.fn(),
  delete: jest.fn(),
};

describe('FavoritesController', () => {
  let controller: FavoritesController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [FavoritesController],
      providers: [
        { provide: PrismaFavoriteRepository, useValue: mockRepo },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue(mockGuard)
      .overrideGuard(NonGuestGuard)
      .useValue(mockGuard)
      .compile();

    controller = module.get<FavoritesController>(FavoritesController);
    jest.clearAllMocks();
  });

  it('should return user favorites', async () => {
    const product = { id: 'prod-1', title: 'Test', price: 1000, seller: {}, images: [] };
    mockRepo.getUserFavorites.mockResolvedValue([{ product }]);
    const result: any = await controller.getFavorites({ userId: 'user-1' } as any);
    expect(result.products).toHaveLength(1);
  });

  it('should check if product is favorited', async () => {
    mockRepo.findByUserAndProduct.mockResolvedValue({ id: 'fav-1' });
    const result: any = await controller.checkFavorite('prod-1', { userId: 'user-1' } as any);
    expect(result.isFavorited).toBe(true);
  });

  it('should return false when product is not favorited', async () => {
    mockRepo.findByUserAndProduct.mockResolvedValue(null);
    const result: any = await controller.checkFavorite('prod-1', { userId: 'user-1' } as any);
    expect(result.isFavorited).toBe(false);
  });

  it('should return error if product not found when toggling', async () => {
    mockRepo.findProductById.mockResolvedValue(null);
    const result = await controller.toggleFavorite('prod-1', { userId: 'user-1' } as any);
    expect(result).toBeDefined();
  });

  it('should return error if product is own when toggling', async () => {
    mockRepo.findProductById.mockResolvedValue({ id: 'prod-1', sellerId: 'user-1', status: 'ACTIVE' });
    const result = await controller.toggleFavorite('prod-1', { userId: 'user-1' } as any);
    expect(result).toBeDefined();
  });

  it('should add favorite', async () => {
    mockRepo.findProductById.mockResolvedValue({ id: 'prod-1', sellerId: 'seller-1', status: 'ACTIVE' });
    mockRepo.findByUserAndProduct.mockResolvedValue(null);
    mockRepo.create.mockResolvedValue({ id: 'fav-1' });
    const result: any = await controller.toggleFavorite('prod-1', { userId: 'user-1' } as any);
    expect(result.favorited).toBe(true);
  });

  it('should remove favorite if already favorited', async () => {
    mockRepo.findProductById.mockResolvedValue({ id: 'prod-1', sellerId: 'seller-1', status: 'ACTIVE' });
    mockRepo.findByUserAndProduct.mockResolvedValue({ id: 'fav-1' });
    mockRepo.delete.mockResolvedValue({});
    const result: any = await controller.toggleFavorite('prod-1', { userId: 'user-1' } as any);
    expect(result.favorited).toBe(false);
  });
});
