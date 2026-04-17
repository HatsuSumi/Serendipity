import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/register_result.dart';
import '../../models/user.dart';
import '../repositories/i_auth_repository.dart';
import 'auth_dependencies_provider.dart';
import 'auth_session_coordinator.dart';
import 'message_provider.dart';

export 'auth_dependencies_provider.dart';
export 'auth_events_provider.dart';

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
  late AuthSessionCoordinator _sessionCoordinator;

  @override
  Stream<User?> build() {
    _repository = ref.read(authRepositoryProvider);
    _sessionCoordinator = AuthSessionCoordinator(
      ref: ref,
      repository: _repository,
      setState: (nextState) => state = nextState,
    );
    
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
  

  /// 获取当前用户快照
  ///
  /// 约束：
  /// - 优先从 authProvider 的状态读取，避免额外触发仓储层的 auth/me 请求
  /// - 只在 authProvider 尚未解析完成时等待一次 future
  Future<User?> get currentUser async {
    final authState = state;
    if (authState.hasValue) {
      return authState.value;
    }

    return await future;
  }

  Future<void> _runAuthAction(
    Future<User> Function() action, {
    required bool isRegister,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = await action();
      state = AsyncValue.data(user);
      await _sessionCoordinator.completeAuthSuccess(
        user,
        isRegister: isRegister,
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<String?> _runRegisterAuthAction(
    Future<RegisterResult> Function() action,
  ) async {
    state = const AsyncValue.loading();

    try {
      final result = await action();
      state = AsyncValue.data(result.user);
      await _sessionCoordinator.completeAuthSuccess(
        result.user,
        isRegister: true,
      );
      return result.recoveryKey;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _runProfileUpdateAction(Future<void> Function() action) async {
    await action();
    final user = await _repository.currentUser;
    state = AsyncValue.data(user);
  }

  void _requireNotEmpty(String value, String message) {
    if (value.isEmpty) {
      throw ArgumentError(message);
    }
  }

  void _requirePhoneNumberWithCountryCode(String phoneNumber) {
    _requireNotEmpty(phoneNumber, '手机号不能为空');
    if (!phoneNumber.startsWith('+')) {
      throw ArgumentError('手机号格式错误：缺少国家代码');
    }
  }

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
    _requireNotEmpty(email, '邮箱不能为空');
    _requireNotEmpty(password, '密码不能为空');

    await _runAuthAction(
      () => _repository.signInWithEmail(email, password),
      isRegister: false,
    );
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
    _requireNotEmpty(email, '邮箱不能为空');
    _requireNotEmpty(password, '密码不能为空');

    return await _runRegisterAuthAction(
      () => _repository.signUpWithEmail(email, password),
    );
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
    _requirePhoneNumberWithCountryCode(phoneNumber);

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
    _requireNotEmpty(phoneNumber, '手机号不能为空');
    _requireNotEmpty(password, '密码不能为空');

    await _runAuthAction(
      () => _repository.signInWithPhonePassword(phoneNumber, password),
      isRegister: false,
    );
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
    _requireNotEmpty(phoneNumber, '手机号不能为空');
    _requireNotEmpty(verificationCode, '验证码不能为空');
    _requireNotEmpty(verificationId, '验证 ID 不能为空');

    await _runAuthAction(
      () => _repository.signInWithPhone(
        phoneNumber,
        verificationCode,
        verificationId,
      ),
      isRegister: false,
    );
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
    _requireNotEmpty(phoneNumber, '手机号不能为空');
    _requireNotEmpty(password, '密码不能为空');

    return await _runRegisterAuthAction(
      () => _repository.signUpWithPhonePassword(phoneNumber, password),
    );
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
    _requireNotEmpty(phoneNumber, '手机号不能为空');
    _requireNotEmpty(verificationCode, '验证码不能为空');
    _requireNotEmpty(verificationId, '验证 ID 不能为空');

    return await _runRegisterAuthAction(
      () => _repository.signUpWithPhone(
        phoneNumber,
        verificationCode,
        verificationId,
      ),
    );
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
    await _sessionCoordinator.signOut();
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
    _requireNotEmpty(email, '邮箱不能为空');
    _requireNotEmpty(recoveryKey, '恢复密钥不能为空');
    _requireNotEmpty(newPassword, '新密码不能为空');
    
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
    await _sessionCoordinator.deleteAccount(password);
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
    _requireNotEmpty(currentPassword, '当前密码不能为空');
    _requireNotEmpty(newPassword, '新密码不能为空');
    
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
    _requireNotEmpty(newEmail, '新邮箱不能为空');
    _requireNotEmpty(password, '密码不能为空');

    await _runProfileUpdateAction(
      () => _repository.updateEmail(newEmail, password),
    );
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
    _requireNotEmpty(newPhoneNumber, '新手机号不能为空');
    _requireNotEmpty(password, '密码不能为空');

    await _runProfileUpdateAction(
      () => _repository.updatePhoneNumber(
        newPhoneNumber,
        password,
      ),
    );
  }
}

/// 用户认证状态 Provider
final authProvider = StreamNotifierProvider<AuthNotifier, User?>(
  () => AuthNotifier(),
);


