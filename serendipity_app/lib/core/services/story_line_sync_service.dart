import '../../models/story_line.dart';
import '../../models/user.dart';
import '../repositories/i_remote_data_repository.dart';
import 'i_storage_service.dart';

class StoryLineSyncService {
  final IRemoteDataRepository _remoteRepository;
  final IStorageService _storageService;

  StoryLineSyncService({
    required IRemoteDataRepository remoteRepository,
    required IStorageService storageService,
  }) : _remoteRepository = remoteRepository,
       _storageService = storageService;

  Future<void> uploadStoryLine(User user, StoryLine storyLine) async {
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    await _remoteRepository.uploadStoryLine(user.id, storyLine);
  }

  Future<void> updateStoryLine(User user, StoryLine storyLine) async {
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    await _remoteRepository.updateStoryLine(user.id, storyLine);
  }

  Future<void> deleteStoryLine(User user, String storyLineId) async {
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (storyLineId.isEmpty) {
      throw ArgumentError('故事线 ID 不能为空');
    }

    await _remoteRepository.deleteStoryLine(user.id, storyLineId);
  }

  Future<int> uploadChangedStoryLines(User user, {DateTime? lastSyncTime}) async {
    final userStoryLines = _storageService.getStoryLinesByUser(user.id);
    final changedStoryLines = lastSyncTime == null
        ? userStoryLines
        : userStoryLines.where((storyLine) => storyLine.updatedAt.isAfter(lastSyncTime)).toList();
    if (changedStoryLines.isEmpty) {
      return 0;
    }

    await _remoteRepository.uploadStoryLines(user.id, changedStoryLines);
    return changedStoryLines.length;
  }

  Future<StoryLineDownloadResult> downloadAndMergeStoryLines(
    User user, {
    required DateTime? lastSyncTime,
    required bool isFullSync,
  }) async {
    final remoteStoryLines = isFullSync
        ? await _remoteRepository.downloadStoryLines(user.id)
        : await _remoteRepository.downloadStoryLinesSince(user.id, lastSyncTime!);
    final mergedStoryLines = await mergeStoryLines(
      remoteStoryLines,
      user.id,
      isFullSync,
    );
    return StoryLineDownloadResult(
      downloadedStoryLines: remoteStoryLines.length,
      mergedStoryLines: mergedStoryLines,
    );
  }

  Future<int> mergeStoryLines(
    List<StoryLine> remoteStoryLines,
    String userId,
    bool isFullSync,
  ) async {
    int mergedCount = 0;

    for (final remoteStoryLine in remoteStoryLines) {
      if (remoteStoryLine.deletedAt != null) {
        final localStoryLine = _storageService.getStoryLine(remoteStoryLine.id);
        if (localStoryLine != null) {
          await _storageService.deleteStoryLine(remoteStoryLine.id);
          mergedCount++;
        }
        continue;
      }

      final localStoryLine = _storageService.getStoryLine(remoteStoryLine.id);
      if (localStoryLine == null ||
          remoteStoryLine.updatedAt.isAfter(localStoryLine.updatedAt)) {
        await _storageService.saveStoryLine(remoteStoryLine);
        if (localStoryLine != null) {
          mergedCount++;
        }
      }
    }

    if (isFullSync) {
      final remoteStoryLineIds = remoteStoryLines.map((storyLine) => storyLine.id).toSet();
      final localStoryLines = _storageService.getStoryLinesByUser(userId);
      for (final localStoryLine in localStoryLines) {
        if (!remoteStoryLineIds.contains(localStoryLine.id)) {
          await _storageService.deleteStoryLine(localStoryLine.id);
        }
      }
    }

    return mergedCount;
  }
}

class StoryLineDownloadResult {
  final int downloadedStoryLines;
  final int mergedStoryLines;

  const StoryLineDownloadResult({
    required this.downloadedStoryLines,
    required this.mergedStoryLines,
  });
}

