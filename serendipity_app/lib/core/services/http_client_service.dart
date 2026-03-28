import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/server_config.dart';
import '../services/i_storage_service.dart';

/// HTTP 客户端服务
/// 
/// 封装所有 HTTP 请求，统一处理：
/// - JWT Token 管理（自动添加到请求头）
/// - Token 自动刷新（过期前自动刷新，防止竞态条件）
/// - 错误处理（统一异常格式）
/// - 请求/响应日志
/// 
/// 遵循单一职责原则（SRP）：只负责 HTTP 通信
class HttpClientService {
  final IStorageService _storage;
  final http.Client _client;
  
  // Token 存储键
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  
  // Token 刷新锁（防止并发刷新）
  // 注意：使用 Completer 引用计数，避免竞态条件
  Completer<void>? _refreshTokenCompleter;
  int _refreshWaiters = 0;
  
  /// 强制登出回调
  /// 
  /// 调用时机：Token 过期且刷新失败时（即被其他设备踢下线）
  /// 调用者：AuthNotifier.build() 注入，通过 messageProvider 向用户提示
  void Function()? onForceLogout;
  
  HttpClientService({
    required IStorageService storage,
    http.Client? client,
  })  : _storage = storage,
        _client = client ?? http.Client();
  
  // ==================== Token 管理 ====================
  
  /// 保存 Token
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    await _storage.saveString(_accessTokenKey, accessToken);
    await _storage.saveString(_refreshTokenKey, refreshToken);
    await _storage.saveString(_tokenExpiryKey, expiresAt.toIso8601String());
  }
  
  /// 获取 Access Token
  Future<String?> getAccessToken() async {
    return await _storage.getString(_accessTokenKey);
  }
  
  /// 获取 Refresh Token
  Future<String?> getRefreshToken() async {
    return await _storage.getString(_refreshTokenKey);
  }
  
  /// 清除 Token
  Future<void> clearTokens() async {
    await _storage.remove(_accessTokenKey);
    await _storage.remove(_refreshTokenKey);
    await _storage.remove(_tokenExpiryKey);
  }
  
  /// 检查 Token 是否即将过期
  Future<bool> isTokenExpiringSoon() async {
    final expiryStr = await _storage.getString(_tokenExpiryKey);
    if (expiryStr == null) return true;
    
    final expiresAt = DateTime.parse(expiryStr);
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    
    // 如果剩余时间少于配置的提前刷新时间，则需要刷新
    return difference.inMinutes < ServerConfig.tokenRefreshAdvance;
  }
  
  /// 刷新 Token
  Future<void> refreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      throw Exception('未找到 Refresh Token');
    }
    
    final response = await post(
      ServerConfig.authRefreshToken,
      body: {'refreshToken': refreshToken},
      skipAuth: true, // 刷新 Token 时不需要 Access Token
    );
    
    final data = response['data'] as Map<String, dynamic>;
    await saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    );
  }
  
  // ==================== HTTP 请求方法 ====================
  
  /// GET 请求
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool skipAuth = false,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    return _executeWithRetry(
      skipAuth: skipAuth,
      request: (headers) => _client
          .get(uri, headers: headers)
          .timeout(Duration(seconds: ServerConfig.requestTimeout)),
    );
  }
  
  /// POST 请求
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool skipAuth = false,
  }) async {
    final uri = _buildUri(endpoint);
    return _executeWithRetry(
      skipAuth: skipAuth,
      request: (headers) => _client
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: ServerConfig.requestTimeout)),
    );
  }
  
  /// PUT 请求
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool skipAuth = false,
  }) async {
    final uri = _buildUri(endpoint);
    return _executeWithRetry(
      skipAuth: skipAuth,
      request: (headers) => _client
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: ServerConfig.requestTimeout)),
    );
  }
  
  /// DELETE 请求
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    bool skipAuth = false,
  }) async {
    final uri = _buildUri(endpoint);
    return _executeWithRetry(
      skipAuth: skipAuth,
      request: (headers) => _client
          .delete(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: ServerConfig.requestTimeout)),
    );
  }
  
  /// 刷新 Token，失败则清除并抛出登录过期异常
  /// 
  /// 触发时机：401 响应且 refresh token 也已失效（如被其他设备踢下线）
  /// 触发 onForceLogout 回调，通知上层（AuthNotifier）向用户展示提示
  Future<void> _refreshAndClearOnFailure() async {
    try {
      await refreshToken();
    } catch (e) {
      await clearTokens();
      onForceLogout?.call();
      throw Exception('Token 已过期，请重新登录');
    }
  }
  
  /// 执行 HTTP 请求，401 时自动刷新 token 并重试一次
  /// 
  /// 参数：
  /// - skipAuth: 是否跳过认证
  /// - request: 请求函数，接收 headers 参数
  /// 
  /// 返回：响应数据
  Future<Map<String, dynamic>> _executeWithRetry({
    required bool skipAuth,
    required Future<http.Response> Function(Map<String, String>) request,
  }) async {
    final headers = await _buildHeaders(skipAuth: skipAuth);
    final response = await request(headers);
    
    // 401 时自动刷新 token 并重试一次
    if (response.statusCode == 401 && !skipAuth) {
      await _refreshAndClearOnFailure();
      final retryHeaders = await _buildHeaders(skipAuth: false);
      final retryResponse = await request(retryHeaders);
      return _handleResponse(retryResponse);
    }
    
    return _handleResponse(response);
  }
  
  // ==================== 私有辅助方法 ====================
  
  /// 构建 URI
  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final url = ServerConfig.buildUrl(endpoint);
    final uri = Uri.parse(url);
    
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    
    return uri;
  }
  
  /// 构建请求头（带 Token 刷新锁，防止并发刷新）
  /// 
  /// 设计原则：
  /// - 使用 Completer 实现单一 Token 刷新
  /// - 多个并发请求共享同一个刷新操作
  /// - 刷新失败时清除 Token，但不影响其他请求
  /// - 使用引用计数避免竞态条件：只有最后一个等待者才能置空 Completer
  Future<Map<String, String>> _buildHeaders({bool skipAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // 如果不跳过认证，尝试添加 Authorization 头
    if (!skipAuth) {
      // 检查 Token 是否即将过期
      if (await isTokenExpiringSoon()) {
        // 如果已有刷新在进行中，等待其完成
        if (_refreshTokenCompleter != null) {
          _refreshWaiters++;
          try {
            await _refreshTokenCompleter!.future;
          } catch (e) {
            // 刷新失败，但不影响当前请求（可能是匿名请求）
          } finally {
            _refreshWaiters--;
            // 只有最后一个等待者才能置空 Completer
            if (_refreshWaiters == 0) {
              _refreshTokenCompleter = null;
            }
          }
        } else {
          // 创建新的刷新操作
          _refreshTokenCompleter = Completer<void>();
          _refreshWaiters = 0;  // 初始化为 0，创建者不计入等待者
          try {
            await refreshToken();
            _refreshTokenCompleter!.complete();
          } catch (e) {
            // Token 刷新失败，清除 Token
            await clearTokens();
            _refreshTokenCompleter!.completeError(e);
          } finally {
            // 重置计数器和 Completer
            _refreshWaiters = 0;
            _refreshTokenCompleter = null;
          }
        }
      }
      
      final accessToken = await getAccessToken();
      if (accessToken != null) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
      // 没有 token 时不添加 Authorization 头，允许匿名访问公开接口
    }
    
    return headers;
  }
  
  /// 处理响应
  Map<String, dynamic> _handleResponse(http.Response response) {
    // 解析响应体
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('服务器响应格式错误');
    }
    
    // 检查 HTTP 状态码
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // 成功响应
      if (body['success'] == true) {
        return body;
      } else {
        throw Exception(body['message'] ?? '请求失败');
      }
    } else {
      // 错误响应
      // 后端返回格式：{ "success": false, "error": { "code": "...", "message": "..." } }
      final error = body['error'];
      
      String message = '请求失败';
      String errorCode = 'UNKNOWN_ERROR';
      
      if (error is Map<String, dynamic>) {
        message = error['message']?.toString() ?? message;
        errorCode = error['code']?.toString() ?? errorCode;
      }
      
      throw HttpException(
        message: message,
        statusCode: response.statusCode,
        errorCode: errorCode,
      );
    }
  }
  
  /// 释放资源
  void dispose() {
    _client.close();
  }
}

/// HTTP 异常
class HttpException implements Exception {
  final String message;
  final int statusCode;
  final String errorCode;
  
  HttpException({
    required this.message,
    required this.statusCode,
    required this.errorCode,
  });
  
  @override
  String toString() {
    return 'HttpException: $message (statusCode: $statusCode, errorCode: $errorCode)';
  }
}
