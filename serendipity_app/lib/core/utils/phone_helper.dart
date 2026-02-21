/// 手机号处理工具类
/// 
/// 提供手机号格式化等相关功能。
/// 
/// 调用者：
/// - LoginPage
/// - RegisterPage
/// 
/// 设计原则：
/// - DRY: 避免重复的手机号处理逻辑
/// - 单一职责: 只负责手机号相关操作
class PhoneHelper {
  /// 格式化手机号（拼接国家代码 + 手机号）
  /// 
  /// 调用者：
  /// - LoginPage._sendVerificationCode()
  /// - LoginPage._handlePhoneLogin()
  /// - RegisterPage._sendVerificationCode()
  /// - RegisterPage._handlePhoneRegister()
  /// 
  /// 参数：
  /// - [countryCode]: 国家代码（如 +86）
  /// - [phoneNumber]: 手机号（不含国家代码）
  /// 
  /// 返回：完整手机号（如 +8613800138000）
  /// 
  /// 示例：
  /// ```dart
  /// final fullPhone = PhoneHelper.formatWithCountryCode('+86', '13800138000');
  /// // 返回: '+8613800138000'
  /// ```
  static String formatWithCountryCode(String countryCode, String phoneNumber) {
    return '$countryCode${phoneNumber.trim()}';
  }
}

