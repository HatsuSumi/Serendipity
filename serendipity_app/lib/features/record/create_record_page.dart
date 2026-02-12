import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/message_helper.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';

/// 创建记录页面（基础版）
class CreateRecordPage extends StatefulWidget {
  const CreateRecordPage({super.key});

  @override
  State<CreateRecordPage> createState() => _CreateRecordPageState();
}

class _CreateRecordPageState extends State<CreateRecordPage> {
  // 表单控制器
  final _formKey = GlobalKey<FormState>();
  final _placeNameController = TextEditingController();
  
  // 必填字段
  DateTime _selectedTime = DateTime.now();
  EncounterStatus _selectedStatus = EncounterStatus.missed;
  
  // 存储服务
  final _storage = StorageService();
  
  // 是否正在保存
  bool _isSaving = false;

  @override
  void dispose() {
    _placeNameController.dispose();
    super.dispose();
  }

  /// 保存记录
  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 创建记录
      final record = EncounterRecord(
        id: const Uuid().v4(),
        timestamp: _selectedTime,
        location: Location(
          placeName: _placeNameController.text.trim(),
        ),
        tags: [], // 基础版暂时为空
        status: _selectedStatus,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 保存到本地
      await _storage.saveRecord(record);

      if (mounted) {
        // 显示成功提示
        MessageHelper.showSuccess(context, '记录已保存');

        // 返回上一页
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showError(context, '保存失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// 选择时间
  Future<void> _selectTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date == null) return;

    if (mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedTime),
      );

      if (time != null) {
        setState(() {
          _selectedTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记录错过'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveRecord,
              child: const Text(
                '保存',
                style: TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 时间选择
            _buildTimeSection(),
            const SizedBox(height: 24),

            // 地点输入
            _buildLocationSection(),
            const SizedBox(height: 24),

            // 状态选择
            _buildStatusSection(),
            const SizedBox(height: 32),

            // 提示文字
            _buildHintText(),
          ],
        ),
      ),
    );
  }

  /// 时间选择区域
  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⏰ 时间',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectTime,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 12),
                Text(
                  _formatDateTime(_selectedTime),
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                const Icon(Icons.edit, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 地点输入区域
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📍 地点',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _placeNameController,
          decoration: InputDecoration(
            hintText: '例如：地铁10号线、星巴克...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.location_on),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入地点';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 状态选择区域
  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '💫 状态',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EncounterStatus.values.map((status) {
            final isSelected = _selectedStatus == status;
            return ChoiceChip(
              label: Text('${status.icon} ${status.label}'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedStatus = status;
                  });
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          '提示：每次见面创建一条新记录，然后通过"故事线"关联',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 提示文字
  Widget _buildHintText() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 如何记录？',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '每次见面 = 一条新记录\n\n'
            '例如：\n'
            '• 今天在地铁看到 TA → 创建记录，选择"错过"\n'
            '• 明天又看到 TA → 创建新记录，选择"再遇"\n'
            '• 后天终于说话了 → 创建新记录，选择"邂逅"\n\n'
            '然后通过"故事线"功能把这些记录关联起来',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

