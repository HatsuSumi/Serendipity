part of 'create_record_page.dart';

extension _CreateRecordPageOtherSettingsSection on _CreateRecordPageState {
  Widget _buildOtherSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📌 其他设置',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildPublishToCommunitySection(),
        const SizedBox(height: 8),
        _buildStoryLineSection(),
      ],
    );
  }

  Widget _buildPublishToCommunitySection() {
    if (!widget.isEditMode) {
      return CheckboxListTile(
        value: _publishToCommunity,
        onChanged: (value) {
          _updateState(() {
            _publishToCommunity = value ?? false;
          });
        },
        title: const Text('发布到树洞'),
        subtitle: Text(
          '匿名分享到社区，其他用户可以看到',
          style: TextStyle(
            fontSize: 12,
            color: _colorScheme.onSurfaceVariant,
          ),
        ),
        contentPadding: EdgeInsets.zero,
      );
    }

    return ValueListenableBuilder<int>(
      valueListenable: _formChangedNotifier,
      builder: (context, _, _) {
        if (_publishStatus == null) {
          return const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('检查发布状态...'),
          );
        }

        if (_publishStatus == 'can_publish') {
          return CheckboxListTile(
            value: _publishToCommunity,
            onChanged: (value) {
              _updateState(() {
                _publishToCommunity = value ?? false;
              });
            },
            title: const Text('发布到树洞'),
            subtitle: Text(
              '匿名分享到社区，其他用户可以看到',
              style: TextStyle(
                fontSize: 12,
                color: _colorScheme.onSurfaceVariant,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          );
        }

        final hasContentChanges = _hasContentChanges();

        if (!hasContentChanges) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_done,
                  size: 20,
                  color: _colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '已发布到社区',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '内容无变化，无法再次发布',
                        style: TextStyle(
                          fontSize: 12,
                          color: _colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return CheckboxListTile(
          value: _publishToCommunity,
          onChanged: (value) {
            _updateState(() {
              _publishToCommunity = value ?? false;
            });
          },
          title: const Text('重新发布到社区'),
          subtitle: Text(
            '内容已修改，勾选后将替换旧帖',
            style: TextStyle(
              fontSize: 12,
              color: _colorScheme.onSurfaceVariant,
            ),
          ),
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }
}

