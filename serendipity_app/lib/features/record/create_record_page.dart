import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/providers/records_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/date_time_helper.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../models/encounter_record.dart';
import '../../models/story_line.dart';
import '../../models/enums.dart';
import 'models/place_history_item.dart';
import 'widgets/story_line_selection_dialog.dart';
import 'widgets/place_history_dialog.dart';
import 'widgets/tags_section.dart';
import 'widgets/weather_selection_section.dart';
import 'widgets/location_permission_dialog.dart';
import '../community/dialogs/publish_warning_dialog.dart';

/// 创建/编辑记录页面
class CreateRecordPage extends ConsumerStatefulWidget {
  /// 要编辑的记录（如果为null则是创建模式）
  final EncounterRecord? recordToEdit;
  
  /// 初始故事线ID（创建记录时自动关联）
  final String? initialStoryLineId;
  
  /// 初始是否发布到树洞（创建记录时自动勾选）
  final bool initialPublishToCommunity;
  
  const CreateRecordPage({
    super.key,
    this.recordToEdit,
    this.initialStoryLineId,
    this.initialPublishToCommunity = false,
  });
  
  /// 是否为编辑模式
  bool get isEditMode => recordToEdit != null;

  @override
  ConsumerState<CreateRecordPage> createState() => _CreateRecordPageState();
}

class _CreateRecordPageState extends ConsumerState<CreateRecordPage> {
  // 表单控制器
  final _formKey = GlobalKey<FormState>();
  final _placeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _conversationStarterController = TextEditingController();
  final _backgroundMusicController = TextEditingController();
  final _ifReencounterController = TextEditingController();
  
  // 必填字段
  DateTime _selectedTime = DateTime.now();
  EncounterStatus? _selectedStatus;
  
  // 可选字段
  PlaceType? _selectedPlaceType;
  EmotionIntensity? _selectedEmotion;
  List<Weather> _selectedWeather = [];
  List<TagWithNote> _tags = [];
  
  // 高级选项
  bool _publishToCommunity = false;
  String? _selectedStoryLineId;
  
  // 发布状态（编辑模式下使用）
  String? _publishStatus; // null: 未检查, 'can_publish': 未发布, 'need_confirm': 已发布, 'cannot_publish': 已发布且无变化
  
  // 表单变化通知器（编辑模式下使用，用于实时更新发布状态UI）
  final _formChangedNotifier = ValueNotifier<int>(0);
  Timer? _debounceTimer;
  
  // 是否正在保存
  bool _isSaving = false;
  
  // 地点历史记录（包含统计信息）
  List<PlaceHistoryItem> _placeHistory = [];
  
  // GPS 定位状态
  bool _ignoreGPS = false; // 是否忽略 GPS 定位

  @override
  void initState() {
    super.initState();
    _loadPlaceHistory();
    _initializeFormData();
    
    // 创建模式下自动获取 GPS 定位
    if (!widget.isEditMode) {
      // 使用 Future.microtask 延迟调用，避免在 build 期间修改 provider
      Future.microtask(() => _requestLocation());
    } else {
      // 编辑模式下检查发布状态
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPublishStatus();
      });
      
      // 编辑模式下监听输入框变化，实时更新发布状态UI
      _placeNameController.addListener(_onFormChanged);
      _descriptionController.addListener(_onFormChanged);
      _conversationStarterController.addListener(_onFormChanged);
      _backgroundMusicController.addListener(_onFormChanged);
      _ifReencounterController.addListener(_onFormChanged);
    }
  }
  
  /// 表单内容变化时触发（编辑模式下使用）
  /// 
  /// 使用防抖优化性能：
  /// - 不是每次输入都立即更新UI
  /// - 停止输入300ms后才触发更新
  void _onFormChanged() {
    // 取消之前的定时器
    _debounceTimer?.cancel();
    
    // 设置新的定时器
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        // 通知 ValueListenableBuilder 重建
        _formChangedNotifier.value++;
      }
    });
  }
  
  /// 请求 GPS 定位
  /// 
  /// 优化说明：
  /// - 移除了本地状态管理（_isLocating, _locationResult）
  /// - 直接使用 LocationProvider 的状态
  /// - 减少状态同步的复杂度
  Future<void> _requestLocation() async {
    try {
      // 先检查权限
      await ref.read(locationProvider.notifier).checkPermission();
      final hasPermission = ref.read(locationProvider).hasPermission ?? false;
      
      if (!hasPermission) {
        // 请求权限
        final granted = await ref.read(locationProvider.notifier).requestPermission();
        
        if (!granted && mounted) {
          // 权限被拒绝，显示引导对话框
          await _showPermissionDialog();
          return;
        }
      }
      
      // 获取位置
      await ref.read(locationProvider.notifier).getCurrentLocation();
    } catch (e) {
      // 错误已经在 Provider 中处理，这里不需要额外处理
    }
  }
  
  /// 检查发布状态（编辑模式下使用）
  Future<void> _checkPublishStatus() async {
    if (!widget.isEditMode || widget.recordToEdit == null) return;
    
    try {
      final communityNotifier = ref.read(communityProvider.notifier);
      final statusMap = await communityNotifier.checkPublishStatus([widget.recordToEdit!]);
      final status = statusMap[widget.recordToEdit!.id] ?? 'can_publish';
      
      if (mounted) {
        setState(() {
          _publishStatus = status;
        });
      }
    } catch (e) {
      // 检查失败，默认为未发布
      if (mounted) {
        setState(() {
          _publishStatus = 'can_publish';
        });
      }
    }
  }
  
  /// 显示权限引导对话框
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
      
      // 编辑模式：检查是否有GPS数据
      // 如果没有GPS数据（latitude/longitude为null），默认勾选"忽略GPS"
      if (record.location.latitude == null || record.location.longitude == null) {
        _ignoreGPS = true;
      }
      
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
    } else {
      // 创建模式：使用初始参数
      if (widget.initialStoryLineId != null) {
        _selectedStoryLineId = widget.initialStoryLineId;
      }
      if (widget.initialPublishToCommunity) {
        _publishToCommunity = true;
      }
    }
  }

  @override
  void dispose() {
    // 清理监听器
    if (widget.isEditMode) {
      _placeNameController.removeListener(_onFormChanged);
      _descriptionController.removeListener(_onFormChanged);
      _conversationStarterController.removeListener(_onFormChanged);
      _backgroundMusicController.removeListener(_onFormChanged);
      _ifReencounterController.removeListener(_onFormChanged);
    }
    
    // 清理定时器
    _debounceTimer?.cancel();
    
    // 清理通知器
    _formChangedNotifier.dispose();
    
    // 清理控制器
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

    // Fail Fast: 验证状态是否已选择
    if (_selectedStatus == null) {
      MessageHelper.showWarning(context, '请选择状态');
      return;
    }

    // Fail Fast: 如果勾选了"发布到社区"，先显示警告对话框
    if (_publishToCommunity) {
      final authState = ref.read(authProvider);
      final currentUser = authState.value;
      
      if (currentUser == null) {
        MessageHelper.showError(context, '请先登录后再发布到树洞');
        return;
      }
      
      // 显示警告对话框，用户确认后才继续保存
      final shouldPublish = await PublishWarningDialog.show(context, ref);
      
      if (!shouldPublish) {
        // 用户取消发布，取消勾选
        setState(() {
          _publishToCommunity = false;
        });
        return;
      }
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
        location: widget.isEditMode
            ? widget.recordToEdit!.location.copyWith(
                // 编辑模式：如果重新定位了，使用新的GPS数据；如果勾选了"忽略GPS"，清除GPS数据
                latitude: () => _ignoreGPS 
                    ? null 
                    : (ref.read(locationProvider).result?.latitude ?? widget.recordToEdit!.location.latitude),
                longitude: () => _ignoreGPS 
                    ? null 
                    : (ref.read(locationProvider).result?.longitude ?? widget.recordToEdit!.location.longitude),
                address: () => _ignoreGPS 
                    ? null 
                    : (ref.read(locationProvider).result?.address ?? widget.recordToEdit!.location.address),
                placeName: () => _placeNameController.text.trim().isEmpty 
                    ? null 
                    : _placeNameController.text.trim(),
                placeType: () => _selectedPlaceType,
              )
            : Location(
                // 创建模式：直接从 Provider 读取定位结果
                latitude: _ignoreGPS ? null : ref.read(locationProvider).result?.latitude,
                longitude: _ignoreGPS ? null : ref.read(locationProvider).result?.longitude,
                address: _ignoreGPS ? null : ref.read(locationProvider).result?.address,
                placeName: _placeNameController.text.trim().isEmpty 
                    ? null 
                    : _placeNameController.text.trim(),
                placeType: _selectedPlaceType,
              ),
        description: description.isEmpty ? null : description,
        tags: _tags,
        emotion: _selectedEmotion,
        status: _selectedStatus!,  // 使用 ! 断言非空（已在上面验证）
        storyLineId: _selectedStoryLineId, // 使用用户选择的故事线
        conversationStarter: conversationStarter?.isEmpty ?? true ? null : conversationStarter,
        backgroundMusic: backgroundMusic.isEmpty ? null : backgroundMusic,
        weather: _selectedWeather,
        ifReencounter: ifReencounter.isEmpty ? null : ifReencounter,
        createdAt: widget.recordToEdit?.createdAt ?? now,
        updatedAt: now,
      );

      // 通过 Provider 保存，自动处理故事线关联
      if (widget.isEditMode) {
        await ref.read(recordsProvider.notifier).updateRecord(record);
      } else {
        await ref.read(recordsProvider.notifier).saveRecord(record);
      }

      // 如果勾选了"发布到树洞"，发布到社区（已经通过警告对话框确认）
      if (_publishToCommunity && mounted) {
        // 编辑模式下，如果之前已发布过（_publishStatus 不是 'can_publish'），则需要 forceReplace
        final forceReplace = widget.isEditMode && _publishStatus != 'can_publish';
        await ref.read(communityProvider.notifier).publishPost(record, forceReplace: forceReplace);
      }

      if (mounted) {
        // 显示成功提示
        MessageHelper.showSuccess(
          context, 
          widget.isEditMode ? '记录已更新' : '记录已保存',
        );

        // 如果是创建"再遇"状态的记录，且关联了故事线，显示"如果再遇"提醒
        if (!widget.isEditMode && 
            _selectedStatus == EncounterStatus.reencounter && 
            _selectedStoryLineId != null) {
          await _showIfReencounterReminderIfNeeded();
        }

        // 异步操作后再次检查 mounted
        if (!mounted) return;

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
          '${widget.isEditMode ? "更新" : "保存"}失败：${AuthErrorHelper.extractErrorMessage(e)}',
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

  /// 显示"如果再遇"提醒（如果需要）
  Future<void> _showIfReencounterReminderIfNeeded() async {
    try {
      // 通过 Provider 获取故事线中的所有记录
      final recordsAsync = ref.read(recordsProvider);
      final allRecords = recordsAsync.value ?? [];
      final records = allRecords.where((r) => r.storyLineId == _selectedStoryLineId).toList();
      
      // 查找所有有"如果再遇"备忘的记录（不限制状态）
      // 重要：排除当前正在创建的记录（通过时间戳判断，因为刚创建的记录时间最新）
      final now = DateTime.now();
      final recordsWithMemo = records.where((record) =>
        record.ifReencounter != null &&
        record.ifReencounter!.isNotEmpty &&
        // 排除刚刚创建的记录（时间差小于1秒的记录）
        now.difference(record.createdAt).inSeconds > 1
      ).toList();
      
      // 如果没有找到，直接返回
      if (recordsWithMemo.isEmpty) {
        return;
      }
      
      // 按时间倒序排序，显示最近的一条
      recordsWithMemo.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final latestRecord = recordsWithMemo.first;
      
      // 显示提醒对话框
      await DialogHelper.show(
        context: context,
        builder: (context) => _buildIfReencounterReminderDialog(latestRecord),
      );
    } catch (e) {
      // 出错时不影响流程，静默失败
    }
  }

  /// 构建"如果再遇"提醒对话框
  Widget _buildIfReencounterReminderDialog(EncounterRecord record) {
    return AlertDialog(
      title: Row(
        children: [
          const Text('💭 '),
          Expanded(
            child: Text(
              '还记得你说过的话吗？',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 提示文字
          Text(
            '在 ${_formatReminderDate(record.timestamp)} ${record.status.label}时，你写下了：',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          
          // "如果再遇"备忘内容
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Text(
              '"${record.ifReencounter}"',
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 鼓励文字
          Text(
            '现在，你们再次相遇了！✨',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ],
    );
  }

  /// 格式化提醒日期
  String _formatReminderDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '今天';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}周前';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}个月前';
    } else {
      return DateTimeHelper.formatChineseDate(date);
    }
  }

  /// 加载地点历史记录
  void _loadPlaceHistory() {
    final recordsAsync = ref.read(recordsProvider);
    final records = recordsAsync.value ?? [];
    
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
        
        // 编辑模式下通知表单变化
        if (widget.isEditMode) {
          _onFormChanged();
        }
      }
    }
  }

  /// 检查是否有未保存的修改（用于返回拦截）
  /// 
  /// 遵循架构原则：
  /// - 编辑模式：对比当前值与原始值，检测是否真的有修改
  /// - 创建模式：检查是否填写了任何内容
  bool _hasUnsavedChanges() {
    // 编辑模式：对比当前值与原始值
    if (widget.isEditMode) {
      final original = widget.recordToEdit!;
      
      // 检查时间是否修改
      if (_selectedTime != original.timestamp) {
        return true;
      }
      
      // 检查状态是否修改
      if (_selectedStatus != original.status) {
        return true;
      }
      
      // 检查地点名称是否修改
      final currentPlaceName = _placeNameController.text.trim();
      final originalPlaceName = original.location.placeName ?? '';
      if (currentPlaceName != originalPlaceName) {
        return true;
      }
      
      // 检查场所类型是否修改
      if (_selectedPlaceType != original.location.placeType) {
        return true;
      }
      
      // 检查描述是否修改
      final currentDescription = _descriptionController.text.trim();
      final originalDescription = original.description ?? '';
      if (currentDescription != originalDescription) {
        return true;
      }
      
      // 检查对话契机是否修改
      final currentConversationStarter = _conversationStarterController.text.trim();
      final originalConversationStarter = original.conversationStarter ?? '';
      if (currentConversationStarter != originalConversationStarter) {
        return true;
      }
      
      // 检查背景音乐是否修改
      final currentBackgroundMusic = _backgroundMusicController.text.trim();
      final originalBackgroundMusic = original.backgroundMusic ?? '';
      if (currentBackgroundMusic != originalBackgroundMusic) {
        return true;
      }
      
      // 检查"如果再遇"是否修改
      final currentIfReencounter = _ifReencounterController.text.trim();
      final originalIfReencounter = original.ifReencounter ?? '';
      if (currentIfReencounter != originalIfReencounter) {
        return true;
      }
      
      // 检查标签是否修改（比较数量和内容）
      if (_tags.length != original.tags.length) {
        return true;
      }
      for (int i = 0; i < _tags.length; i++) {
        if (_tags[i].tag != original.tags[i].tag || 
            _tags[i].note != original.tags[i].note) {
          return true;
        }
      }
      
      // 检查情绪强度是否修改
      if (_selectedEmotion != original.emotion) {
        return true;
      }
      
      // 检查天气是否修改（比较数量和内容）
      if (_selectedWeather.length != original.weather.length) {
        return true;
      }
      final originalWeatherSet = original.weather.toSet();
      final currentWeatherSet = _selectedWeather.toSet();
      if (!currentWeatherSet.containsAll(originalWeatherSet) || 
          !originalWeatherSet.containsAll(currentWeatherSet)) {
        return true;
      }
      
      // 检查故事线是否修改
      if (_selectedStoryLineId != original.storyLineId) {
        return true;
      }
      
      // 所有字段都没有修改
      return false;
    }
    
    // 创建模式：检查是否有任何输入
    // 注意：时间和GPS定位是自动获取的，不算用户输入
    return _selectedStatus != null ||  // 选择了状态
        _placeNameController.text.trim().isNotEmpty ||  // 输入了地点名称
        _selectedPlaceType != null ||  // 选择了场所类型
        _descriptionController.text.trim().isNotEmpty ||  // 输入了描述
        _tags.isNotEmpty ||  // 添加了标签
        _selectedEmotion != null ||  // 选择了情绪强度
        _conversationStarterController.text.trim().isNotEmpty ||  // 输入了对话契机
        _backgroundMusicController.text.trim().isNotEmpty ||  // 输入了背景音乐
        _selectedWeather.isNotEmpty ||  // 选择了天气
        _ifReencounterController.text.trim().isNotEmpty ||  // 输入了"如果再遇"
        _publishToCommunity ||  // 勾选了发布到树洞
        _selectedStoryLineId != null;  // 选择了故事线
  }
  
  /// 检查记录内容是否有修改（仅检查会显示在社区的字段）
  /// 
  /// 用于判断是否需要重新发布到社区
  /// 
  /// 根据 PublishWarningDialog 的说明，社区帖子包含以下字段：
  /// - 错过时间、发布时间、地址、地点名称、场所类型、省市区、描述、标签、状态
  /// 
  /// 社区帖子不包含以下字段（不检查）：
  /// - 精确GPS坐标、情绪强度、对话契机、背景音乐、天气、"如果再遇"备忘、故事线
  bool _hasContentChanges() {
    if (!widget.isEditMode) return false;
    
    final original = widget.recordToEdit!;
    
    // 检查时间是否修改（错过时间）
    if (_selectedTime != original.timestamp) {
      return true;
    }
    
    // 检查状态是否修改
    if (_selectedStatus != original.status) {
      return true;
    }
    
    // 检查地点名称是否修改
    final currentPlaceName = _placeNameController.text.trim();
    final originalPlaceName = original.location.placeName ?? '';
    if (currentPlaceName != originalPlaceName) {
      return true;
    }
    
    // 检查场所类型是否修改
    if (_selectedPlaceType != original.location.placeType) {
      return true;
    }
    
    // 检查描述是否修改
    final currentDescription = _descriptionController.text.trim();
    final originalDescription = original.description ?? '';
    if (currentDescription != originalDescription) {
      return true;
    }
    
    // 检查标签是否修改（比较数量和内容）
    if (_tags.length != original.tags.length) {
      return true;
    }
    for (int i = 0; i < _tags.length; i++) {
      if (_tags[i].tag != original.tags[i].tag || 
          _tags[i].note != original.tags[i].note) {
        return true;
      }
    }
    
    // 注意：以下字段不会显示在社区，不检查
    // - 对话契机（conversationStarter）
    // - 背景音乐（backgroundMusic）
    // - "如果再遇"备忘（ifReencounter）
    // - 情绪强度（emotion）
    // - 天气（weather）
    // - 故事线（storyLineId）
    // - 精确GPS坐标（latitude/longitude）
    
    return false;
  }
  
  /// 显示未保存修改确认对话框
  Future<bool> _showUnsavedChangesDialog() async {
    final result = await DialogHelper.show<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃修改？'),
        content: Text(
          widget.isEditMode 
              ? '你有未保存的修改，确定要放弃吗？'
              : '你填写的内容还未保存，确定要放弃吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续编辑'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('放弃'),
          ),
        ],
      ),
    );
    
    return result ?? false;  // 用户点击外部关闭对话框，视为取消
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,  // 禁止直接返回
      onPopInvokedWithResult: (didPop, result) async {
        // 如果已经 pop 了，不需要处理
        if (didPop) {
          return;
        }
        
        // 检查是否有未保存的修改
        if (_hasUnsavedChanges()) {
          // 显示确认对话框
          final shouldPop = await _showUnsavedChangesDialog();
          
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          // 没有修改，直接返回
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
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
    ),
    );
  }

  /// 时间选择区域
  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '⏰ 时间',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
                  DateTimeHelper.formatDateTime(_selectedTime),
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
        
        // GPS 定位状态显示（创建模式和编辑模式都显示）
        _buildLocationStatus(),
        const SizedBox(height: 12),
        
        // 忽略 GPS 定位选项（创建模式和编辑模式都显示）
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                value: _ignoreGPS,
                onChanged: (value) {
                  setState(() {
                    _ignoreGPS = value ?? false;
                  });
                  
                  // 编辑模式下通知表单变化
                  if (widget.isEditMode) {
                    _onFormChanged();
                  }
                },
                title: const Text('忽略 GPS 定位'),
                subtitle: Text(
                  '只使用下面输入的地点名称（用于UI显示）',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.help_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => _showIgnoreGPSHelpDialog(context),
              tooltip: '为什么要忽略GPS？',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 12),
        
        // 引导文字 + 说明
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '地点名称（可选）',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '可以写地址，也可以取个名字',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 地点名称输入
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _placeNameController,
                decoration: InputDecoration(
                  hintText: '例如：地铁10号线、常去的咖啡馆',
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
        
        // 场所类型标题
        Text(
          '场所类型（可选）',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        
        // 场所类型选择
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
                
                // 编辑模式下通知表单变化
                if (widget.isEditMode) {
                  _onFormChanged();
                }
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
  
  /// 构建 GPS 定位状态显示
  /// 
  /// 优化说明：
  /// - 直接使用 LocationProvider 的状态
  /// - 使用 ref.watch 监听状态变化
  /// - 自动响应状态更新，无需手动 setState
  /// - 编辑模式：显示已保存的GPS信息，允许重新定位
  Widget _buildLocationStatus() {
    // 直接读取 Provider 状态
    final locationState = ref.watch(locationProvider);
    
    // 编辑模式：优先显示已保存的GPS信息
    if (widget.isEditMode && widget.recordToEdit != null) {
      final location = widget.recordToEdit!.location;
      final hasGPS = location.latitude != null && location.longitude != null;
      
      // 如果有已保存的GPS信息
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
      
      // 如果没有GPS信息（之前勾选了"忽略GPS"）
      if (!hasGPS && !locationState.isLoading && locationState.result == null) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '当时创建记录时勾选了"忽略GPS"',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    
    // 定位中
    if (locationState.isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
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
    
    // 定位成功
    if (locationState.result?.isSuccess == true) {
      final result = locationState.result!;
      final address = result.address ?? '位置已获取';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                      color: Theme.of(context).colorScheme.primary,
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
    
    // 定位失败
    if (locationState.result?.isSuccess == false) {
      final result = locationState.result!;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
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
                      color: Theme.of(context).colorScheme.error,
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
    
    // 初始状态：还未开始定位（不应该出现，但作为兜底）
    return const SizedBox.shrink();
  }
  
  /// 显示历史地点选择对话框
  Future<void> _showPlaceHistoryDialog() async {
    final selected = await DialogHelper.show<String>(
      context: context,
      builder: (context) => PlaceHistoryDialog(
        placeHistory: _placeHistory,
        onHistoryChanged: () {
          setState(() {
            // 触发重新加载
            _loadPlaceHistory();
          });
        },
      ),
    );
    
    if (selected != null) {
      setState(() {
        _placeNameController.text = selected;
      });
      
      // 编辑模式下通知表单变化
      if (widget.isEditMode) {
        _onFormChanged();
      }
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
      
      // 编辑模式下通知表单变化
      if (widget.isEditMode) {
        _onFormChanged();
      }
    }
  }

  /// 状态选择区域
  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '💫 状态',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            // 帮助图标
            IconButton(
              icon: Icon(
                Icons.help_outline,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => _showRecordGuideDialog(context),
              tooltip: '如何记录？',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ],
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
                  
                  // 编辑模式下通知表单变化
                  if (widget.isEditMode) {
                    _onFormChanged();
                  }
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 显示忽略GPS帮助对话框
  void _showIgnoreGPSHelpDialog(BuildContext context) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('💡 '),
            Expanded(
              child: Text(
                '为什么要忽略GPS？',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '延迟记录场景',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '通勤路上擦肩而过的瞬间，往往无法立即记录：',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                context,
                '早上在地铁站看到 TA',
                '当时在赶路，没时间掏出手机（走路一般不看手机）',
              ),
              const SizedBox(height: 8),
              _buildHelpItem(
                context,
                '回到公司/家后才想起来记录',
                '此时GPS定位已经变成了公司/家的地址',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ 勾选"忽略GPS定位"后：',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '不会保存当前的GPS坐标\n'
                      '只使用你手动输入的地点名称\n'
                      '适合延迟记录的场景',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '注意：时间字段也会自动获取当前时间，延迟记录时记得手动调整。',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '提示：路上快速看一眼时间，比看具体地点更快更安全。',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                '💡 编辑模式下的"事后补救"',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '如果昨天延迟记录时GPS定位错了，今天又路过同一地点：',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _buildHelpItem(
                context,
                '打开昨天的记录进入编辑模式',
                '点击"重新定位"按钮获取正确的GPS坐标',
              ),
              const SizedBox(height: 8),
              _buildHelpItem(
                context,
                '或者如果想清除错误的GPS数据',
                '勾选"忽略GPS定位"，只保留地点名称',
              ),
              const SizedBox(height: 16),
              Divider(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                '❓ 既然位置可能不准，为什么不提供地图选点功能？',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '高德地图 Flutter 插件与当前 Flutter 版本不兼容（使用了已废弃的 API），暂时无法提供地图选点功能。',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '目前的替代方案：\n'
                'GPS 自动定位 + 手动输入地点名称\n'
                '使用"忽略 GPS"+ 完全手动输入\n'
                '使用地点历史记录快速选择\n'
                '编辑模式下"事后补救"重新定位',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  /// 构建帮助项
  Widget _buildHelpItem(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  /// 显示记录引导对话框
  void _showRecordGuideDialog(BuildContext context) {
    DialogHelper.show(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('💡 '),
            Expanded(
              child: Text(
                '如何记录？',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '每次见面 = 一条新记录',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '例如：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _buildGuideItem(
                context,
                '今天在地铁看到 TA',
                '→ 创建记录，选择"错过"',
              ),
              const SizedBox(height: 8),
              _buildGuideItem(
                context,
                '明天看到 TA，但低头假装没看见',
                '→ 创建新记录，选择"回避"',
              ),
              const SizedBox(height: 8),
              _buildGuideItem(
                context,
                '后天看到 TA，鼓起勇气看了一眼（没说话）',
                '→ 创建新记录，选择"再遇"',
              ),
              const SizedBox(height: 8),
              _buildGuideItem(
                context,
                '大后天又看到 TA（还是没说话）',
                '→ 创建新记录，还是选择"再遇"',
              ),
              const SizedBox(height: 8),
              _buildGuideItem(
                context,
                '第 N 天终于说话了',
                '→ 创建新记录，选择"邂逅"',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '然后通过"故事线"功能把这些记录关联起来',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '💡 什么时候停止记录？',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '邂逅后如果继续在一起，就不用再记录了\n'
                      '但如果经历了"别离"或"失联"，之后又"重逢"，可以继续记录，即邂逅→别离/失联→重逢',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '关于状态间的区别详见关于页面',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  /// 构建引导项
  Widget _buildGuideItem(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
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
    return TagsSection(
      tags: _tags,
      onTagsChanged: (updatedTags) {
        setState(() {
          _tags = updatedTags;
        });
        
        // 编辑模式下通知表单变化
        if (widget.isEditMode) {
          _onFormChanged();
        }
      },
    );
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
                
                // 编辑模式下通知表单变化
                if (widget.isEditMode) {
                  _onFormChanged();
                }
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
    return WeatherSelectionSection(
      selectedWeather: _selectedWeather,
      onWeatherChanged: (updatedWeather) {
        setState(() {
          _selectedWeather = updatedWeather;
        });
        
        // 编辑模式下通知表单变化
        if (widget.isEditMode) {
          _onFormChanged();
        }
      },
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
    // 通过 Provider 获取故事线名称（如果已关联）
    String? storyLineName;
    if (_selectedStoryLineId != null) {
      final storyLinesAsync = ref.read(storyLinesProvider);
      final storyLines = storyLinesAsync.value ?? [];
      try {
        final storyLine = storyLines.firstWhere((sl) => sl.id == _selectedStoryLineId);
        storyLineName = storyLine.name;
      } catch (e) {
        // 未找到故事线
        storyLineName = null;
      }
    }
    
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
        
        // 发布到树洞（根据模式和状态动态显示）
        _buildPublishToCommunitySection(),
        
        const SizedBox(height: 8),
        
        // 关联到故事线
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('关联到故事线'),
          subtitle: storyLineName != null
              ? Row(
                  children: [
                    const Text('📖 '),
                    Expanded(
                      child: Text(
                        storyLineName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
                    
                    // 编辑模式下通知表单变化
                    if (widget.isEditMode) {
                      _onFormChanged();
                    }
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
  
  /// 构建发布到树洞区域
  /// 
  /// 根据模式和状态动态显示：
  /// - 创建模式：显示"发布到树洞"复选框
  /// - 编辑模式 + 未发布：显示"发布到树洞"复选框
  /// - 编辑模式 + 已发布 + 无修改：显示"已发布到社区，内容无变化，无法再次发布"
  /// - 编辑模式 + 已发布 + 有修改：显示"重新发布到社区"复选框
  /// 
  /// 性能优化：
  /// - 使用 ValueListenableBuilder 只重建此区域
  /// - 使用防抖减少频繁更新
  Widget _buildPublishToCommunitySection() {
    // 创建模式：显示普通复选框
    if (!widget.isEditMode) {
      return CheckboxListTile(
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
      );
    }
    
    // 编辑模式：使用 ValueListenableBuilder 监听表单变化
    return ValueListenableBuilder<int>(
      valueListenable: _formChangedNotifier,
      builder: (context, _, __) {
        // 还在检查发布状态
        if (_publishStatus == null) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: const Text('检查发布状态...'),
          );
        }
        
        // 未发布：显示普通复选框
        if (_publishStatus == 'can_publish') {
          return CheckboxListTile(
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
          );
        }
        
        // 已发布：检查记录内容是否有修改（排除故事线）
        final hasContentChanges = _hasContentChanges();
        
        // 已发布 + 无内容修改：显示灰色提示
        if (!hasContentChanges) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_done,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '内容无变化，无法再次发布',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        
        // 已发布 + 有修改：显示"重新发布到社区"复选框
        return CheckboxListTile(
          value: _publishToCommunity,
          onChanged: (value) {
            setState(() {
              _publishToCommunity = value ?? false;
            });
          },
          title: const Text('重新发布到社区'),
          subtitle: Text(
            '内容已修改，勾选后将替换旧帖',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }
  
  /// 显示故事线选择对话框
  Future<void> _showStoryLineSelectionDialog() async {
    final storyLinesAsync = ref.read(storyLinesProvider);
    
    // 直接获取数据，不使用 await
    final storyLines = storyLinesAsync.when(
      data: (data) => data,
      loading: () => <StoryLine>[],
      error: (_, _) => <StoryLine>[],
    );
    
    if (!mounted) return;
    
    final result = await DialogHelper.show<String>(
      context: context,
      builder: (context) => StoryLineSelectionDialog(
        storyLines: storyLines,
        currentStoryLineId: _selectedStoryLineId,
      ),
    );
    
    if (result != null && mounted) {
      setState(() {
        _selectedStoryLineId = result;
      });
      
      // 编辑模式下通知表单变化
      if (widget.isEditMode) {
        _onFormChanged();
      }
    }
  }
}

