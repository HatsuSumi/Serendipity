import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/anniversary_reminder_provider.dart';
import '../../core/providers/records_provider.dart';
import '../../core/providers/message_provider.dart';
import '../../core/providers/achievement_provider.dart';
import '../../core/providers/auth_provider.dart';
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
import '../auth/login_page.dart';
import 'anniversary_reminder_dialog.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  int _currentIndex = 0;
  bool _isShowingAchievementDialog = false;

  /// 显示成就解锁对话框
  ///
  /// 仅在主页重新成为当前路由后消费待展示成就，
  /// 避免创建记录页尚未 pop 完成时抢占导航结果。
  Future<void> _showAchievementDialog(List<String> achievementIds) async {
    if (!mounted || _isShowingAchievementDialog) {
      return;
    }

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      return;
    }

    _isShowingAchievementDialog = true;
    ref.read(newlyUnlockedAchievementsProvider.notifier).clear();

    try {
      final result = await AchievementUnlockedDialog.show(context, achievementIds);

      if (mounted && result == 'view') {
        NavigationHelper.pushWithTransition(
          context,
          ref,
          const AchievementsPage(),
        );
      }
    } finally {
      _isShowingAchievementDialog = false;
      if (mounted) {
        Future.microtask(_consumePendingAchievementDialog);
      }
    }
  }

  Future<void> _consumePendingAchievementDialog() async {
    if (!mounted || _isShowingAchievementDialog) {
      return;
    }

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      return;
    }

    final pendingAchievementIds = ref.read(newlyUnlockedAchievementsProvider);
    if (pendingAchievementIds.isEmpty) {
      return;
    }

    await _showAchievementDialog(List<String>.from(pendingAchievementIds));
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingMessage();
      _checkAnniversaryReminder();
      _consumePendingAchievementDialog();
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
    ref.listen<AsyncValue<Object?>>(authProvider, (previous, next) {
      final wasLoggedIn = previous?.valueOrNull != null;
      final isLoggedOut = next.valueOrNull == null && !next.isLoading;
      if (wasLoggedIn && isLoggedOut && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    });

    ref.listen<AppMessage?>(messageProvider, (previous, next) {
      if (next != null) {
        switch (next.type) {
          case MessageType.success:
            MessageHelper.showSuccess(context, next.message);
            break;
          case MessageType.error:
            MessageHelper.showError(context, next.message);
            break;
          case MessageType.info:
            MessageHelper.showSuccess(context, next.message);
            break;
        }

        Future.microtask(() {
          ref.read(messageProvider.notifier).clear();
        });
      }
    });

    ref.listen<List<String>>(newlyUnlockedAchievementsProvider, (previous, next) {
      if (next.isNotEmpty) {
        Future.microtask(_consumePendingAchievementDialog);
      }
    });

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const TimelinePage(),
          const StoryLinesPage(),
          CommunityPage(isVisible: _currentIndex == 2),
          const ProfilePage(),
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
                final result = await Navigator.of(context).push<dynamic>(
                  PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.black54,
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return const CreateRecordPage();
                    },
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOutCubic;

                      final slideTween = Tween(begin: begin, end: end).chain(
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

                if (result is bool && result == true && mounted) {
                  ref.invalidate(recordsProvider);
                  Future.microtask(_consumePendingAchievementDialog);
                } else if (result is EncounterRecord && mounted) {
                  ref.invalidate(recordsProvider);
                  Future.microtask(_consumePendingAchievementDialog);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('创建记录'),
            )
          : null,
    );
  }
}
