import 'package:flutter/material.dart';
import '../../../core/utils/dialog_helper.dart';

/// 同步说明对话框
/// 
/// 职责：
/// - 向用户解释自动同步和手动同步的机制
/// - 说明增量同步的概念
/// - 解释上传和下载的含义
/// 
/// 调用者：
/// - SettingsPage：手动同步旁边的问号图标
class SyncInfoDialog extends StatelessWidget {
  const SyncInfoDialog({super.key});

  /// 显示同步说明对话框
  /// 
  /// 调用者：SettingsPage
  static Future<void> show(BuildContext context) async {
    return DialogHelper.show<void>(
      context: context,
      builder: (context) => const SyncInfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('关于数据同步'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 自动同步和手动同步
            _buildSectionTitle(context, '自动同步 vs 手动同步'),
            const SizedBox(height: 8),
            _buildInfoText(
              context,
              '自动同步：在以下情况下自动触发',
            ),
            const SizedBox(height: 8),
            _buildInfoText(
              context,
              '1. 注册成功后（跳过下载，只上传本地数据）',
            ),
            _buildInfoText(
              context,
              '2. 登录成功后（增量同步）',
            ),
            _buildInfoText(
              context,
              '3. App 启动时（增量同步，如果已登录）',
            ),
            _buildInfoText(
              context,
              '4. 网络重新连接时（增量同步）',
            ),
            _buildInfoText(
              context,
              '5. 每 60 秒轮询一次服务器健康状态（如果服务器从故障恢复则触发同步）',
            ),
            const SizedBox(height: 16),
            _buildInfoText(
              context,
              '手动同步：点击"手动同步"按钮（增量同步）',
            ),
            const SizedBox(height: 8),
            _buildInfoText(
              context,
              '说明：以上同步会记录到"同步历史"，支持多设备数据同步。',
            ),
            const SizedBox(height: 16),
            _buildInfoText(
              context,
              '【实时同步】单条数据立即同步',
              isBold: true,
            ),
            const SizedBox(height: 4),
            _buildInfoText(
              context,
              '1. 创建记录后，自动上传该记录',
            ),
            _buildInfoText(
              context,
              '2. 编辑记录后，自动上传该记录',
            ),
            _buildInfoText(
              context,
              '3. 删除记录后，自动删除云端数据',
            ),
            _buildInfoText(
              context,
              '4. 创建故事线后，自动上传该故事线',
            ),
            _buildInfoText(
              context,
              '5. 编辑故事线后，自动上传该故事线',
            ),
            _buildInfoText(
              context,
              '6. 删除故事线后，自动删除云端数据',
            ),
            _buildInfoText(
              context,
              '7. 签到后，自动上传签到记录',
            ),
            _buildInfoText(
              context,
              '8. 解锁成就后，自动上传成就解锁记录',
            ),
            _buildInfoText(
              context,
              '9. 修改用户设置后，自动上传设置',
            ),
            _buildInfoText(
              context,
              '10. 收藏/取消收藏帖子或记录后，自动同步收藏状态',
            ),
            const SizedBox(height: 8),
            _buildInfoText(
              context,
              '说明：实时同步无需等待，操作完成即同步完成，不会记录到"同步历史"。',
            ),
            const SizedBox(height: 16),

            // 何时需要手动同步
            _buildSectionTitle(context, '何时需要手动同步？'),
            const SizedBox(height: 8),
            _buildInfoText(
              context,
              '在以下情况下，建议手动同步：',
            ),
            const SizedBox(height: 4),
            _buildInfoText(
              context,
              '1. 更换设备后，首次登录时（自动同步已触发，但可手动再次同步确认）',
            ),
            _buildInfoText(
              context,
              '2. 长时间未使用应用后（自动同步已触发，但可手动再次同步确认）',
            ),
            _buildInfoText(
              context,
              '3. 怀疑数据不一致时',
            ),
            const SizedBox(height: 16),

            // 全量同步 vs 增量同步
            _buildSectionTitle(context, '全量同步 vs 增量同步'),
            const SizedBox(height: 8),
            _buildInfoText(
              context,
              '全量同步：扫描所有数据，上传和下载所有内容。',
            ),
            const SizedBox(height: 8),
            _buildInfoText(
              context,
              '增量同步：只同步有变化的数据（根据最后更新时间判断），节省流量和时间。',
            ),
            const SizedBox(height: 8),
            _buildInfoText(
              context,
              '本应用使用增量同步策略，支持多设备数据同步。',
            ),
            const SizedBox(height: 16),

            // 上传和下载
            _buildSectionTitle(context, '上传和下载是什么意思？'),
            const SizedBox(height: 8),
            _buildInfoText(
              context,
              '上传：将本地有变化的数据发送到云端服务器。',
            ),
            const SizedBox(height: 8),
            _buildInfoText(
              context,
              '下载：从云端服务器获取有变化的数据到本地。',
            ),
            const SizedBox(height: 8),
            _buildInfoText(
              context,
              '如果显示"数据已是最新，无需同步"，说明本地和云端数据完全一致。',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('我知道了'),
        ),
      ],
    );
  }

  /// 构建章节标题
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// 构建说明文本
  Widget _buildInfoText(BuildContext context, String text, {bool isBold = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.5,
      ),
    );
  }
}
