import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/core/providers/auth_provider.dart';
import 'package:serendipity_app/core/providers/records_provider.dart';
import 'package:serendipity_app/core/repositories/achievement_repository.dart';
import 'package:serendipity_app/core/repositories/i_remote_data_repository.dart';
import 'package:serendipity_app/core/services/i_storage_service.dart';
import 'package:serendipity_app/core/services/sync_orchestrator.dart';
import 'package:serendipity_app/core/services/sync_result.dart';
import 'package:serendipity_app/core/services/sync_service.dart';
import 'package:serendipity_app/models/enums.dart';
import 'package:serendipity_app/models/sync_history.dart';
import 'package:serendipity_app/models/user.dart';

void main() {
  group('SyncOrchestrator', () {
    late ProviderContainer container;
    late TestSyncService syncService;
    late WidgetRef ref;

    setUp(() async {
      syncService = TestSyncService();
      container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(TestStorageService()),
          syncServiceProvider.overrideWithValue(syncService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('应该返回真实同步结果并发送一次完成通知', (tester) async {
      syncService.completer = Completer<SyncResult>();
      final orchestrator = container.read(syncOrchestratorProvider);
      ref = await _pumpAndCaptureRef(tester, container);

      final future = orchestrator.sync(
        ref,
        createUser(),
        source: SyncSource.manual,
      );

      expect(orchestrator.isSyncing, isTrue);
      expect(syncService.callCount, 1);
      expect(container.read(syncCompletedProvider), 0);

      syncService.completer!.complete(testSyncResult);
      await tester.pump();

      final result = await future;
      expect(identical(result, testSyncResult), isTrue);
      expect(container.read(syncCompletedProvider), 1);
      expect(orchestrator.isSyncing, isFalse);
    });

    testWidgets('并发调用应该复用同一个进行中的同步结果', (tester) async {
      syncService.completer = Completer<SyncResult>();
      final orchestrator = container.read(syncOrchestratorProvider);
      ref = await _pumpAndCaptureRef(tester, container);

      final future1 = orchestrator.sync(
        ref,
        createUser(),
        source: SyncSource.manual,
      );
      final future2 = orchestrator.sync(
        ref,
        createUser(),
        source: SyncSource.manual,
      );

      expect(syncService.callCount, 1);
      expect(orchestrator.isSyncing, isTrue);

      syncService.completer!.complete(testSyncResult);
      await tester.pump();

      final result1 = await future1;
      final result2 = await future2;
      expect(identical(result1, testSyncResult), isTrue);
      expect(identical(result2, testSyncResult), isTrue);
      expect(container.read(syncCompletedProvider), 1);
      expect(orchestrator.isSyncing, isFalse);
    });

    testWidgets('并发调用在最终失败时应该共享同一个错误', (tester) async {
      syncService.throwError = StateError('sync failed');
      final orchestrator = container.read(syncOrchestratorProvider);
      ref = await _pumpAndCaptureRef(tester, container);

      final future1 = orchestrator.sync(
        ref,
        createUser(),
        source: SyncSource.manual,
      );
      final future2 = orchestrator.sync(
        ref,
        createUser(),
        source: SyncSource.manual,
      );

      expect(syncService.callCount, 1);

      final expectation1 = expectLater(
        future1,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'sync failed',
          ),
        ),
      );
      final expectation2 = expectLater(
        future2,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'sync failed',
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      await Future.wait([expectation1, expectation2]);

      expect(syncService.callCount, 3);
      expect(container.read(syncCompletedProvider), 0);
      expect(orchestrator.isSyncing, isFalse);
    });
  });
}

Future<WidgetRef> _pumpAndCaptureRef(
  WidgetTester tester,
  ProviderContainer container,
) async {
  late WidgetRef capturedRef;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Consumer(
          builder: (context, ref, child) {
            capturedRef = ref;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );

  await tester.pump();
  return capturedRef;
}

User createUser() {
  return User(
    id: 'user-1',
    email: 'user@example.com',
    authProvider: AuthProvider.email,
    isEmailVerified: true,
    isPhoneVerified: false,
    createdAt: DateTime(2026, 4, 12),
  );
}

const testSyncResult = SyncResult(
  uploadedRecords: 1,
  uploadedStoryLines: 2,
  uploadedCheckIns: 0,
  downloadedRecords: 3,
  downloadedStoryLines: 4,
  downloadedCheckIns: 0,
  mergedRecords: 1,
  mergedStoryLines: 0,
  mergedCheckIns: 0,
  syncedAchievements: 2,
);

class TestSyncService extends SyncService {
  TestSyncService()
      : super(
          remoteRepository: TestRemoteDataRepository(),
          storageService: TestStorageService(),
          achievementRepository: AchievementRepository(TestStorageService()),
        );

  int callCount = 0;
  Completer<SyncResult>? completer;
  Object? throwError;

  @override
  Future<SyncResult> syncAllData(
    User user, {
    DateTime? lastSyncTime,
    bool skipFullSyncCleanup = false,
    SyncSource source = SyncSource.manual,
    void Function(String)? onProgress,
  }) async {
    callCount += 1;

    if (throwError != null) {
      throw throwError!;
    }

    final activeCompleter = completer;
    if (activeCompleter != null) {
      return await activeCompleter.future;
    }

    return testSyncResult;
  }
}

class TestStorageService implements IStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestRemoteDataRepository implements IRemoteDataRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

