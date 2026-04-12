import { PrismaClient, StoryLine } from '@prisma/client';
import {
  CreateStoryLineDto,
  UpdateStoryLineDto,
} from '../types/storyline.dto';
import { toJsonValue } from '../utils/prisma-json';

/**
 * StoryLine Repository 接口
 * 负责故事线数据的持久化操作
 */
export interface IStoryLineRepository {
  /**
   * 创建故事线
   * @param userId - 用户 ID
   * @param data - 故事线数据
   * @returns 创建后的故事线
   */
  create(userId: string, data: CreateStoryLineDto): Promise<StoryLine>;

  /**
   * 批量创建故事线
   * @param userId - 用户 ID
   * @param storylines - 故事线数据数组
   * @returns 成功创建的故事线数组
   */
  batchCreate(userId: string, storylines: CreateStoryLineDto[]): Promise<StoryLine[]>;

  /**
   * 根据 ID 全局查找故事线
   * @param id - 故事线 ID
   * @returns 故事线对象，不存在则返回 null
   */
  findByIdGlobal(id: string): Promise<StoryLine | null>;

  /**
   * 根据 ID 查找故事线
   * @param id - 故事线 ID
   * @param userId - 用户 ID
   * @returns 故事线对象，不存在则返回 null
   */
  findById(id: string, userId: string): Promise<StoryLine | null>;

  /**
   * 根据用户 ID 查找故事线列表（支持增量同步和分页）
   * @param userId - 用户 ID
   * @param lastSyncTime - 最后同步时间（可选）
   * @param limit - 每页数量（默认 100）
   * @param offset - 偏移量（默认 0）
   * @returns 故事线列表和总数
   */
  findByUserId(
    userId: string,
    lastSyncTime?: Date,
    limit?: number,
    offset?: number
  ): Promise<{ storylines: StoryLine[]; total: number }>;

  /**
   * 更新故事线
   * @param id - 故事线 ID
   * @param data - 更新数据
   * @returns 更新后的故事线
   * @note 权限验证应在 Service 层完成
   */
  update(
    id: string,
    data: UpdateStoryLineDto
  ): Promise<StoryLine>;

  /**
   * 删除故事线
   * @param id - 故事线 ID
   * @note 权限验证应在 Service 层完成
   */
  delete(id: string): Promise<void>;
}

/**
 * StoryLine Repository 实现
 * 负责故事线数据的持久化操作
 */
export class StoryLineRepository implements IStoryLineRepository {
  constructor(private prisma: PrismaClient) {}

  /**
   * 创建故事线
   */
  async create(userId: string, data: CreateStoryLineDto): Promise<StoryLine> {
    return this.prisma.storyLine.create({
      data: {
        id: data.id,
        userId,
        name: data.name,
        recordIds: toJsonValue(data.recordIds),
        isPinned: data.isPinned,
        createdAt: new Date(data.createdAt),
        updatedAt: new Date(data.updatedAt),
      },
    });
  }

  /**
   * 批量创建故事线（使用事务）
   */
  async batchCreate(userId: string, storylines: CreateStoryLineDto[]): Promise<StoryLine[]> {
    return this.prisma.$transaction(
      storylines.map((data) =>
        this.prisma.storyLine.create({
          data: {
            id: data.id,
            userId,
            name: data.name,
            recordIds: toJsonValue(data.recordIds),
            isPinned: data.isPinned,
            createdAt: new Date(data.createdAt),
            updatedAt: new Date(data.updatedAt),
          },
        })
      )
    );
  }

  /**
   * 根据 ID 全局查找故事线
   */
  async findByIdGlobal(id: string): Promise<StoryLine | null> {
    return this.prisma.storyLine.findUnique({
      where: { id },
    });
  }

  /**
   * 根据 ID 查找故事线
   */
  async findById(id: string, userId: string): Promise<StoryLine | null> {
    return this.prisma.storyLine.findFirst({
      where: { id, userId },
    });
  }

  /**
   * 根据用户 ID 查找故事线列表（支持增量同步和分页）
   */
  async findByUserId(
    userId: string,
    lastSyncTime?: Date,
    limit: number = 100,
    offset: number = 0
  ): Promise<{ storylines: StoryLine[]; total: number }> {
    const where = {
      userId,
      ...(lastSyncTime && { updatedAt: { gt: lastSyncTime } }),
    };

    const [storylines, total] = await Promise.all([
      this.prisma.storyLine.findMany({
        where,
        orderBy: { updatedAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.storyLine.count({ where }),
    ]);

    return { storylines, total };
  }

  /**
   * 更新故事线
   * 使用辅助函数构建更新数据，保持代码简洁
   */
  async update(
    id: string,
    data: UpdateStoryLineDto
  ): Promise<StoryLine> {
    const updateData = this.buildUpdateData(data);

    return this.prisma.storyLine.update({
      where: { id },
      data: updateData,
    });
  }

  /**
   * 删除故事线
   */
  async delete(id: string): Promise<void> {
    await this.prisma.storyLine.delete({
      where: { id },
    });
  }

  /**
   * 构建更新数据对象
   * 提取为私有方法，简化 update 方法
   * @private
   */
  private buildUpdateData(data: UpdateStoryLineDto): any {
    const updateData: any = {
      updatedAt: new Date(data.updatedAt),
    };

    if (data.name !== undefined) {
      updateData.name = data.name;
    }

    if (data.recordIds !== undefined) {
      updateData.recordIds = toJsonValue(data.recordIds);
    }

    if (data.isPinned !== undefined) {
      updateData.isPinned = data.isPinned;
    }

    return updateData;
  }
}
