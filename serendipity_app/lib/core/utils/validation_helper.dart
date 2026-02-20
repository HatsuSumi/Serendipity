/// 验证工具类
/// 
/// 提供统一的验证规则，作为唯一的验证规则来源（Single Source of Truth）。
/// 所有验证逻辑都应该调用此类的方法，避免重复定义。
/// 
/// 调用者：
/// - AuthTextField：UI 层表单验证
/// - FirebaseAuthRepository：Repository 层参数验证
/// - TestAuthRepository：Repository 层参数验证
/// 
/// 设计原则：
/// - DRY: 避免重复的验证逻辑
/// - 单一职责: 只负责验证规则
/// - Fail Fast: 验证失败立即返回错误信息
class ValidationHelper {
  /// 邮箱正则表达式
  /// 
  /// 规则：
  /// - 用户名部分：字母、数字、点、下划线、百分号、加号、连字符
  /// - @ 符号
  /// - 域名部分：字母、数字、点、连字符
  /// - 顶级域名：至少 2 个字母
  /// 
  /// 示例：
  /// - ✅ user@example.com
  /// - ✅ user.name+tag@example.co.uk
  /// - ✅ user_123@sub.example.com
  /// - ❌ user@example (缺少顶级域名)
  /// - ❌ @example.com (缺少用户名)
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  /// 中国手机号正则表达式
  /// 
  /// 规则：
  /// - 1 开头
  /// - 11 位数字
  /// 
  /// 示例：
  /// - ✅ 13800138000
  /// - ✅ 18912345678
  /// - ❌ 12345678901 (不是 1 开头)
  /// - ❌ 1234567890 (不足 11 位)
  static final RegExp _chinesePhoneRegex = RegExp(r'^1\d{10}$');
  
  /// 国际手机号正则表达式（至少 8 位数字）
  static final RegExp _internationalPhoneRegex = RegExp(r'^\d{8,}$');
  
  /// 最小密码长度
  static const int minPasswordLength = 6;
  
  /// 验证码长度
  static const int verificationCodeLength = 6;
  
  // ==================== 邮箱验证 ====================
  
  /// 验证邮箱格式（用于 UI 层）
  /// 
  /// 返回：
  /// - null：验证通过
  /// - String：错误信息
  /// 
  /// 调用者：AuthTextField._validateEmail()
  static String? validateEmailForUI(String value) {
    // 先 trim 去除首尾空格
    final trimmedValue = value.trim();
    
    // Fail Fast：空值检查
    if (trimmedValue.isEmpty) {
      return '邮箱不能为空';
    }
    
    // 基础格式验证：必须包含 @ 和至少一个点
    if (!trimmedValue.contains('@') || !trimmedValue.contains('.')) {
      return '邮箱格式不正确';
    }
    
    // 正则表达式验证
    if (!_emailRegex.hasMatch(trimmedValue)) {
      return '邮箱格式不正确';
    }
    
    // 额外验证：不允许连续的点
    if (trimmedValue.contains('..')) {
      return '邮箱格式不正确';
    }
    
    // 额外验证：用户名部分不允许以点开头或结尾
    final parts = trimmedValue.split('@');
    if (parts[0].startsWith('.') || parts[0].endsWith('.')) {
      return '邮箱格式不正确';
    }
    
    // 额外验证：域名部分不允许以点或连字符开头或结尾
    if (parts[1].startsWith('.') || parts[1].startsWith('-') ||
        parts[1].endsWith('.') || parts[1].endsWith('-')) {
      return '邮箱格式不正确';
    }
    
    return null;
  }
  
  /// 验证邮箱格式（用于 Repository 层）
  /// 
  /// 抛出：ArgumentError（如果验证失败）
  /// 
  /// 调用者：
  /// - FirebaseAuthRepository._validateEmail()
  /// - TestAuthRepository.signInWithEmail()
  /// - TestAuthRepository.signUpWithEmail()
  static void validateEmailForRepository(String email) {
    final error = validateEmailForUI(email);
    if (error != null) {
      throw ArgumentError(error);
    }
  }
  
  // ==================== 密码验证 ====================
  
  /// 验证密码强度（用于 UI 层）
  /// 
  /// 返回：
  /// - null：验证通过
  /// - String：错误信息
  /// 
  /// 调用者：AuthTextField._validatePassword()
  static String? validatePasswordForUI(String value) {
    // Fail Fast：空值检查
    if (value.isEmpty) {
      return '密码不能为空';
    }
    
    // 长度检查
    if (value.length < minPasswordLength) {
      return '密码至少需要$minPasswordLength位';
    }
    
    return null;
  }
  
  /// 验证密码强度（用于 Repository 层）
  /// 
  /// 抛出：ArgumentError（如果验证失败）
  /// 
  /// 调用者：
  /// - FirebaseAuthRepository._validatePassword()
  /// - TestAuthRepository.signInWithEmail()
  /// - TestAuthRepository.signUpWithEmail()
  static void validatePasswordForRepository(String password) {
    final error = validatePasswordForUI(password);
    if (error != null) {
      throw ArgumentError(error);
    }
  }
  
  // ==================== 手机号验证 ====================
  
  /// 验证手机号格式（用于 UI 层）
  /// 
  /// 返回：
  /// - null：验证通过
  /// - String：错误信息
  /// 
  /// 调用者：AuthTextField._validatePhone()
  static String? validatePhoneForUI(String value) {
    // Fail Fast：空值检查
    if (value.trim().isEmpty) {
      return '手机号不能为空';
    }
    
    // 中国手机号：1 开头，11 位数字
    if (_chinesePhoneRegex.hasMatch(value)) {
      return null;
    }
    
    // 国际手机号：至少 8 位数字
    if (_internationalPhoneRegex.hasMatch(value)) {
      return null;
    }
    
    return '手机号格式不正确';
  }
  
  /// 验证手机号格式（用于 Repository 层，包含国家代码）
  /// 
  /// 参数：
  /// - phoneNumber：完整手机号（包含国家代码，如 +8613800138000）
  /// 
  /// 抛出：ArgumentError（如果验证失败）
  /// 
  /// 调用者：
  /// - FirebaseAuthRepository._validatePhoneNumber()
  /// - TestAuthRepository.signInWithPhone()
  /// - TestAuthRepository.signUpWithPhone()
  static void validatePhoneNumberForRepository(String phoneNumber) {
    // Fail Fast：空值检查
    if (phoneNumber.trim().isEmpty) {
      throw ArgumentError('手机号不能为空');
    }
    
    // 手机号必须包含国家代码（如 +86）
    if (!phoneNumber.startsWith('+')) {
      throw ArgumentError('手机号必须包含国家代码（如 +86）');
    }
    
    // 简单验证：+ 号后面至少有 10 位数字
    final digitsOnly = phoneNumber.substring(1).replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) {
      throw ArgumentError('手机号格式不正确');
    }
  }
  
  // ==================== 验证码验证 ====================
  
  /// 验证验证码格式（用于 UI 层）
  /// 
  /// 返回：
  /// - null：验证通过
  /// - String：错误信息
  /// 
  /// 调用者：AuthTextField._validateVerificationCode()
  static String? validateVerificationCodeForUI(String value) {
    // Fail Fast：空值检查
    if (value.trim().isEmpty) {
      return '验证码不能为空';
    }
    
    // 长度检查
    if (value.length != verificationCodeLength) {
      return '验证码应为$verificationCodeLength位数字';
    }
    
    // 格式检查：只能是数字
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return '验证码只能包含数字';
    }
    
    return null;
  }
  
  /// 验证验证码格式（用于 Repository 层）
  /// 
  /// 抛出：ArgumentError（如果验证失败）
  /// 
  /// 调用者：
  /// - FirebaseAuthRepository.signInWithPhone()
  /// - TestAuthRepository.signInWithPhone()
  static void validateVerificationCodeForRepository(String verificationCode) {
    final error = validateVerificationCodeForUI(verificationCode);
    if (error != null) {
      throw ArgumentError(error);
    }
  }
}

