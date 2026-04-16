part of '../storage_service.dart';

mixin _StorageServiceRecords on _StorageServiceCore {
  @override
  Future<void> saveRecord(EncounterRecord record) async {
    assert(record.id.isNotEmpty, 'Record ID cannot be empty');
    await recordsBoxOrThrow.put(record.id, record);
  }

  @override
  EncounterRecord? getRecord(String id) {
    assert(id.isNotEmpty, 'Record ID cannot be empty');
    return recordsBoxOrThrow.get(id);
  }

  @override
  List<EncounterRecord> getAllRecords() {
    return recordsBoxOrThrow.values.toList();
  }

  @override
  List<EncounterRecord> getRecordsSortedByTime() {
    final records = getAllRecords();
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }

  @override
  Future<void> deleteRecord(String id) async {
    assert(id.isNotEmpty, 'Record ID cannot be empty');
    await recordsBoxOrThrow.delete(id);
  }

  @override
  Future<void> updateRecord(EncounterRecord record) async {
    assert(record.id.isNotEmpty, 'Record ID cannot be empty');
    await recordsBoxOrThrow.put(record.id, record);
  }

  @override
  List<EncounterRecord> getRecordsByStoryLine(String storyLineId) {
    assert(storyLineId.isNotEmpty, 'Story line ID cannot be empty');
    return getAllRecords()
        .where((record) => record.storyLineId == storyLineId)
        .toList();
  }

  @override
  List<EncounterRecord> getRecordsWithoutStoryLine() {
    return getAllRecords()
        .where((record) => record.storyLineId == null)
        .toList();
  }

  @override
  List<EncounterRecord> getRecordsByUser(String? userId) {
    final records = getAllRecords()
        .where((record) => record.ownerId == userId)
        .toList();
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return records;
  }
}
