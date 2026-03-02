import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 恢复密钥对话框
/// 
/// 在用户注册成功后显示，强制用户确认已保存恢复密钥。
/// 遵循单一职责原则（SRP）：只负责展示恢复密钥并确认用户已保存。
/// 
/// 调用者：
/// - RegisterPage：注册成功后显示此对话框
class RecoveryKeyDialog extends StatefulWidget {
  final String recoveryKey;
  
  const RecoveryKeyDialog({
    super.key,
    required this.recoveryKey,
  });

  @override
  State<RecoveryKeyDialog> createState() => _RecoveryKeyDialogState();
}

class _RecoveryKeyDialogState extends State<RecoveryKeyDialog> {
  bool _hasConfirmed = false;
  bool _isCopied = false;
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 禁止通过返回键关闭对话框，必须点击"我已保存"按钮
      canPop: false,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.key,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('保存恢复密钥'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 警告提示
              _buildWarningCard(context),
              
              const SizedBox(height: 16),
              
              // 恢复密钥显示
              _buildRecoveryKeyCard(context),
              
              const SizedBox(height: 16),
              
              // 使用说明
              _buildInstructions(context),
              
              const SizedBox(height: 16),
              
              // 确认复选框
              _buildConfirmationCheckbox(context),
            ],
          ),
        ),
        actions: [
          // 复制按钮
          TextButton.icon(
            onPressed: _copyToClipboard,
            icon: Icon(_isCopied ? Icons.check : Icons.copy),
            label: Text(_isCopied ? '已复制' : '复制密钥'),
          ),
          
          // 确认按钮（只有勾选后才能点击）
          FilledButton(
            onPressed: _hasConfirmed ? () => Navigator.of(context).pop() : null,
            child: const Text('我已保存'),
          ),
        ],
      ),
    );
  }
  
  /// 构建警告卡片
  Widget _buildWarningCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '请务必保存此恢复密钥！\n忘记密码时需要使用它来重置密码。',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onErrorContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建恢复密钥卡片
  Widget _buildRecoveryKeyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: SelectableText(
        widget.recoveryKey,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'monospace',
          letterSpacing: 1.2,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  /// 构建使用说明
  Widget _buildInstructions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '保存方式：',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        _buildInstructionItem(context, '截图保存到相册'),
        _buildInstructionItem(context, '复制到密码管理器'),
        _buildInstructionItem(context, '手写记录在安全的地方'),
      ],
    );
  }
  
  /// 构建说明项
  Widget _buildInstructionItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建确认复选框
  Widget _buildConfirmationCheckbox(BuildContext context) {
    return CheckboxListTile(
      value: _hasConfirmed,
      onChanged: (value) {
        setState(() {
          _hasConfirmed = value ?? false;
        });
      },
      title: const Text(
        '我已安全保存恢复密钥',
        style: TextStyle(fontSize: 14),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
  
  /// 复制到剪贴板
  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.recoveryKey));
    
    if (mounted) {
      setState(() {
        _isCopied = true;
      });
      
      // 2秒后恢复按钮状态
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isCopied = false;
          });
        }
      });
      
      // 显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('恢复密钥已复制到剪贴板'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

