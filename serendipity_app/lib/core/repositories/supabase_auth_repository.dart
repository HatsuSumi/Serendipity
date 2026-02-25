import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user.dart' as app_user;
import '../../models/enums.dart';
import 'i_auth_repository.dart';

/// Supabase 认证仓库实现
/// 
/// 使用 Supabase Auth 服务，支持邮箱、手机号等多种认证方式。
class SupabaseAuthRepository implements IAuthRepository {
  final SupabaseClient _client;
  
  SupabaseAuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;
  
  @override
  Future<app_user.User?> get currentUser async {
    final supabaseUser = _client.auth.currentUser;
    if (supabaseUser == null) return null;
    
    return _convertToAppUser(supabaseUser);
  }
  
  @override
  Stream<app_user.User?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) {
      final supabaseUser = data.session?.user;
      if (supabaseUser == null) return null;
      return _convertToAppUser(supabaseUser);
    });
  }
  
  @override
  Future<app_user.User> signInWithEmail(String email, String password) async {
    // Fail Fast：参数验证
    if (email.isEmpty) {
      throw ArgumentError('邮箱不能为空');
    }
    if (password.isEmpty || password.length < 6) {
      throw ArgumentError('密码长度必须至少 6 位');
    }
    
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('登录失败：未返回用户信息');
      }
      
      return _convertToAppUser(response.user!);
    } on AuthException catch (e) {
      throw Exception('登录失败：${e.message}');
    }
  }
  
  @override
  Future<app_user.User> signUpWithEmail(String email, String password) async {
    // Fail Fast：参数验证
    if (email.isEmpty) {
      throw ArgumentError('邮箱不能为空');
    }
    if (password.isEmpty || password.length < 6) {
      throw ArgumentError('密码长度必须至少 6 位');
    }
    
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('注册失败：未返回用户信息');
      }
      
      return _convertToAppUser(response.user!);
    } on AuthException catch (e) {
      throw Exception('注册失败：${e.message}');
    }
  }
  
  @override
  Future<app_user.User> signInWithPhone(
    String phoneNumber,
    String verificationCode,
    String verificationId,
  ) async {
    // Fail Fast：参数验证
    if (phoneNumber.isEmpty) {
      throw ArgumentError('手机号不能为空');
    }
    if (verificationCode.isEmpty) {
      throw ArgumentError('验证码不能为空');
    }
    
    try {
      final response = await _client.auth.verifyOTP(
        phone: phoneNumber,
        token: verificationCode,
        type: OtpType.sms,
      );
      
      if (response.user == null) {
        throw Exception('登录失败：未返回用户信息');
      }
      
      return _convertToAppUser(response.user!);
    } on AuthException catch (e) {
      throw Exception('登录失败：${e.message}');
    }
  }
  
  @override
  Future<String> sendPhoneVerificationCode(String phoneNumber) async {
    // Fail Fast：参数验证
    if (phoneNumber.isEmpty) {
      throw ArgumentError('手机号不能为空');
    }
    if (!phoneNumber.startsWith('+')) {
      throw ArgumentError('手机号格式错误：缺少国家代码');
    }
    
    try {
      await _client.auth.signInWithOtp(
        phone: phoneNumber,
      );
      
      // Supabase 不返回 verificationId，直接返回手机号作为标识
      return phoneNumber;
    } on AuthException catch (e) {
      throw Exception('发送验证码失败：${e.message}');
    }
  }
  
  @override
  Future<app_user.User> signUpWithPhone(
    String phoneNumber,
    String verificationCode,
    String verificationId,
  ) async {
    // Supabase 的手机号注册和登录是同一个流程
    return signInWithPhone(phoneNumber, verificationCode, verificationId);
  }
  
  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('登出失败：${e.message}');
    }
  }
  
  @override
  Future<void> resetPassword(String email) async {
    // Fail Fast：参数验证
    if (email.isEmpty) {
      throw ArgumentError('邮箱不能为空');
    }
    
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception('发送重置邮件失败：${e.message}');
    }
  }
  
  @override
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    // Fail Fast：参数验证
    if (currentPassword.isEmpty) {
      throw ArgumentError('当前密码不能为空');
    }
    if (newPassword.isEmpty || newPassword.length < 6) {
      throw ArgumentError('新密码长度必须至少 6 位');
    }
    
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('用户未登录');
    }
    
    try {
      // Supabase 需要先重新认证
      await _client.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );
      
      // 然后更新密码
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception('修改密码失败：${e.message}');
    }
  }
  
  @override
  Future<void> updateEmail(String newEmail, String password) async {
    // Fail Fast：参数验证
    if (newEmail.isEmpty) {
      throw ArgumentError('新邮箱不能为空');
    }
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }
    
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('用户未登录');
    }
    
    try {
      // Supabase 需要先重新认证
      await _client.auth.signInWithPassword(
        email: user.email!,
        password: password,
      );
      
      // 然后更新邮箱
      await _client.auth.updateUser(
        UserAttributes(email: newEmail),
      );
    } on AuthException catch (e) {
      throw Exception('更换邮箱失败：${e.message}');
    }
  }
  
  @override
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
    
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('用户未登录');
    }
    
    try {
      // 验证新手机号
      await _client.auth.verifyOTP(
        phone: newPhoneNumber,
        token: verificationCode,
        type: OtpType.phoneChange,
      );
      
      // 更新手机号
      await _client.auth.updateUser(
        UserAttributes(phone: newPhoneNumber),
      );
    } on AuthException catch (e) {
      throw Exception('更换手机号失败：${e.message}');
    }
  }
  
  /// 将 Supabase User 转换为应用的 User 模型
  app_user.User _convertToAppUser(User supabaseUser) {
    return app_user.User(
      id: supabaseUser.id,
      email: supabaseUser.email,
      phoneNumber: supabaseUser.phone,
      displayName: supabaseUser.userMetadata?['display_name'] as String?,
      avatarUrl: supabaseUser.userMetadata?['avatar_url'] as String?,
      authProvider: AuthProvider.email, // Supabase 统一使用 email provider
      isEmailVerified: supabaseUser.emailConfirmedAt != null,
      isPhoneVerified: supabaseUser.phoneConfirmedAt != null,
      createdAt: supabaseUser.createdAt != null 
          ? DateTime.parse(supabaseUser.createdAt)
          : DateTime.now(),
      updatedAt: supabaseUser.updatedAt != null
          ? DateTime.parse(supabaseUser.updatedAt!)
          : DateTime.now(),
    );
  }
}

