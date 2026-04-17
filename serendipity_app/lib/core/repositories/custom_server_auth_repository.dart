import '../../models/user.dart';
import '../../models/register_result.dart';
import 'i_auth_repository.dart';
import '../services/device_identity_service.dart';
import '../services/http_client_service.dart';
import '../utils/validation_helper.dart';
import 'custom_server_auth_remote_data_source.dart';
import 'custom_server_auth_session.dart';
import 'custom_server_auth_token_store.dart';
import 'custom_server_auth_user_mapper.dart';

/// 自建服务器认证仓库实现
/// 
/// 使用自建 Node.js 后端，支持邮箱、手机号等多种认证方式。
class CustomServerAuthRepository implements IAuthRepository {
  final HttpClientService _httpClient;
  final CustomServerAuthRemoteDataSource _remoteDataSource;
  late final CustomServerAuthSession _session;
  final CustomServerAuthTokenStore _tokenStore;
  final CustomServerAuthUserMapper _userMapper;
  
  CustomServerAuthRepository({
    required HttpClientService httpClient,
    required DeviceIdentityService deviceIdentityService,
  })  : _httpClient = httpClient,
        _remoteDataSource = CustomServerAuthRemoteDataSource(
          httpClient: httpClient,
          deviceIdentityService: deviceIdentityService,
        ),
        _userMapper = const CustomServerAuthUserMapper(),
        _tokenStore = CustomServerAuthTokenStore(httpClient: httpClient) {
    _session = CustomServerAuthSession(
      httpClient: _httpClient,
      remoteDataSource: _remoteDataSource,
      userMapper: _userMapper,
    );
  }
  
  @override
  Future<User?> get currentUser async {
    return _session.getCurrentUser();
  }
  
  @override
  Stream<User?> get authStateChanges {
    return _session.authStateChanges;
  }
  
  Never _rethrowHttpException(HttpException error, {String? prefix}) {
    if (prefix == null || prefix.isEmpty) {
      throw Exception(error.message);
    }
    throw Exception('$prefix${error.message}');
  }
  
  @override
  Future<User> signInWithEmail(String email, String password) async {
    ValidationHelper.validateEmailForRepository(email);
    ValidationHelper.validatePasswordForRepository(password);
    
    try {
      final response = await _remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      
      await _tokenStore.saveFromResponse(data);
      
      final user = _userMapper.fromResponse(data['user'] as Map<String, dynamic>);
      _session.setCurrentUser(user);
      return user;
    } on HttpException catch (e) {
      _rethrowHttpException(e);
    }
  }
  
  @override
  Future<RegisterResult> signUpWithEmail(String email, String password) async {
    ValidationHelper.validateEmailForRepository(email);
    ValidationHelper.validatePasswordForRepository(password);
    
    try {
      final response = await _remoteDataSource.signUpWithEmail(
        email: email,
        password: password,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      
      await _tokenStore.saveFromResponse(data);
      
      final user = _userMapper.fromResponse(data['user'] as Map<String, dynamic>);
      _session.setCurrentUser(user);
      
      // 提取恢复密钥（仅在注册时返回）
      final recoveryKey = data['recoveryKey'] as String?;
      
      return RegisterResult(
        user: user,
        recoveryKey: recoveryKey,
      );
    } on HttpException catch (e) {
      _rethrowHttpException(e);
    }
  }
  
  @override
  Future<User> signInWithPhonePassword(String phoneNumber, String password) async {
    ValidationHelper.validatePhoneNumberForRepository(phoneNumber);
    ValidationHelper.validatePasswordForRepository(password);
    
    try {
      final response = await _remoteDataSource.signInWithPhonePassword(
        phoneNumber: phoneNumber,
        password: password,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      
      await _tokenStore.saveFromResponse(data);
      
      final user = _userMapper.fromResponse(data['user'] as Map<String, dynamic>);
      _session.setCurrentUser(user);
      return user;
    } on HttpException catch (e) {
      _rethrowHttpException(e, prefix: '登录失败：');
    }
  }
  
  @override
  Future<User> signInWithPhone(
    String phoneNumber,
    String verificationCode,
    String verificationId,
  ) async {
    ValidationHelper.validatePhoneNumberForRepository(phoneNumber);
    ValidationHelper.validateVerificationCodeForRepository(verificationCode);
    
    try {
      final response = await _remoteDataSource.signInWithPhoneCode(
        phoneNumber: phoneNumber,
        verificationCode: verificationCode,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      
      await _tokenStore.saveFromResponse(data);
      
      final user = _userMapper.fromResponse(data['user'] as Map<String, dynamic>);
      _session.setCurrentUser(user);
      return user;
    } on HttpException catch (e) {
      _rethrowHttpException(e, prefix: '登录失败：');
    }
  }
  
  @override
  Future<String> sendPhoneVerificationCode(String phoneNumber) async {
    ValidationHelper.validatePhoneNumberForRepository(phoneNumber);
    
    try {
      await _remoteDataSource.sendPhoneVerificationCode(phoneNumber: phoneNumber);
      
      // 自建服务器不返回 verificationId，直接返回手机号作为标识
      return phoneNumber;
    } on HttpException catch (e) {
      _rethrowHttpException(e);
    }
  }
  
  @override
  Future<RegisterResult> signUpWithPhonePassword(String phoneNumber, String password) async {
    ValidationHelper.validatePhoneNumberForRepository(phoneNumber);
    ValidationHelper.validatePasswordForRepository(password);
    
    try {
      final response = await _remoteDataSource.signUpWithPhonePassword(
        phoneNumber: phoneNumber,
        password: password,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      
      await _tokenStore.saveFromResponse(data);
      
      final user = _userMapper.fromResponse(data['user'] as Map<String, dynamic>);
      _session.setCurrentUser(user);
      
      // 提取恢复密钥（仅在注册时返回）
      final recoveryKey = data['recoveryKey'] as String?;
      
      return RegisterResult(
        user: user,
        recoveryKey: recoveryKey,
      );
    } on HttpException catch (e) {
      _rethrowHttpException(e, prefix: '注册失败：');
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
      await _remoteDataSource.signOut();
    } catch (e) {
      // 即使服务器登出失败，也清除本地 Token
    } finally {
      await _session.clearSession();
      _httpClient.endSignOut();
    }
  }
  
  @override
  Future<void> resetPassword(String email, String recoveryKey, String newPassword) async {
    // Fail Fast：参数验证
    ValidationHelper.validateEmailForRepository(email);
    if (recoveryKey.isEmpty) {
      throw ArgumentError('恢复密钥不能为空');
    }
    ValidationHelper.validatePasswordForRepository(newPassword);
    
    try {
      await _remoteDataSource.resetPassword(
        email: email,
        recoveryKey: recoveryKey,
        newPassword: newPassword,
      );
    } on HttpException catch (e) {
      _rethrowHttpException(e);
    }
  }
  
  @override
  Future<String> generateRecoveryKey() async {
    if (!_session.hasAuthenticatedUser) {
      throw StateError('用户未登录');
    }
    
    try {
      final response = await _remoteDataSource.generateRecoveryKey();
      
      final data = response['data'] as Map<String, dynamic>;
      return data['recoveryKey'] as String;
    } on HttpException catch (e) {
      _rethrowHttpException(e);
    }
  }
  
  @override
  Future<String?> getRecoveryKey() async {
    if (!_session.hasAuthenticatedUser) {
      throw StateError('用户未登录');
    }
    
    try {
      final response = await _remoteDataSource.getRecoveryKey();
      
      final data = response['data'] as Map<String, dynamic>;
      return data['recoveryKey'] as String?;
    } on HttpException catch (e) {
      _rethrowHttpException(e);
    }
  }
  
  @override
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    if (currentPassword.isEmpty) {
      throw ArgumentError('当前密码不能为空');
    }
    ValidationHelper.validatePasswordForRepository(newPassword);
    
    if (!_session.hasAuthenticatedUser) {
      throw StateError('用户未登录');
    }
    
    try {
      await _remoteDataSource.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on HttpException catch (e) {
      _rethrowHttpException(e);
    }
  }
  
  @override
  Future<void> updateEmail(String newEmail, String password) async {
    ValidationHelper.validateEmailForRepository(newEmail);
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }
    
    if (!_session.hasAuthenticatedUser) {
      throw StateError('用户未登录');
    }
    
    try {
      final response = await _remoteDataSource.updateEmail(
        newEmail: newEmail,
        password: password,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      final user = _userMapper.fromResponse(data);
      _session.setCurrentUser(user);
    } on HttpException catch (e) {
      _rethrowHttpException(e);
    }
  }
  
  @override
  Future<void> updatePhoneNumber(
    String newPhoneNumber,
    String password,
  ) async {
    ValidationHelper.validatePhoneNumberForRepository(newPhoneNumber);
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }
    
    if (!_session.hasAuthenticatedUser) {
      throw StateError('用户未登录');
    }
    
    try {
      final response = await _remoteDataSource.updatePhoneNumber(
        newPhoneNumber: newPhoneNumber,
        password: password,
      );
      
      final data = response['data'] as Map<String, dynamic>;
      final user = _userMapper.fromResponse(data);
      _session.setCurrentUser(user);
    } on HttpException catch (e) {
      _rethrowHttpException(e);
    }
  }
  
  @override
  Future<void> deleteAccount(String password) async {
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }
    if (!_session.hasAuthenticatedUser) {
      throw StateError('用户未登录');
    }

    _httpClient.beginSignOut();   
    try {
      await _remoteDataSource.deleteAccount(password: password);
      await _session.clearSession();
    } on HttpException catch (e) {
      _rethrowHttpException(e);
    } finally {
      _httpClient.endSignOut();
    }
  } 

  @override
  void invalidateUserCache() {
    _session.invalidateUserCache();
  }
}
