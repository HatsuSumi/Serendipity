import '../../models/story_line.dart';
import '../config/server_config.dart';
import '../services/http_client_service.dart';

class CustomServerRemoteStoryLinesRepository {
  final HttpClientService _httpClient;

  const CustomServerRemoteStoryLinesRepository({required HttpClientService httpClient})
      : _httpClient = httpClient;

  Map<String, dynamic> toServerDto(StoryLine storyLine) {
    final json = storyLine.toJson();
    json.remove('userId');
    return json;
  }

  Future<void> uploadStoryLine(String userId, StoryLine storyLine) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    try {
      await _httpClient.post(
        ServerConfig.storylines,
        body: toServerDto(storyLine),
      );
    } on HttpException catch (e) {
      throw Exception('上传故事线失败：${e.message}');
    }
  }

  Future<void> updateStoryLine(String userId, StoryLine storyLine) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    try {
      await _httpClient.put(
        ServerConfig.storylineById(storyLine.id),
        body: toServerDto(storyLine),
      );
    } on HttpException catch (e) {
      throw Exception('更新故事线失败：${e.message}');
    }
  }

  Future<void> uploadStoryLines(String userId, List<StoryLine> storyLines) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (storyLines.isEmpty) {
      return;
    }

    try {
      await _httpClient.post(
        ServerConfig.storylinesBatch,
        body: {
          'storyLines': storyLines.map(toServerDto).toList(),
        },
      );
    } on HttpException catch (e) {
      throw Exception('批量上传故事线失败：${e.message}');
    }
  }

  Future<List<StoryLine>> downloadStoryLines(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    try {
      final response = await _httpClient.get(ServerConfig.storylines);
      final data = response['data'] as Map<String, dynamic>;
      final storylinesJson = data['storyLines'] as List;

      return storylinesJson
          .map((json) => StoryLine.fromJson(json as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      throw Exception('下载故事线失败：${e.message}');
    }
  }

  Future<List<StoryLine>> downloadStoryLinesSince(String userId, DateTime lastSyncTime) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    try {
      final response = await _httpClient.get(
        ServerConfig.storylines,
        queryParams: {
          'lastSyncTime': lastSyncTime.toIso8601String(),
        },
      );
      final data = response['data'] as Map<String, dynamic>;
      final storylinesJson = data['storyLines'] as List;

      return storylinesJson
          .map((json) => StoryLine.fromJson(json as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      throw Exception('下载增量故事线失败：${e.message}');
    }
  }

  Future<void> deleteStoryLine(String userId, String storyLineId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (storyLineId.isEmpty) {
      throw ArgumentError('故事线 ID 不能为空');
    }

    try {
      await _httpClient.delete(ServerConfig.storylineById(storyLineId));
    } on HttpException catch (e) {
      throw Exception('删除故事线失败：${e.message}');
    }
  }
}

