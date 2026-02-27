"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const storyLineRepository_1 = require("../../../src/repositories/storyLineRepository");
const prisma_mock_1 = require("../../mocks/prisma.mock");
describe('StoryLineRepository', () => {
    let storyLineRepository;
    beforeEach(() => {
        storyLineRepository = new storyLineRepository_1.StoryLineRepository(prisma_mock_1.prismaMock);
    });
    describe('create', () => {
        it('应该创建新故事线', async () => {
            const mockStoryLine = {
                id: 'storyline-id',
                userId: 'user-id',
                name: 'Test StoryLine',
                recordIds: [],
                createdAt: new Date(),
                updatedAt: new Date(),
            };
            prisma_mock_1.prismaMock.storyLine.create.mockResolvedValue(mockStoryLine);
            const result = await storyLineRepository.create('user-id', {
                id: 'storyline-id',
                name: 'Test StoryLine',
                recordIds: [],
                createdAt: new Date(),
                updatedAt: new Date(),
            });
            expect(result).toEqual(mockStoryLine);
            expect(prisma_mock_1.prismaMock.storyLine.create).toHaveBeenCalled();
        });
    });
    describe('findById', () => {
        it('应该根据 ID 查找故事线', async () => {
            const mockStoryLine = {
                id: 'storyline-id',
                userId: 'user-id',
                name: 'Test StoryLine',
                recordIds: [],
                createdAt: new Date(),
                updatedAt: new Date(),
            };
            prisma_mock_1.prismaMock.storyLine.findFirst.mockResolvedValue(mockStoryLine);
            const result = await storyLineRepository.findById('storyline-id', 'user-id');
            expect(result).toEqual(mockStoryLine);
        });
    });
});
//# sourceMappingURL=storyLineRepository.test.js.map