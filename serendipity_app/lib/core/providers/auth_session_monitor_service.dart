import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

/// 会话监控服务
///
/// 职责：
/// - 在应用回到前台时主动校验当前会话
/// - 在应用位于前台且用户已登录时做低频定时验活
/// - 发现会话失效后统一触发本地退出
class AuthSessionMonitorService {
  AuthSessionMonitorService(this._ref);

  final Ref _ref;

  static const Duration _foregroundValidationInterval = Duration(minutes: 1);

  Timer? _foregroundValidationTimer;
  bool _isStarted = false;
  bool _isValidating = false;
  bool _isSessionInvalidHandled = false;

  void start() {
    if (_isStarted) {
      return;
    }
    _isStarted = true;
    _syncForegroundTimer();
  }

  void stop() {
    _foregroundValidationTimer?.cancel();
    _foregroundValidationTimer = null;
    _isStarted = false;
    _isValidating = false;
    _isSessionInvalidHandled = false;
  }

  Future<void> onAppResumed() async {
    await validateCurrentSession(force: true);
    _syncForegroundTimer();
  }

  Future<void> validateCurrentSession({bool force = false}) async {
    if (_isValidating) {
      return;
    }

    final currentUser = _ref.read(authProvider).valueOrNull;
    if (currentUser == null) {
      _syncForegroundTimer();
      return;
    }

    final repository = _ref.read(authRepositoryProvider);

    _isValidating = true;
    try {
      final validatedUser = await repository.validateSession();
      if (validatedUser == null) {
        await _handleSessionInvalid();
      } else {
        _isSessionInvalidHandled = false;
        _ref.read(authProvider.notifier).updateCurrentUser(validatedUser);
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('会话验活失败: $error');
        print(stackTrace);
      }
      if (force) {
        // 前台恢复校验遇到异常时不强退，避免瞬时网络抖动误伤。
      }
    } finally {
      _isValidating = false;
      _syncForegroundTimer();
    }
  }

  Future<void> _handleSessionInvalid() async {
    if (_isSessionInvalidHandled) {
      return;
    }
    _isSessionInvalidHandled = true;

    await _ref.read(authProvider.notifier).handleSessionInvalidation();
  }

  void _syncForegroundTimer() {
    _foregroundValidationTimer?.cancel();

    final user = _ref.read(authProvider).valueOrNull;
    if (!_isStarted || user == null) {
      _foregroundValidationTimer = null;
      return;
    }

    _foregroundValidationTimer = Timer.periodic(
      _foregroundValidationInterval,
      (_) {
        unawaited(validateCurrentSession());
      },
    );
  }
}

final authSessionMonitorServiceProvider = Provider<AuthSessionMonitorService>((ref) {
  final service = AuthSessionMonitorService(ref);
  ref.onDispose(service.stop);
  return service;
});
