import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_app/models/sync_history.dart';
import 'package:serendipity_app/core/services/sync_service.dart';

void main() {
  group('SyncHistory Model Tests', () {
    test('should create success sync history', () {
      final syncStartTime = DateTime(2026, 3, 9, 14, 30, 0);
      final syncEndTime = DateTime(2026, 3, 9, 14, 30, 5);
      
      final result = SyncResult(
        uploadedRecords: 5,
        uploadedStoryLines: 2,
        uploadedCheckIns: 1,
        downloadedRecords: 3,
        downloadedStoryLines: 1,
        downloadedCheckIns: 0,
        mergedRecords: 1,
        mergedStoryLines: 0,
        mergedCheckIns: 0,
        syncedAchievements: 2,
      );
      
      final history = SyncHistory.fromSuccess(
        result: result,
        syncStartTime: syncStartTime,
        syncEndTime: syncEndTime,
        source: SyncSource.manual,
      );
      
      expect(history.success, true);
      expect(history.isManual, true);
      expect(history.source, SyncSource.manual);
      expect(history.uploadedRecords, 5);
      expect(history.downloadedRecords, 3);
      expect(history.mergedRecords, 1);
      expect(history.durationMs, 5000);
      expect(history.errorMessage, null);
      expect(history.hasChanges, true);
    });
    
    test('should create error sync history', () {
      final syncStartTime = DateTime(2026, 3, 9, 14, 30, 0);
      final syncEndTime = DateTime(2026, 3, 9, 14, 30, 2);
      
      final history = SyncHistory.fromError(
        errorMessage: 'Network error',
        syncStartTime: syncStartTime,
        syncEndTime: syncEndTime,
        source: SyncSource.polling,
      );
      
      expect(history.success, false);
      expect(history.isManual, false);
      expect(history.source, SyncSource.polling);
      expect(history.errorMessage, 'Network error');
      expect(history.uploadedRecords, 0);
      expect(history.downloadedRecords, 0);
      expect(history.durationMs, 2000);
      expect(history.hasChanges, false);
    });
    
    test('should throw error when error message is empty', () {
      final syncStartTime = DateTime(2026, 3, 9, 14, 30, 0);
      final syncEndTime = DateTime(2026, 3, 9, 14, 30, 2);
      
      expect(
        () => SyncHistory.fromError(
          errorMessage: '',
          syncStartTime: syncStartTime,
          syncEndTime: syncEndTime,
          source: SyncSource.manual,
        ),
        throwsArgumentError,
      );
    });
  });
  
  group('SyncSource Enum Tests', () {
    test('should have correct enum names', () {
      expect(SyncSource.manual.name, 'manual');
      expect(SyncSource.appStartup.name, 'appStartup');
      expect(SyncSource.login.name, 'login');
      expect(SyncSource.register.name, 'register');
      expect(SyncSource.networkReconnect.name, 'networkReconnect');
      expect(SyncSource.polling.name, 'polling');
    });
    
    test('should have correct source descriptions', () {
      final testCases = {
        SyncSource.manual: '手动同步',
        SyncSource.appStartup: 'App启动',
        SyncSource.login: '登录后',
        SyncSource.register: '注册后',
        SyncSource.networkReconnect: '网络恢复',
        SyncSource.polling: '60秒轮询',
      };
      
      for (final entry in testCases.entries) {
        final history = SyncHistory.fromSuccess(
          result: _createEmptyResult(),
          syncStartTime: DateTime.now(),
          syncEndTime: DateTime.now(),
          source: entry.key,
        );
        expect(history.sourceDescription, entry.value);
      }
    });
  });
  
  group('SyncResult Tests', () {
    test('should detect no changes', () {
      final result = _createEmptyResult();
      expect(result.hasChanges, false);
    });
    
    test('should detect changes', () {
      final result = SyncResult(
        uploadedRecords: 1,
        uploadedStoryLines: 0,
        uploadedCheckIns: 0,
        downloadedRecords: 0,
        downloadedStoryLines: 0,
        downloadedCheckIns: 0,
        mergedRecords: 0,
        mergedStoryLines: 0,
        mergedCheckIns: 0,
        syncedAchievements: 0,
      );
      
      expect(result.hasChanges, true);
    });
  });
  
  group('Sync Duration Tests', () {
    test('should format duration in milliseconds', () {
      final history = SyncHistory.fromSuccess(
        result: _createEmptyResult(),
        syncStartTime: DateTime(2026, 3, 9, 14, 30, 0, 0),
        syncEndTime: DateTime(2026, 3, 9, 14, 30, 0, 500),
        source: SyncSource.manual,
      );
      
      expect(history.formattedDuration, '500ms');
    });
    
    test('should format duration in seconds', () {
      final history = SyncHistory.fromSuccess(
        result: _createEmptyResult(),
        syncStartTime: DateTime(2026, 3, 9, 14, 30, 0),
        syncEndTime: DateTime(2026, 3, 9, 14, 30, 3, 500),
        source: SyncSource.manual,
      );
      
      expect(history.formattedDuration, '3.5s');
    });
  });
  
  group('Sync Type Classification Tests', () {
    test('should identify manual sync', () {
      final manualHistory = SyncHistory.fromSuccess(
        result: _createEmptyResult(),
        syncStartTime: DateTime.now(),
        syncEndTime: DateTime.now(),
        source: SyncSource.manual,
      );
      expect(manualHistory.isManual, true);
      
      final autoHistory = SyncHistory.fromSuccess(
        result: _createEmptyResult(),
        syncStartTime: DateTime.now(),
        syncEndTime: DateTime.now(),
        source: SyncSource.polling,
      );
      expect(autoHistory.isManual, false);
    });
  });
}

SyncResult _createEmptyResult() {
  return const SyncResult(
    uploadedRecords: 0,
    uploadedStoryLines: 0,
    uploadedCheckIns: 0,
    downloadedRecords: 0,
    downloadedStoryLines: 0,
    downloadedCheckIns: 0,
    mergedRecords: 0,
    mergedStoryLines: 0,
    mergedCheckIns: 0,
    syncedAchievements: 0,
  );
}

