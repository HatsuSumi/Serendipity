import '../../models/achievement_unlock.dart';
import '../config/server_config.dart';
import '../services/http_client_service.dart';

class CustomServerRemoteAchievementRepository {
  final HttpClientService _httpClient;

  const CustomServerRemoteAchievementRepository({required HttpClientService httpClient})
      : _httpClient = httpClient;

  Future<void> uploadAchievementUnlock(AchievementUnlock unlock) async {
    if (unlock.userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (unlock.achievementId.isEmpty) {
      throw ArgumentError('成就 ID 不能为空');
    }

    try {
      await _httpClient.post(
        ServerConfig.achievementUnlocks,
        body: unlock.toJson(),
      );
    } on HttpException catch (e) {
      throw Exception('上传成就解锁记录失败：${e.message}');
    }
  }

  Future<List<AchievementUnlock>> downloadAchievementUnlocks(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    try {
      final response = await _httpClient.get(
        ServerConfig.achievementUnlocks,
        queryParams: {'userId': userId},
      );
      final data = response['data'] as Map<String, dynamic>;
      final unlocksJson = data['unlocks'] as List;

      return unlocksJson
          .map((json) => AchievementUnlock.fromJson(json as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      throw Exception('下载成就解锁记录失败：${e.message}');
    }
  }
}

