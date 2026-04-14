import 'package:uuid/uuid.dart';
import 'i_storage_service.dart';

class DeviceIdentityService {
  static const String _deviceIdKey = 'device_id';
  static const Uuid _uuid = Uuid();

  final IStorageService _storage;

  DeviceIdentityService({required IStorageService storage}) : _storage = storage;

  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final deviceId = _uuid.v4();
    await _storage.saveString(_deviceIdKey, deviceId);
    return deviceId;
  }
}

