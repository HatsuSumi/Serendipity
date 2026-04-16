part of '../storage_service.dart';

mixin _StorageServiceCheckIns on _StorageServiceCore {
  @override
  Future<void> saveCheckIn(CheckInRecord checkIn) async {
    assert(checkIn.id.isNotEmpty, 'CheckIn ID cannot be empty');
    await checkInsBoxOrThrow.put(checkIn.id, checkIn);
  }

  @override
  CheckInRecord? getCheckIn(String id) {
    assert(id.isNotEmpty, 'CheckIn ID cannot be empty');
    return checkInsBoxOrThrow.get(id);
  }

  @override
  List<CheckInRecord> getAllCheckIns() {
    return checkInsBoxOrThrow.values.toList();
  }

  @override
  List<CheckInRecord> getCheckInsSortedByDate() {
    final checkIns = getAllCheckIns();
    checkIns.sort((a, b) => b.date.compareTo(a.date));
    return checkIns;
  }

  @override
  List<CheckInRecord> getCheckInsByUser(String? userId) {
    final checkIns = getAllCheckIns()
        .where((checkIn) => checkIn.userId == userId)
        .toList();
    checkIns.sort((a, b) => b.date.compareTo(a.date));
    return checkIns;
  }

  @override
  Future<void> deleteCheckIn(String id) async {
    assert(id.isNotEmpty, 'CheckIn ID cannot be empty');
    await checkInsBoxOrThrow.delete(id);
  }
}
