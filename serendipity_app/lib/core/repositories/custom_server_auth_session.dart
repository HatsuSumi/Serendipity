import '../../models/user.dart';
import '../services/http_client_service.dart';
import 'custom_server_auth_remote_data_source.dart';
import 'custom_server_auth_user_mapper.dart';

class CustomServerAuthSession {
  final HttpClientService _httpClient;
  final CustomServerAuthRemoteDataSource _remoteDataSource;
  final CustomServerAuthUserMapper _userMapper;

  User? _currentUser;

  CustomServerAuthSession({
    required HttpClientService httpClient,
    required CustomServerAuthRemoteDataSource remoteDataSource,
    required CustomServerAuthUserMapper userMapper,
  })  : _httpClient = httpClient,
        _remoteDataSource = remoteDataSource,
        _userMapper = userMapper;

  Future<User?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    final token = await _httpClient.getAccessToken();
    if (token == null) {
      return null;
    }

    try {
      final response = await _remoteDataSource.fetchCurrentUser();
      final userData = response['data'] as Map<String, dynamic>;
      _currentUser = _userMapper.fromResponse(userData);
      return _currentUser;
    } catch (_) {
      _currentUser = null;
      await _httpClient.clearTokens();
      return null;
    }
  }

  Stream<User?> get authStateChanges async* {
    yield await getCurrentUser();

    yield* Stream.periodic(
      const Duration(seconds: 300),
      (_) => getCurrentUser(),
    ).asyncMap((future) => future);
  }

  void setCurrentUser(User user) {
    _currentUser = user;
  }

  void invalidateUserCache() {
    _currentUser = null;
  }

  bool get hasAuthenticatedUser {
    return _currentUser != null;
  }

  Future<void> clearSession() async {
    _currentUser = null;
    await _httpClient.clearTokens();
  }
}

