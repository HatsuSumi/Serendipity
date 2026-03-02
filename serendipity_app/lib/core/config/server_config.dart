/// 自建服务器配置
/// 
/// 管理自建服务器的 API 端点和配置项。
class ServerConfig {
  /// 服务器基础 URL
  /// 
  /// 开发环境：
  /// - 本地开发：http://localhost:3000
  /// - 手机测试：http://192.168.x.x:3000（电脑局域网 IP）
  /// 
  /// 生产环境：
  /// - https://api.serendipity.com
  static const String baseUrl = String.fromEnvironment(
    'SERVER_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
  
  /// API 版本
  static const String apiVersion = 'v1';
  
  /// API 基础路径
  static String get apiBasePath => '/api/$apiVersion';
  
  /// 完整的 API URL
  static String get apiUrl => '$baseUrl$apiBasePath';
  
  /// 请求超时时间（秒）
  static const int requestTimeout = 30;
  
  /// 连接超时时间（秒）
  static const int connectTimeout = 10;
  
  /// Token 刷新提前时间（分钟）
  /// 在 Token 过期前 5 分钟自动刷新
  static const int tokenRefreshAdvance = 5;
  
  // ==================== API 端点 ====================
  
  // 认证相关
  static const String authRegister = '/auth/register/email';
  static const String authLogin = '/auth/login/email';
  static const String authLoginCode = '/auth/login/phone';
  static const String authVerificationCode = '/auth/send-verification-code';
  static const String authResetPassword = '/auth/reset-password';
  static const String authChangePassword = '/auth/password';
  static const String authRefreshToken = '/auth/refresh-token';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';
  static const String authChangeEmail = '/auth/email';
  static const String authChangePhone = '/auth/phone';
  static const String authGenerateRecoveryKey = '/auth/recovery-key';
  
  // 用户相关
  static const String usersMe = '/users/me';
  static const String usersSettings = '/users/settings';
  
  // 记录相关
  static const String records = '/records';
  static const String recordsBatch = '/records/batch';
  static String recordById(String id) => '/records/$id';
  
  // 故事线相关
  static const String storylines = '/storylines';
  static const String storylinesBatch = '/storylines/batch';
  static String storylineById(String id) => '/storylines/$id';
  
  // 社区相关
  static const String communityPosts = '/community/posts';
  static const String communityMyPosts = '/community/my-posts';
  static const String communityPostsFilter = '/community/posts/filter';
  static String communityPostById(String id) => '/community/posts/$id';
  
  // 支付相关
  static const String paymentCreate = '/payment/create';
  static const String paymentStatus = '/payment/status';
  static const String membershipStatus = '/membership/status';
  
  /// 构建完整的 API URL
  static String buildUrl(String endpoint) {
    return '$apiUrl$endpoint';
  }
}

