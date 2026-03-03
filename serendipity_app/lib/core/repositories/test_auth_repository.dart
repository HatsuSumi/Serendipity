import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user.dart';
import '../../models/register_result.dart';
import '../../models/enums.dart';
import '../../core/utils/validation_helper.dart';
import 'i_auth_repository.dart';

/// 测试认证仓库
/// 
/// 仅用于开发和测试环境，提供模拟的认证功能。
/// 遵循依赖倒置原则（DIP），实现 IAuthRepository 接口。
/// 
/// 使用单例模式确保数据在整个应用生命周期中持久化。
/// 
/// 使用场景：
/// - 开发环境：无需真实后端配置即可测试
/// - 单元测试：提供可预测的认证行为
/// - 集成测试：避免真实网络请求
/// 
/// 测试账号：
/// - 手机号：+8613800138000
/// - 验证码：123456（固定）
/// - 邮箱：test@example.com
/// - 密码：123456（固定）
class TestAuthRepository implements IAuthRepository {
  // 单例模式
  static final TestAuthRepository _instance = TestAuthRepository._internal();
  
  factory TestAuthRepository() {
    return _instance;
  }
  
  TestAuthRepository._internal() {
    _initializeTestData();
  }
  
  /// 模拟的当前用户
  User? _currentUser;
  
  /// 认证状态流控制器
  final _authStateController = StreamController<User?>.broadcast();
  
  /// Hive box 名称
  static const String _testUsersBoxName = 'test_users';
  static const String _testSessionBoxName = 'test_session';
  static const String _testPasswordsBoxName = 'test_passwords'; // 新增：存储密码的 box
  static const String _currentUserIdKey = 'current_user_id';
  
  /// 初始化测试数据（从 Hive 加载）
  Future<void> _initializeTestData() async {
    try {
      // 确保 box 已打开
      if (!Hive.isBoxOpen(_testUsersBoxName)) {
        await Hive.openBox<User>(_testUsersBoxName);
      }
      if (!Hive.isBoxOpen(_testSessionBoxName)) {
        await Hive.openBox(_testSessionBoxName);
      }
      if (!Hive.isBoxOpen(_testPasswordsBoxName)) {
        await Hive.openBox(_testPasswordsBoxName);
      }
      
      // 从 Hive 恢复当前用户状态
      final sessionBox = Hive.box(_testSessionBoxName);
      final currentUserId = sessionBox.get(_currentUserIdKey) as String?;
      
      if (currentUserId != null) {
        // 尝试从用户列表中恢复用户
        _currentUser = _testUsersBox.get(currentUserId);
      } else {
        _currentUser = null;
      }
      
      // 测试环境数据已加载
    } catch (e) {
      // 初始化失败不影响应用启动
    }
  }
  
  /// 获取测试用户 Box
  Box<User> get _testUsersBox => Hive.box<User>(_testUsersBoxName);
  
  /// 获取会话 Box
  Box get _sessionBox => Hive.box(_testSessionBoxName);
  
  /// 获取密码 Box
  Box get _passwordsBox => Hive.box(_testPasswordsBoxName);
  
  /// 保存当前用户 ID 到 Hive
  Future<void> _saveCurrentUserId(String userId) async {
    await _sessionBox.put(_currentUserIdKey, userId);
  }
  
  /// 清除当前用户 ID
  Future<void> _clearCurrentUserId() async {
    await _sessionBox.delete(_currentUserIdKey);
  }
  
  /// 根据邮箱查找用户
  User? _getUserByEmail(String email) {
    try {
      return _testUsersBox.values.firstWhere(
        (user) => user.email == email,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// 根据手机号查找用户
  User? _getUserByPhone(String phoneNumber) {
    try {
      return _testUsersBox.values.firstWhere(
        (user) => user.phoneNumber == phoneNumber,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// 保存用户到 Hive
  Future<void> _saveUser(User user) async {
    await _testUsersBox.put(user.id, user);
  }
  
  /// 保存密码到 Hive（仅用于测试环境）
  /// 
  /// ⚠️ 安全警告：
  /// 1. 这里使用明文存储密码，仅用于开发和测试环境
  /// 2. 生产环境绝不应该在客户端存储密码（明文或哈希）
  /// 3. 认证服务会在服务器端安全处理密码
  /// 4. 如果需要本地存储，应该使用加密哈希（如 SHA-256）
  /// 
  /// 为什么测试环境可以接受明文：
  /// - 仅在本地开发环境使用
  /// - 不会暴露到网络
  /// - 方便调试和测试
  Future<void> _savePassword(String userId, String password) async {
    await _passwordsBox.put(userId, password);
  }
  
  /// 获取保存的密码
  String? _getPassword(String userId) {
    return _passwordsBox.get(userId) as String?;
  }
  
  @override
  Future<User?> get currentUser async {
    return _currentUser;
  }
  
  @override
  Stream<User?> get authStateChanges {
    // 优化：创建一个新的 Stream，先发送当前状态，再监听后续事件
    return Stream<User?>.multi((controller) {
      // 立即发送当前状态
      controller.add(_currentUser);
      
      // 监听后续事件并转发
      final subscription = _authStateController.stream.listen(
        (user) {
          controller.add(user);
        },
        onError: (error) => controller.addError(error),
      );
      
      // 清理资源
      controller.onCancel = () {
        subscription.cancel();
      };
    });
  }
  
  @override
  Future<User> signInWithEmail(String email, String password) async {
    // Fail Fast：参数验证（使用统一的验证规则）
    ValidationHelper.validateEmailForRepository(email);
    ValidationHelper.validatePasswordForRepository(password);
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 检查用户是否存在
    final user = _getUserByEmail(email);
    if (user == null) {
      // 清空当前用户
      _currentUser = null;
      _authStateController.add(null);
      throw Exception('该邮箱尚未注册');
    }
    
    // 检查密码（从 Hive 获取保存的密码）
    final savedPassword = _getPassword(user.id);
    
    // Fail Fast: 密码必须存在
    if (savedPassword == null) {
      _currentUser = null;
      _authStateController.add(null);
      throw Exception('账号数据异常，请重新注册');
    }
    
    // Fail Fast: 密码必须匹配
    if (password != savedPassword) {
      _currentUser = null;
      _authStateController.add(null);
      throw Exception('密码错误');
    }
    
    // 登录成功
    _currentUser = user;
    _authStateController.add(_currentUser);
    
    // 保存当前用户 ID 到 Hive
    await _saveCurrentUserId(user.id);
    
    return _currentUser!;
  }
  
  @override
  Future<RegisterResult> signUpWithEmail(String email, String password) async {
    // Fail Fast：参数验证（使用统一的验证规则）
    ValidationHelper.validateEmailForRepository(email);
    ValidationHelper.validatePasswordForRepository(password);
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 检查邮箱是否已注册
    if (_getUserByEmail(email) != null) {
      throw Exception('该邮箱已被注册');
    }
    
    // 创建新用户
    final user = User(
      id: 'test-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      authProvider: AuthProvider.email,
      isEmailVerified: true, // 测试环境自动验证
      isPhoneVerified: false,
      lastLoginAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // 保存到 Hive
    await _saveUser(user);
    
    // 保存密码到 Hive（仅测试环境）
    await _savePassword(user.id, password);
    
    // 生成恢复密钥
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final recoveryKey = 'test-${timestamp.toString().substring(timestamp.toString().length - 8)}';
    final formattedKey = '${recoveryKey.substring(0, 4)}-${recoveryKey.substring(4, 8)}-${recoveryKey.substring(8)}';
    
    // 保存恢复密钥到 Hive
    await _passwordsBox.put('recovery_key_${user.id}', formattedKey);
    
    // 自动登录
    _currentUser = user;
    _authStateController.add(_currentUser);
    
    // 保存当前用户 ID 到 Hive
    await _saveCurrentUserId(user.id);
    
    return RegisterResult(
      user: user,
      recoveryKey: formattedKey,
    );
  }
  
  @override
  Future<String> sendPhoneVerificationCode(String phoneNumber) async {
    // Fail Fast：参数验证
    if (phoneNumber.isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }
    if (!phoneNumber.startsWith('+')) {
      throw ArgumentError('Phone number must include country code (e.g., +86)');
    }
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 生成模拟的 verificationId
    final verificationId = 'test-verification-id-${DateTime.now().millisecondsSinceEpoch}';
    
    return verificationId;
  }
  
  @override
  Future<User> signInWithPhone(
    String phoneNumber,
    String verificationCode,
    String verificationId,
  ) async {
    // Fail Fast：参数验证
    if (phoneNumber.isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }
    if (verificationCode.isEmpty) {
      throw ArgumentError('Verification code cannot be empty');
    }
    if (verificationId.isEmpty) {
      throw ArgumentError('Verification ID cannot be empty');
    }
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 检查验证码（测试环境固定验证码：123456）
    if (verificationCode != '123456') {
      throw Exception('验证码错误');
    }
    
    // 检查用户是否存在
    final user = _getUserByPhone(phoneNumber);
    if (user == null) {
      throw Exception('该手机号尚未注册');
    }
    
    // 登录成功
    _currentUser = user;
    _authStateController.add(_currentUser);
    
    // 保存当前用户 ID 到 Hive
    await _saveCurrentUserId(user.id);
    
    return _currentUser!;
  }
  
  @override
  Future<RegisterResult> signUpWithPhone(
    String phoneNumber,
    String verificationCode,
    String verificationId,
  ) async {
    // Fail Fast：参数验证
    if (phoneNumber.isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }
    if (verificationCode.isEmpty) {
      throw ArgumentError('Verification code cannot be empty');
    }
    if (verificationId.isEmpty) {
      throw ArgumentError('Verification ID cannot be empty');
    }
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 检查验证码（测试环境固定验证码：123456）
    if (verificationCode != '123456') {
      throw Exception('验证码错误');
    }
    
    // 检查手机号是否已注册
    if (_getUserByPhone(phoneNumber) != null) {
      throw Exception('该手机号已被注册');
    }
    
    // 创建新用户
    final user = User(
      id: 'test-user-${DateTime.now().millisecondsSinceEpoch}',
      phoneNumber: phoneNumber,
      authProvider: AuthProvider.phone,
      isEmailVerified: false,
      isPhoneVerified: true, // 测试环境自动验证
      lastLoginAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // 保存到 Hive
    await _saveUser(user);
    
    // 生成恢复密钥
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final recoveryKey = 'test-${timestamp.toString().substring(timestamp.toString().length - 8)}';
    final formattedKey = '${recoveryKey.substring(0, 4)}-${recoveryKey.substring(4, 8)}-${recoveryKey.substring(8)}';
    
    // 保存恢复密钥到 Hive
    await _passwordsBox.put('recovery_key_${user.id}', formattedKey);
    
    // 自动登录
    _currentUser = user;
    _authStateController.add(_currentUser);
    
    // 保存当前用户 ID 到 Hive
    await _saveCurrentUserId(user.id);
    
    return RegisterResult(
      user: user,
      recoveryKey: formattedKey,
    );
  }
  
  @override
  Future<void> signOut() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 300));
    
    _currentUser = null;
    
    // 清除保存的用户 ID
    await _clearCurrentUserId();
    
    _authStateController.add(null);
  }
  
  @override
  Future<void> resetPassword(String email, String recoveryKey, String newPassword) async {
    // Fail Fast：参数验证
    if (email.isEmpty) {
      throw ArgumentError('邮箱不能为空');
    }
    if (recoveryKey.isEmpty) {
      throw ArgumentError('恢复密钥不能为空');
    }
    ValidationHelper.validatePasswordForRepository(newPassword);
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 检查邮箱是否存在
    final user = _getUserByEmail(email);
    if (user == null) {
      throw Exception('该邮箱不存在');
    }
    
    // 测试环境：验证恢复密钥（从 Hive 获取）
    final savedRecoveryKey = _passwordsBox.get('recovery_key_${user.id}') as String?;
    if (savedRecoveryKey == null || savedRecoveryKey != recoveryKey) {
      throw Exception('邮箱或恢复密钥错误');
    }
    
    // 更新密码
    await _savePassword(user.id, newPassword);
  }
  
  @override
  Future<String> generateRecoveryKey() async {
    // Fail Fast：用户未登录
    if (_currentUser == null) {
      throw StateError('用户未登录');
    }
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 生成恢复密钥（测试环境使用简单格式）
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final recoveryKey = 'test-${timestamp.toString().substring(timestamp.toString().length - 8)}';
    final formattedKey = '${recoveryKey.substring(0, 4)}-${recoveryKey.substring(4, 8)}-${recoveryKey.substring(8)}';
    
    // 保存恢复密钥到 Hive（测试环境）
    await _passwordsBox.put('recovery_key_${_currentUser!.id}', formattedKey);
    
    return formattedKey;
  }
  
  @override
  Future<String?> getRecoveryKey() async {
    // Fail Fast：用户未登录
    if (_currentUser == null) {
      throw StateError('用户未登录');
    }
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 从 Hive 获取恢复密钥
    return _passwordsBox.get('recovery_key_${_currentUser!.id}') as String?;
  }
  
  @override
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    // Fail Fast：参数验证
    if (currentPassword.isEmpty) {
      throw ArgumentError('当前密码不能为空');
    }
    ValidationHelper.validatePasswordForRepository(newPassword);
    
    // Fail Fast：用户未登录
    if (_currentUser == null) {
      throw StateError('用户未登录');
    }
    
    // Fail Fast：只有邮箱登录的用户才能修改密码
    if (_currentUser!.email == null) {
      throw StateError('只有邮箱登录的用户才能修改密码');
    }
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 验证当前密码
    final savedPassword = _getPassword(_currentUser!.id);
    if (savedPassword == null || savedPassword != currentPassword) {
      throw Exception('当前密码错误');
    }
    
    // 更新密码
    await _savePassword(_currentUser!.id, newPassword);
  }
  
  @override
  Future<void> updateEmail(String newEmail, String password) async {
    // Fail Fast：参数验证
    ValidationHelper.validateEmailForRepository(newEmail);
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }
    
    // Fail Fast：用户未登录
    if (_currentUser == null) {
      throw StateError('用户未登录');
    }
    
    // Fail Fast：只有邮箱登录的用户才能更换邮箱
    if (_currentUser!.email == null) {
      throw StateError('只有邮箱登录的用户才能更换邮箱');
    }
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 验证密码
    final savedPassword = _getPassword(_currentUser!.id);
    if (savedPassword == null || savedPassword != password) {
      throw Exception('密码错误');
    }
    
    // 检查新邮箱是否已被使用
    if (_getUserByEmail(newEmail) != null) {
      throw Exception('该邮箱已被使用');
    }
    
    // 更新邮箱
    final updatedUser = User(
      id: _currentUser!.id,
      email: newEmail,
      phoneNumber: _currentUser!.phoneNumber,
      displayName: _currentUser!.displayName,
      avatarUrl: _currentUser!.avatarUrl,
      authProvider: _currentUser!.authProvider,
      isEmailVerified: true,
      isPhoneVerified: _currentUser!.isPhoneVerified,
      lastLoginAt: _currentUser!.lastLoginAt,
      createdAt: _currentUser!.createdAt,
      updatedAt: DateTime.now(),
    );
    
    await _saveUser(updatedUser);
    _currentUser = updatedUser;
    _authStateController.add(_currentUser);
  }
  
  @override
  Future<void> updatePhoneNumber(
    String newPhoneNumber,
    String verificationCode,
    String verificationId,
  ) async {
    // Fail Fast：参数验证
    ValidationHelper.validatePhoneNumberForRepository(newPhoneNumber);
    if (verificationCode.isEmpty) {
      throw ArgumentError('验证码不能为空');
    }
    if (verificationId.isEmpty) {
      throw ArgumentError('验证 ID 不能为空');
    }
    
    // Fail Fast：用户未登录
    if (_currentUser == null) {
      throw StateError('用户未登录');
    }
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 验证验证码（测试环境固定验证码：123456）
    if (verificationCode != '123456') {
      throw Exception('验证码错误');
    }
    
    // 检查新手机号是否已被使用
    if (_getUserByPhone(newPhoneNumber) != null) {
      throw Exception('该手机号已被使用');
    }
    
    // 更新手机号
    final updatedUser = User(
      id: _currentUser!.id,
      email: _currentUser!.email,
      phoneNumber: newPhoneNumber,
      displayName: _currentUser!.displayName,
      avatarUrl: _currentUser!.avatarUrl,
      authProvider: _currentUser!.authProvider,
      isEmailVerified: _currentUser!.isEmailVerified,
      isPhoneVerified: true,
      lastLoginAt: _currentUser!.lastLoginAt,
      createdAt: _currentUser!.createdAt,
      updatedAt: DateTime.now(),
    );
    
    await _saveUser(updatedUser);
    _currentUser = updatedUser;
    _authStateController.add(_currentUser);
  }
  
  /// 释放资源
  void dispose() {
    _authStateController.close();
  }
}

