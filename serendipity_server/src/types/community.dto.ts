// 社区帖子相关的 DTO 类型定义

// 标签类型
export interface TagDto {
  tag: string;
  note?: string;
}

// 发布社区帖子请求
export interface CreateCommunityPostDto {
  id: string;
  recordId: string;
  timestamp: string; // ISO 8601 格式
  address?: string;
  placeName?: string;
  placeType?: string;
  province?: string;  // 省份（如"广东省"）
  city?: string;      // 城市（如"深圳市"）
  area?: string;      // 区县（如"南山区"）
  description?: string;
  tags: TagDto[];
  status: string;
  publishedAt?: string; // ISO 8601 格式，可选
  forceReplace?: boolean; // 是否强制替换（用户已确认）
}

// 社区帖子响应
export interface CommunityPostResponseDto {
  id: string;
  recordId: string;
  timestamp: string;
  address?: string;
  placeName?: string;
  placeType?: string;
  province?: string;  // 省份（如"广东省"）
  city?: string;      // 城市（如"深圳市"）
  area?: string;      // 区县（如"南山区"）
  description?: string;
  tags: TagDto[];
  status: string;
  isOwner?: boolean;  // 是否是当前用户的帖子（用于显示删除按钮）
  publishedAt: string;
  createdAt: string;
  updatedAt: string;
}

// 发布社区帖子响应
export interface CreateCommunityPostResponseDto {
  id: string;
  publishedAt: string;
  replaced: boolean;  // 是否替换了旧帖子
}

// 社区帖子列表响应
export interface CommunityPostListResponseDto {
  posts: CommunityPostResponseDto[];
  hasMore: boolean;
}

// 我的社区帖子响应
export interface MyCommunityPostsResponseDto {
  posts: CommunityPostResponseDto[];
  total: number;
}

// 筛选社区帖子查询参数
export interface FilterCommunityPostsQuery {
  startDate?: string; // YYYY-MM-DD 错过时间开始
  endDate?: string; // YYYY-MM-DD 错过时间结束
  publishStartDate?: string; // YYYY-MM-DD 发布时间开始
  publishEndDate?: string; // YYYY-MM-DD 发布时间结束
  province?: string;  // 省份（如"广东省"）
  city?: string;      // 城市（如"深圳市"）
  area?: string;      // 区县（如"南山区"）
  placeTypes?: string; // 场所类型（多个用逗号分隔，OR逻辑）
  tags?: string; // 标签（多个用逗号分隔，OR逻辑）
  statuses?: string; // 状态（多个用逗号分隔，OR逻辑）
  limit?: number;
}

// 检查发布状态请求
export interface CheckPublishStatusDto {
  recordId: string;
  timestamp: string;
  address?: string;
  placeName?: string;
  placeType?: string;
  province?: string;
  city?: string;
  area?: string;
  description?: string;
  tags: TagDto[];
  status: string;
}

// 发布状态枚举
export enum PublishStatus {
  CAN_PUBLISH = 'can_publish',           // 可以发布（未发布过）
  NEED_CONFIRM = 'need_confirm',         // 需要确认（已发布，内容已变化）
  CANNOT_PUBLISH = 'cannot_publish',     // 不能发布（已发布，内容未变化）
}

// 单条记录的发布状态响应
export interface RecordPublishStatusDto {
  recordId: string;
  status: PublishStatus;
}

// 批量检查发布状态响应
export interface CheckPublishStatusResponseDto {
  statuses: RecordPublishStatusDto[];
}

