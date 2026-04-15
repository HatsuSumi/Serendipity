import '../../models/membership.dart';
import '../../models/user.dart';
import '../repositories/i_remote_data_repository.dart';
import 'i_storage_service.dart';

class MembershipSyncService {
  final IRemoteDataRepository _remoteRepository;
  final IStorageService _storageService;

  MembershipSyncService({
    required IRemoteDataRepository remoteRepository,
    required IStorageService storageService,
  }) : _remoteRepository = remoteRepository,
       _storageService = storageService;

  /// 会员数据以服务端为真源
  Future<Membership?> refreshMembership(User user) async {
    if (user.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    final remoteMembership = await _remoteRepository.downloadMembership(user.id);
    if (remoteMembership == null) {
      await _storageService.deleteMembership(user.id);
      return null;
    }

    await _storageService.saveMembership(remoteMembership);
    return remoteMembership;
  }

  Future<void> syncMembership(User user) async {
    try {
      await refreshMembership(user);
    } catch (e) {
      // 会员同步失败不影响其他数据同步
    }
  }
}

