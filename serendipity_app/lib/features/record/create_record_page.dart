import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';

/// 地点历史记录项
class PlaceHistoryItem {
  final String placeName;
  final int usageCount;
  final DateTime lastUsedTime;

  PlaceHistoryItem({
    required this.placeName,
    required this.usageCount,
    required this.lastUsedTime,
  });
}

/// 排序方式
enum PlaceSortType {
  usageDesc('使用频率 ↓'),
  usageAsc('使用频率 ↑'),
  timeDesc('最近使用 ↓'),
  timeAsc('最近使用 ↑');

  final String label;
  const PlaceSortType(this.label);
}

/// 创建/编辑记录页面
class CreateRecordPage extends StatefulWidget {
  /// 要编辑的记录（如果为null则是创建模式）
  final EncounterRecord? recordToEdit;
  
  /// 初始故事线ID（创建记录时自动关联）
  final String? initialStoryLineId;
  
  const CreateRecordPage({
    super.key,
    this.recordToEdit,
    this.initialStoryLineId,
  });
  
  /// 是否为编辑模式
  bool get isEditMode => recordToEdit != null;

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
  List<Weather> _selectedWeather = [];
  List<TagWithNote> _tags = [];
  
  // 高级选项
  bool _publishToCommunity = false;
  String? _selectedStoryLineId;
  
  // 正在删除的标签（使用标签名而不是索引）
  final Set<String> _removingTagNames = {};
  
  // 正在添加的标签（用于添加动画）
  final Set<String> _addingTagNames = {};
  
  // 正在删除的天气（使用天气值而不是索引）
  final Set<int> _removingWeatherValues = {};
  
  // 正在添加的天气（用于添加动画）
  final Set<int> _addingWeatherValues = {};
  
  // 存储服务
  final _storage = StorageService();
  
  // 是否正在保存
  bool _isSaving = false;
  
  // 地点历史记录（包含统计信息）
  List<PlaceHistoryItem> _placeHistory = [];

  @override
  void initState() {
    super.initState();
    _loadPlaceHistory();
    _initializeFormData();
  }
  
  /// 初始化表单数据（编辑模式下预填充）
  void _initializeFormData() {
    if (widget.recordToEdit != null) {
      final record = widget.recordToEdit!;
      
      // 预填充必填字段
      _selectedTime = record.timestamp;
      _selectedStatus = record.status;
      
      // 预填充地点信息
      if (record.location.placeName != null) {
        _placeNameController.text = record.location.placeName!;
      }
      _selectedPlaceType = record.location.placeType;
      
      // 预填充可选字段
      if (record.description != null) {
        _descriptionController.text = record.description!;
      }
      
      if (record.conversationStarter != null) {
        _conversationStarterController.text = record.conversationStarter!;
      }
      
      if (record.backgroundMusic != null) {
        _backgroundMusicController.text = record.backgroundMusic!;
      }
      
      if (record.ifReencounter != null) {
        _ifReencounterController.text = record.ifReencounter!;
      }
      
      _tags = List.from(record.tags);
      _selectedEmotion = record.emotion;
      _selectedWeather = List.from(record.weather);
      
      // 预填充高级选项
      _selectedStoryLineId = record.storyLineId;
    } else if (widget.initialStoryLineId != null) {
      // 创建模式下，如果提供了初始故事线ID，则自动关联
      _selectedStoryLineId = widget.initialStoryLineId;
    }
  }

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
      
      final now = DateTime.now();
      
      // 创建或更新记录
      final record = EncounterRecord(
        id: widget.recordToEdit?.id ?? const Uuid().v4(),
        timestamp: _selectedTime,
        location: Location(
          // 编辑模式下保留原有的GPS坐标
          latitude: widget.recordToEdit?.location.latitude,
          longitude: widget.recordToEdit?.location.longitude,
          address: widget.recordToEdit?.location.address,
          placeName: _placeNameController.text.trim().isEmpty 
              ? null 
              : _placeNameController.text.trim(),
          placeType: _selectedPlaceType,
        ),
        description: description.isEmpty ? null : description,
        tags: _tags,
        emotion: _selectedEmotion,
        status: _selectedStatus,
        storyLineId: _selectedStoryLineId, // 使用用户选择的故事线
        conversationStarter: conversationStarter?.isEmpty ?? true ? null : conversationStarter,
        backgroundMusic: backgroundMusic.isEmpty ? null : backgroundMusic,
        weather: _selectedWeather,
        ifReencounter: ifReencounter.isEmpty ? null : ifReencounter,
        createdAt: widget.recordToEdit?.createdAt ?? now,
        updatedAt: now,
      );

      // 直接保存到 Storage，不通过 Provider
      if (widget.isEditMode) {
        await _storage.updateRecord(record);
      } else {
        await _storage.saveRecord(record);
      }

      if (mounted) {
        // 显示成功提示
        MessageHelper.showSuccess(
          context, 
          widget.isEditMode ? '记录已更新' : '记录已保存',
        );

        // 返回上一页，编辑模式返回记录对象，创建模式返回 true
        if (widget.isEditMode) {
          Navigator.of(context).pop(record);
        } else {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showError(
          context, 
          '${widget.isEditMode ? "更新" : "保存"}失败：$e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// 加载地点历史记录
  void _loadPlaceHistory() {
    final records = _storage.getAllRecords();
    
    // 统计每个地点的使用次数和最后使用时间
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
    
    setState(() {
      _placeHistory = placeMap.values.toList();
    });
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
        title: Text(widget.isEditMode ? '编辑记录' : '创建记录'),
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

            // 对话契机（仅邂逅状态显示，带动画）
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  );
                },
                child: _selectedStatus == EncounterStatus.met
                    ? Column(
                        key: const ValueKey('conversation_starter'),
                        children: [
                          _buildConversationStarterSection(),
                          const SizedBox(height: 24),
                        ],
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('empty'),
                      ),
              ),
            ),

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
            const SizedBox(height: 24),

            // 其他设置
            _buildOtherSettingsSection(),
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
          hoverDuration: const Duration(milliseconds: 300),
          borderRadius: BorderRadius.circular(8),
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
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _placeNameController,
                decoration: InputDecoration(
                  hintText: '例如：地铁10号线、星巴克...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.location_on),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: _showPlaceHistoryDialog,
              icon: const Icon(Icons.history),
              tooltip: '历史地点',
            ),
          ],
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
  
  /// 显示历史地点选择对话框
  Future<void> _showPlaceHistoryDialog() async {
    PlaceSortType currentSort = PlaceSortType.timeDesc;
    
    final selected = await DialogHelper.show<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 根据当前排序方式排序
          List<PlaceHistoryItem> sortedPlaces = List.from(_placeHistory);
          switch (currentSort) {
            case PlaceSortType.usageDesc:
              sortedPlaces.sort((a, b) => b.usageCount.compareTo(a.usageCount));
              break;
            case PlaceSortType.usageAsc:
              sortedPlaces.sort((a, b) => a.usageCount.compareTo(b.usageCount));
              break;
            case PlaceSortType.timeDesc:
              sortedPlaces.sort((a, b) => b.lastUsedTime.compareTo(a.lastUsedTime));
              break;
            case PlaceSortType.timeAsc:
              sortedPlaces.sort((a, b) => a.lastUsedTime.compareTo(b.lastUsedTime));
              break;
          }
          
          return AlertDialog(
            title: Row(
              children: [
                const Text('选择历史地点'),
                const Spacer(),
                PopupMenuButton<PlaceSortType>(
                  icon: const Icon(Icons.sort),
                  tooltip: '排序方式',
                  onSelected: (PlaceSortType type) {
                    setDialogState(() {
                      currentSort = type;
                    });
                  },
                  itemBuilder: (context) => PlaceSortType.values.map((type) {
                    return PopupMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          if (currentSort == type)
                            const Icon(Icons.check, size: 20)
                          else
                            const SizedBox(width: 20),
                          const SizedBox(width: 8),
                          Text(type.label),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: sortedPlaces.isEmpty
                  ? Center(
                      child: Text(
                        '暂无历史地点',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: sortedPlaces.length,
                      itemBuilder: (context, index) {
                        final item = sortedPlaces[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(item.placeName),
                          subtitle: Text(
                            '使用 ${item.usageCount} 次 · ${_formatDate(item.lastUsedTime)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              final confirm = await DialogHelper.show<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('确认删除'),
                                  content: Text(
                                    '确定要删除地点"${item.placeName}"的历史记录吗？\n\n这不会删除相关的记录，只是从历史列表中移除。',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('删除'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirm == true) {
                                setDialogState(() {
                                  _placeHistory.removeWhere((p) => p.placeName == item.placeName);
                                });
                                setState(() {
                                  // 同步外部状态
                                });
                              }
                            },
                          ),
                          onTap: () => Navigator.of(context).pop(item.placeName),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
            ],
          );
        },
      ),
    );
    
    if (selected != null) {
      setState(() {
        _placeNameController.text = selected;
      });
    }
  }
  
  /// 格式化日期（相对时间）
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return '今天';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} 周前';
    } else if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()} 月前';
    } else {
      return '${(diff.inDays / 365).floor()} 年前';
    }
  }
  
  /// 显示场所类型选择对话框
  Future<void> _showPlaceTypeDialog() async {
    final selected = await DialogHelper.show<PlaceType>(
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
              final isRemoving = _removingTagNames.contains(tagWithNote.tag);
              final isAdding = _addingTagNames.contains(tagWithNote.tag);
              
              // 添加时从0到1，删除时从1到0，正常时保持1
              final scale = (isAdding || isRemoving) ? 0.0 : 1.0;
              final opacity = (isAdding || isRemoving) ? 0.0 : 1.0;
              
              return AnimatedScale(
                key: ValueKey('scale_${tagWithNote.tag}'),
                scale: scale,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: opacity,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Chip(
                    label: Text(tagWithNote.tag),
                    onDeleted: () => _removeTagWithAnimation(tagWithNote),
                  ),
                ),
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
  
  /// 删除标签（带动画）
  void _removeTagWithAnimation(TagWithNote tagWithNote) async {
    // 标记为删除中，触发动画
    setState(() {
      _removingTagNames.add(tagWithNote.tag);
    });
    
    // 等待动画完成
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 从列表中移除
    if (mounted) {
      setState(() {
        _tags.remove(tagWithNote);
        _removingTagNames.remove(tagWithNote.tag); // 删除完成后清除标记
      });
    }
  }
  
  /// 删除天气（带动画）
  void _removeWeatherWithAnimation(Weather weather) async {
    // 标记为删除中，触发动画
    setState(() {
      _removingWeatherValues.add(weather.value);
    });
    
    // 等待动画完成
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 从列表中移除
    if (mounted) {
      setState(() {
        _selectedWeather.remove(weather);
        _removingWeatherValues.remove(weather.value); // 删除完成后清除标记
      });
    }
  }
  
  /// 显示添加标签对话框
  Future<void> _showAddTagDialog() async {
    final tagController = TextEditingController();
    final noteController = TextEditingController();
    
    final result = await DialogHelper.show<TagWithNote>(
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
                // 检查是否已存在同名标签
                final isDuplicate = _tags.any((t) => t.tag == tag);
                if (isDuplicate) {
                  MessageHelper.showWarning(context, '该标签已存在');
                  return;
                }
                
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
      // 先标记为添加中
      setState(() {
        _addingTagNames.add(result.tag);
        _tags.add(result);
      });
      
      // 等待一帧后触发动画
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        setState(() {
          _addingTagNames.remove(result.tag);
        });
      }
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
            hintText: '记录当时在听的歌曲，格式：歌名 - 歌手',
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
              '（可选，支持多选）',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 已选择的天气（带添加/删除动画）
        if (_selectedWeather.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedWeather.map((weather) {
                final isRemoving = _removingWeatherValues.contains(weather.value);
                final isAdding = _addingWeatherValues.contains(weather.value);
                
                // 添加时从0到1，删除时从1到0，正常时保持1
                final scale = (isAdding || isRemoving) ? 0.0 : 1.0;
                final opacity = (isAdding || isRemoving) ? 0.0 : 1.0;
                
                return AnimatedScale(
                  key: ValueKey('scale_${weather.value}'),
                  scale: scale,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    opacity: opacity,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Chip(
                      avatar: Text(weather.icon),
                      label: Text(weather.label),
                      onDeleted: () => _removeWeatherWithAnimation(weather),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        
        // 按分类显示天气选项
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: WeatherCategory.values.map((category) {
              final weathersInCategory = Weather.values
                  .where((w) => w.category == category)
                  .toList();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 分类标题
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 8),
                    child: Row(
                      children: [
                        Text(
                          category.icon,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 该分类下的天气选项
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: weathersInCategory.map((weather) {
                      final isSelected = _selectedWeather.contains(weather);
                      
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(weather.icon),
                            const SizedBox(width: 4),
                            Text(weather.label),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) async {
                          if (selected) {
                            // 标记为正在添加
                            setState(() {
                              _addingWeatherValues.add(weather.value);
                              // 天空状况只能选一个（互斥）
                              if (category == WeatherCategory.sky) {
                                _selectedWeather.removeWhere(
                                  (w) => w.category == WeatherCategory.sky,
                                );
                              }
                              // 风力只能选一个（互斥）
                              if (category == WeatherCategory.wind) {
                                _selectedWeather.removeWhere(
                                  (w) => w.category == WeatherCategory.wind,
                                );
                              }
                              _selectedWeather.add(weather);
                            });
                            
                            // 等待一帧后触发动画
                            await Future.delayed(const Duration(milliseconds: 50));
                            if (mounted) {
                              setState(() {
                                _addingWeatherValues.remove(weather.value);
                              });
                            }
                          } else {
                            _removeWeatherWithAnimation(weather);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  
                  if (category != WeatherCategory.values.last)
                    const Divider(height: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
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
  
  /// 其他设置区域
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
        
        // 发布到树洞
        CheckboxListTile(
          value: _publishToCommunity,
          onChanged: (value) {
            setState(() {
              _publishToCommunity = value ?? false;
            });
          },
          title: const Text('发布到树洞'),
          subtitle: Text(
            '匿名分享到社区，其他用户可以看到',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        
        const SizedBox(height: 8),
        
        // 关联到故事线
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('关联到故事线'),
          subtitle: _selectedStoryLineId != null
              ? Text(
                  _selectedStoryLineId!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : Text(
                  '将多个相关记录串联成完整故事',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedStoryLineId != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedStoryLineId = null;
                    });
                  },
                  tooltip: '清除',
                ),
              TextButton(
                onPressed: _showStoryLineSelectionDialog,
                child: Text(_selectedStoryLineId != null ? '更改' : '选择'),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// 显示故事线选择对话框
  Future<void> _showStoryLineSelectionDialog() async {
    // TODO: 实现故事线选择对话框
    // 目前故事线功能未实现，先显示提示
    MessageHelper.showInfo(context, '故事线功能待开发');
  }
}

