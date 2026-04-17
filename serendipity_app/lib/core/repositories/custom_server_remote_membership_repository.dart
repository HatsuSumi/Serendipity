import '../../models/membership.dart';
import '../config/server_config.dart';
import '../services/http_client_service.dart';

class CustomServerRemoteMembershipRepository {
  final HttpClientService _httpClient;

  const CustomServerRemoteMembershipRepository({required HttpClientService httpClient})
      : _httpClient = httpClient;

  Future<Membership?> downloadMembership(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    try {
      final response = await _httpClient.get(ServerConfig.usersMembership);
      final data = response['data'];
      if (data == null) {
        return null;
      }
      return Membership.fromJson(data as Map<String, dynamic>);
    } on HttpException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      throw Exception('下载会员信息失败：${e.message}');
    }
  }

  Future<Membership> activateMembership(String userId, double monthlyAmount) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (monthlyAmount < 0 || monthlyAmount > 648) {
      throw ArgumentError('monthlyAmount 必须在 0 到 648 之间');
    }

    try {
      final response = await _httpClient.post(
        ServerConfig.usersMembership,
        body: {'monthlyAmount': monthlyAmount},
      );
      final data = response['data'] as Map<String, dynamic>;
      return Membership.fromJson(data);
    } on HttpException catch (e) {
      throw Exception('开通会员失败：${e.message}');
    }
  }
}

