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
              '自动同步：在以下情况下自动触发全量同步',
            ),
            const SizedBox(height: 4),
            _buildInfoText(
              context,
              '1. 首次启动 App 时',
            ),
            _buildInfoText(
              context,
              '2. 登录或注册成功后',
            ),
            _buildInfoText(
              context,
              '3. 网络重新连接时',
            ),
            _buildInfoText(
              context,
              '4. 每 60 秒轮询一次（后台自动）',
            ),
            const SizedBox(height: 8),
            _buildInfoText(
              context,
              '此外，创建、编辑、删除记录/故事线，以及签到时，会自动上传单条数据到云端（增量上传）。',
            ),
            const SizedBox(height: 8),
            _buildInfoText(
              context,
              '手动同步：点击"手动同步"按钮，主动触发数据同步，确保本地和云端数据一致。',
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
              '1. 更换设备后，首次登录时',
            ),
            _buildInfoText(
              context,
              '2. 长时间未使用应用后',
            ),
            _buildInfoText(
              context,
              '3. 怀疑数据不一致时',
            ),
            const SizedBox(height: 16),

            // 增量同步
            _buildSectionTitle(context, '什么是增量同步？'),
            const SizedBox(height: 8),
            _buildInfoText(
              context,
              '本项目采用增量同步机制，只同步有变化的数据，而不是每次都同步全部数据。',
            ),
            const SizedBox(height: 8),
            _buildInfoText(
              context,
              '这样可以大幅减少网络流量和同步时间，提升使用体验。',
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
  Widget _buildInfoText(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.5,
      ),
    );
  }
}
