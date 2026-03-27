import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';
import '../utils/anniversary_helper.dart';
import '../utils/check_in_reminder_helper.dart';
import '../repositories/check_in_repository.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';

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

  /// 纪念日提醒通知ID起始值
  /// 每条邂逅记录对应一个通知，ID = _anniversaryBaseId + index
  static const int _anniversaryBaseId = 100;

  /// 签到提醒渠道
  static const String _channelId = 'check_in_reminder';
  static const String _channelName = '签到提醒';
  static const String _channelDescription = '每日签到提醒';

  /// 纪念日提醒渠道
  static const String _anniversaryChannelId = 'anniversary_reminder';
  static const String _anniversaryChannelName = '纪念日提醒';
  static const String _anniversaryChannelDescription = '邂逅周年纪念日提醒';

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

  /// 调度纪念日提醒通知
  ///
  /// 根据"邂逅"记录列表，为每条今年尚未触发的周年记录调度一次性通知。
  /// 调度前先取消旧的所有纪念日通知，保证幂等。
  ///
  /// [records] 全量记录列表（仅会处理 EncounterStatus.encountered 的记录）
  /// [notifyHour]   通知时间（小时），默认 0 点
  /// [notifyMinute] 通知时间（分钟），默认 0 分
  ///
  /// 调用者：
  /// - UserSettingsNotifier._scheduleAnniversaryReminders()
  Future<void> scheduleAnniversaryReminders(
    List<EncounterRecord> records, {
    int notifyHour = 0,
    int notifyMinute = 0,
  }) async {
    // 先取消所有旧的纪念日通知，保证幂等
    await cancelAnniversaryReminders();

    final now = DateTime.now();

    // 收集今年每条邂逅记录对应的提醒日期（月日），去重并按日期排序
    // 用 Map<String, EncounterRecord> 以 'MM-DD' 为 key 去重，保留最早的记录
    final Map<String, EncounterRecord> dateKeyToRecord = {};
    for (final record in records) {
      if (record.status != EncounterStatus.met) continue;
      final ts = record.timestamp;
      // 不包括当年本身
      if (ts.year >= now.year) continue;
      final key =
          '${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';
      // 同一天多条记录，保留最早的那条作为通知代表
      dateKeyToRecord.putIfAbsent(key, () => record);
    }

    if (dateKeyToRecord.isEmpty) return;

    final notificationDetails = NotificationDetails(
      android: const AndroidNotificationDetails(
        _anniversaryChannelId,
        _anniversaryChannelName,
        channelDescription: _anniversaryChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    int index = 0;
    for (final entry in dateKeyToRecord.entries) {
      final record = entry.value;
      final ts = record.timestamp;

      // 计算今年该纪念日的通知时间
      var scheduledDate = DateTime(
        now.year,
        ts.month,
        ts.day,
        notifyHour,
        notifyMinute,
      );

      // 今年该日期已过，跳过（明年由下次调用重新调度）
      if (scheduledDate.isBefore(now)) {
        index++;
        continue;
      }

      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
      final body = AnniversaryHelper.generateNotificationBody(record);

      await _plugin.zonedSchedule(
        _anniversaryBaseId + index,
        AnniversaryHelper.notificationTitle,
        body,
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // 不设置 matchDateTimeComponents：一次性通知，不每年自动重复
        // 每年 App 启动时重新调度，保证文案中的年数始终正确
      );

      index++;
    }
  }

  /// 取消所有纪念日提醒通知
  ///
  /// 调用者：
  /// - scheduleAnniversaryReminders()：重新调度前先清空
  /// - UserSettingsNotifier：用户关闭纪念日提醒时调用
  Future<void> cancelAnniversaryReminders() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final n in pending) {
      if (n.id >= _anniversaryBaseId) {
        await _plugin.cancel(n.id);
      }
    }
  }
}

