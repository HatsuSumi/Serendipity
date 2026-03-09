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
  /// 注意：同步失败不影响用户使用，用户可以稍后手动触发同步
  Future<void> _triggerSync(User user, {bool isRegister = false}) async {
    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.syncAllData(
        user,
        source: isRegister ? SyncSource.register : SyncSource.login,
      );
      
      // 同步完成后刷新所有数据 Provider
      _invalidateDataProviders();
    } catch (e) {
      // 同步失败不影响用户使用
      // 生产环境应记录错误日志
    }
  }
  
  /// 刷新所有数据 Provider（清除内存缓存）
  /// 
  /// 调用时机：
  /// - 清空本地数据后
  /// - 数据同步完成后
  /// 
  /// 作用：强制 Provider 重新从存储加载数据
  void _invalidateDataProviders() {
    ref.invalidate(recordsProvider);
    ref.invalidate(storyLinesProvider);
    ref.invalidate(checkInProvider);
    ref.invalidate(achievementsProvider);
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
  /// 1. 清空本地用户数据（防止账号切换时数据混淆）
  /// 2. 调用 AuthRepository 登录
  /// 3. 触发数据同步（从云端下载当前用户数据）
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
      // 1. 清空本地用户数据
      final storageService = ref.read(storageServiceProvider);
      await storageService.clearUserData();
      
      // 2. 刷新所有数据 Provider（清除内存缓存）
      _invalidateDataProviders();
      
      // 3. 调用 AuthRepository 登录
      await _repository.signInWithEmail(email, password);
      final user = await _repository.currentUser;
      state = AsyncValue.data(user);
      
      // 4. 登录成功后触发数据同步
      if (user != null) {
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
  /// 1. 清空本地用户数据（防止旧数据污染新账号）
  /// 2. 调用 AuthRepository 注册
  /// 3. 触发数据同步（创建云端空数据）
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
      // 1. 清空本地用户数据
      final storageService = ref.read(storageServiceProvider);
      await storageService.clearUserData();
      
      // 2. 刷新所有数据 Provider（清除内存缓存）
      _invalidateDataProviders();
      
      // 3. 调用 AuthRepository 注册
      final result = await _repository.signUpWithEmail(email, password);
      state = AsyncValue.data(result.user);
      
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
  /// 1. 清空本地用户数据（防止账号切换时数据混淆）
  /// 2. 调用 AuthRepository 登录
  /// 3. 触发数据同步（从云端下载当前用户数据）
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
      // 1. 清空本地用户数据
      final storageService = ref.read(storageServiceProvider);
      await storageService.clearUserData();
      
      // 2. 刷新所有数据 Provider（清除内存缓存）
      _invalidateDataProviders();
      
      // 3. 调用 AuthRepository 登录
      await _repository.signInWithPhone(
        phoneNumber,
        verificationCode,
        verificationId,
      );
      final user = await _repository.currentUser;
      state = AsyncValue.data(user);
      
      // 4. 登录成功后触发数据同步
      if (user != null) {
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
  /// 1. 清空本地用户数据（防止旧数据污染新账号）
  /// 2. 调用 AuthRepository 注册
  /// 3. 触发数据同步（创建云端空数据）
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
      // 1. 清空本地用户数据
      final storageService = ref.read(storageServiceProvider);
      await storageService.clearUserData();
      
      // 2. 刷新所有数据 Provider（清除内存缓存）
      _invalidateDataProviders();
      
      // 3. 调用 AuthRepository 注册
      final result = await _repository.signUpWithPhone(
        phoneNumber,
        verificationCode,
        verificationId,
      );
      state = AsyncValue.data(result.user);
      
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
  /// 2. 清空本地用户数据（避免数据混淆）
  /// 3. 更新认证状态为 null
  /// 
  /// Fail Fast：登出失败立即抛异常
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    
    try {
      // 1. 调用 AuthRepository 登出
      await _repository.signOut();
      
      // 2. 清空本地用户数据
      final storageService = ref.read(storageServiceProvider);
      await storageService.clearUserData();
      
      // 3. 刷新所有数据 Provider（清除内存缓存）
      _invalidateDataProviders();
      
      // 4. 更新认证状态
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 重新抛出异常，让调用者可以捕获
    }
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

