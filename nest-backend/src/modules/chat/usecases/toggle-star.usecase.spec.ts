import { Test, TestingModule } from '@nestjs/testing';
import { ToggleStarUseCase } from './toggle-star.usecase';
import { ConversationDatabaseRepository } from '../data/repositories/conversation-database.repository';
import { ChatThreadAccessService } from '../services/chat-thread-access.service';
import { NotFoundError } from '@/shared/core/errors';
import { left, right } from '@/shared/core/either';

const mockRepo = {
  messageBelongsToThread: jest.fn(),
  findStarByUserAndMessage: jest.fn(),
  deleteStar: jest.fn(),
  createStar: jest.fn(),
};

const mockThreadAccess = {
  resolveThread: jest.fn(),
};

describe('ToggleStarUseCase', () => {
  let sut: ToggleStarUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ToggleStarUseCase,
        { provide: ConversationDatabaseRepository, useValue: mockRepo },
        { provide: ChatThreadAccessService, useValue: mockThreadAccess },
      ],
    }).compile();

    sut = module.get(ToggleStarUseCase);
    jest.clearAllMocks();
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ directConversationId: 'conv-1', otherUserId: 'user-2' }),
    );
    mockRepo.messageBelongsToThread.mockResolvedValue(right(true));
  });

  it('deve retornar erro quando a conversa nao pode ser resolvida', async () => {
    mockThreadAccess.resolveThread.mockResolvedValue(left(new NotFoundError('Conversa')));

    const result = await sut.execute({ userId: 'user-1', messageId: 'msg-1', conversationId: 'conv-1' });

    expect(result.isLeft()).toBe(true);
    expect(mockRepo.createStar).not.toHaveBeenCalled();
    expect(mockRepo.deleteStar).not.toHaveBeenCalled();
  });

  it('deve retornar NotFoundError quando a mensagem e de outra conversa', async () => {
    mockRepo.messageBelongsToThread.mockResolvedValue(right(false));

    const result = await sut.execute({ userId: 'user-1', messageId: 'msg-1', conversationId: 'conv-1' });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(NotFoundError);
    expect(mockRepo.createStar).not.toHaveBeenCalled();
  });

  it('deve desfavoritar quando a mensagem ja esta favoritada', async () => {
    mockRepo.findStarByUserAndMessage.mockResolvedValue(right({ id: 'star-1' }));
    mockRepo.deleteStar.mockResolvedValue(right(undefined));

    const result = await sut.execute({ userId: 'user-1', messageId: 'msg-1', conversationId: 'conv-1' });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value).toEqual({ starred: false });
    expect(mockRepo.deleteStar).toHaveBeenCalledWith('star-1');
    expect(mockRepo.createStar).not.toHaveBeenCalled();
  });

  it('deve favoritar mensagem direta quando ainda nao favoritada', async () => {
    mockRepo.findStarByUserAndMessage.mockResolvedValue(right(null));
    mockRepo.createStar.mockResolvedValue(right(undefined));

    const result = await sut.execute({ userId: 'user-1', messageId: 'msg-1', conversationId: 'conv-1' });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value).toEqual({ starred: true });
    expect(mockRepo.createStar).toHaveBeenCalledWith({
      userId: 'user-1',
      messageId: 'msg-1',
      model: 'DIRECT',
    });
  });

  it('deve favoritar com modelo ORDER em conversa de pedido', async () => {
    mockThreadAccess.resolveThread.mockResolvedValue(
      right({ orderId: 'order-1', otherUserId: 'seller-1' }),
    );
    mockRepo.findStarByUserAndMessage.mockResolvedValue(right(null));
    mockRepo.createStar.mockResolvedValue(right(undefined));

    const result = await sut.execute({ userId: 'buyer-1', messageId: 'msg-1', conversationId: 'order-1' });

    expect(result.isRight()).toBe(true);
    expect(mockRepo.findStarByUserAndMessage).toHaveBeenCalledWith('buyer-1', 'msg-1', 'ORDER');
    expect(mockRepo.createStar).toHaveBeenCalledWith({
      userId: 'buyer-1',
      messageId: 'msg-1',
      model: 'ORDER',
    });
  });
});
