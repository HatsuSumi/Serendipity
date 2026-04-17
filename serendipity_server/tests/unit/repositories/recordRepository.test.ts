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
        anniversaryMonth: 4,
        anniversaryDay: 12,
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

      // Repository 使用 upsert 而不是 create
      prismaMock.record.upsert.mockResolvedValue(mockRecord as any);

      const result = await recordRepository.create('user-id', {
        id: 'record-id',
        timestamp: new Date(),
        anniversaryMonth: 4,
        anniversaryDay: 12,
        location: {},
        description: 'Test',
        tags: [],
        status: 'active',
        weather: [],
        isPinned: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      expect(result).toEqual(mockRecord);
      expect(prismaMock.record.upsert).toHaveBeenCalled();
    });
  });

  describe('findById', () => {
    it('应该根据 ID 查找未删除记录', async () => {
      const mockRecord = {
        id: 'record-id',
        userId: 'user-id',
        timestamp: new Date(),
        anniversaryMonth: 4,
        anniversaryDay: 12,
        location: {},
        tags: [],
        status: 'active',
        weather: [],
        isPinned: false,
        deletedAt: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      prismaMock.record.findFirst.mockResolvedValue(mockRecord as any);

      const result = await recordRepository.findById('record-id', 'user-id');

      expect(result).toEqual(mockRecord);
      expect(prismaMock.record.findFirst).toHaveBeenCalledWith({
        where: { id: 'record-id', userId: 'user-id', deletedAt: null },
      });
    });
  });

  describe('delete', () => {
    it('应该将记录墓碑化而不是物理删除', async () => {
      const deletedAt = new Date('2026-04-13T10:00:00.000Z');
      prismaMock.record.update.mockResolvedValue({} as any);

      await recordRepository.delete('record-id', deletedAt);

      expect(prismaMock.record.update).toHaveBeenCalledWith({
        where: { id: 'record-id' },
        data: {
          deletedAt,
          updatedAt: deletedAt,
        },
      });
    });
  });
});


