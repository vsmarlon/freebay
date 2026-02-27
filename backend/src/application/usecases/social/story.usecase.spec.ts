import {
  CreateStoryUseCase,
  GetStoriesUseCase,
  DeleteStoryUseCase,
  ViewStoryUseCase,
  GetUserStoriesUseCase,
} from './story.usecase';
import { IStoryRepository } from '@/domain/repositories';
import { StoryEntity } from '@/domain/entities';

const mockStoryRepository: jest.Mocked<IStoryRepository> = {
  createStory: jest.fn(),
  getStories: jest.fn(),
  getUserStories: jest.fn(),
  deleteStory: jest.fn(),
  viewStory: jest.fn(),
};

const mockStory: StoryEntity = {
  id: 'story-1',
  userId: 'user-1',
  imageUrl: '/uploads/story_user-1_123.jpg',
  expiresAt: new Date(Date.now() + 86400000),
  createdAt: new Date(),
  user: {
    id: 'user-1',
    displayName: 'Test User',
    avatarUrl: null,
    isVerified: false,
  },
  isViewed: false,
};

describe('CreateStoryUseCase', () => {
  let sut: CreateStoryUseCase;

  beforeEach(() => {
    sut = new CreateStoryUseCase(mockStoryRepository);
    jest.clearAllMocks();
  });

  it('should create a story and return right', async () => {
    mockStoryRepository.createStory.mockResolvedValue(mockStory);

    const result = await sut.execute('user-1', '/uploads/story.jpg');

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value.userId).toBe('user-1');
    }
    expect(mockStoryRepository.createStory).toHaveBeenCalledWith('user-1', '/uploads/story.jpg');
  });
});

describe('GetStoriesUseCase', () => {
  let sut: GetStoriesUseCase;

  beforeEach(() => {
    sut = new GetStoriesUseCase(mockStoryRepository);
    jest.clearAllMocks();
  });

  it('should return stories and userHasStory flag', async () => {
    mockStoryRepository.getStories.mockResolvedValue({
      stories: [mockStory],
      userHasStory: true,
    });

    const result = await sut.execute('user-1');

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value.stories).toHaveLength(1);
      expect(result.value.userHasStory).toBe(true);
    }
  });
});

describe('DeleteStoryUseCase', () => {
  let sut: DeleteStoryUseCase;

  beforeEach(() => {
    sut = new DeleteStoryUseCase(mockStoryRepository);
    jest.clearAllMocks();
  });

  it('should delete and return right', async () => {
    mockStoryRepository.deleteStory.mockResolvedValue();

    const result = await sut.execute('story-1', 'user-1');

    expect(result._tag).toBe('right');
    expect(mockStoryRepository.deleteStory).toHaveBeenCalledWith('story-1', 'user-1');
  });
});

describe('ViewStoryUseCase', () => {
  let sut: ViewStoryUseCase;

  beforeEach(() => {
    sut = new ViewStoryUseCase(mockStoryRepository);
    jest.clearAllMocks();
  });

  it('should mark story as viewed and return right', async () => {
    mockStoryRepository.viewStory.mockResolvedValue();

    const result = await sut.execute('story-1', 'viewer-1');

    expect(result._tag).toBe('right');
    expect(mockStoryRepository.viewStory).toHaveBeenCalledWith('story-1', 'viewer-1');
  });
});

describe('GetUserStoriesUseCase', () => {
  let sut: GetUserStoriesUseCase;

  beforeEach(() => {
    sut = new GetUserStoriesUseCase(mockStoryRepository);
    jest.clearAllMocks();
  });

  it('should return user stories', async () => {
    mockStoryRepository.getUserStories.mockResolvedValue([mockStory]);

    const result = await sut.execute('user-1', 'viewer-1');

    expect(result._tag).toBe('right');
    if (result._tag === 'right') {
      expect(result.value).toHaveLength(1);
    }
    expect(mockStoryRepository.getUserStories).toHaveBeenCalledWith('user-1', 'viewer-1');
  });
});
