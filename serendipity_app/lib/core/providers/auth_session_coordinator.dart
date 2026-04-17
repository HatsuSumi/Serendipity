import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';
import '../repositories/i_auth_repository.dart';
import '../services/push_token_sync_service.dart';
import 'achievement_provider.dart';
import 'auth_dependencies_provider.dart';
import 'auth_events_provider.dart';
import 'check_in_provider.dart';
import 'community_provider.dart';
import 'records_provider.dart';
import 'story_lines_provider.dart';

class AuthSessionCoordinator {
  AuthSessionCoordinator({
    required this.ref,
    required this.repository,
    required this.setState,
  });

  final Ref ref;
  final IAuthRepository repository;
  final void Function(AsyncValue<User?> state) setState;

  void triggerSync(User user, {bool isRegister = false}) {
    Future.microtask(() {
      ref.read(authCompletedProvider.notifier).emit(
            AuthCompletedEvent(
              user: user,
              isRegister: isRegister,
            ),
          );
    });
  }

  void invalidateDataProviders() {
    ref.invalidate(recordsProvider);
    ref.invalidate(storyLinesProvider);
    ref.invalidate(checkInProvider);
    ref.invalidate(achievementsProvider);
    ref.invalidate(communityProvider);
    ref.invalidate(myPostsProvider);
  }

  Future<void> bindOfflineDataIfNeeded(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    final storageService = ref.read(storageServiceProvider);
    await storageService.bindOfflineDataToUser(userId);
  }

  Future<void> completeAuthSuccess(
    User user, {
    required bool isRegister,
  }) async {
    await bindOfflineDataIfNeeded(user.id);
    invalidateDataProviders();
    triggerSync(user, isRegister: isRegister);
  }

  Future<void> signOut() async {
    ref.read(pushTokenSignOutInProgressProvider.notifier).state = true;

    try {
      final pushTokenRemoteService = ref.read(pushTokenRemoteServiceProvider);
      await pushTokenRemoteService.unregisterCurrentToken(null);
      await repository.signOut();

      final storageService = ref.read(storageServiceProvider);
      await storageService.clearAuthData();

      setState(const AsyncValue.data(null));
      invalidateDataProviders();
    } catch (error, stackTrace) {
      ref.read(pushTokenSignOutInProgressProvider.notifier).state = false;
      setState(AsyncValue.error(error, stackTrace));
      rethrow;
    }
  }

  Future<void> deleteAccount(String password) async {
    if (password.isEmpty) {
      throw ArgumentError('密码不能为空');
    }

    final currentUser = await repository.currentUser;
    ref.read(pushTokenSignOutInProgressProvider.notifier).state = true;

    try {
      final pushTokenRemoteService = ref.read(pushTokenRemoteServiceProvider);
      await pushTokenRemoteService.unregisterCurrentToken(null);
      await repository.deleteAccount(password);
    } catch (_) {
      ref.read(pushTokenSignOutInProgressProvider.notifier).state = false;
      rethrow;
    }

    if (currentUser != null) {
      final storageService = ref.read(storageServiceProvider);
      await storageService.deleteUserData(currentUser.id);
    }

    setState(const AsyncValue.data(null));
    invalidateDataProviders();
  }
}

