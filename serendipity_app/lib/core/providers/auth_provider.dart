import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../repositories/i_auth_repository.dart';
import '../repositories/firebase_auth_repository.dart';
import '../repositories/test_auth_repository.dart';
import '../config/app_config.dart';

/// 认证仓储 Provider
/// 
/// 依赖抽象接口 IAuthRepository，不依赖具体实现。
/// 遵循依赖倒置原则（DIP）：切换到自建服务器时只需修改这一行。
/// 
/// 环境选择：
/// - 开发模式 + 启用测试模式：使用 TestAuthRepository
/// - 其他情况：使用 FirebaseAuthRepository
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  // 开发环境且启用测试模式时，使用测试仓库
  if (kDebugMode && AppConfig.enableTestMode) {
    return TestAuthRepository();
  }
  
  // 生产环境或未启用测试模式时，使用 Firebase
  return FirebaseAuthRepository();
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
      await _repository.signInWithEmail(email, password);
      final user = await _repository.currentUser;
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 重新抛出异常，让调用者可以捕获
    }
  }

  /// 邮箱注册
  /// 
  /// 调用者：RegisterPage._handleEmailRegister()
  /// 
  /// Fail Fast：
  /// - 邮箱格式错误立即抛异常
  /// - 密码长度不足立即抛异常
  /// - 注册失败立即抛异常
  Future<void> signUpWithEmail(String email, String password) async {
    // Fail Fast：参数验证（UI 层已经 trim，这里只验证非空）
    if (email.isEmpty) {
      throw ArgumentError('邮箱不能为空');
    }
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }

    state = const AsyncValue.loading();
    
    try {
      await _repository.signUpWithEmail(email, password);
      final user = await _repository.currentUser;
      state = AsyncValue.data(user);
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
      await _repository.signInWithPhone(
        phoneNumber,
        verificationCode,
        verificationId,
      );
      final user = await _repository.currentUser;
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 重新抛出异常，让调用者可以捕获
    }
  }

  /// 手机号注册
  /// 
  /// 调用者：RegisterPage._handlePhoneRegister()
  /// 
  /// Fail Fast：
  /// - 手机号格式错误立即抛异常
  /// - 验证码格式错误立即抛异常
  /// - verificationId 为空立即抛异常
  /// - 注册失败立即抛异常
  Future<void> signUpWithPhone(
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
      await _repository.signUpWithPhone(
        phoneNumber,
        verificationCode,
        verificationId,
      );
      final user = await _repository.currentUser;
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow; // 重新抛出异常，让调用者可以捕获
    }
  }

  /// 登出
  /// 
  /// 调用者：SettingsPage 的登出按钮
  /// 
  /// Fail Fast：登出失败立即抛异常
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    
    try {
      await _repository.signOut();
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
  /// - 发送失败立即抛异常
  Future<void> resetPassword(String email) async {
    // Fail Fast：参数验证（UI 层已经 trim，这里只验证非空）
    if (email.isEmpty) {
      throw ArgumentError('邮箱不能为空');
    }
    
    await _repository.resetPassword(email);
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

