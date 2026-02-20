/// 应用配置
/// 
/// 集中管理应用的配置项，包括测试模式、API 端点等。
class AppConfig {
  /// 是否启用测试模式
  /// 
  /// - true：使用 TestAuthRepository，无需 Firebase 配置
  /// - false：使用 FirebaseAuthRepository，需要真实 Firebase 配置
  /// 
  /// 测试模式特性：
  /// - 固定验证码：123456
  /// - 固定密码：123456
  /// - 无需网络请求
  /// - 数据存储在内存中
  /// 
  /// ⚠️ 注意：生产环境必须设置为 false
  static const bool enableTestMode = true;
}

