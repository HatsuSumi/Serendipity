import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';
import '../utils/check_in_reminder_helper.dart';
import '../repositories/check_in_repository.dart';

/// 本地通知服务
/// 
/// 负责本地通知的初始化、调度和取消
/// 
/// 调用者：
/// - main.dart：应用启动时初始化
/// - UserSettingsProvider：用户修改设置时调度/取消通知
/// 
/// 设计原则：
/// - 单一职责：只负责通知相关操作
/// - Fail Fast：初始化失败立即抛出异常
/// - 依赖注入：通过构造函数注入 CheckInRepository
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final CheckInRepository _checkInRepository;

  /// 签到提醒通知ID（固定值，用于更新/取消通知）
  static const int _checkInReminderId = 0;

  /// 通知渠道ID（Android）
  static const String _channelId = 'check_in_reminder';

  /// 通知渠道名称（Android）
  static const String _channelName = '签到提醒';

  /// 通知渠道描述（Android）
  static const String _channelDescription = '每日签到提醒';

  NotificationService(this._checkInRepository)
      : _plugin = FlutterLocalNotificationsPlugin();

  /// 初始化通知服务
  /// 
  /// 必须在使用通知功能前调用
  /// 
  /// 抛出 [StateError] 如果初始化失败
  Future<void> initialize() async {
    // 初始化时区数据
    tz.initializeTimeZones();
    
    // Android 初始化设置
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 初始化设置
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // 稍后手动请求
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _plugin.initialize(initSettings);

    // Fail Fast：初始化失败立即报错
    if (initialized != true) {
      throw StateError('Failed to initialize notification service');
    }
  }

  /// 请求通知权限
  /// 
  /// Android 13+ 和 iOS 需要请求权限
  /// 
  /// 返回 true 如果用户授予权限，否则返回 false
  Future<bool> requestPermission() async {
    // Android 13+ 请求权限
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      if (granted != true) {
        return false;
      }
    }

    // iOS 请求权限
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted != true) {
        return false;
      }
    }

    return true;
  }

  /// 调度签到提醒通知
  /// 
  /// 每天在指定时间发送提醒（只在未签到时发送）
  /// 
  /// [time] 提醒时间，不能为 null
  /// 
  /// 抛出 [ArgumentError] 如果 time 为 null
  Future<void> scheduleCheckInReminder(TimeOfDay time) async {
    // Fail Fast：参数校验
    ArgumentError.checkNotNull(time, 'time');

    // 取消旧的通知（如果存在）
    await cancelCheckInReminder();

    // 计算下一次通知时间
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // 如果今天的时间已过，调度到明天
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // 转换为时区时间
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // 生成通知内容
    final consecutiveDays = _checkInRepository.calculateConsecutiveDays();
    final content = CheckInReminderHelper.generateContent(consecutiveDays);

    // Android 通知详情
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    // iOS 通知详情
    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 调度通知（每天重复）
    await _plugin.zonedSchedule(
      _checkInReminderId,
      CheckInReminderHelper.title,
      content,
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 每天重复
    );
  }

  /// 取消签到提醒通知
  Future<void> cancelCheckInReminder() async {
    await _plugin.cancel(_checkInReminderId);
  }

  /// 检查是否有待处理的通知
  /// 
  /// 返回 true 如果有待处理的签到提醒通知
  Future<bool> hasScheduledCheckInReminder() async {
    final pendingNotifications = await _plugin.pendingNotificationRequests();
    return pendingNotifications.any((n) => n.id == _checkInReminderId);
  }
}

