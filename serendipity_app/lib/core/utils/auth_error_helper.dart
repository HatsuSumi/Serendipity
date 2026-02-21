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
    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }
    
    // 去掉 "ArgumentError: " 前缀
    if (message.startsWith('ArgumentError: ')) {
      return message.substring(15);
    }
    
    // 去掉 "StateError: " 前缀
    if (message.startsWith('StateError: ')) {
      return message.substring(12);
    }
    
    return message;
  }
}

