"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const communityPostRepository_1 = require("../../../src/repositories/communityPostRepository");
const prisma_mock_1 = require("../../mocks/prisma.mock");
describe('CommunityPostRepository', () => {
    let communityPostRepository;
    beforeEach(() => {
        communityPostRepository = new communityPostRepository_1.CommunityPostRepository(prisma_mock_1.prismaMock);
    });
    describe('create', () => {
        it('应该创建新社区帖子', async () => {
            const mockPost = {
                id: 'post-id',
                userId: 'user-id',
                recordId: 'record-id',
                timestamp: new Date(),
                tags: [],
                status: 'active',
                publishedAt: new Date(),
                createdAt: new Date(),
                updatedAt: new Date(),
            };
            prisma_mock_1.prismaMock.communityPost.create.mockResolvedValue(mockPost);
            const result = await communityPostRepository.create('user-id', {
                id: 'post-id',
                recordId: 'record-id',
                timestamp: new Date().toISOString(),
                tags: [],
                status: 'active',
            });
            expect(result).toEqual(mockPost);
            expect(prisma_mock_1.prismaMock.communityPost.create).toHaveBeenCalled();
        });
    });
    describe('findById', () => {
        it('应该根据 ID 查找帖子', async () => {
            const mockPost = {
                id: 'post-id',
                userId: 'user-id',
                recordId: 'record-id',
                timestamp: new Date(),
                tags: [],
                status: 'active',
                createdAt: new Date(),
                updatedAt: new Date(),
            };
            prisma_mock_1.prismaMock.communityPost.findUnique.mockResolvedValue(mockPost);
            const result = await communityPostRepository.findById('post-id');
            expect(result).toEqual(mockPost);
        });
    });
});
//# sourceMappingURL=communityPostRepository.test.js.map