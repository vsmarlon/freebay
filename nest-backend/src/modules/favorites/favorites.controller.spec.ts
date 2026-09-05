import { Test, TestingModule } from '@nestjs/testing';
import { CanActivate } from '@nestjs/common';
import { FavoritesController } from './favorites.controller';
import { GetFavoritesUseCase } from './usecases/get-favorites.usecase';
import { CheckFavoriteUseCase } from './usecases/check-favorite.usecase';
import { ToggleFavoriteUseCase } from './usecases/toggle-favorite.usecase';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';
import { AuthUser } from '@/shared/core/types';
import { right } from '@/shared/core/either';

const mockGuard: CanActivate = { canActivate: jest.fn(() => true) };

const mockGetFavoritesUseCase = {
  execute: jest.fn(),
};
const mockCheckFavoriteUseCase = {
  execute: jest.fn(),
};
const mockToggleFavoriteUseCase = {
  execute: jest.fn(),
};

const mockUser: AuthUser = { userId: 'user-1', role: 'USER' };

describe('FavoritesController', () => {
  let controller: FavoritesController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [FavoritesController],
      providers: [
        { provide: GetFavoritesUseCase, useValue: mockGetFavoritesUseCase },
        { provide: CheckFavoriteUseCase, useValue: mockCheckFavoriteUseCase },
        { provide: ToggleFavoriteUseCase, useValue: mockToggleFavoriteUseCase },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue(mockGuard)
      .compile();

    controller = module.get<FavoritesController>(FavoritesController);
    jest.clearAllMocks();
  });

  it('should return user favorites', async () => {
    const products = [{ id: 'prod-1', title: 'Test', price: 1000, seller: {}, images: [] }];
    mockGetFavoritesUseCase.execute.mockResolvedValue(right({ products }));
    const result = await controller.getFavorites(mockUser.userId);
    expect(result.value).toEqual({ products });
  });

  it('should check if product is favorited', async () => {
    mockCheckFavoriteUseCase.execute.mockResolvedValue(right({ isFavorited: true }));
    const result = await controller.checkFavorite('prod-1', mockUser.userId);
    expect(result.value).toEqual({ isFavorited: true });
  });

  it('should return false when product is not favorited', async () => {
    mockCheckFavoriteUseCase.execute.mockResolvedValue(right({ isFavorited: false }));
    const result = await controller.checkFavorite('prod-1', mockUser.userId);
    expect(result.value).toEqual({ isFavorited: false });
  });

  it('should toggle favorite', async () => {
    mockToggleFavoriteUseCase.execute.mockResolvedValue(right({ isFavorited: true }));
    const result = await controller.toggleFavorite('prod-1', mockUser.userId);
    expect(result.value).toEqual({ isFavorited: true });
  });
});

