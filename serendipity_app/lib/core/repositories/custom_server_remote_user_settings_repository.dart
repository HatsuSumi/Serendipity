import '../../models/user_settings.dart';
import '../config/server_config.dart';
import '../services/http_client_service.dart';

class CustomServerRemoteUserSettingsRepository {
  final HttpClientService _httpClient;

  const CustomServerRemoteUserSettingsRepository({required HttpClientService httpClient})
      : _httpClient = httpClient;

  Future<UserSettings> uploadSettings(String userId, UserSettings settings) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (settings.userId.isEmpty) {
      throw ArgumentError('用户设置中的用户 ID 不能为空');
    }
    if (settings.userId != userId) {
      throw ArgumentError('用户设置中的用户 ID 与参数不一致');
    }

    try {
      final response = await _httpClient.put(
        ServerConfig.usersSettings,
        body: settings.toServerDto(),
      );
      final data = response['data'] as Map<String, dynamic>;
      return UserSettings.fromServerDto(data, userId);
    } on HttpException catch (e) {
      throw Exception('上传用户设置失败：${e.message}');
    }
  }

  Future<UserSettings?> downloadSettings(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    try {
      final response = await _httpClient.get(ServerConfig.usersSettings);
      final data = response['data'] as Map<String, dynamic>;
      return UserSettings.fromServerDto(data, userId);
    } on HttpException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      throw Exception('下载用户设置失败：${e.message}');
    }
  }
}

