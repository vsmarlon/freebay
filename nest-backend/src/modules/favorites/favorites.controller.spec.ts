import { Test, TestingModule } from '@nestjs/testing';
import { CanActivate } from '@nestjs/common';
import { FavoritesController } from './favorites.controller';
import { FavoritesService } from './favorites.service';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { NonGuestGuard } from '@/shared/guards/non-guest.guard';
import { AuthUser } from '@/shared/core/types';

const mockGuard: CanActivate = { canActivate: jest.fn(() => true) };

const mockService = {
  getFavorites: jest.fn(),
  checkFavorite: jest.fn(),
  toggleFavorite: jest.fn(),
};

const mockUser: AuthUser = { userId: 'user-1', role: 'USER' };

describe('FavoritesController', () => {
  let controller: FavoritesController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [FavoritesController],
      providers: [
        { provide: FavoritesService, useValue: mockService },
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
    const products = [{ id: 'prod-1', title: 'Test', price: 1000, seller: {}, images: [] }];
    mockService.getFavorites.mockResolvedValue({ products });
    const result = await controller.getFavorites(mockUser);
    expect(result.products).toHaveLength(1);
  });

  it('should check if product is favorited', async () => {
    mockService.checkFavorite.mockResolvedValue({ isFavorited: true });
    const result = await controller.checkFavorite('prod-1', mockUser);
    expect(result.isFavorited).toBe(true);
  });

  it('should return false when product is not favorited', async () => {
    mockService.checkFavorite.mockResolvedValue({ isFavorited: false });
    const result = await controller.checkFavorite('prod-1', mockUser);
    expect(result.isFavorited).toBe(false);
  });

  it('should return error if product not found when toggling', async () => {
    mockService.toggleFavorite.mockRejectedValue(new Error('Not found'));
    await expect(controller.toggleFavorite('prod-1', mockUser)).rejects.toThrow();
  });

  it('should add favorite', async () => {
    mockService.toggleFavorite.mockResolvedValue(undefined);
    const result = await controller.toggleFavorite('prod-1', mockUser);
    expect(result).toBeUndefined();
  });

  it('should remove favorite if already favorited', async () => {
    mockService.toggleFavorite.mockResolvedValue(undefined);
    const result = await controller.toggleFavorite('prod-1', mockUser);
    expect(result).toBeUndefined();
  });
});
