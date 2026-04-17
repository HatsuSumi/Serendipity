import '../../models/push_token_registration.dart';
import 'i_remote_data_repository.dart';
import '../config/server_config.dart';
import '../services/http_client_service.dart';

class CustomServerRemotePushRepository {
  final HttpClientService _httpClient;

  const CustomServerRemotePushRepository({required HttpClientService httpClient})
      : _httpClient = httpClient;

  Future<void> registerPushToken(PushTokenRegistration registration) async {
    if (registration.token.isEmpty) {
      throw ArgumentError('push token 不能为空');
    }
    if (registration.platform.isEmpty) {
      throw ArgumentError('platform 不能为空');
    }
    if (registration.timezone.isEmpty) {
      throw ArgumentError('timezone 不能为空');
    }

    try {
      await _httpClient.post(
        ServerConfig.pushTokens,
        body: registration.toJson(),
      );
    } on HttpException catch (e) {
      throw Exception('注册 push token 失败：${e.message}');
    }
  }

  Future<void> unregisterPushToken(String token) async {
    if (token.isEmpty) {
      throw ArgumentError('push token 不能为空');
    }

    try {
      await _httpClient.delete(
        ServerConfig.pushTokens,
        body: {'token': token},
      );
    } on HttpException catch (e) {
      throw Exception('注销 push token 失败：${e.message}');
    }
  }

  Future<RepositoryPushTokenStatus> listPushTokens() async {
    try {
      final response = await _httpClient.get(ServerConfig.pushTokens);
      return RepositoryPushTokenStatus.fromJson(response['data'] as Map<String, dynamic>);
    } on HttpException catch (e) {
      throw Exception('获取 push token 注册状态失败：${e.message}');
    }
  }

  Future<RepositoryServerTestPushSummary> sendCheckInReminderTest() async {
    try {
      final response = await _httpClient.post(
        '${ServerConfig.pushTokens}/test/check-in-reminder',
      );
      return RepositoryServerTestPushSummary.fromJson(response['data'] as Map<String, dynamic>);
    } on HttpException catch (e) {
      throw Exception('发送签到提醒测试推送失败：${e.message}');
    }
  }

  Future<RepositoryServerTestPushSummary> sendAnniversaryReminderTest() async {
    try {
      final response = await _httpClient.post(
        '${ServerConfig.pushTokens}/test/anniversary-reminder',
      );
      return RepositoryServerTestPushSummary.fromJson(response['data'] as Map<String, dynamic>);
    } on HttpException catch (e) {
      throw Exception('发送纪念日提醒测试推送失败：${e.message}');
    }
  }
}

