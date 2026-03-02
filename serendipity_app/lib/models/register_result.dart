import 'user.dart';

/// 注册结果
/// 
/// 包含注册成功后的用户信息和恢复密钥（仅在注册时返回一次）。
/// 遵循单一职责原则（SRP）：只负责封装注册结果数据。
class RegisterResult {
  /// 注册成功的用户
  final User user;
  
  /// 恢复密钥（仅在注册时返回一次，用于忘记密码时重置）
  final String? recoveryKey;
  
  const RegisterResult({
    required this.user,
    this.recoveryKey,
  });
}

