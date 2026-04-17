import '../config/server_config.dart';
import '../services/device_identity_service.dart';
import '../services/http_client_service.dart';

class CustomServerAuthRemoteDataSource {
  final HttpClientService _httpClient;
  final DeviceIdentityService _deviceIdentityService;

  CustomServerAuthRemoteDataSource({
    required HttpClientService httpClient,
    required DeviceIdentityService deviceIdentityService,
  })  : _httpClient = httpClient,
        _deviceIdentityService = deviceIdentityService;

  Future<String> _getDeviceId() {
    return _deviceIdentityService.getOrCreateDeviceId();
  }

  Future<Map<String, dynamic>> fetchCurrentUser() {
    return _httpClient.get(ServerConfig.authMe);
  }

  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final deviceId = await _getDeviceId();
    return _httpClient.post(
      ServerConfig.authLogin,
      body: {
        'email': email,
        'password': password,
        'deviceId': deviceId,
      },
      skipAuth: true,
    );
  }

  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final deviceId = await _getDeviceId();
    return _httpClient.post(
      ServerConfig.authRegister,
      body: {
        'email': email,
        'password': password,
        'deviceId': deviceId,
      },
      skipAuth: true,
    );
  }

  Future<Map<String, dynamic>> signInWithPhonePassword({
    required String phoneNumber,
    required String password,
  }) async {
    final deviceId = await _getDeviceId();
    return _httpClient.post(
      ServerConfig.authLoginPhone,
      body: {
        'phoneNumber': phoneNumber,
        'password': password,
        'deviceId': deviceId,
      },
      skipAuth: true,
    );
  }

  Future<Map<String, dynamic>> signInWithPhoneCode({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    final deviceId = await _getDeviceId();
    return _httpClient.post(
      ServerConfig.authLoginCode,
      body: {
        'phoneNumber': phoneNumber,
        'code': verificationCode,
        'deviceId': deviceId,
      },
      skipAuth: true,
    );
  }

  Future<void> sendPhoneVerificationCode({required String phoneNumber}) async {
    await _httpClient.post(
      ServerConfig.authVerificationCode,
      body: {
        'phoneNumber': phoneNumber,
        'purpose': 'login',
      },
      skipAuth: true,
    );
  }

  Future<Map<String, dynamic>> signUpWithPhonePassword({
    required String phoneNumber,
    required String password,
  }) async {
    final deviceId = await _getDeviceId();
    return _httpClient.post(
      ServerConfig.authRegisterPhone,
      body: {
        'phoneNumber': phoneNumber,
        'password': password,
        'deviceId': deviceId,
      },
      skipAuth: true,
    );
  }

  Future<void> signOut() async {
    await _httpClient.post(ServerConfig.authLogout);
  }

  Future<void> resetPassword({
    required String email,
    required String recoveryKey,
    required String newPassword,
  }) async {
    await _httpClient.post(
      ServerConfig.authResetPassword,
      body: {
        'email': email,
        'recoveryKey': recoveryKey,
        'newPassword': newPassword,
      },
      skipAuth: true,
    );
  }

  Future<Map<String, dynamic>> generateRecoveryKey() {
    return _httpClient.post(ServerConfig.authGenerateRecoveryKey);
  }

  Future<Map<String, dynamic>> getRecoveryKey() {
    return _httpClient.get(ServerConfig.authGetRecoveryKey);
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _httpClient.put(
      ServerConfig.authChangePassword,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<Map<String, dynamic>> updateEmail({
    required String newEmail,
    required String password,
  }) {
    return _httpClient.put(
      ServerConfig.authChangeEmail,
      body: {
        'newEmail': newEmail,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> updatePhoneNumber({
    required String newPhoneNumber,
    required String password,
  }) {
    return _httpClient.put(
      ServerConfig.authChangePhone,
      body: {
        'newPhoneNumber': newPhoneNumber,
        'password': password,
      },
    );
  }

  Future<void> deleteAccount({required String password}) async {
    await _httpClient.delete(
      ServerConfig.authDeleteAccount,
      body: {'password': password},
    );
  }
}

