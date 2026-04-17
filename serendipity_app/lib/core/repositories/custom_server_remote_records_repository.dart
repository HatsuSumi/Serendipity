import '../../models/encounter_record.dart';
import '../config/server_config.dart';
import '../services/http_client_service.dart';
import '../utils/address_helper.dart';

class CustomServerRemoteRecordsRepository {
  final HttpClientService _httpClient;
  static const int _syncPageSize = 100;

  const CustomServerRemoteRecordsRepository({required HttpClientService httpClient})
      : _httpClient = httpClient;

  Future<List<EncounterRecord>> downloadRecordsPaged(
    String userId, {
    DateTime? lastSyncTime,
  }) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    final allRecords = <EncounterRecord>[];
    var offset = 0;
    var hasMore = true;

    while (hasMore) {
      final queryParams = <String, String>{
        'limit': _syncPageSize.toString(),
        'offset': offset.toString(),
      };
      if (lastSyncTime != null) {
        queryParams['lastSyncTime'] = lastSyncTime.toIso8601String();
      }

      final response = await _httpClient.get(
        ServerConfig.records,
        queryParams: queryParams,
      );
      final data = response['data'] as Map<String, dynamic>;
      final recordsJson = data['records'] as List;
      final pageRecords = recordsJson
          .map((json) => EncounterRecord.fromJson(json as Map<String, dynamic>))
          .toList();

      allRecords.addAll(pageRecords);
      hasMore = data['hasMore'] as bool? ?? false;
      offset += pageRecords.length;

      if (pageRecords.isEmpty) {
        break;
      }
    }

    return allRecords;
  }

  Map<String, dynamic> toServerDto(EncounterRecord record) {
    final recordJson = record.toJson();
    final location = recordJson['location'] as Map<String, dynamic>;
    final region = AddressHelper.extractRegion(location['address'] as String?);

    if (region.province != null) {
      location['province'] = region.province;
    }
    if (region.city != null) {
      location['city'] = region.city;
    }
    if (region.area != null) {
      location['area'] = region.area;
    }

    return recordJson;
  }

  Future<void> uploadRecord(String userId, EncounterRecord record) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    try {
      await _httpClient.post(
        ServerConfig.records,
        body: toServerDto(record),
      );
    } on HttpException catch (e) {
      throw Exception('上传记录失败：${e.message}');
    }
  }

  Future<void> updateRecord(String userId, EncounterRecord record) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }

    try {
      await _httpClient.put(
        ServerConfig.recordById(record.id),
        body: toServerDto(record),
      );
    } on HttpException catch (e) {
      throw Exception('更新记录失败：${e.message}');
    }
  }

  Future<void> uploadRecords(String userId, List<EncounterRecord> records) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (records.isEmpty) {
      return;
    }

    try {
      await _httpClient.post(
        ServerConfig.recordsBatch,
        body: {
          'records': records.map(toServerDto).toList(),
        },
      );
    } on HttpException catch (e) {
      throw Exception('批量上传记录失败：${e.message}');
    }
  }

  Future<List<EncounterRecord>> downloadRecords(String userId) async {
    try {
      return await downloadRecordsPaged(userId);
    } on HttpException catch (e) {
      throw Exception('下载记录失败：${e.message}');
    }
  }

  Future<List<EncounterRecord>> downloadRecordsSince(String userId, DateTime lastSyncTime) async {
    try {
      return await downloadRecordsPaged(
        userId,
        lastSyncTime: lastSyncTime,
      );
    } on HttpException catch (e) {
      throw Exception('下载增量记录失败：${e.message}');
    }
  }

  Future<void> deleteRecord(String userId, String recordId) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (recordId.isEmpty) {
      throw ArgumentError('记录 ID 不能为空');
    }

    try {
      await _httpClient.delete(ServerConfig.recordById(recordId));
    } on HttpException catch (e) {
      throw Exception('删除记录失败：${e.message}');
    }
  }

  Future<List<EncounterRecord>> filterRecords({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? province,
    String? city,
    String? area,
    List<String>? placeNameKeywords,
    List<String>? descriptionKeywords,
    List<String>? ifReencounterKeywords,
    List<String>? conversationStarterKeywords,
    List<String>? backgroundMusicKeywords,
    List<String>? placeTypes,
    List<String>? tags,
    List<String>? statuses,
    List<String>? emotionIntensities,
    List<String>? weathers,
    String tagMatchMode = 'contains',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    int limit = 20,
    int offset = 0,
  }) async {
    if (userId.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (limit <= 0) {
      throw ArgumentError('limit 必须大于 0');
    }
    if (offset < 0) {
      throw ArgumentError('offset 不能为负数');
    }
    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      throw ArgumentError('开始日期不能晚于结束日期');
    }

    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (province != null && province.isNotEmpty) {
        queryParams['province'] = province;
      }
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      if (area != null && area.isNotEmpty) {
        queryParams['area'] = area;
      }
      if (placeNameKeywords != null && placeNameKeywords.isNotEmpty) {
        queryParams['placeNameKeywords'] = placeNameKeywords.join(',');
      }
      if (descriptionKeywords != null && descriptionKeywords.isNotEmpty) {
        queryParams['descriptionKeywords'] = descriptionKeywords.join(',');
      }
      if (ifReencounterKeywords != null && ifReencounterKeywords.isNotEmpty) {
        queryParams['ifReencounterKeywords'] = ifReencounterKeywords.join(',');
      }
      if (conversationStarterKeywords != null && conversationStarterKeywords.isNotEmpty) {
        queryParams['conversationStarterKeywords'] = conversationStarterKeywords.join(',');
      }
      if (backgroundMusicKeywords != null && backgroundMusicKeywords.isNotEmpty) {
        queryParams['backgroundMusicKeywords'] = backgroundMusicKeywords.join(',');
      }
      if (placeTypes != null && placeTypes.isNotEmpty) {
        queryParams['placeTypes'] = placeTypes.join(',');
      }
      if (tags != null && tags.isNotEmpty) {
        queryParams['tags'] = tags.join(',');
      }
      if (statuses != null && statuses.isNotEmpty) {
        queryParams['statuses'] = statuses.join(',');
      }
      if (emotionIntensities != null && emotionIntensities.isNotEmpty) {
        queryParams['emotionIntensities'] = emotionIntensities.join(',');
      }
      if (weathers != null && weathers.isNotEmpty) {
        queryParams['weathers'] = weathers.join(',');
      }
      if (tagMatchMode == 'wholeWord') {
        queryParams['tagMatchMode'] = tagMatchMode;
      }

      final response = await _httpClient.get(
        '${ServerConfig.records}/filter',
        queryParams: queryParams,
      );

      final data = response['data'] as Map<String, dynamic>;
      final recordsJson = data['records'] as List;

      return recordsJson
          .map((json) => EncounterRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } on HttpException catch (e) {
      throw Exception('筛选记录失败：${e.message}');
    }
  }
}

