/// 同步结果统计
///
/// 记录同步过程中的数据统计信息
class SyncResult {
  /// 上传的记录数量
  final int uploadedRecords;

  /// 上传的故事线数量
  final int uploadedStoryLines;

  /// 上传的签到记录数量
  final int uploadedCheckIns;

  /// 下载的记录数量
  final int downloadedRecords;

  /// 下载的故事线数量
  final int downloadedStoryLines;

  /// 下载的签到记录数量
  final int downloadedCheckIns;

  /// 合并冲突的记录数量
  final int mergedRecords;

  /// 合并冲突的故事线数量
  final int mergedStoryLines;

  /// 合并冲突的签到记录数量
  final int mergedCheckIns;

  /// 同步的成就解锁数量
  final int syncedAchievements;

  const SyncResult({
    required this.uploadedRecords,
    required this.uploadedStoryLines,
    required this.uploadedCheckIns,
    required this.downloadedRecords,
    required this.downloadedStoryLines,
    required this.downloadedCheckIns,
    required this.mergedRecords,
    required this.mergedStoryLines,
    required this.mergedCheckIns,
    required this.syncedAchievements,
  });

  /// 是否有数据变化
  ///
  /// 注意：不包括 syncedAchievements，因为成就同步是静默的，不算作"有变化"
  bool get hasChanges {
    return uploadedRecords > 0 ||
        uploadedStoryLines > 0 ||
        uploadedCheckIns > 0 ||
        downloadedRecords > 0 ||
        downloadedStoryLines > 0 ||
        downloadedCheckIns > 0 ||
        mergedRecords > 0 ||
        mergedStoryLines > 0 ||
        mergedCheckIns > 0;
  }
}

class UploadSyncStats {
  final int records;
  final int storyLines;
  final int checkIns;

  const UploadSyncStats({
    required this.records,
    required this.storyLines,
    required this.checkIns,
  });
}

class DownloadSyncStats {
  final int records;
  final int storyLines;
  final int checkIns;
  final int mergedRecords;
  final int mergedStoryLines;
  final int mergedCheckIns;

  const DownloadSyncStats({
    required this.records,
    required this.storyLines,
    required this.checkIns,
    required this.mergedRecords,
    required this.mergedStoryLines,
    required this.mergedCheckIns,
  });
}

