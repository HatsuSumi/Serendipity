import { CommunityPostResponseDto } from './community.dto';
import { RecordResponseDto } from './record.dto';

export type FavoritePostSnapshotDto = CommunityPostResponseDto;

export type FavoriteRecordSnapshotDto = RecordResponseDto;

export interface FavoritedPostsResponseDto {
  posts: CommunityPostResponseDto[];
  deletedPosts: CommunityPostResponseDto[];
  deletedPostIds: string[];
}

export interface FavoritedRecordsResponseDto {
  records: RecordResponseDto[];
  deletedRecords: RecordResponseDto[];
  deletedRecordIds: string[];
}

