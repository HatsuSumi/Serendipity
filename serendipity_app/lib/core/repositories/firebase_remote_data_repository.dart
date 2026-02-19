import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../services/firebase_service.dart';
import 'i_remote_data_repository.dart';

/// Firebase 远程数据仓库实现
/// 
/// 实现 IRemoteDataRepository 接口，使用 Cloud Firestore 作为数据存储服务。
/// 遵循单一职责原则（SRP）和依赖倒置原则（DIP）。
/// 
/// 调用者：
/// - SyncService：通过接口调用所有方法
class FirebaseRemoteDataRepository implements IRemoteDataRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  
  // Firestore 集合名称
  static const String _recordsCollection = 'records';
  static const String _storyLinesCollection = 'story_lines';
  
  // ==================== 记录相关操作 ====================
  
  @override
  Future<void> uploadRecord(String userId, EncounterRecord record) async {
    _ensureInitialized();
    
    // Fail Fast：参数验证
    _validateUserId(userId);
    if (record == null) {
      throw ArgumentError('Record cannot be null');
    }
    
    try {
      // 使用用户 ID 作为子集合的父文档
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(_recordsCollection)
          .doc(record.id)
          .set(record.toJson());
    } on FirebaseException catch (e) {
      // 检查是否是限额错误
      if (e.code == 'resource-exhausted') {
        throw Exception('云端同步失败：今日使用量已达上限\n\n您的数据已安全保存到本地，明天会自动同步到云端');
      }
      throw Exception('Failed to upload record: ${e.message}');
    }
  }
  
  @override
  Future<void> uploadRecords(String userId, List<EncounterRecord> records) async {
    _ensureInitialized();
    
    // Fail Fast：参数验证
    _validateUserId(userId);
    
    // 允许空列表，直接返回
    if (records.isEmpty) {
      return;
    }
    
    try {
      // 使用批量写入提高性能
      final batch = _firestore.batch();
      
      for (final record in records) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection(_recordsCollection)
            .doc(record.id);
        
        batch.set(docRef, record.toJson());
      }
      
      await batch.commit();
    } on FirebaseException catch (e) {
      // 检查是否是限额错误
      if (e.code == 'resource-exhausted') {
        throw Exception('云端同步失败：今日使用量已达上限\n\n您的数据已安全保存到本地，明天会自动同步到云端');
      }
      throw Exception('Failed to upload records: ${e.message}');
    }
  }
  
  @override
  Future<List<EncounterRecord>> downloadRecords(String userId) async {
    _ensureInitialized();
    
    // Fail Fast：参数验证
    _validateUserId(userId);
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(_recordsCollection)
          .get();
      
      return snapshot.docs
          .map((doc) => EncounterRecord.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      // 检查是否是限额错误
      if (e.code == 'resource-exhausted') {
        throw Exception('云端同步失败：今日使用量已达上限\n\n您可以继续使用本地数据，明天会自动同步');
      }
      throw Exception('Failed to download records: ${e.message}');
    }
  }
  
  @override
  Future<void> deleteRecord(String userId, String recordId) async {
    _ensureInitialized();
    
    // Fail Fast：参数验证
    _validateUserId(userId);
    if (recordId.isEmpty) {
      throw ArgumentError('Record ID cannot be empty');
    }
    
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(_recordsCollection)
          .doc(recordId)
          .delete();
    } on FirebaseException catch (e) {
      // 检查是否是限额错误
      if (e.code == 'resource-exhausted') {
        throw Exception('云端同步失败：今日使用量已达上限\n\n您的数据已在本地删除，明天会自动同步到云端');
      }
      throw Exception('Failed to delete record: ${e.message}');
    }
  }
  
  // ==================== 故事线相关操作 ====================
  
  @override
  Future<void> uploadStoryLine(String userId, StoryLine storyLine) async {
    _ensureInitialized();
    
    // Fail Fast：参数验证
    _validateUserId(userId);
    if (storyLine == null) {
      throw ArgumentError('StoryLine cannot be null');
    }
    
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(_storyLinesCollection)
          .doc(storyLine.id)
          .set(storyLine.toJson());
    } on FirebaseException catch (e) {
      // 检查是否是限额错误
      if (e.code == 'resource-exhausted') {
        throw Exception('云端同步失败：今日使用量已达上限\n\n您的数据已安全保存到本地，明天会自动同步到云端');
      }
      throw Exception('Failed to upload story line: ${e.message}');
    }
  }
  
  @override
  Future<void> uploadStoryLines(String userId, List<StoryLine> storyLines) async {
    _ensureInitialized();
    
    // Fail Fast：参数验证
    _validateUserId(userId);
    
    // 允许空列表，直接返回
    if (storyLines.isEmpty) {
      return;
    }
    
    try {
      // 使用批量写入提高性能
      final batch = _firestore.batch();
      
      for (final storyLine in storyLines) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection(_storyLinesCollection)
            .doc(storyLine.id);
        
        batch.set(docRef, storyLine.toJson());
      }
      
      await batch.commit();
    } on FirebaseException catch (e) {
      // 检查是否是限额错误
      if (e.code == 'resource-exhausted') {
        throw Exception('云端同步失败：今日使用量已达上限\n\n您的数据已安全保存到本地，明天会自动同步到云端');
      }
      throw Exception('Failed to upload story lines: ${e.message}');
    }
  }
  
  @override
  Future<List<StoryLine>> downloadStoryLines(String userId) async {
    _ensureInitialized();
    
    // Fail Fast：参数验证
    _validateUserId(userId);
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(_storyLinesCollection)
          .get();
      
      return snapshot.docs
          .map((doc) => StoryLine.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      // 检查是否是限额错误
      if (e.code == 'resource-exhausted') {
        throw Exception('云端同步失败：今日使用量已达上限\n\n您可以继续使用本地数据，明天会自动同步');
      }
      throw Exception('Failed to download story lines: ${e.message}');
    }
  }
  
  @override
  Future<void> deleteStoryLine(String userId, String storyLineId) async {
    _ensureInitialized();
    
    // Fail Fast：参数验证
    _validateUserId(userId);
    if (storyLineId.isEmpty) {
      throw ArgumentError('StoryLine ID cannot be empty');
    }
    
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(_storyLinesCollection)
          .doc(storyLineId)
          .delete();
    } on FirebaseException catch (e) {
      // 检查是否是限额错误
      if (e.code == 'resource-exhausted') {
        throw Exception('云端同步失败：今日使用量已达上限\n\n您的数据已在本地删除，明天会自动同步到云端');
      }
      throw Exception('Failed to delete story line: ${e.message}');
    }
  }
  
  // ==================== 私有辅助方法 ====================
  
  /// 确保 Firebase 已初始化
  /// 
  /// 调用者：所有公开方法
  /// 
  /// Fail Fast：如果未初始化，立即抛出异常
  void _ensureInitialized() {
    if (!_firebaseService.isInitialized) {
      throw StateError(
        'Firebase not initialized. Call FirebaseService.initialize() first.',
      );
    }
  }
  
  /// 验证用户 ID
  /// 
  /// 调用者：所有公开方法
  /// 
  /// Fail Fast：用户 ID 为空立即抛出异常
  void _validateUserId(String userId) {
    if (userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
  }
}

