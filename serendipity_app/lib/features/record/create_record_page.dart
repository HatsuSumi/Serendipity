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

part 'create_record_page_body.dart';
part 'create_record_page_sections.dart';
part 'create_record_page_status_and_description_sections.dart';
part 'create_record_page_additional_info_sections.dart';
part 'create_record_page_location_section.dart';
part 'create_record_page_location_status.dart';
part 'create_record_page_location_actions.dart';
part 'create_record_page_help_dialogs.dart';
part 'create_record_page_ignore_gps_help_dialog.dart';
part 'create_record_page_record_guide_dialog.dart';
part 'create_record_page_other_settings_section.dart';
part 'create_record_page_story_line_section.dart';
part 'create_record_page_story_line_actions.dart';
part 'create_record_page_reminder_dialogs.dart';
part 'create_record_page_form_state.dart';
part 'create_record_page_save_action.dart';
part 'create_record_page_location_flow_actions.dart';
part 'create_record_page_publish_status_actions.dart';
part 'create_record_page_time_actions.dart';

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
  void _updateState(VoidCallback fn) {
    setState(fn);
  }

  late ColorScheme _colorScheme;

  final _formKey = GlobalKey<FormState>();
  final _placeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _conversationStarterController = TextEditingController();
  final _backgroundMusicController = TextEditingController();
  final _ifReencounterController = TextEditingController();
  
  DateTime _selectedTime = DateTime.now();
  EncounterStatus? _selectedStatus;
  
  PlaceType? _selectedPlaceType;
  EmotionIntensity? _selectedEmotion;
  List<Weather> _selectedWeather = [];
  List<TagWithNote> _tags = [];
  
  bool _publishToCommunity = false;
  String? _selectedStoryLineId;
  
  String? _publishStatus;
  
  final _formChangedNotifier = ValueNotifier<int>(0);
  Timer? _debounceTimer;
  
  bool _isSaving = false;
  
  List<PlaceHistoryItem> _placeHistory = [];
  
  bool _ignoreGPS = false;

  @override
  void initState() {
    super.initState();
    _loadPlaceHistory();
    _initializeFormData();
    
    if (!widget.isEditMode) {
      Future.microtask(() => _requestLocation());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPublishStatus();
      });
      
      _placeNameController.addListener(_onFormChanged);
      _descriptionController.addListener(_onFormChanged);
      _conversationStarterController.addListener(_onFormChanged);
      _backgroundMusicController.addListener(_onFormChanged);
      _ifReencounterController.addListener(_onFormChanged);
    }
  }
  
  void _onFormChanged() {
    _debounceTimer?.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _formChangedNotifier.value++;
      }
    });
  }

  @override
  void dispose() {
    if (widget.isEditMode) {
      _placeNameController.removeListener(_onFormChanged);
      _descriptionController.removeListener(_onFormChanged);
      _conversationStarterController.removeListener(_onFormChanged);
      _backgroundMusicController.removeListener(_onFormChanged);
      _ifReencounterController.removeListener(_onFormChanged);
    }
    
    _debounceTimer?.cancel();
    _formChangedNotifier.dispose();
    _placeNameController.dispose();
    _descriptionController.dispose();
    _conversationStarterController.dispose();
    _backgroundMusicController.dispose();
    _ifReencounterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CreateRecordPageBody(this);
  }
}
