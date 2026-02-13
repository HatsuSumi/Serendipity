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
  final _descriptionController = TextEditingController();
  final _conversationStarterController = TextEditingController();
  final _backgroundMusicController = TextEditingController();
  final _ifReencounterController = TextEditingController();
  
  // 必填字段
  DateTime _selectedTime = DateTime.now();
  EncounterStatus _selectedStatus = EncounterStatus.missed;
  
  // 可选字段
  PlaceType? _selectedPlaceType;
  EmotionIntensity? _selectedEmotion;
  Weather? _selectedWeather;
  List<TagWithNote> _tags = [];
  
  // 存储服务
  final _storage = StorageService();
  
  // 是否正在保存
  bool _isSaving = false;

  @override
  void dispose() {
    _placeNameController.dispose();
    _descriptionController.dispose();
    _conversationStarterController.dispose();
    _backgroundMusicController.dispose();
    _ifReencounterController.dispose();
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
      // 获取描述（去除首尾空格）
      final description = _descriptionController.text.trim();
      
      // 获取对话契机（仅邂逅状态）
      final conversationStarter = _selectedStatus == EncounterStatus.met
          ? _conversationStarterController.text.trim()
          : null;
      
      // 获取背景音乐
      final backgroundMusic = _backgroundMusicController.text.trim();
      
      // 获取"如果再遇"备忘
      final ifReencounter = _ifReencounterController.text.trim();
      
      // 创建记录
      final record = EncounterRecord(
        id: const Uuid().v4(),
        timestamp: _selectedTime,
        location: Location(
          placeName: _placeNameController.text.trim().isEmpty 
              ? null 
              : _placeNameController.text.trim(),
          placeType: _selectedPlaceType,
        ),
        description: description.isEmpty ? null : description,
        tags: _tags,
        emotion: _selectedEmotion,
        status: _selectedStatus,
        conversationStarter: conversationStarter?.isEmpty ?? true ? null : conversationStarter,
        backgroundMusic: backgroundMusic.isEmpty ? null : backgroundMusic,
        weather: _selectedWeather,
        ifReencounter: ifReencounter.isEmpty ? null : ifReencounter,
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
        title: const Text('创建记录'),
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
            const SizedBox(height: 24),

            // 对话契机（仅邂逅状态显示）
            if (_selectedStatus == EncounterStatus.met) ...[
              _buildConversationStarterSection(),
              const SizedBox(height: 24),
            ],

            // 描述输入（可选）
            _buildDescriptionSection(),
            const SizedBox(height: 24),

            // 特征标签（可选）
            _buildTagsSection(),
            const SizedBox(height: 24),

            // 情绪强度（可选）
            _buildEmotionSection(),
            const SizedBox(height: 24),

            // 背景音乐（可选）
            _buildBackgroundMusicSection(),
            const SizedBox(height: 24),

            // 天气（可选）
            _buildWeatherSection(),
            const SizedBox(height: 24),

            // "如果再遇"备忘（可选）
            _buildIfReencounterSection(),
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
        
        // 地点名称输入
        TextFormField(
          controller: _placeNameController,
          decoration: InputDecoration(
            hintText: '例如：地铁10号线、星巴克...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 12),
        
        // 场所类型选择
        Text(
          '场所类型（可选）',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PlaceType.values.take(10).map((type) {
            final isSelected = _selectedPlaceType == type;
            return FilterChip(
              label: Text('${type.icon} ${type.label}'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedPlaceType = selected ? type : null;
                });
              },
            );
          }).toList(),
        ),
        if (PlaceType.values.length > 10)
          TextButton(
            onPressed: () => _showPlaceTypeDialog(),
            child: const Text('查看全部场所类型 →'),
          ),
      ],
    );
  }
  
  /// 显示场所类型选择对话框
  Future<void> _showPlaceTypeDialog() async {
    final selected = await showDialog<PlaceType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择场所类型'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: PlaceType.values.map((type) {
              return ListTile(
                leading: Text(type.icon, style: const TextStyle(fontSize: 24)),
                title: Text(type.label),
                selected: _selectedPlaceType == type,
                onTap: () => Navigator.of(context).pop(type),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('清除'),
          ),
        ],
      ),
    );
    
    if (selected != null || selected == null && _selectedPlaceType != null) {
      setState(() {
        _selectedPlaceType = selected;
      });
    }
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
          '提示：每次见面创建一条新记录，然后通过"故事线"关联\n详细说明请查看"关于"页面',
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
  
  /// 描述输入区域
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '📝 描述',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '（可选）',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: '记录当时的情景、感受...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
  
  /// 特征标签区域
  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🏷️ 特征标签',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '（可选）',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 已选择的标签
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tagWithNote) {
              return Chip(
                label: Text(tagWithNote.tag),
                onDeleted: () {
                  setState(() {
                    _tags.remove(tagWithNote);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        
        // 添加标签按钮
        OutlinedButton.icon(
          onPressed: () => _showAddTagDialog(),
          icon: const Icon(Icons.add),
          label: const Text('添加标签'),
        ),
      ],
    );
  }
  
  /// 显示添加标签对话框
  Future<void> _showAddTagDialog() async {
    final tagController = TextEditingController();
    final noteController = TextEditingController();
    
    final result = await showDialog<TagWithNote>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加标签'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tagController,
              decoration: const InputDecoration(
                labelText: '标签名称',
                hintText: '例如：长发、黑色外套...',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                hintText: '例如：光线不好，可能是深棕色',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final tag = tagController.text.trim();
              if (tag.isNotEmpty) {
                final note = noteController.text.trim();
                Navigator.of(context).pop(
                  TagWithNote(
                    tag: tag,
                    note: note.isEmpty ? null : note,
                  ),
                );
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      setState(() {
        _tags.add(result);
      });
    }
  }
  
  /// 对话契机区域（仅邂逅状态）
  Widget _buildConversationStarterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '💬 对话契机',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '（可选）',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _conversationStarterController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: '记录你们是如何开始对话的...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
  
  /// 情绪强度区域
  Widget _buildEmotionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '❤️ 情绪强度',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '（可选）',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EmotionIntensity.values.map((emotion) {
            final isSelected = _selectedEmotion == emotion;
            return ChoiceChip(
              label: Text(emotion.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedEmotion = selected ? emotion : null;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  
  /// 背景音乐区域
  Widget _buildBackgroundMusicSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '🎵 背景音乐',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '（可选）',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _backgroundMusicController,
          decoration: InputDecoration(
            hintText: '歌名 - 歌手',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.music_note),
          ),
        ),
      ],
    );
  }
  
  /// 天气区域
  Widget _buildWeatherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '☀️ 天气',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '（可选）',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 显示已选择的天气
        if (_selectedWeather != null)
          Card(
            child: ListTile(
              leading: Text(_selectedWeather!.icon, style: const TextStyle(fontSize: 24)),
              title: Text(_selectedWeather!.label),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedWeather = null;
                  });
                },
              ),
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: () => _showWeatherDialog(),
            icon: const Icon(Icons.wb_sunny),
            label: const Text('选择天气'),
          ),
      ],
    );
  }
  
  /// 显示天气选择对话框
  Future<void> _showWeatherDialog() async {
    final selected = await showDialog<Weather>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择天气'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: Weather.values.map((weather) {
              return ListTile(
                leading: Text(weather.icon, style: const TextStyle(fontSize: 24)),
                title: Text(weather.label),
                onTap: () => Navigator.of(context).pop(weather),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
    
    if (selected != null) {
      setState(() {
        _selectedWeather = selected;
      });
    }
  }
  
  /// "如果再遇"备忘区域
  Widget _buildIfReencounterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '💡 如果再遇',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '（可选）',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ifReencounterController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '下次见面想做什么、想说什么...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

