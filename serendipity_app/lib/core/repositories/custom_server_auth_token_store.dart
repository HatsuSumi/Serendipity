import '../services/http_client_service.dart';

class CustomServerAuthTokenStore {
  final HttpClientService _httpClient;

  CustomServerAuthTokenStore({required HttpClientService httpClient})
    : _httpClient = httpClient;

  Future<void> saveFromResponse(Map<String, dynamic> data) async {
    final tokens = data['tokens'] as Map<String, dynamic>;
    await _httpClient.saveTokens(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
      expiresAt: DateTime.parse(tokens['expiresAt'] as String),
    );
  }
}

