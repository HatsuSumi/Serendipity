import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../models/sync_history.dart';
import '../repositories/i_auth_repository.dart';
import '../repositories/test_auth_repository.dart';
import '../repositories/custom_server_auth_repository.dart';
import '../services/http_client_service.dart';
import '../services/i_storage_service.dart';
import '../services/sync_service.dart';
import '../config/app_config.dart';
import 'records_provider.dart';
import 'story_lines_provider.dart';
import 'check_in_provider.dart';
import 'achievement_provider.dart';
import 'community_provider.dart';

/// 存储服务 Provider
final storageServiceProvider = Provider<IStorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be overridden in main.dart');
});

/// HTTP 客户端服务 Provider
final httpClientServiceProvider = Provider<HttpClientService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return HttpClientService(storage: storage);
});

/// 认证仓储 Provider
/// 
/// 依赖抽象接口 IAuthRepository，不依赖具体实现。
/// 遵循依赖倒置原则（DIP）：切换后端只需修改 AppConfig.serverType。
/// 
/// 后端选择：
/// - ServerType.test：使用 TestAuthRepository（测试模式）
/// - ServerType.customServer：使用 CustomServerAuthRepository（自建服务器）
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  switch (AppConfig.serverType) {
    case ServerType.test:
      return TestAuthRepository();
    
    case ServerType.customServer:
      final httpClient = ref.watch(httpClientServiceProvider);
      return CustomServerAuthRepository(httpClient: httpClient);
  }
});

/// 用户认证状态管理
/// 
/// 负责用户登录、注册、登出等认证操作。
/// 遵循单一职责原则（SRP）和分层约束。
/// 
/// 调用者：
/// - LoginPage：邮箱登录、手机号登录
/// - RegisterPage：邮箱注册、手机号注册
/// - SettingsPage：登出（未来）
/// - main.dart：监听认证状态变化，决定显示欢迎页还是主页
class AuthNotifier extends StreamNotifier<User?> {
  late IAuthRepository _repository;

  @override
  Stream<User?> build() {
    _repository = ref.read(authRepositoryProvider);
    // 监听认证状态变化
    // 注意：TestAuthRepository 的 authStateChanges 会立即发送当前状态
    return _repository.authStateChanges;
  }
  
  /// 触发数据同步
  /// 
  /// 调用时机：用户登录/注册成功后
  /// 
  /// 同步策略：
  /// - 注册：首次同步（lastSyncTime: null），只上传不下载
  ///   原因：新用户云端确实没有数据
  /// - 登录：读取该用户的上次同步时间
  ///   - 该用户首次同步（lastSyncTime: null）：全量下载
  ///   - 该用户非首次同步（lastSyncTime != null）：增量同步
  /// 
  /// 注意：同步失败不影响用户使用，用户可以稍后手动触发同步
  Future<void> _triggerSync(User user, {bool isRegister = false}) async {
    try {
      final syncService = ref.read(syncServiceProvider);
      
      // 注册场景：跳过下载（新用户云端确实没数据）
      // 登录/启动场景：读取持久化的上次同步时间，null 时全量下载
      final lastSyncTime = isRegister
          ? null
          : await syncService.getLastSyncTime(user.id);
      
      await syncService.syncAllData(
        user,
        lastSyncTime: lastSyncTime,
        skipDownload: isRegister,
        source: isRegister ? SyncSource.register : SyncSource.login,
      );
      
      // 同步完成后刷新所有数据 Provider
      _invalidateDataProviders();
      // 同时递增信号，确保 watch(syncCompletedProvider) 的 Provider 也重建
      ref.read(syncCompletedProvider.notifier).state++;
    } catch (e) {
      // 同步失败不影响用户使用
    }
  }
  
  /// 刷新所有数据 Provider（清除内存缓存）
  /// 
  /// 调用时机：
  /// - 清空本地数据后
  /// - 数据同步完成后
  /// 
  /// 作用：强制 Provider 重新从存储加载数据
  /// 刷新所有数据 Provider（清除内存缓存）
  /// 
  /// 调用时机：
  /// - 清空本地数据后
  /// - 数据同步完成后
  /// 
  /// 作用：强制 Provider 重新从存储加载数据
  /// 
  /// 设计说明：
  /// - 所有数据 Provider（recordsProvider、storyLinesProvider、checkInProvider）
  ///   都是 AsyncNotifier，在 build() 里 watch(syncCompletedProvider)
  /// - invalidate 后，Provider 重建，自动以新 userId 加载数据
  /// - 无需显式调用 refresh()，架构完全信号驱动
  void _invalidateDataProviders() {
    ref.invalidate(recordsProvider);
    ref.invalidate(storyLinesProvider);
    ref.invalidate(checkInProvider);
    ref.invalidate(achievementsProvider);
    // 社区列表携带 isOwner 字段，用户切换时必须重新以新身份加载
    // 否则登出后匿名刷新的结果（isOwner=false）会在重新登录后持续显示
    ref.invalidate(communityProvider);
    ref.invalidate(myPostsProvider);
  }

  /// 获取当前用户
  /// 
  /// 调用者：
  /// - main.dart：判断是否已登录
  /// - 各个需要用户信息的页面
  Future<User?> get currentUser => _repository.currentUser;

  /// 邮箱登录
  /// 
  /// 调用者：LoginPage._handleEmailLogin()
  /// 
  /// 登录流程：
  /// 1. 调用 AuthRepository 登录
  /// 2. 检查并绑定离线数据（如果有）
  /// 3. 刷新所有数据 Provider
  /// 4. 触发数据同步（从云端下载当前用户数据）
  /// 
  /// Fail Fast：
  /// - 邮箱格式错误立即抛异常
  /// - 密码长度不足立即抛异常
  /// - 登录失败立即抛异常
  Future<void> signInWithEmail(String email, String password) async {
    // Fail Fast：参数验证（UI 层已经 trim，这里只验证非空）
    if (email.isEmpty) {
      throw ArgumentError('邮箱不能为空');
    }
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }

    state = const AsyncValue.loading();
    
    try {
      // 1. 调用 AuthRepository 登录
      await _repository.signInWithEmail(email, password);
      final user = await _repository.currentUser;
      state = AsyncValue.data(user);
      
      if (user != null) {
        // 2. 绑定离线数据到当前用户
        await _bindOfflineDataIfNeeded(user.id);
        
        // 3. 刷新所有数据 Provider
        _invalidateDataProviders();
        
        // 4. 登录成功后触发数据同步
        await _triggerSync(user);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 重新抛出异常，让调用者可以捕获
    }
  }

  /// 邮箱注册
  /// 
  /// 调用者：RegisterPage._handleEmailRegister()
  /// 
  /// 注册流程：
  /// 1. 调用 AuthRepository 注册
  /// 2. 绑定离线数据到新账号
  /// 3. 刷新所有数据 Provider
  /// 4. 触发数据同步（上传到云端）
  /// 
  /// 返回：恢复密钥（仅在注册时返回一次）
  /// 
  /// Fail Fast：
  /// - 邮箱格式错误立即抛异常
  /// - 密码长度不足立即抛异常
  /// - 注册失败立即抛异常
  Future<String?> signUpWithEmail(String email, String password) async {
    // Fail Fast：参数验证（UI 层已经 trim，这里只验证非空）
    if (email.isEmpty) {
      throw ArgumentError('邮箱不能为空');
    }
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }

    state = const AsyncValue.loading();
    
    try {
      // 1. 调用 AuthRepository 注册
      final result = await _repository.signUpWithEmail(email, password);
      state = AsyncValue.data(result.user);
      
      // 2. 绑定离线数据到新账号
      await _bindOfflineDataIfNeeded(result.user.id);
      
      // 3. 刷新所有数据 Provider
      _invalidateDataProviders();
      
      // 4. 注册成功后触发数据同步
      await _triggerSync(result.user, isRegister: true);
      
      return result.recoveryKey; // 返回恢复密钥
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 重新抛出异常，让调用者可以捕获
    }
  }

  /// 发送手机验证码
  /// 
  /// 返回：验证 ID（用于后续验证）
  /// 
  /// 调用者：
  /// - LoginPage._sendVerificationCode()
  /// - RegisterPage._sendVerificationCode()
  /// 
  /// Fail Fast：
  /// - 手机号格式错误立即抛异常
  /// - 发送失败立即抛异常
  Future<String> sendPhoneVerificationCode(String phoneNumber) async {
    // Fail Fast：参数验证（UI 层已经 trim，这里只验证非空和格式）
    if (phoneNumber.isEmpty) {
      throw ArgumentError('手机号不能为空');
    }
    // 注意：phoneNumber 已经在页面层拼接了国家代码（如 +8613800138000）
    // 这里只需要验证格式是否正确
    if (!phoneNumber.startsWith('+')) {
      throw ArgumentError('手机号格式错误：缺少国家代码');
    }

    return await _repository.sendPhoneVerificationCode(phoneNumber);
  }

  /// 手机号登录
  /// 
  /// 调用者：LoginPage._handlePhoneLogin()
  /// 
  /// 登录流程：
  /// 1. 调用 AuthRepository 登录
  /// 2. 检查并绑定离线数据（如果有）
  /// 3. 刷新所有数据 Provider
  /// 4. 触发数据同步（从云端下载当前用户数据）
  /// 
  /// Fail Fast：
  /// - 手机号格式错误立即抛异常
  /// - 验证码格式错误立即抛异常
  /// - verificationId 为空立即抛异常
  /// - 登录失败立即抛异常
  Future<void> signInWithPhone(
    String phoneNumber,
    String verificationCode,
    String verificationId,
  ) async {
    // Fail Fast：参数验证（UI 层已经 trim，这里只验证非空）
    if (phoneNumber.isEmpty) {
      throw ArgumentError('手机号不能为空');
    }
    if (verificationCode.isEmpty) {
      throw ArgumentError('验证码不能为空');
    }
    if (verificationId.isEmpty) {
      throw ArgumentError('验证 ID 不能为空');
    }

    state = const AsyncValue.loading();
    
    try {
      // 1. 调用 AuthRepository 登录
      await _repository.signInWithPhone(
        phoneNumber,
        verificationCode,
        verificationId,
      );
      final user = await _repository.currentUser;
      state = AsyncValue.data(user);
      
      if (user != null) {
        // 2. 绑定离线数据到当前用户
        await _bindOfflineDataIfNeeded(user.id);
        
        // 3. 刷新所有数据 Provider
        _invalidateDataProviders();
        
        // 4. 登录成功后触发数据同步
        await _triggerSync(user);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 重新抛出异常，让调用者可以捕获
    }
  }

  /// 手机号注册
  /// 
  /// 调用者：RegisterPage._handlePhoneRegister()
  /// 
  /// 注册流程：
  /// 1. 调用 AuthRepository 注册
  /// 2. 绑定离线数据到新账号
  /// 3. 刷新所有数据 Provider
  /// 4. 触发数据同步（上传到云端）
  /// 
  /// 返回：恢复密钥（仅在注册时返回一次）
  /// 
  /// Fail Fast：
  /// - 手机号格式错误立即抛异常
  /// - 验证码格式错误立即抛异常
  /// - verificationId 为空立即抛异常
  /// - 注册失败立即抛异常
  Future<String?> signUpWithPhone(
    String phoneNumber,
    String verificationCode,
    String verificationId,
  ) async {
    // Fail Fast：参数验证（UI 层已经 trim，这里只验证非空）
    if (phoneNumber.isEmpty) {
      throw ArgumentError('手机号不能为空');
    }
    if (verificationCode.isEmpty) {
      throw ArgumentError('验证码不能为空');
    }
    if (verificationId.isEmpty) {
      throw ArgumentError('验证 ID 不能为空');
    }

    state = const AsyncValue.loading();
    
    try {
      // 1. 调用 AuthRepository 注册
      final result = await _repository.signUpWithPhone(
        phoneNumber,
        verificationCode,
        verificationId,
      );
      state = AsyncValue.data(result.user);
      
      // 2. 绑定离线数据到新账号
      await _bindOfflineDataIfNeeded(result.user.id);
      
      // 3. 刷新所有数据 Provider
      _invalidateDataProviders();
      
      // 4. 注册成功后触发数据同步
      await _triggerSync(result.user, isRegister: true);
      
      return result.recoveryKey; // 返回恢复密钥
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 重新抛出异常，让调用者可以捕获
    }
  }

  /// 登出
  /// 
  /// 调用者：SettingsPage 的登出按钮
  /// 
  /// 登出流程：
  /// 1. 调用 AuthRepository 登出（清除 Token）
  /// 2. 清空认证数据（只清空 Token 等认证信息，保留业务数据）
  /// 3. 刷新所有数据 Provider
  /// 4. 更新认证状态为 null
  /// 
  /// 设计说明：
  /// - 支持多用户离线使用
  /// - 用户 A 登出后，A 的数据仍在本地（离线可用）
  /// - 用户 B 登录，只看到 B 的数据（通过 ownerId 过滤）
  /// - 用户 A 重新登录，数据立即可用（无需等待同步）
  /// 
  /// Fail Fast：登出失败立即抛异常
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    
    try {
      // 1. 调用 AuthRepository 登出（清除 Token）
      await _repository.signOut();
      
      // 2. 清空认证数据（只清空 Token 等认证信息）
      // 保留所有业务数据，支持多用户离线使用
      final storageService = ref.read(storageServiceProvider);
      await storageService.clearAuthData();
      
      // 3. 刷新所有数据 Provider
      _invalidateDataProviders();
      
      // 4. 更新认证状态
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 重新抛出异常，让调用者可以捕获
    }
  }
  
  /// 绑定离线数据到指定用户（如果有离线数据）
  /// 
  /// 调用时机：首次登录/注册时
  /// 
  /// 策略：自动绑定所有离线数据，不询问用户
  /// 
  /// Fail Fast：
  /// - userId 为空：抛出 ArgumentError
  Future<void> _bindOfflineDataIfNeeded(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    final storageService = ref.read(storageServiceProvider);
    
    // 直接绑定离线数据（不询问用户）
    // 如果没有离线数据，bindOfflineDataToUser 会自动跳过
    await storageService.bindOfflineDataToUser(userId);
  }
  
  /// 发送密码重置邮件
  /// 
  /// 调用者：ForgotPasswordPage._handleSendResetEmail()
  /// 
  /// Fail Fast：
  /// - 邮箱格式错误立即抛异常
  /// - 恢复密钥为空立即抛异常
  /// - 新密码格式错误立即抛异常
  Future<void> resetPassword(String email, String recoveryKey, String newPassword) async {
    // Fail Fast：参数验证（UI 层已经 trim，这里只验证非空）
    if (email.isEmpty) {
      throw ArgumentError('邮箱不能为空');
    }
    if (recoveryKey.isEmpty) {
      throw ArgumentError('恢复密钥不能为空');
    }
    if (newPassword.isEmpty) {
      throw ArgumentError('新密码不能为空');
    }
    
    await _repository.resetPassword(email, recoveryKey, newPassword);
  }
  
  /// 生成恢复密钥
  /// 
  /// 调用者：SettingsPage（账号管理）
  /// 
  /// Fail Fast：
  /// - 用户未登录立即抛异常
  Future<String> generateRecoveryKey() async {
    return await _repository.generateRecoveryKey();
  }
  
  /// 获取当前恢复密钥
  /// 
  /// 调用者：SettingsPage（账号管理）
  /// 
  /// Fail Fast：
  /// - 用户未登录立即抛异常
  Future<String?> getRecoveryKey() async {
    return await _repository.getRecoveryKey();
  }
  
  /// 修改密码
  /// 
  /// 调用者：SettingsPage（账号管理）
  /// 
  /// Fail Fast：
  /// - 当前密码为空立即抛异常
  /// - 新密码格式错误立即抛异常
  /// - 当前密码错误立即抛异常
  /// - 用户未登录立即抛异常
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    // Fail Fast：参数验证
    if (currentPassword.isEmpty) {
      throw ArgumentError('当前密码不能为空');
    }
    if (newPassword.isEmpty) {
      throw ArgumentError('新密码不能为空');
    }
    
    await _repository.updatePassword(currentPassword, newPassword);
  }
  
  /// 更换邮箱
  /// 
  /// 调用者：SettingsPage（账号管理）
  /// 
  /// Fail Fast：
  /// - 新邮箱格式错误立即抛异常
  /// - 密码为空立即抛异常
  /// - 密码错误立即抛异常
  /// - 邮箱已被使用立即抛异常
  /// - 用户未登录立即抛异常
  Future<void> updateEmail(String newEmail, String password) async {
    // Fail Fast：参数验证
    if (newEmail.isEmpty) {
      throw ArgumentError('新邮箱不能为空');
    }
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }
    
    await _repository.updateEmail(newEmail, password);
    
    // 更新成功后刷新用户状态
    final user = await _repository.currentUser;
    state = AsyncValue.data(user);
  }
  
  /// 更换手机号
  /// 
  /// 调用者：SettingsPage（账号管理）
  /// 
  /// Fail Fast：
  /// - 新手机号格式错误立即抛异常
  /// - 验证码为空立即抛异常
  /// - 验证 ID 为空立即抛异常
  /// - 验证码错误立即抛异常
  /// - 手机号已被使用立即抛异常
  /// - 用户未登录立即抛异常
  Future<void> updatePhoneNumber(
    String newPhoneNumber,
    String verificationCode,
    String verificationId,
  ) async {
    // Fail Fast：参数验证
    if (newPhoneNumber.isEmpty) {
      throw ArgumentError('新手机号不能为空');
    }
    if (verificationCode.isEmpty) {
      throw ArgumentError('验证码不能为空');
    }
    if (verificationId.isEmpty) {
      throw ArgumentError('验证 ID 不能为空');
    }
    
    await _repository.updatePhoneNumber(
      newPhoneNumber,
      verificationCode,
      verificationId,
    );
    
    // 更新成功后刷新用户状态
    final user = await _repository.currentUser;
    state = AsyncValue.data(user);
  }
}

/// 用户认证状态 Provider
final authProvider = StreamNotifierProvider<AuthNotifier, User?>(
  () => AuthNotifier(),
);

