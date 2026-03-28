import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../repositories/i_auth_repository.dart';
import '../repositories/test_auth_repository.dart';
import '../repositories/custom_server_auth_repository.dart';
import '../services/http_client_service.dart';
import '../services/i_storage_service.dart';
import '../config/app_config.dart';
import 'records_provider.dart';
import 'story_lines_provider.dart';
import 'check_in_provider.dart';
import 'achievement_provider.dart';
import 'community_provider.dart';
import 'message_provider.dart';

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
    
    // 注入强制登出回调：Token 过期且刷新失败时（被其他设备踢下线），
    // 通过 messageProvider 发送跨页面消息，主页面监听后显示提示。
    // 只对 CustomServerAuthRepository 生效（TestAuthRepository 无 Token 机制）
    final httpClient = ref.read(httpClientServiceProvider);
    httpClient.onForceLogout = () {
      ref.read(messageProvider.notifier).showError('你的账号已在其他设备登录，请重新登录');
      // 清除本地认证状态，触发页面跳转到登录页
      Future.microtask(() => state = const AsyncValue.data(null));
    };
    
    // 监听认证状态变化
    // 注意：TestAuthRepository 的 authStateChanges 会立即发送当前状态
    return _repository.authStateChanges;
  }
  
  /// 触发数据同步
  /// 
  /// 调用时机：用户登录/注册成功后
  /// 
  /// 设计说明：
  /// - 不直接调用 SyncService（违反分层约束）
  /// - 通过信号驱动，让 NetworkMonitorService 负责实际同步
  /// - AuthNotifier 只负责认证，不负责同步业务逻辑
  /// - 使用 Future.microtask 确保信号在当前事件循环后发送
  /// 
  /// 同步策略由 NetworkMonitorService 决定：
  /// - 注册：SyncSource.register，跳过下载
  /// - 登录：SyncSource.login，读取上次同步时间
  void _triggerSync(User user, {bool isRegister = false}) {
    // 不 await，直接发送信号（异步）
    // 使用 Future.microtask 确保信号在当前事件循环后发送，避免竞态条件
    Future.microtask(() {
      ref.read(authCompletedProvider.notifier).emit(AuthCompletedEvent(
        user: user,
        isRegister: isRegister,
      ));
    });
  }
  
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
        _triggerSync(user);
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
      _triggerSync(result.user, isRegister: true);
      
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

  /// 手机号密码登录
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
  /// - 密码格式错误立即抛异常
  /// - 登录失败立即抛异常
  Future<void> signInWithPhonePassword(
    String phoneNumber,
    String password,
  ) async {
    // Fail Fast：参数验证（UI 层已经 trim，这里只验证非空）
    if (phoneNumber.isEmpty) {
      throw ArgumentError('手机号不能为空');
    }
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }

    state = const AsyncValue.loading();
    
    try {
      // 1. 调用 AuthRepository 登录
      await _repository.signInWithPhonePassword(phoneNumber, password);
      final user = await _repository.currentUser;
      state = AsyncValue.data(user);
      
      if (user != null) {
        // 2. 绑定离线数据到当前用户
        await _bindOfflineDataIfNeeded(user.id);
        
        // 3. 刷新所有数据 Provider
        _invalidateDataProviders();
        
        // 4. 登录成功后触发数据同步
        _triggerSync(user);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 重新抛出异常，让调用者可以捕获
    }
  }

  /// 手机号登录（验证码方式）
  /// 
  /// 调用者：LoginPage._handlePhoneLogin()（已禁用）
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
        _triggerSync(user);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 重新抛出异常，让调用者可以捕获
    }
  }

  /// 手机号密码注册
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
  /// - 密码格式错误立即抛异常
  /// - 注册失败立即抛异常
  Future<String?> signUpWithPhonePassword(
    String phoneNumber,
    String password,
  ) async {
    // Fail Fast：参数验证（UI 层已经 trim，这里只验证非空）
    if (phoneNumber.isEmpty) {
      throw ArgumentError('手机号不能为空');
    }
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }

    state = const AsyncValue.loading();
    
    try {
      // 1. 调用 AuthRepository 注册
      final result = await _repository.signUpWithPhonePassword(phoneNumber, password);
      state = AsyncValue.data(result.user);
      
      // 2. 绑定离线数据到新账号
      await _bindOfflineDataIfNeeded(result.user.id);
      
      // 3. 刷新所有数据 Provider
      _invalidateDataProviders();
      
      // 4. 注册成功后触发数据同步
      _triggerSync(result.user, isRegister: true);
      
      return result.recoveryKey; // 返回恢复密钥
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 重新抛出异常，让调用者可以捕获
    }
  }

  /// 手机号注册（验证码方式）
  /// 
  /// 调用者：RegisterPage._handlePhoneRegister()（已禁用）
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
      _triggerSync(result.user, isRegister: true);
      
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
  
  /// 注销账号
  ///
  /// 调用者：AccountSettingsPage（账号管理）
  ///
  /// 注销流程：
  /// 1. 调用 AuthRepository 注销（服务端删除用户数据）
  /// 2. 清空本地所有数据
  /// 3. 刷新所有数据 Provider
  /// 4. 更新认证状态为 null
  ///
  /// Fail Fast：
  /// - 密码为空立即抛异常
  /// - 密码错误立即抛异常
  /// - 用户未登录立即抛异常
  Future<void> deleteAccount(String password) async {
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }

    // 先获取当前用户 ID，再注销（注销后 _currentUser 会被清空）
    final currentUser = await _repository.currentUser;
    await _repository.deleteAccount(password);

    if (currentUser != null) {
      final storageService = ref.read(storageServiceProvider);
      await storageService.deleteUserData(currentUser.id);
    }

    _invalidateDataProviders();
    state = const AsyncValue.data(null);
  }

  /// 直接更新当前用户 state
  ///
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
    
    // Repository 已经更新了 _currentUser，直接获取即可
    final user = await _repository.currentUser;
    state = AsyncValue.data(user);
  }
  
  /// 更换手机号
  /// 
  /// 调用者：SettingsPage（账号管理）
  /// 
  /// Fail Fast：
  /// - 新手机号格式错误立即抛异常
  /// - 密码为空立即抛异常
  /// - 密码错误立即抛异常
  /// - 手机号已被使用立即抛异常
  /// - 用户未登录立即抛异常
  Future<void> updatePhoneNumber(
    String newPhoneNumber,
    String password,
  ) async {
    // Fail Fast：参数验证
    if (newPhoneNumber.isEmpty) {
      throw ArgumentError('新手机号不能为空');
    }
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }
    
    await _repository.updatePhoneNumber(
      newPhoneNumber,
      password,
    );
    
    // Repository 已经更新了 _currentUser，直接获取即可
    final user = await _repository.currentUser;
    state = AsyncValue.data(user);
  }
}

/// 用户认证状态 Provider
final authProvider = StreamNotifierProvider<AuthNotifier, User?>(
  () => AuthNotifier(),
);

/// 认证完成信号（用于触发同步）
/// 
/// 设计说明：
/// - AuthNotifier 登录/注册成功后发送此信号
/// - NetworkMonitorService 监听此信号，触发实际同步
/// - 这样可以保持分层约束：UI 层不直接调用 SyncService
class AuthCompletedEvent {
  final User user;
  final bool isRegister;
  
  AuthCompletedEvent({
    required this.user,
    required this.isRegister,
  });
}

/// 认证完成事件通知器
/// 
/// 使用 StateNotifierProvider 而不是 StateProvider，原因：
/// - StateNotifier 提供更好的事件语义
/// - 可以在 build 方法中初始化为 null，避免信号丢失
/// - 支持更复杂的状态转换逻辑
class AuthCompletedNotifier extends StateNotifier<AuthCompletedEvent?> {
  AuthCompletedNotifier() : super(null);
  
  /// 发送认证完成事件
  void emit(AuthCompletedEvent event) {
    state = event;
  }
}

final authCompletedProvider = StateNotifierProvider<AuthCompletedNotifier, AuthCompletedEvent?>((ref) {
  return AuthCompletedNotifier();
});

