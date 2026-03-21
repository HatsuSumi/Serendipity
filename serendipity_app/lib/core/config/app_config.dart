/// 后端服务器类型
enum ServerType {
  /// 测试模式（内存数据，无需网络）
  test,
  
  /// 自建服务器后端
  customServer,
}

/// 应用配置
/// 
/// 集中管理应用的配置项，包括后端服务器类型、API 端点等。
class AppConfig {
  /// 当前使用的后端服务器类型
  /// 
  /// - ServerType.test：测试模式，使用 TestAuthRepository 和 TestRemoteDataRepository
  ///   - 固定验证码：123456
  ///   - 固定密码：123456
  ///   - 无需网络请求
  ///   - 数据存储在内存中
  /// 
  /// - ServerType.customServer：自建服务器后端，使用 CustomServerAuthRepository 和 CustomServerRemoteDataRepository
  ///   - 需要配置服务器地址（见 ServerConfig）
  ///   - 使用 JWT Token 认证
  ///   - 支持邮箱、手机号登录
  /// 
  /// ⚠️ 注意：生产环境使用 ServerType.customServer
  static const ServerType serverType = ServerType.customServer;

  /// 开发者模式
  /// 
  /// - true：跳过会员检查，所有会员功能对开发者开放
  /// - false：正常会员权限验证
  /// 
  /// ⚠️ 注意：上线前必须设为 false
  static const bool isDeveloperMode = true;
}

