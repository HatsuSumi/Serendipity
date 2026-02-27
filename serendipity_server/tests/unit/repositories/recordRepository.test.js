"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const recordRepository_1 = require("../../../src/repositories/recordRepository");
const prisma_mock_1 = require("../../mocks/prisma.mock");
describe('RecordRepository', () => {
    let recordRepository;
    beforeEach(() => {
        recordRepository = new recordRepository_1.RecordRepository(prisma_mock_1.prismaMock);
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
            prisma_mock_1.prismaMock.record.create.mockResolvedValue(mockRecord);
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
            expect(prisma_mock_1.prismaMock.record.create).toHaveBeenCalled();
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
            prisma_mock_1.prismaMock.record.findFirst.mockResolvedValue(mockRecord);
            const result = await recordRepository.findById('record-id', 'user-id');
            expect(result).toEqual(mockRecord);
        });
    });
});
//# sourceMappingURL=recordRepository.test.js.map