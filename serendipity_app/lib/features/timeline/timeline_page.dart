import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/records_provider.dart';
import '../../core/utils/message_helper.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';

/// 时间轴页面（记录列表）
class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TA'),
      ),
      body: recordsAsync.when(
        data: (records) => records.isEmpty
            ? _buildEmptyState(context)
            : _buildRecordList(context, records, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败：$error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(recordsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '💫',
            style: TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有记录',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮记录第一次错过',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 记录列表
  Widget _buildRecordList(BuildContext context, List<EncounterRecord> records, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(recordsProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return _buildRecordCard(context, record);
        },
      ),
    );
  }

  /// 记录卡片
  Widget _buildRecordCard(BuildContext context, EncounterRecord record) {
    final statusColor = _getStatusColor(record.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          context.push('/record/detail', extra: record);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 状态和时间
              Row(
                children: [
                  Text(
                    record.status.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    record.status.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(record.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 地点
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      record.location.placeName ?? '未知地点',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              // 描述（如果有）
              if (record.description != null && record.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  record.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // 标签（如果有）
              if (record.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: record.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag.tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 根据状态获取情感色调
  Color _getStatusColor(EncounterStatus status) {
    switch (status) {
      case EncounterStatus.missed:
        return const Color(0xFF7B9EB0); // 灰蓝色调
      case EncounterStatus.reencounter:
        return const Color(0xFFFFD700); // 金色
      case EncounterStatus.met:
        return const Color(0xFFFF9E80); // 粉橙色调
      case EncounterStatus.reunion:
        return const Color(0xFFE91E63); // 玫瑰金色调
      case EncounterStatus.farewell:
        return const Color(0xFFBCAAA4); // 玫瑰灰色调
      case EncounterStatus.lost:
        return const Color(0xFFD4A574); // 秋叶色调
    }
  }

  /// 格式化时间
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}
