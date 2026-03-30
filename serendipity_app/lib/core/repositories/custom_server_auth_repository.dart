import '../../models/user.dart';
import '../../models/register_result.dart';
import '../../models/enums.dart';
import 'i_auth_repository.dart';
import '../services/http_client_service.dart';
import '../config/server_config.dart';

/// 自建服务器认证仓库实现
/// 
/// 使用自建 Node.js 后端，支持邮箱、手机号等多种认证方式。
class CustomServerAuthRepository implements IAuthRepository {
  final HttpClientService _httpClient;
  User? _currentUser;
  
  CustomServerAuthRepository({required HttpClientService httpClient})
      : _httpClient = httpClient;
  
  @override
  Future<User?> get currentUser async {
    // 如果已有缓存的用户，直接返回
    if (_currentUser != null) {
      return _currentUser;
    }
    
    // 检查是否有 Token
    final token = await _httpClient.getAccessToken();
    if (token == null) {
      return null;
    }
    
    // 从服务器获取用户信息
    try {
      final response = await _httpClient.get(ServerConfig.authMe);
      final userData = response['data'] as Map<String, dynamic>;
      _currentUser = _convertToAppUser(userData);
      return _currentUser;
    } catch (e) {
      // Token 无效，清除缓存
      _currentUser = null;
      await _httpClient.clearTokens();
      return null;
    }
  }
  
  @override
  Stream<User?> get authStateChanges async* {
    // 立即发出当前用户状态（不等待轮询周期）
    yield await currentUser;
    
    // 每 300 秒轮询一次，验证 Token 有效性
    // Token 的实时有效性由 HttpClientService 的自动刷新机制保证，
    // 无需高频轮询。高频轮询（如 5 秒）会导致所有 watch(authProvider)
    // 的 Widget 每轮询一次就 rebuild 一次，影响性能。
    yield* Stream.periodic(
      const Duration(seconds: 300),
      (_) => currentUser,
    ).asyncMap((future) => future);
  }
  
  /// 从响应中保存 Token
  /// 
  /// 遵循 DRY 原则：提取公共逻辑，避免重复代码
  Future<void> _saveTokensFromResponse(Map<String, dynamic> data) async {
    final tokens = data['tokens'] as Map<String, dynamic>;
    await _httpClient.saveTokens(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
      expiresAt: DateTime.parse(tokens['expiresAt'] as String),
    );
  }
  
  @override
  Future<User> signInWithEmail(String email, String password) async {
    // Fail Fast：参数验证
    if (email.isEmpty) {
      throw ArgumentError('邮箱不能为空');
    }
    if (password.isEmpty || password.length < 6) {
      throw ArgumentError('密码长度必须至少 6 位');
    }
    
    try {
      final response = await _httpClient.post(
        ServerConfig.authLogin,
        body: {
          'email': email,
          'password': password,
        },
        skipAuth: true,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      
      // 保存 Token
      await _saveTokensFromResponse(data);
      
      // 保存用户信息
      _currentUser = _convertToAppUser(data['user'] as Map<String, dynamic>);
      return _currentUser!;
    } on HttpException catch (e) {
      throw Exception(e.message);
    }
  }
  
  @override
  Future<RegisterResult> signUpWithEmail(String email, String password) async {
    // Fail Fast：参数验证
    if (email.isEmpty) {
      throw ArgumentError('邮箱不能为空');
    }
    if (password.isEmpty || password.length < 6) {
      throw ArgumentError('密码长度必须至少 6 位');
    }
    
    try {
      final response = await _httpClient.post(
        ServerConfig.authRegister,
        body: {
          'email': email,
          'password': password,
        },
        skipAuth: true,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      
      // 保存 Token
      await _saveTokensFromResponse(data);
      
      // 保存用户信息
      _currentUser = _convertToAppUser(data['user'] as Map<String, dynamic>);
      
      // 提取恢复密钥（仅在注册时返回）
      final recoveryKey = data['recoveryKey'] as String?;
      
      return RegisterResult(
        user: _currentUser!,
        recoveryKey: recoveryKey,
      );
    } on HttpException catch (e) {
      throw Exception(e.message);
    }
  }
  
  @override
  Future<User> signInWithPhonePassword(String phoneNumber, String password) async {
    // Fail Fast：参数验证
    if (phoneNumber.isEmpty) {
      throw ArgumentError('手机号不能为空');
    }
    if (password.isEmpty || password.length < 6) {
      throw ArgumentError('密码长度必须至少 6 位');
    }
    
    try {
      final response = await _httpClient.post(
        ServerConfig.authLoginPhone,
        body: {
          'phoneNumber': phoneNumber,
          'password': password,
        },
        skipAuth: true,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      
      // 保存 Token
      await _saveTokensFromResponse(data);
      
      // 保存用户信息
      _currentUser = _convertToAppUser(data['user'] as Map<String, dynamic>);
      return _currentUser!;
    } on HttpException catch (e) {
      throw Exception('登录失败：${e.message}');
    }
  }
  
  @override
  Future<User> signInWithPhone(
    String phoneNumber,
    String verificationCode,
    String verificationId,
  ) async {
    // Fail Fast：参数验证
    if (phoneNumber.isEmpty) {
      throw ArgumentError('手机号不能为空');
    }
    if (verificationCode.isEmpty) {
      throw ArgumentError('验证码不能为空');
    }
    
    try {
      final response = await _httpClient.post(
        ServerConfig.authLoginCode,
        body: {
          'phoneNumber': phoneNumber,
          'code': verificationCode,
        },
        skipAuth: true,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      
      // 保存 Token
      await _saveTokensFromResponse(data);
      
      // 保存用户信息
      _currentUser = _convertToAppUser(data['user'] as Map<String, dynamic>);
      return _currentUser!;
    } on HttpException catch (e) {
      throw Exception('登录失败：${e.message}');
    }
  }
  
  @override
  Future<String> sendPhoneVerificationCode(String phoneNumber) async {
    // Fail Fast：参数验证
    if (phoneNumber.isEmpty) {
      throw ArgumentError('手机号不能为空');
    }
    if (!phoneNumber.startsWith('+')) {
      throw ArgumentError('手机号格式错误：缺少国家代码');
    }
    
    try {
      await _httpClient.post(
        ServerConfig.authVerificationCode,
        body: {
          'phoneNumber': phoneNumber,
          'purpose': 'login',
        },
        skipAuth: true,
      );
      
      // 自建服务器不返回 verificationId，直接返回手机号作为标识
      return phoneNumber;
    } on HttpException catch (e) {
      throw Exception(e.message);
    }
  }
  
  @override
  Future<RegisterResult> signUpWithPhonePassword(String phoneNumber, String password) async {
    // Fail Fast：参数验证
    if (phoneNumber.isEmpty) {
      throw ArgumentError('手机号不能为空');
    }
    if (password.isEmpty || password.length < 6) {
      throw ArgumentError('密码长度必须至少 6 位');
    }
    
    try {
      final response = await _httpClient.post(
        ServerConfig.authRegisterPhone,
        body: {
          'phoneNumber': phoneNumber,
          'password': password,
        },
        skipAuth: true,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      
      // 保存 Token
      await _saveTokensFromResponse(data);
      
      // 保存用户信息
      _currentUser = _convertToAppUser(data['user'] as Map<String, dynamic>);
      
      // 提取恢复密钥（仅在注册时返回）
      final recoveryKey = data['recoveryKey'] as String?;
      
      return RegisterResult(
        user: _currentUser!,
        recoveryKey: recoveryKey,
      );
    } on HttpException catch (e) {
      throw Exception('注册失败：${e.message}');
    }
  }
  
  @override
  Future<RegisterResult> signUpWithPhone(
    String phoneNumber,
    String verificationCode,
    String verificationId,
  ) async {
    // 自建服务器的手机号注册和登录是同一个流程
    // 但注册时会返回恢复密钥
    final user = await signInWithPhone(phoneNumber, verificationCode, verificationId);
    
    // 注意：这里无法获取恢复密钥，因为 signInWithPhone 不返回恢复密钥
    // 如果需要支持手机号注册时返回恢复密钥，需要后端提供单独的注册接口
    return RegisterResult(
      user: user,
      recoveryKey: null, // 手机号注册暂不返回恢复密钥
    );
  }
  
  @override
  Future<void> signOut() async {
    _httpClient.beginSignOut();
    try {
      // 调用服务器登出接口
      await _httpClient.post(ServerConfig.authLogout);
    } catch (e) {
      // 即使服务器登出失败，也清除本地 Token
    } finally {
      _currentUser = null;
      await _httpClient.clearTokens();
      _httpClient.endSignOut();
    }
  }
  
  @override
  Future<void> resetPassword(String email, String recoveryKey, String newPassword) async {
    // Fail Fast：参数验证
    if (email.isEmpty) {
      throw ArgumentError('邮箱不能为空');
    }
    if (recoveryKey.isEmpty) {
      throw ArgumentError('恢复密钥不能为空');
    }
    if (newPassword.isEmpty || newPassword.length < 6) {
      throw ArgumentError('新密码长度必须至少 6 位');
    }
    
    try {
      await _httpClient.post(
        ServerConfig.authResetPassword,
        body: {
          'email': email,
          'recoveryKey': recoveryKey,
          'newPassword': newPassword,
        },
        skipAuth: true,
      );
    } on HttpException catch (e) {
      throw Exception(e.message);
    }
  }
  
  @override
  Future<String> generateRecoveryKey() async {
    if (_currentUser == null) {
      throw StateError('用户未登录');
    }
    
    try {
      final response = await _httpClient.post(
        ServerConfig.authGenerateRecoveryKey,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      return data['recoveryKey'] as String;
    } on HttpException catch (e) {
      throw Exception(e.message);
    }
  }
  
  @override
  Future<String?> getRecoveryKey() async {
    if (_currentUser == null) {
      throw StateError('用户未登录');
    }
    
    try {
      final response = await _httpClient.get(
        ServerConfig.authGetRecoveryKey,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      return data['recoveryKey'] as String?;
    } on HttpException catch (e) {
      throw Exception(e.message);
    }
  }
  
  @override
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    // Fail Fast：参数验证
    if (currentPassword.isEmpty) {
      throw ArgumentError('当前密码不能为空');
    }
    if (newPassword.isEmpty || newPassword.length < 6) {
      throw ArgumentError('新密码长度必须至少 6 位');
    }
    
    if (_currentUser == null) {
      throw StateError('用户未登录');
    }
    
    try {
      await _httpClient.put(
        ServerConfig.authChangePassword,
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on HttpException catch (e) {
      throw Exception(e.message);
    }
  }
  
  @override
  Future<void> updateEmail(String newEmail, String password) async {
    // Fail Fast：参数验证
    if (newEmail.isEmpty) {
      throw ArgumentError('新邮箱不能为空');
    }
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }
    
    if (_currentUser == null) {
      throw StateError('用户未登录');
    }
    
    try {
      final response = await _httpClient.put(
        ServerConfig.authChangeEmail,
        body: {
          'newEmail': newEmail,
          'password': password,
        },
      );
      
      // 更新本地用户信息（只更新变化的字段）
      final data = response['data'] as Map<String, dynamic>;
      _currentUser = _currentUser!.copyWith(
        email: () => data['email'] as String,
        updatedAt: () => DateTime.parse(data['updatedAt'] as String),
      );
    } on HttpException catch (e) {
      throw Exception(e.message);
    }
  }
  
  @override
  Future<void> updatePhoneNumber(
    String newPhoneNumber,
    String password,
  ) async {
    // Fail Fast：参数验证
    if (newPhoneNumber.isEmpty) {
      throw ArgumentError('新手机号不能为空');
    }
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }
    
    if (_currentUser == null) {
      throw StateError('用户未登录');
    }
    
    try {
      final response = await _httpClient.put(
        ServerConfig.authChangePhone,
        body: {
          'newPhoneNumber': newPhoneNumber,
          'password': password,
        },
      );
      
      // 更新本地用户信息（只更新变化的字段）
      final data = response['data'] as Map<String, dynamic>;
      _currentUser = _currentUser!.copyWith(
        phoneNumber: () => data['phoneNumber'] as String,
        updatedAt: () => DateTime.parse(data['updatedAt'] as String),
      );
    } on HttpException catch (e) {
      throw Exception(e.message);
    }
  }
  
  @override
  Future<void> deleteAccount(String password) async {
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }
    if (_currentUser == null) {
      throw StateError('用户未登录');
    }

    _httpClient.beginSignOut();   
    try {
      await _httpClient.delete(
        ServerConfig.authDeleteAccount,
        body: {'password': password},
      );
      _currentUser = null;
      await _httpClient.clearTokens();
    } on HttpException catch (e) {
      throw Exception(e.message);
      } finally {
      _httpClient.endSignOut();
    }
  } 

  @override
  void invalidateUserCache() {
    _currentUser = null;
  }

  /// 将服务器返回的用户数据转换为应用的 User 模型
  /// 
  /// Fail Fast：必需字段缺失时抛出异常
  User _convertToAppUser(Map<String, dynamic> data) {
    // Fail Fast：必需字段验证
    final id = data['id'] as String?;
    final createdAtStr = data['createdAt'] as String?;
    
    if (id == null || id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (createdAtStr == null || createdAtStr.isEmpty) {
      throw ArgumentError('创建时间不能为空');
    }
    
    return User(
      id: id,
      email: data['email'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      displayName: data['displayName'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      authProvider: _parseAuthProvider(data['authProvider'] as String?),
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: data['isPhoneVerified'] as bool? ?? false,
      createdAt: DateTime.parse(createdAtStr),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.parse(data['updatedAt'] as String)
          : null,  // User 构造函数会自动使用 createdAt 作为降级
    );
  }
  
  /// 解析认证提供商
  AuthProvider _parseAuthProvider(String? provider) {
    if (provider == null) return AuthProvider.email;
    
    switch (provider.toLowerCase()) {
      case 'email':
        return AuthProvider.email;
      case 'phone':
        return AuthProvider.phone;
      default:
        return AuthProvider.email;
    }
  }
}

