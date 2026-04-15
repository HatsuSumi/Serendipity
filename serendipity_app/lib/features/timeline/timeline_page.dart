// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../core/providers/records_provider.dart';
import '../../core/providers/records_filter_provider.dart';
import '../../core/providers/story_lines_provider.dart';
import '../../core/providers/community_provider.dart';
import '../../core/providers/favorites_provider.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/navigation_helper.dart';
import '../../core/utils/record_helper.dart';
import '../../core/utils/date_time_helper.dart';
import '../../core/utils/check_in_animation_helper.dart';
import '../../core/utils/async_action_helper.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/theme/status_color_extension.dart';

import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/common_filter_widgets.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';
import '../record/record_detail_page.dart';
import '../record/create_record_page.dart';
import '../record/widgets/record_export_card.dart';
import '../story_line/link_to_story_line_dialog.dart';
import '../community/dialogs/publish_warning_dialog.dart';
import '../check_in/widgets/check_in_card.dart';
import 'record_filter_dialog.dart';

part 'timeline_page_app_bar.dart';
part 'timeline_page_list.dart';
part 'timeline_page_record_card_sections.dart';
part 'timeline_page_record_card_content_section.dart';
part 'timeline_page_record_card_additional_fields_section.dart';
part 'timeline_page_record_card.dart';
part 'timeline_page_navigation_actions.dart';
part 'timeline_page_publish_delete_actions.dart';
part 'timeline_page_actions.dart';

/// 排序方式
enum RecordSortType {
  createdDesc('创建时间 ↓'),
  createdAsc('创建时间 ↑'),
  updatedDesc('更新时间 ↓'),
  updatedAsc('更新时间 ↑');

  final String label;
  const RecordSortType(this.label);
}

/// 时间轴页面（记录列表）
class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  // 当前排序方式（默认创建时间降序）
  RecordSortType _currentSort = RecordSortType.createdDesc;
  
  // 是否打码敏感信息
  bool _isMasked = false;
  
  // 粒子效果控制器
  ConfettiController? _confettiController;

  // 滚动控制器（用于分页加载）
  final ScrollController _scrollController = ScrollController();

  // 主题颜色缓存（每次 build 从 Provider 更新，子方法直接使用）
  late ColorScheme _colorScheme;
  late TextTheme _textTheme;
  
  @override
  void initState() {
    super.initState();
    _confettiController = CheckInAnimationHelper.createConfettiController();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _confettiController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听：接近底部时触发加载更多
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // 距离底部 200px 时触发
    if (position.pixels >= position.maxScrollExtent - 200) {
      final notifier = ref.read(recordsProvider.notifier);
      if (notifier.hasMore) {
        notifier.loadMore();
      }
    }
  }

  void _selectSortType(RecordSortType type) {
    setState(() {
      _currentSort = type;
    });
  }

  void _toggleMask(BuildContext context) {
    setState(() {
      _isMasked = !_isMasked;
    });
    MessageHelper.showSuccess(
      context,
      _isMasked ? '已打码敏感信息' : '已显示原始信息',
    );
  }

  @override
  Widget build(BuildContext context) {
    _colorScheme = Theme.of(context).colorScheme;
    _textTheme = Theme.of(context).textTheme;
    final filterCriteria = ref.watch(recordsFilterProvider);
    final countAsync = ref.watch(recordsCountProvider);

    return Scaffold(
      appBar: _buildAppBar(context, filterCriteria, countAsync),
      body: Stack(
        children: [
          // 主内容：使用后端筛选
          _buildFilteredRecordList(context, ref, filterCriteria),
          // 粒子效果（覆盖在整个页面最顶层）
          if (_confettiController != null)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: CheckInAnimationHelper.createConfettiWidget(
                  controller: _confettiController!,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建错误 Widget
  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, Object? error) {
    final errorMessage = error != null 
        ? AuthErrorHelper.extractErrorMessage(error)
        : '加载失败';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 根据排序方式排序记录
  /// 
  /// 置顶记录始终在最前面，然后按照选择的排序方式排序
  List<EncounterRecord> _sortRecords(List<EncounterRecord> records) {
    final sorted = List<EncounterRecord>.from(records);
    
    // 一次性排序：先按置顶状态，再按选择的排序方式
    sorted.sort((a, b) {
      // 1. 置顶记录优先
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      // 2. 都是置顶或都不是置顶，按照选择的排序方式
      switch (_currentSort) {
        case RecordSortType.createdDesc:
          return b.createdAt.compareTo(a.createdAt);
        case RecordSortType.createdAsc:
          return a.createdAt.compareTo(b.createdAt);
        case RecordSortType.updatedDesc:
          return b.updatedAt.compareTo(a.updatedAt);
        case RecordSortType.updatedAsc:
          return a.updatedAt.compareTo(b.updatedAt);
      }
    });
    
    return sorted;
  }

}
