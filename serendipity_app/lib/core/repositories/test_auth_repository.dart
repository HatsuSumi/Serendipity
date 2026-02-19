import 'dart:async';
import '../../models/user.dart';
import '../../models/enums.dart';
import 'i_auth_repository.dart';

/// 测试认证仓库
/// 
/// 仅用于开发和测试环境，提供模拟的认证功能。
/// 遵循依赖倒置原则（DIP），实现 IAuthRepository 接口。
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
  /// 模拟的当前用户
  User? _currentUser;
  
  /// 认证状态流控制器
  final _authStateController = StreamController<User?>.broadcast();
  
  /// 模拟用户数据库（邮箱 -> 用户）
  final Map<String, User> _usersByEmail = {};
  
  /// 模拟用户数据库（手机号 -> 用户）
  final Map<String, User> _usersByPhone = {};
  
  @override
  Future<User?> get currentUser async {
    return _currentUser;
  }
  
  @override
  Stream<User?> get authStateChanges {
    return _authStateController.stream;
  }
  
  @override
  Future<User> signInWithEmail(String email, String password) async {
    // Fail Fast：参数验证
    if (email.isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }
    if (password.isEmpty) {
      throw ArgumentError('Password cannot be empty');
    }
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 检查用户是否存在
    if (!_usersByEmail.containsKey(email)) {
      throw Exception('该邮箱尚未注册');
    }
    
    // 检查密码（测试环境固定密码：123456）
    if (password != '123456') {
      throw Exception('密码错误');
    }
    
    // 登录成功
    _currentUser = _usersByEmail[email];
    _authStateController.add(_currentUser);
    
    return _currentUser!;
  }
  
  @override
  Future<User> signUpWithEmail(String email, String password) async {
    // Fail Fast：参数验证
    if (email.isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }
    if (password.isEmpty) {
      throw ArgumentError('Password cannot be empty');
    }
    if (password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters');
    }
    
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 检查邮箱是否已注册
    if (_usersByEmail.containsKey(email)) {
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
    
    // 保存到模拟数据库
    _usersByEmail[email] = user;
    
    // 自动登录
    _currentUser = user;
    _authStateController.add(_currentUser);
    
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
    if (!_usersByPhone.containsKey(phoneNumber)) {
      throw Exception('该手机号尚未注册');
    }
    
    // 登录成功
    _currentUser = _usersByPhone[phoneNumber];
    _authStateController.add(_currentUser);
    
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
    if (_usersByPhone.containsKey(phoneNumber)) {
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
    
    // 保存到模拟数据库
    _usersByPhone[phoneNumber] = user;
    
    // 自动登录
    _currentUser = user;
    _authStateController.add(_currentUser);
    
    return user;
  }
  
  @override
  Future<void> signOut() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 300));
    
    _currentUser = null;
    _authStateController.add(null);
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
    if (!_usersByEmail.containsKey(email)) {
      throw Exception('该邮箱不存在');
    }
    
    // 测试环境：直接成功（不发送真实邮件）
  }
  
  /// 释放资源
  void dispose() {
    _authStateController.close();
  }
}

