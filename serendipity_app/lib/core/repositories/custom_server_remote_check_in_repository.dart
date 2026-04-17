import '../../models/check_in_record.dart';
import '../config/server_config.dart';
import '../services/http_client_service.dart';

class CustomServerRemoteCheckInRepository {
  final HttpClientService _httpClient;

  const CustomServerRemoteCheckInRepository({required HttpClientService httpClient})
      : _httpClient = httpClient;

  Future<CheckInRecord> createTodayCheckIn(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    try {
      final response = await _httpClient.post(ServerConfig.checkIns);
      final data = response['data'] as Map<String, dynamic>;
      return CheckInRecord.fromJson(data);
    } on HttpException catch (e) {
      throw Exception('创建签到记录失败：${e.message}');
    }
  }

  Future<Map<String, dynamic>> getCheckInStatus(
    String userId,
    int year,
    int month,
  ) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    try {
      final response = await _httpClient.get(
        ServerConfig.checkInStatus,
        queryParams: {
          'year': year.toString(),
          'month': month.toString(),
        },
      );
      return response['data'] as Map<String, dynamic>;
    } on HttpException catch (e) {
      throw Exception('获取签到状态失败：${e.message}');
    }
  }

  Future<List<CheckInRecord>> downloadCheckIns(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    try {
      final response = await _httpClient.get(ServerConfig.checkIns);
      final data = response['data'] as Map<String, dynamic>;
      final checkInsJson = data['checkIns'] as List;

      return checkInsJson
          .map((json) => CheckInRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      throw Exception('下载签到记录失败：${e.message}');
    }
  }

  Future<List<CheckInRecord>> downloadCheckInsSince(String userId, DateTime lastSyncTime) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    try {
      final response = await _httpClient.get(
        ServerConfig.checkIns,
        queryParams: {
          'lastSyncTime': lastSyncTime.toIso8601String(),
        },
      );
      final data = response['data'] as Map<String, dynamic>;
      final checkInsJson = data['checkIns'] as List;

      return checkInsJson
          .map((json) => CheckInRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      throw Exception('下载增量签到记录失败：${e.message}');
    }
  }

  Future<void> deleteCheckIn(String userId, String checkInId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (checkInId.isEmpty) {
      throw ArgumentError('签到记录 ID 不能为空');
    }

    try {
      await _httpClient.delete(ServerConfig.checkInById(checkInId));
    } on HttpException catch (e) {
      throw Exception('删除签到记录失败：${e.message}');
    }
  }
}

