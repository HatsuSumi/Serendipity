import { RecordRepository } from '../../../src/repositories/recordRepository';
import { prismaMock } from '../../mocks/prisma.mock';

describe('RecordRepository', () => {
  let recordRepository: RecordRepository;

  beforeEach(() => {
    recordRepository = new RecordRepository(prismaMock as any);
  });

  describe('create', () => {
    it('应该创建新记录', async () => {
      const mockRecord = {
        id: 'record-id',
        userId: 'user-id',
        timestamp: new Date(),
        location: {},
        description: 'Test',
        tags: [],
        emotion: null,
        status: 'active',
        storyLineId: null,
        ifReencounter: null,
        conversationStarter: null,
        backgroundMusic: null,
        weather: [],
        isPinned: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      prismaMock.record.create.mockResolvedValue(mockRecord as any);

      const result = await recordRepository.create('user-id', {
        id: 'record-id',
        timestamp: new Date(),
        location: {},
        tags: [],
        status: 'active',
        weather: [],
        isPinned: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      expect(result).toEqual(mockRecord);
      expect(prismaMock.record.create).toHaveBeenCalled();
    });
  });

  describe('findById', () => {
    it('应该根据 ID 查找记录', async () => {
      const mockRecord = {
        id: 'record-id',
        userId: 'user-id',
        timestamp: new Date(),
        location: {},
        tags: [],
        status: 'active',
        weather: [],
        isPinned: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      prismaMock.record.findFirst.mockResolvedValue(mockRecord as any);

      const result = await recordRepository.findById('record-id', 'user-id');

      expect(result).toEqual(mockRecord);
    });
  });
});


