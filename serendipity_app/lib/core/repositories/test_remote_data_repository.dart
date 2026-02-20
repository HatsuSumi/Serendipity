import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import 'i_remote_data_repository.dart';

/// 测试远程数据仓库
/// 
/// 仅用于开发和测试环境，提供空实现（不执行任何操作）。
/// 遵循依赖倒置原则（DIP），实现 IRemoteDataRepository 接口。
/// 
/// 使用场景：
/// - 开发环境：无需真实 Firebase 配置即可测试
/// - 单元测试：避免真实网络请求
/// - 集成测试：提供可预测的行为
class TestRemoteDataRepository implements IRemoteDataRepository {
  @override
  Future<void> uploadRecord(String userId, EncounterRecord record) async {
    // 测试模式：不执行任何操作
    print('🔍 [TestRemoteData] uploadRecord: ${record.id} (测试模式，不上传)');
  }

  @override
  Future<void> uploadRecords(String userId, List<EncounterRecord> records) async {
    // 测试模式：不执行任何操作
    print('🔍 [TestRemoteData] uploadRecords: ${records.length} 条记录 (测试模式，不上传)');
  }

  @override
  Future<List<EncounterRecord>> downloadRecords(String userId) async {
    // 测试模式：返回空列表
    print('🔍 [TestRemoteData] downloadRecords (测试模式，返回空列表)');
    return [];
  }

  @override
  Future<void> deleteRecord(String userId, String recordId) async {
    // 测试模式：不执行任何操作
    print('🔍 [TestRemoteData] deleteRecord: $recordId (测试模式，不删除)');
  }

  @override
  Future<void> uploadStoryLine(String userId, StoryLine storyLine) async {
    // 测试模式：不执行任何操作
    print('🔍 [TestRemoteData] uploadStoryLine: ${storyLine.id} (测试模式，不上传)');
  }

  @override
  Future<void> uploadStoryLines(String userId, List<StoryLine> storyLines) async {
    // 测试模式：不执行任何操作
    print('🔍 [TestRemoteData] uploadStoryLines: ${storyLines.length} 条故事线 (测试模式，不上传)');
  }

  @override
  Future<List<StoryLine>> downloadStoryLines(String userId) async {
    // 测试模式：返回空列表
    print('🔍 [TestRemoteData] downloadStoryLines (测试模式，返回空列表)');
    return [];
  }

  @override
  Future<void> deleteStoryLine(String userId, String storyLineId) async {
    // 测试模式：不执行任何操作
    print('🔍 [TestRemoteData] deleteStoryLine: $storyLineId (测试模式，不删除)');
  }
}

