import '../../models/user.dart';
import '../../models/register_result.dart';

/// 认证仓库接口
/// 
/// 定义所有认证相关操作的契约，遵循依赖倒置原则（DIP）。
/// 具体实现可以是自建服务器或其他认证服务。
/// 
/// 调用者：
/// - AuthProvider：状态管理层，调用所有方法
/// - LoginPage/RegisterPage：通过 AuthProvider 间接调用
abstract class IAuthRepository {
  /// 获取当前登录用户
  /// 
  /// 返回当前已登录的用户，如果未登录则返回 null。
  /// 
  /// 调用者：
  /// - AuthProvider.build()：初始化时获取当前用户状态
  /// 
  /// Fail Fast：
  /// - 如果认证服务未初始化，应抛出 StateError
  Future<User?> get currentUser;
  
  /// 监听认证状态变化
  /// 
  /// 返回一个 Stream，当用户登录/登出时会发出新的用户状态。
  /// 
  /// 调用者：
  /// - AuthProvider：订阅此 Stream 以自动更新用户状态
  /// 
  /// Fail Fast：
  /// - 如果认证服务未初始化，应抛出 StateError
  Stream<User?> get authStateChanges;
  
  /// 使用邮箱和密码登录
  /// 
  /// 参数：
  /// - [email]：用户邮箱
  /// - [password]：用户密码
  /// 
  /// 返回：登录成功的用户对象
  /// 
  /// 调用者：
  /// - AuthProvider.signInWithEmail()
  /// - LoginPage 通过 AuthProvider 调用
  /// 
  /// Fail Fast：
  /// - email 为空或格式不正确：抛出 ArgumentError
  /// - password 长度小于 6：抛出 ArgumentError
  /// - 认证失败：抛出具体的认证异常（由实现类定义）
  Future<User> signInWithEmail(String email, String password);
  
  /// 使用邮箱和密码注册
  /// 
  /// 参数：
  /// - [email]：用户邮箱
  /// - [password]：用户密码
  /// 
  /// 返回：注册结果（包含用户对象和恢复密钥）
  /// 
  /// 调用者：
  /// - AuthProvider.signUpWithEmail()
  /// - RegisterPage 通过 AuthProvider 调用
  /// 
  /// Fail Fast：
  /// - email 为空或格式不正确：抛出 ArgumentError
  /// - password 长度小于 6：抛出 ArgumentError
  /// - 邮箱已被注册：抛出具体的认证异常（由实现类定义）
  Future<RegisterResult> signUpWithEmail(String email, String password);
  
  /// 使用手机号和密码登录
  /// 
  /// 参数：
  /// - [phoneNumber]：手机号（包含国家代码，如 +86）
  /// - [password]：用户密码
  /// 
  /// 返回：登录成功的用户对象
  /// 
  /// 调用者：
  /// - AuthProvider.signInWithPhonePassword()
  /// - LoginPage 通过 AuthProvider 调用
  /// 
  /// Fail Fast：
  /// - phoneNumber 为空或格式不正确：抛出 ArgumentError
  /// - password 长度小于 6：抛出 ArgumentError
  /// - 认证失败：抛出具体的认证异常（由实现类定义）
  Future<User> signInWithPhonePassword(String phoneNumber, String password);
  
  /// 使用手机号和验证码登录
  /// 
  /// 参数：
  /// - [phoneNumber]：手机号（包含国家代码，如 +86）
  /// - [verificationCode]：短信验证码
  /// - [verificationId]：验证 ID（由 sendPhoneVerificationCode 返回）
  /// 
  /// 返回：登录成功的用户对象
  /// 
  /// 调用者：
  /// - AuthProvider.signInWithPhone()
  /// - LoginPage 通过 AuthProvider 调用（已禁用）
  /// 
  /// Fail Fast：
  /// - phoneNumber 为空或格式不正确：抛出 ArgumentError
  /// - verificationCode 为空：抛出 ArgumentError
  /// - verificationId 为空：抛出 ArgumentError
  /// - 验证码错误：抛出具体的认证异常（由实现类定义）
  Future<User> signInWithPhone(
    String phoneNumber,
    String verificationCode,
    String verificationId,
  );
  
  /// 发送手机验证码
  /// 
  /// 参数：
  /// - [phoneNumber]：手机号（包含国家代码，如 +86）
  /// 
  /// 返回：验证 ID（用于后续验证）
  /// 
  /// 调用者：
  /// - AuthProvider.sendPhoneVerificationCode()
  /// - LoginPage/RegisterPage 通过 AuthProvider 调用
  /// 
  /// Fail Fast：
  /// - phoneNumber 为空或格式不正确：抛出 ArgumentError
  /// - 发送失败：抛出具体的认证异常（由实现类定义）
  Future<String> sendPhoneVerificationCode(String phoneNumber);
  
  /// 使用手机号和密码注册
  /// 
  /// 参数：
  /// - [phoneNumber]：手机号（包含国家代码，如 +86）
  /// - [password]：用户密码
  /// 
  /// 返回：注册结果（包含用户对象和恢复密钥）
  /// 
  /// 调用者：
  /// - AuthProvider.signUpWithPhonePassword()
  /// - RegisterPage 通过 AuthProvider 调用
  /// 
  /// Fail Fast：
  /// - phoneNumber 为空或格式不正确：抛出 ArgumentError
  /// - password 长度小于 6：抛出 ArgumentError
  /// - 手机号已被注册：抛出具体的认证异常（由实现类定义）
  Future<RegisterResult> signUpWithPhonePassword(String phoneNumber, String password);
  
  /// 使用手机号和验证码注册
  /// 
  /// 参数：
  /// - [phoneNumber]：手机号（包含国家代码，如 +86）
  /// - [verificationCode]：短信验证码
  /// - [verificationId]：验证 ID（由 sendPhoneVerificationCode 返回）
  /// 
  /// 返回：注册结果（包含用户对象和恢复密钥）
  /// 
  /// 调用者：
  /// - AuthProvider.signUpWithPhone()
  /// - RegisterPage 通过 AuthProvider 调用（已禁用）
  /// 
  /// Fail Fast：
  /// - phoneNumber 为空或格式不正确：抛出 ArgumentError
  /// - verificationCode 为空：抛出 ArgumentError
  /// - verificationId 为空：抛出 ArgumentError
  /// - 手机号已被注册：抛出具体的认证异常（由实现类定义）
  Future<RegisterResult> signUpWithPhone(
    String phoneNumber,
    String verificationCode,
    String verificationId,
  );
  
  /// 登出
  /// 
  /// 调用者：
  /// - AuthProvider.signOut()
  /// - SettingsPage 通过 AuthProvider 调用
  /// 
  /// Fail Fast：
  /// - 登出失败：抛出具体的认证异常（由实现类定义）
  Future<void> signOut();
  
  /// 发送密码重置邮件
  /// 
  /// 参数：
  /// - [email]：用户邮箱
  /// - [recoveryKey]：恢复密钥
  /// - [newPassword]：新密码
  /// 
  /// 调用者：
  /// - AuthProvider.resetPassword()
  /// - ForgotPasswordPage 通过 AuthProvider 调用
  /// 
  /// Fail Fast：
  /// - email 为空或格式不正确：抛出 ArgumentError
  /// - recoveryKey 为空：抛出 ArgumentError
  /// - newPassword 为空或长度小于 6：抛出 ArgumentError
  /// - 邮箱或恢复密钥错误：抛出具体的认证异常（由实现类定义）
  Future<void> resetPassword(String email, String recoveryKey, String newPassword);
  
  /// 生成恢复密钥
  /// 
  /// 返回：生成的恢复密钥字符串
  /// 
  /// 调用者：
  /// - AuthProvider.generateRecoveryKey()
  /// - SettingsPage 通过 AuthProvider 调用
  /// 
  /// Fail Fast：
  /// - 用户未登录：抛出 StateError
  Future<String> generateRecoveryKey();
  
  /// 获取当前恢复密钥
  /// 
  /// 返回：当前的恢复密钥字符串，如果未设置则返回 null
  /// 
  /// 调用者：
  /// - AuthProvider.getRecoveryKey()
  /// - SettingsPage 通过 AuthProvider 调用
  /// 
  /// Fail Fast：
  /// - 用户未登录：抛出 StateError
  Future<String?> getRecoveryKey();
  
  /// 修改密码
  /// 
  /// 参数：
  /// - [currentPassword]：当前密码
  /// - [newPassword]：新密码
  /// 
  /// 调用者：
  /// - AuthProvider.updatePassword()
  /// - SettingsPage 通过 AuthProvider 调用
  /// 
  /// Fail Fast：
  /// - currentPassword 为空：抛出 ArgumentError
  /// - newPassword 为空或长度小于 6：抛出 ArgumentError
  /// - 当前密码错误：抛出具体的认证异常（由实现类定义）
  /// - 用户未登录：抛出 StateError
  Future<void> updatePassword(String currentPassword, String newPassword);
  
  /// 更换邮箱
  /// 
  /// 参数：
  /// - [newEmail]：新邮箱
  /// - [password]：当前密码（用于重新认证）
  /// 
  /// 调用者：
  /// - AuthProvider.updateEmail()
  /// - SettingsPage 通过 AuthProvider 调用
  /// 
  /// Fail Fast：
  /// - newEmail 为空或格式不正确：抛出 ArgumentError
  /// - password 为空：抛出 ArgumentError
  /// - 密码错误：抛出具体的认证异常（由实现类定义）
  /// - 邮箱已被使用：抛出具体的认证异常（由实现类定义）
  /// - 用户未登录：抛出 StateError
  Future<void> updateEmail(String newEmail, String password);
  
  /// 更换手机号
  /// 
  /// 参数：
  /// - [newPhoneNumber]：新手机号（包含国家代码，如 +86）
  /// - [password]：当前密码（用于验证身份）
  /// 
  /// 调用者：
  /// - AuthProvider.updatePhoneNumber()
  /// - SettingsPage 通过 AuthProvider 调用
  /// 
  /// Fail Fast：
  /// - newPhoneNumber 为空或格式不正确：抛出 ArgumentError
  /// - password 为空：抛出 ArgumentError
  /// - 密码错误：抛出具体的认证异常（由实现类定义）
  /// - 手机号已被使用：抛出具体的认证异常（由实现类定义）
  /// - 用户未登录：抛出 StateError
  Future<void> updatePhoneNumber(
    String newPhoneNumber,
    String password,
  );

  /// 注销账号
  ///
  /// 参数：
  /// - [password]：当前密码（用于身份验证）
  ///
  /// 调用者：
  /// - AuthProvider.deleteAccount()
  /// - AccountSettingsPage 通过 AuthProvider 调用
  ///
  /// Fail Fast：
  /// - password 为空：抛出 ArgumentError
  /// - 密码错误：抛出具体的认证异常（由实现类定义）
  /// - 用户未登录：抛出 StateError
  Future<void> deleteAccount(String password);
}

