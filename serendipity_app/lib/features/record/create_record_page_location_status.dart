part of 'create_record_page.dart';

extension _CreateRecordPageLocationStatus on _CreateRecordPageState {
  Widget _buildLocationStatus() {
    final locationState = ref.watch(locationProvider);

    if (widget.isEditMode && widget.recordToEdit != null) {
      final location = widget.recordToEdit!.location;
      final hasGPS = location.latitude != null && location.longitude != null;

      if (hasGPS && !locationState.isLoading && locationState.result == null) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 已保存的GPS信息',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location.address ?? '${location.latitude}, ${location.longitude}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.my_location, size: 20),
                onPressed: _requestLocation,
                tooltip: '重新定位',
              ),
            ],
          ),
        );
      }

      if (!hasGPS && !locationState.isLoading && locationState.result == null) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📍 未保存GPS信息',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '当时创建记录时勾选了"忽略GPS"',
                      style: TextStyle(
                        fontSize: 13,
                        color: _colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_location, size: 20),
                onPressed: _requestLocation,
                tooltip: '获取GPS定位',
              ),
            ],
          ),
        );
      }
    }

    if (locationState.isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.isEditMode ? '正在重新获取位置...' : '正在获取位置...',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    if (locationState.result?.isSuccess == true) {
      final result = locationState.result!;
      final address = result.address ?? '位置已获取';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEditMode ? '✅ 已重新定位' : '✅ 已定位',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _requestLocation,
              tooltip: '重新定位',
            ),
          ],
        ),
      );
    }

    if (locationState.result?.isSuccess == false) {
      final result = locationState.result!;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: _colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ 无法获取GPS定位',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.errorMessage ?? '定位失败',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _requestLocation,
              tooltip: '重试',
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

