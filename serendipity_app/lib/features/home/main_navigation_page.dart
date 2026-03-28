import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/anniversary_reminder_provider.dart';
import '../../core/providers/records_provider.dart';
import '../../core/providers/message_provider.dart';
import '../../core/providers/achievement_provider.dart';
import '../../core/utils/message_helper.dart';
import '../../core/utils/navigation_helper.dart';
import '../../core/widgets/achievement_unlocked_dialog.dart';
import '../../models/encounter_record.dart';
import '../timeline/timeline_page.dart';
import '../story_line/story_lines_page.dart';
import '../community/community_page.dart';
import '../settings/profile_page.dart';
import '../record/create_record_page.dart';
import '../achievement/achievements_page.dart';
import 'anniversary_reminder_dialog.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  int _currentIndex = 0;

  /// 显示成就解锁对话框
  /// 
  /// 提取为独立方法，使代码更清晰，避免嵌套过深
  Future<void> _showAchievementDialog(List<String> achievementIds) async {
    if (!mounted) return;
    
    final result = await AchievementUnlockedDialog.show(context, achievementIds);
    
    // 用户点击"查看成就"，跳转到成就页面
    if (mounted && result == 'view') {
      NavigationHelper.pushWithTransition(
        context,
        ref,
        const AchievementsPage(),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    
    // 在下一帧检查是否有待显示的消息和纪念日提醒
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingMessage();
      _checkAnniversaryReminder();
    });
  }

  /// 检查是否有待显示的全局消息
  void _checkPendingMessage() {
    final message = ref.read(messageProvider);
    if (message != null && mounted) {
      switch (message.type) {
        case MessageType.success:
          MessageHelper.showSuccess(context, message.message);
          break;
        case MessageType.error:
          MessageHelper.showError(context, message.message);
          break;
        case MessageType.info:
          MessageHelper.showSuccess(context, message.message);
          break;
      }
      ref.read(messageProvider.notifier).clear();
    }
  }

  /// 检查今天是否有纪念日需要弹窗提醒
  ///
  /// 读取 anniversaryReminderProvider，非空时展示弹窗并标记今天已弹。
  Future<void> _checkAnniversaryReminder() async {
    if (!mounted) return;
    final records = await ref.read(anniversaryReminderProvider.future);
    if (!mounted || records.isEmpty) return;
    await AnniversaryReminderRecord.markShownToday();
    if (!mounted) return;
    await AnniversaryReminderDialog.show(context, records);
  }

  @override
  Widget build(BuildContext context) {
    // 监听全局消息（用于页面已加载后的消息）
    ref.listen<AppMessage?>(messageProvider, (previous, next) {
      if (next != null) {
        // 根据消息类型显示不同的提示
        switch (next.type) {
          case MessageType.success:
            MessageHelper.showSuccess(context, next.message);
            break;
          case MessageType.error:
            MessageHelper.showError(context, next.message);
            break;
          case MessageType.info:
            // 暂时使用 showSuccess，以后可以添加 showInfo
            MessageHelper.showSuccess(context, next.message);
            break;
        }
        
        // 清除消息，避免重复显示
        Future.microtask(() {
          ref.read(messageProvider.notifier).clear();
        });
      }
    });
    
    // 监听成就解锁通知
    ref.listen<List<String>>(newlyUnlockedAchievementsProvider, (previous, next) {
      if (next.isNotEmpty) {
        // 显示成就解锁对话框
        // 由于成就检测现在在页面关闭后才触发，导航栈已经清晰，可以直接显示
        _showAchievementDialog(next);
        
        // 清空通知列表
        ref.read(newlyUnlockedAchievementsProvider.notifier).clear();
      }
    });
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const TimelinePage(), // 时间轴
          const StoryLinesPage(), // 故事线
          CommunityPage(isVisible: _currentIndex == 2), // 社区页面
          const ProfilePage(), // 我的
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'TA',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: '故事线',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud),
            label: '树洞',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              heroTag: 'create_record_fab',
              onPressed: () async {
                // 使用 Navigator.push 以便自定义动画
                final result = await Navigator.of(context).push<dynamic>(
                  PageRouteBuilder(
                    opaque: false, // 允许透过新页面看到底层
                    barrierColor: Colors.black54, // 添加半透明遮罩
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return const CreateRecordPage();
                    },
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      // 从底部滑入动画
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOutCubic;
                      
                      var slideTween = Tween(begin: begin, end: end).chain(
                        CurveTween(curve: curve),
                      );
                      
                      return SlideTransition(
                        position: animation.drive(slideTween),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                    reverseTransitionDuration: const Duration(milliseconds: 400),
                  ),
                );
                
                // 如果创建成功，让 Provider 失效并自动重新加载
                if (result is bool && result == true && mounted) {
                  ref.invalidate(recordsProvider);
                  
                  // 页面已关闭，现在可以安全地检测成就
                  // 注意：这里无法获取到 record 对象，所以需要从最新的记录列表中获取
                  // 由于刚刚 invalidate，需要等待 Provider 重新加载
                  final recordsAsync = await ref.read(recordsProvider.future);
                  if (recordsAsync.isNotEmpty && mounted) {
                    // 获取最新创建的记录（按 createdAt 排序，取最新的）
                    final latestRecord = recordsAsync.reduce((a, b) => 
                      a.createdAt.isAfter(b.createdAt) ? a : b
                    );
                    
                    // 检测成就
                    await ref.read(recordsProvider.notifier).checkAchievementsForRecord(latestRecord);
                  }
                } else if (result is EncounterRecord && mounted) {
                  // 编辑模式返回了更新后的记录
                  ref.invalidate(recordsProvider);
                  
                  // 页面已关闭，检测成就
                  await ref.read(recordsProvider.notifier).checkAchievementsForRecord(result);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('创建记录'),
            )
          : null,
    );
  }
}

