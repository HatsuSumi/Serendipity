// 记录相关的 DTO（Data Transfer Object）

// 位置信息
export interface LocationDto {
  latitude?: number;
  longitude?: number;
  address?: string;
  placeName?: string;
  placeType?: string;
  province?: string;
  city?: string;
  area?: string;
}

// 标签 + 备注
export interface TagWithNoteDto {
  tag: string;
  note?: string;
}

// 创建记录请求
export interface CreateRecordDto {
  id: string;
  sourceDeviceId: string;
  timestamp: Date;
  location: LocationDto;
  description?: string;
  tags: TagWithNoteDto[];
  emotion?: string;
  status: string;
  storyLineId?: string;
  ifReencounter?: string;
  conversationStarter?: string;
  backgroundMusic?: string;
  weather: string[];
  isPinned: boolean;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;
}

// 批量上传记录请求
export interface BatchCreateRecordsDto {
  records: CreateRecordDto[];
}

// 更新记录请求
export interface UpdateRecordDto {
  timestamp?: Date;
  location?: LocationDto;
  description?: string;
  tags?: TagWithNoteDto[];
  emotion?: string;
  status?: string;
  storyLineId?: string;
  ifReencounter?: string;
  conversationStarter?: string;
  backgroundMusic?: string;
  weather?: string[];
  isPinned?: boolean;
  updatedAt: Date;
  deletedAt?: Date;
}

// 下载记录查询参数
export interface GetRecordsQueryDto {
  lastSyncTime?: string;
  deviceId?: string;
  limit?: number;
  offset?: number;
}

// 记录响应
export interface RecordResponseDto {
  id: string;
  ownerId: string;
  sourceDeviceId: string;
  timestamp: string;
  location: LocationDto;
  description?: string;
  tags: TagWithNoteDto[];
  emotion?: string;
  status: string;
  storyLineId?: string;
  ifReencounter?: string;
  conversationStarter?: string;
  backgroundMusic?: string;
  weather: string[];
  isPinned: boolean;
  createdAt: string;
  updatedAt: string;
  deletedAt?: string;
}

// 批量上传响应
export interface BatchCreateRecordsResponseDto {
  total: number;
  succeeded: number;
  failed: number;
  syncedAt: Date;
}

// 下载记录响应
export interface GetRecordsResponseDto {
  records: RecordResponseDto[];
  total: number;
  hasMore: boolean;
  syncTime: Date;
}

