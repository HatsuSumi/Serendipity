part of 'create_record_page.dart';

extension _CreateRecordPageLocationFlowActions on _CreateRecordPageState {
  Future<void> _requestLocation() async {
    try {
      await ref.read(locationProvider.notifier).checkPermission();
      final hasPermission = ref.read(locationProvider).hasPermission ?? false;

      if (!hasPermission) {
        final granted = await ref.read(locationProvider.notifier).requestPermission();

        if (!granted && mounted) {
          await _showPermissionDialog();
          return;
        }
      }

      await ref.read(locationProvider.notifier).getCurrentLocation();
    } catch (e) {
      // 错误已经在 Provider 中处理，这里不需要额外处理
    }
  }

  Future<void> _showPermissionDialog() async {
    if (!mounted) return;

    await DialogHelper.show(
      context: context,
      builder: (dialogContext) => LocationPermissionDialog(
        onOpenSettings: () async {
          final opened = await ref.read(locationProvider.notifier).openSettings();
          if (!opened && mounted) {
            if (!mounted) return;
            MessageHelper.showError(context, '无法打开系统设置');
          }
        },
      ),
    );
  }

  void _loadPlaceHistory() {
    final recordsAsync = ref.read(recordsProvider);
    final records = recordsAsync.value ?? [];
    final Map<String, PlaceHistoryItem> placeMap = {};

    for (final record in records) {
      final placeName = record.location.placeName;
      if (placeName != null && placeName.isNotEmpty) {
        if (placeMap.containsKey(placeName)) {
          final existing = placeMap[placeName]!;
          placeMap[placeName] = PlaceHistoryItem(
            placeName: placeName,
            usageCount: existing.usageCount + 1,
            lastUsedTime: record.timestamp.isAfter(existing.lastUsedTime)
                ? record.timestamp
                : existing.lastUsedTime,
          );
        } else {
          placeMap[placeName] = PlaceHistoryItem(
            placeName: placeName,
            usageCount: 1,
            lastUsedTime: record.timestamp,
          );
        }
      }
    }

    _updateState(() {
      _placeHistory = placeMap.values.toList();
    });
  }
}

