import { Test, TestingModule } from '@nestjs/testing';
import { right } from '@/shared/core/either';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { ListFollowersUseCase } from './usecases/list-followers.usecase';
import { ListFollowingUseCase } from './usecases/list-following.usecase';
import { GetFollowStatusUseCase } from './usecases/get-follow-status.usecase';
import { GetBlockStatusUseCase } from './usecases/get-block-status.usecase';
import { PrismaBlockRepository } from './data/repositories/block-database.repository';
import { UsersAccountController } from './users-account.controller';
import { UsersDiscoveryController } from './users-discovery.controller';
import { UsersSocialController } from './users-social.controller';
import {
  GetProfileUseCase,
  GetUserStatsUseCase,
  UpdateProfileUseCase,
  RequestProfileVerificationUseCase,
  UpdateFcmTokenUseCase,
  FollowUserUseCase,
  UnfollowUserUseCase,
  BlockUserUseCase,
  UnblockUserUseCase,
  SearchUsersUseCase,
  GetSuggestionsUseCase,
  RegisterPhoneUseCase,
  VerifyPhoneUseCase,
  RequestAccountDeletionUseCase,
  CancelAccountDeletionUseCase,
  ExportUserDataUseCase,
} from './usecases';
import { request as httpRequest, IncomingMessage } from 'http';
import { ManageSafetyListUseCase } from './usecases/manage-safety-list.usecase';

const UUID = '550e8400-e29b-41d4-a716-446655440000';

describe('Users controllers route precedence', () => {
  let app: ReturnType<TestingModule['createNestApplication']>;
  const getProfile = { execute: jest.fn() };
  const followUser = { execute: jest.fn() };
  const searchUsers = { execute: jest.fn() };
  const listFollowers = { execute: jest.fn() };
  const listFollowing = { execute: jest.fn() };
  const followStatus = { execute: jest.fn() };
  const blockStatus = { execute: jest.fn() };
  const blockRepository = { getBlockedUsers: jest.fn() };
  const userRepository = { findById: jest.fn() };

  const get = (path: string): Promise<{ status: number; body: string }> =>
    new Promise((resolve, reject) => {
      const address = app.getHttpServer().address();
      if (address === null || typeof address === 'string') {
        throw new Error('Test server did not bind to a port');
      }
      const req = httpRequest(
        { hostname: '127.0.0.1', port: address.port, path, method: 'GET' },
        (res: IncomingMessage) => {
          const chunks: Buffer[] = [];
          res.on('data', (c: Buffer) => chunks.push(c));
          res.on('end', () =>
            resolve({
              status: res.statusCode ?? 0,
              body: Buffer.concat(chunks).toString('utf8'),
            }),
          );
          res.on('error', reject);
        },
      );
      req.on('error', reject);
      req.end();
    });

  const post = (path: string): Promise<{ status: number }> =>
    new Promise((resolve, reject) => {
      const address = app.getHttpServer().address();
      if (address === null || typeof address === 'string') {
        throw new Error('Test server did not bind to a port');
      }
      const req = httpRequest(
        {
          hostname: '127.0.0.1',
          port: address.port,
          path,
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
        },
        (res: IncomingMessage) => {
          res.resume();
          res.on('end', () => resolve({ status: res.statusCode ?? 0 }));
          res.on('error', reject);
        },
      );
      req.on('error', reject);
      req.end('{}');
    });

  beforeAll(async () => {
    getProfile.execute.mockResolvedValue(right({ id: 'user-1' }));
    followUser.execute.mockResolvedValue(right({ active: true, count: 1 }));
    searchUsers.execute.mockResolvedValue(right([]));
    listFollowers.execute.mockResolvedValue(right({ users: [], total: 0, limit: 20, offset: 0 }));
    listFollowing.execute.mockResolvedValue(right({ users: [], total: 0, limit: 20, offset: 0 }));
    blockRepository.getBlockedUsers.mockResolvedValue(right([]));
    userRepository.findById.mockResolvedValue(right({ id: UUID }));

    const module: TestingModule = await Test.createTestingModule({
      controllers: [
        UsersAccountController,
        UsersDiscoveryController,
        UsersSocialController,
      ],
      providers: [
        { provide: UserDatabaseRepository, useValue: userRepository },
        { provide: PrismaBlockRepository, useValue: blockRepository },
        { provide: GetProfileUseCase, useValue: getProfile },
        { provide: GetUserStatsUseCase, useValue: { execute: jest.fn() } },
        { provide: UpdateProfileUseCase, useValue: { execute: jest.fn() } },
        { provide: RequestProfileVerificationUseCase, useValue: { request: jest.fn() } },
        { provide: UpdateFcmTokenUseCase, useValue: { execute: jest.fn() } },
        { provide: FollowUserUseCase, useValue: followUser },
        { provide: UnfollowUserUseCase, useValue: { execute: jest.fn() } },
        { provide: BlockUserUseCase, useValue: { execute: jest.fn() } },
        { provide: UnblockUserUseCase, useValue: { execute: jest.fn() } },
        { provide: ListFollowersUseCase, useValue: listFollowers },
        { provide: ListFollowingUseCase, useValue: listFollowing },
        { provide: GetFollowStatusUseCase, useValue: followStatus },
        { provide: GetBlockStatusUseCase, useValue: blockStatus },
        { provide: SearchUsersUseCase, useValue: searchUsers },
        { provide: GetSuggestionsUseCase, useValue: { execute: jest.fn() } },
        { provide: RegisterPhoneUseCase, useValue: { execute: jest.fn() } },
        { provide: VerifyPhoneUseCase, useValue: { execute: jest.fn() } },
        {
          provide: RequestAccountDeletionUseCase,
          useValue: { execute: jest.fn() },
        },
        {
          provide: CancelAccountDeletionUseCase,
          useValue: { execute: jest.fn() },
        },
        { provide: ExportUserDataUseCase, useValue: { execute: jest.fn() } },
        { provide: ManageSafetyListUseCase, useValue: { candidates: jest.fn(), list: jest.fn(), change: jest.fn() } },
      ],
    }).compile();
    app = module.createNestApplication();
    await app.init();
    await app.listen(0);
  });

  afterAll(async () => app.close());

  it('routes GET /users/me to the account controller, not :id', async () => {
    const res = await get('/users/me');
    expect(res.status).toBe(200);
    expect(getProfile.execute).toHaveBeenCalledWith(
      expect.objectContaining({ includePrivate: true }),
    );
  });

  it('routes GET /users/me/followers to the social controller, not :id/followers', async () => {
    const res = await get('/users/me/followers');
    expect(res.status).toBe(200);
    expect(listFollowers.execute).toHaveBeenCalledWith({ userId: undefined, limit: 20, offset: 0 });
  });

  it('routes GET /users/:id to the public profile', async () => {
    const res = await get(`/users/${UUID}`);
    expect(res.status).toBe(200);
    expect(getProfile.execute).toHaveBeenCalledWith({ userId: UUID, viewerId: undefined });
  });

  it('routes POST /users/:id/follow to the follow use case', async () => {
    const res = await post(`/users/${UUID}/follow`);
    expect(res.status).toBe(200);
    expect(followUser.execute).toHaveBeenCalledWith(
      expect.objectContaining({ followingId: UUID }),
    );
  });

  it('routes GET /users/blocked and /users/search to discovery', async () => {
    expect((await get('/users/blocked')).status).toBe(200);
    expect(blockRepository.getBlockedUsers).toHaveBeenCalled();
    expect((await get('/users/search?q=a')).status).toBe(200);
    expect(searchUsers.execute).toHaveBeenCalledWith(
      expect.objectContaining({ query: 'a' }),
    );
  });
});
