/// 认证错误处理工具类
/// 
/// 提供统一的错误信息提取和处理方法。
/// 
/// 调用者：
/// - LoginPage
/// - RegisterPage
/// - ForgotPasswordPage
/// - AsyncActionHelper
/// 
/// 设计原则：
/// - DRY: 避免重复的错误处理代码
/// - 单一职责: 只负责错误信息处理
class AuthErrorHelper {
  /// 提取错误信息（去掉 "Exception:" 前缀）
  /// 
  /// 调用者：
  /// - LoginPage._handleEmailLogin()
  /// - LoginPage._handlePhoneLogin()
  /// - LoginPage._sendVerificationCode()
  /// - RegisterPage._handleEmailRegister()
  /// - RegisterPage._handlePhoneRegister()
  /// - RegisterPage._sendVerificationCode()
  /// - ForgotPasswordPage._handleSendResetEmail()
  /// - AsyncActionHelper.execute()
  /// - AsyncActionHelper.executeWithResult()
  /// 
  /// 参数：
  /// - [error]: 捕获的异常对象
  /// 
  /// 返回：清理后的错误信息
  static String extractErrorMessage(Object error) {
    final message = error.toString();
    
    // 去掉 "Exception: " 前缀
    String cleanMessage = message;
    if (message.startsWith('Exception: ')) {
      cleanMessage = message.substring(11);
    } else if (message.startsWith('ArgumentError: ')) {
      cleanMessage = message.substring(15);
    } else if (message.startsWith('StateError: ')) {
      cleanMessage = message.substring(12);
    } else if (message.startsWith('Bad state: ')) {
      cleanMessage = message.substring(11);
    }
    
    // 翻译常见的 Supabase 错误信息
    return _translateErrorMessage(cleanMessage);
  }
  
  /// 翻译 Supabase 错误信息为中文
  static String _translateErrorMessage(String message) {
    // Supabase 常见错误信息映射
    final errorMap = {
      'User already registered': '该邮箱已注册',
      'Invalid login credentials': '邮箱或密码错误',
      'Email not confirmed': '请先验证邮箱',
      'Invalid email': '邮箱格式不正确',
      'Password should be at least 6 characters': '密码长度至少 6 位',
      'Unsupported phone provider': '不支持手机号登录',
      'Invalid phone number': '手机号格式不正确',
      'Invalid verification code': '验证码错误',
      'Verification code expired': '验证码已过期',
      'Email rate limit exceeded': '发送邮件过于频繁，请稍后再试',
      'SMS rate limit exceeded': '发送短信过于频繁，请稍后再试',
      'User not found': '用户不存在',
      'Invalid password': '密码错误',
      'Email already exists': '该邮箱已被使用',
      'Phone already exists': '该手机号已被使用',
    };
    
    // 检查是否包含已知错误信息
    for (final entry in errorMap.entries) {
      if (message.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // 如果没有匹配的翻译，返回原始信息
    return message;
  }
}

