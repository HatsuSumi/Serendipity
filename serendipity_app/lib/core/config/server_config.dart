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
  
  /// 网络状态轮询间隔（秒）
  /// 作为 connectivity_plus 监听的备份方案
  static const int networkPollingInterval = 60;
  
  /// 服务器健康检查超时时间（秒）
  static const int healthCheckTimeout = 5;
  
  // ==================== API 端点 ====================
  
  // 认证相关
  static const String authRegister = '/auth/register/email';
  static const String authLogin = '/auth/login/email';
  static const String authRegisterPhone = '/auth/register/phone';
  static const String authLoginPhone = '/auth/login/phone-password';
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
  static const String authGetRecoveryKey = '/auth/recovery-key';
  static const String authDeleteAccount = '/auth/account';
  
  // 用户相关
  static const String usersMe = '/users/me';
  static const String usersAvatar = '/users/avatar';
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
  static String communityPostById(String id) => '/community/posts/$id';
  static String communityPostByRecordId(String recordId) => '/community/posts/by-record/$recordId';
  
  // 签到相关
  static const String checkIns = '/check-ins';
  static const String checkInStatus = '/check-ins/status';
  static String checkInById(String id) => '/check-ins/$id';

  // 推送相关
  static const String pushTokens = '/push-tokens';
  
  // 统计相关
  static const String statisticsOverview = '/statistics/overview';
  static const String achievementUnlocks = '/achievement-unlocks';
  
  // 收藏相关
  static const String favoritePosts = '/favorites/posts';
  static const String favoriteRecords = '/favorites/records';
  static String favoritePostById(String postId) => '/favorites/posts/$postId';
  static String favoriteRecordById(String recordId) => '/favorites/records/$recordId';
  
  /// 构建完整的 API URL
  static String buildUrl(String endpoint) {
    return '$apiUrl$endpoint';
  }
}

