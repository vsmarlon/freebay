import { Test, TestingModule } from '@nestjs/testing';
import { RegisterUseCase } from './register.usecase';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { prisma } from '../../../../test/setup-integration';
import { UserFactory } from '../../../../test/factories';
import { RegisterDTO } from '../dtos/auth.dto';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

describe('RegisterUseCase Integration', () => {
  let sut: RegisterUseCase;
  let userRepository: UserDatabaseRepository;
  let userFactory: UserFactory;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UserDatabaseRepository,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    userRepository = module.get(UserDatabaseRepository);
    userFactory = new UserFactory(prisma);
    sut = new RegisterUseCase(userRepository);
  });

  describe('Business Rules', () => {
    it('registers a new user successfully', async () => {
      const input: RegisterDTO = {
        email: 'newuser@example.com',
        password: 'password123',
        displayName: 'New User',
        username: 'new_user',
      };

      const result = await sut.execute(input);

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value.user).toBeDefined();
        expect(result.value.user.displayName).toBe(input.displayName);
        expect(result.value.user.reputationScore).toBe(0);
        expect(result.value.user.totalReviews).toBe(0);

        const dbUser = await prisma.user.findUnique({
          where: { email: input.email },
        });
        expect(dbUser).toBeDefined();
        expect(dbUser?.email).toBe(input.email);
      }
    });

    it('hashes the password before storing', async () => {
      const input: RegisterDTO = {
        email: 'secure@example.com',
        password: 'mySecretPassword',
        displayName: 'Secure User',
        username: 'secure_user',
      };

      const result = await sut.execute(input);

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        const dbUser = await prisma.user.findUnique({
          where: { email: input.email },
        });

        expect(dbUser?.passwordHash).not.toBe(input.password);
        expect(dbUser?.passwordHash?.length).toBeGreaterThan(20);
      }
    });

    it('returns error if email already exists', async () => {
      const existingUser = await userFactory.create({
        email: 'duplicate@example.com',
      });

      const input: RegisterDTO = {
        email: existingUser.email,
        password: 'password123',
        displayName: 'Another User',
        username: 'another_user',
      };

      const result = await sut.execute(input);

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value.code).toBe('EMAIL_ALREADY_EXISTS');
        expect(result.value.message).toContain('já está em uso');
      }
    });

    it('returns error if username already exists', async () => {
      const existingUser = await userFactory.create({
        username: 'takenname',
      });

      const input: RegisterDTO = {
        email: 'brandnew@example.com',
        password: 'password123',
        displayName: 'Yet Another User',
        username: existingUser.username!,
      };

      const result = await sut.execute(input);

      expect(result.isLeft()).toBe(true);
      if (result.isLeft()) {
        expect(result.value.code).toBe('USERNAME_ALREADY_EXISTS');
        expect(result.value.message).toContain('já está em uso');
      }
    });

    it('registers user with optional city and state', async () => {
      const input: RegisterDTO = {
        email: 'location@example.com',
        password: 'password123',
        displayName: 'User with Location',
        username: 'location_user',
        city: 'São Paulo',
        state: 'SP',
      };

      const result = await sut.execute(input);

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        const dbUser = await prisma.user.findUnique({
          where: { email: input.email },
        });

        expect(dbUser?.city).toBe('São Paulo');
        expect(dbUser?.state).toBe('SP');
      }
    });

    it('initializes reputation score to 0', async () => {
      const input: RegisterDTO = {
        email: 'newbie@example.com',
        password: 'password123',
        displayName: 'Newbie',
        username: 'newbie',
      };

      const result = await sut.execute(input);

      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value.user.reputationScore).toBe(0);
        expect(result.value.user.totalReviews).toBe(0);

        const dbUser = await prisma.user.findUnique({
          where: { email: input.email },
        });
        expect(dbUser?.reputationScore).toBe(0);
        expect(dbUser?.totalReviews).toBe(0);
      }
    });

    it('creates multiple users with unique emails', async () => {
      const users = [
        { email: 'user1@example.com', password: 'pass123', displayName: 'User 1', username: 'user_one' },
        { email: 'user2@example.com', password: 'pass123', displayName: 'User 2', username: 'user_two' },
        { email: 'user3@example.com', password: 'pass123', displayName: 'User 3', username: 'user_three' },
      ];

      const results = await Promise.all(users.map((user) => sut.execute(user)));

      expect(results.every((r) => r.isRight())).toBe(true);

      const dbUsers = await prisma.user.findMany({
        where: {
          email: {
            in: users.map((u) => u.email),
          },
        },
      });

      expect(dbUsers).toHaveLength(3);
    });
  });
});
