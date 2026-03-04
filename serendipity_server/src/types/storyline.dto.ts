// 故事线相关的 DTO（Data Transfer Object）

// 创建故事线请求
export interface CreateStoryLineDto {
  id: string;
  name: string;
  recordIds: string[];
  createdAt: Date;
  updatedAt: Date;
}

// 批量上传故事线请求
export interface BatchCreateStoryLinesDto {
  storyLines: CreateStoryLineDto[];
}

// 更新故事线请求
export interface UpdateStoryLineDto {
  name?: string;
  recordIds?: string[];
  updatedAt: Date;
}

// 下载故事线查询参数
export interface GetStoryLinesQueryDto {
  lastSyncTime?: string;
  limit?: number;
  offset?: number;
}

// 故事线响应
export interface StoryLineResponseDto {
  id: string;
  userId: string;
  name: string;
  recordIds: string[];
  createdAt: Date;
  updatedAt: Date;
}

// 批量上传响应
export interface BatchCreateStoryLinesResponseDto {
  total: number;
  succeeded: number;
  failed: number;
  syncedAt: Date;
}

// 下载故事线响应
export interface GetStoryLinesResponseDto {
  storylines: StoryLineResponseDto[];
  total: number;
  hasMore: boolean;
  syncTime: Date;
}

