part of '../storage_service.dart';

mixin _StorageServiceAuxiliaryData on _StorageServiceCore {
  @override
  Future<void> saveFavoritedRecordSnapshot(EncounterRecord record) async {
    await favoritedRecordSnapshotsBoxOrThrow.put(record.id, record);
  }

  @override
  EncounterRecord? getFavoritedRecordSnapshot(String recordId) {
    return favoritedRecordSnapshotsBoxOrThrow.get(recordId);
  }

  @override
  Future<void> deleteFavoritedRecordSnapshot(String recordId) async {
    await favoritedRecordSnapshotsBoxOrThrow.delete(recordId);
  }

  @override
  Future<void> saveFavoritedPostSnapshot(
    String postId,
    Map<String, dynamic> postJson,
  ) async {
    await favoritedPostSnapshotsBoxOrThrow.put(postId, jsonEncode(postJson));
  }

  @override
  Map<String, dynamic>? getFavoritedPostSnapshot(String postId) {
    final raw = favoritedPostSnapshotsBoxOrThrow.get(postId);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> deleteFavoritedPostSnapshot(String postId) async {
    await favoritedPostSnapshotsBoxOrThrow.delete(postId);
  }

  @override
  Future<Membership?> getMembership(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    final json = membershipsBoxOrThrow.get(userId);
    if (json == null) return null;
    return Membership.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  @override
  Future<void> saveMembership(Membership membership) async {
    if (membership.userId.isEmpty) {
      throw ArgumentError('membership.userId cannot be empty');
    }
    await membershipsBoxOrThrow.put(
      membership.userId,
      jsonEncode(membership.toJson()),
    );
  }

  @override
  Future<void> deleteMembership(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    await membershipsBoxOrThrow.delete(userId);
  }
}
