import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/user.dart';
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
/// - 开发环境：无需真实 Firebase 配置即可测试
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
  User? __currentUser;
  
  User? get _currentUser => __currentUser;
  
  set _currentUser(User? value) {
    print('🔍 [TestAuth] _currentUser 被设置: ${value?.id ?? "null"}');
    print('🔍 [TestAuth] 调用栈: ${StackTrace.current}');
    __currentUser = value;
  }
  
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
        print('🔍 [TestAuth] 从 Hive 恢复登录状态: ${_currentUser?.id ?? "null"}');
      } else {
        _currentUser = null;
        print('🔍 [TestAuth] 无保存的登录状态');
      }
      
      // 打印所有已注册用户
      final allUsers = _testUsersBox.values.toList();
      print('📊 [TestAuth] 已注册用户数: ${allUsers.length}');
      if (allUsers.isNotEmpty) {
        print('📋 [TestAuth] 已注册用户列表:');
        for (var i = 0; i < allUsers.length; i++) {
          final user = allUsers[i];
          print('   ${i + 1}. ID: ${user.id}');
          if (user.email != null) {
            print('      邮箱: ${user.email}');
          }
          if (user.phoneNumber != null) {
            print('      手机号: ${user.phoneNumber}');
          }
          print('      注册时间: ${user.createdAt}');
        }
      }
    } catch (e) {
      print('❌ [TestAuth] 初始化测试数据失败: $e');
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
    print('✅ [TestAuth] 当前用户 ID 已保存到 Hive: $userId');
  }
  
  /// 清除当前用户 ID
  Future<void> _clearCurrentUserId() async {
    await _sessionBox.delete(_currentUserIdKey);
    print('✅ [TestAuth] 当前用户 ID 已从 Hive 清除');
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
    print('✅ [TestAuth] 用户已保存到 Hive: ${user.id}');
  }
  
  /// 保存密码到 Hive（仅用于测试环境）
  /// 
  /// ⚠️ 安全警告：
  /// 1. 这里使用明文存储密码，仅用于开发和测试环境
  /// 2. 生产环境绝不应该在客户端存储密码（明文或哈希）
  /// 3. Firebase Authentication 会在服务器端安全处理密码
  /// 4. 如果需要本地存储，应该使用加密哈希（如 SHA-256）
  /// 
  /// 为什么测试环境可以接受明文：
  /// - 仅在本地开发环境使用
  /// - 不会暴露到网络
  /// - 方便调试和测试
  Future<void> _savePassword(String userId, String password) async {
    await _passwordsBox.put(userId, password);
    print('✅ [TestAuth] 密码已保存到 Hive: $userId');
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
      print('🔍 [TestAuth] authStateChanges 被监听，当前用户: ${_currentUser?.id ?? "null"}');
      controller.add(_currentUser);
      
      // 监听后续事件并转发
      final subscription = _authStateController.stream.listen(
        (user) {
          print('🔍 [TestAuth] authStateChanges 收到新事件: ${user?.id ?? "null"}');
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
    print('🔍 [TestAuth] signInWithEmail 开始');
    print('🔍 [TestAuth] 邮箱: $email');
    print('🔍 [TestAuth] 密码: $password');
    
    // Fail Fast：参数验证（使用统一的验证规则）
    ValidationHelper.validateEmailForRepository(email);
    ValidationHelper.validatePasswordForRepository(password);
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 检查用户是否存在
    print('🔍 [TestAuth] 检查用户是否存在...');
    print('🔍 [TestAuth] 当前数据库中的用户数: ${_testUsersBox.length}');
    final user = _getUserByEmail(email);
    if (user == null) {
      print('❌ [TestAuth] 该邮箱尚未注册');
      // 清空当前用户
      _currentUser = null;
      _authStateController.add(null);
      throw Exception('该邮箱尚未注册');
    }
    print('✅ [TestAuth] 用户存在: ${user.id}');
    
    // 检查密码（从 Hive 获取保存的密码）
    print('🔍 [TestAuth] 检查密码...');
    final savedPassword = _getPassword(user.id);
    print('🔍 [TestAuth] 输入密码: "$password"');
    print('🔍 [TestAuth] 保存的密码: "$savedPassword"');
    
    // Fail Fast: 密码必须存在
    if (savedPassword == null) {
      print('❌ [TestAuth] 数据异常：密码未保存');
      _currentUser = null;
      _authStateController.add(null);
      throw Exception('账号数据异常，请重新注册');
    }
    
    // Fail Fast: 密码必须匹配
    if (password != savedPassword) {
      print('❌ [TestAuth] 密码错误');
      _currentUser = null;
      _authStateController.add(null);
      throw Exception('密码错误');
    }
    
    print('✅ [TestAuth] 密码正确');
    
    // 登录成功
    _currentUser = user;
    _authStateController.add(_currentUser);
    
    // 保存当前用户 ID 到 Hive
    await _saveCurrentUserId(user.id);
    
    print('✅ [TestAuth] 登录成功');
    return _currentUser!;
  }
  
  @override
  Future<User> signUpWithEmail(String email, String password) async {
    print('🔍 [TestAuth] signUpWithEmail 开始');
    print('🔍 [TestAuth] 邮箱: $email');
    print('🔍 [TestAuth] 密码: $password');
    
    // Fail Fast：参数验证（使用统一的验证规则）
    ValidationHelper.validateEmailForRepository(email);
    ValidationHelper.validatePasswordForRepository(password);
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 检查邮箱是否已注册
    print('🔍 [TestAuth] 检查邮箱是否已注册...');
    print('🔍 [TestAuth] 当前数据库中的用户数: ${_testUsersBox.length}');
    if (_getUserByEmail(email) != null) {
      print('❌ [TestAuth] 该邮箱已被注册');
      throw Exception('该邮箱已被注册');
    }
    print('✅ [TestAuth] 邮箱可用');
    
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
    
    print('🔍 [TestAuth] 创建用户: ${user.id}');
    
    // 保存到 Hive
    await _saveUser(user);
    
    // 保存密码到 Hive（仅测试环境）
    await _savePassword(user.id, password);
    
    print('🔍 [TestAuth] 数据库中的用户数: ${_testUsersBox.length}');
    
    // 自动登录
    _currentUser = user;
    _authStateController.add(_currentUser);
    
    // 保存当前用户 ID 到 Hive
    await _saveCurrentUserId(user.id);
    
    print('✅ [TestAuth] 注册成功并自动登录');
    return user;
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
  Future<User> signUpWithPhone(
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
    
    // 自动登录
    _currentUser = user;
    _authStateController.add(_currentUser);
    
    // 保存当前用户 ID 到 Hive
    await _saveCurrentUserId(user.id);
    
    return user;
  }
  
  @override
  Future<void> signOut() async {
    print('🔍 [TestAuth] signOut 开始');
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 300));
    
    print('🔍 [TestAuth] 清空当前用户');
    _currentUser = null;
    
    // 清除保存的用户 ID
    await _clearCurrentUserId();
    
    print('🔍 [TestAuth] 发送 null 事件到 authStateChanges');
    _authStateController.add(null);
    
    print('✅ [TestAuth] signOut 完成');
  }
  
  @override
  Future<void> resetPassword(String email) async {
    // Fail Fast：参数验证
    if (email.isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 检查邮箱是否存在
    if (_getUserByEmail(email) == null) {
      throw Exception('该邮箱不存在');
    }
    
    // 测试环境：直接成功（不发送真实邮件）
  }
  
  /// 释放资源
  void dispose() {
    _authStateController.close();
  }
}

