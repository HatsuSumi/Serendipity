import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/anniversary_helper.dart';
import '../utils/check_in_reminder_helper.dart';
import '../repositories/check_in_repository.dart';
import '../repositories/i_remote_data_repository.dart';
import '../../models/encounter_record.dart';
import '../../models/enums.dart';
import '../../models/user_settings.dart';
import 'i_storage_service.dart';

/// 测试通知调度结果
///
/// 调用者：
/// - DevToolsPage：根据结果展示准确反馈
///
enum TestNotificationResult {
  scheduled,
  permissionDenied,
  unsupportedPlatform,
  schedulingFailed,
}

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
  final IRemoteDataRepository? _remoteDataRepository;
  final IStorageService? _storageService;
  bool _isInitialized = false;
  final DateTime Function() _nowProvider;

  /// 签到提醒通知ID（固定值，用于更新/取消通知）
  static const int _checkInReminderId = 0;
  static const String _checkInReminderPayload = 'check_in_reminder';

  /// 纪念日提醒通知ID起始值
  /// 每条邂逅记录对应一个通知，ID = _anniversaryBaseId + index
  static const int _anniversaryBaseId = 100;

  /// 签到提醒渠道
  static const String _channelId = 'check_in_reminder';
  static const String _channelName = '签到提醒';
  static const String _channelDescription = '每日签到提醒';
  static const String _serverCheckInPayload = 'server_check_in_reminder';

  /// 纪念日提醒渠道
  static const String _anniversaryChannelId = 'anniversary_reminder';
  static const String _anniversaryChannelName = '纪念日提醒';
  static const String _anniversaryChannelDescription = '邂逅周年纪念日提醒';
  static const String _serverAnniversaryPayload = 'server_anniversary_reminder';

  NotificationService(
    this._checkInRepository, {
    IRemoteDataRepository? remoteDataRepository,
    IStorageService? storageService,
    FlutterLocalNotificationsPlugin? plugin,
    DateTime Function()? nowProvider,
  })  : _remoteDataRepository = remoteDataRepository,
        _storageService = storageService,
        _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _nowProvider = nowProvider ?? DateTime.now;

  /// 初始化通知服务
  /// 
  /// 必须在使用通知功能前调用
  /// 
  /// 抛出 [StateError] 如果初始化失败
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

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

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationResponse,
    );

    // Fail Fast：初始化失败立即报错
    if (initialized != true) {
      throw StateError('Failed to initialize notification service');
    }

    await _createAndroidNotificationChannels();
    await _configureFirebaseMessageHandlers();

    _isInitialized = true;
  }

  Future<void> _configureFirebaseMessageHandlers() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundRemoteMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageOpenedApp);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await _handleRemoteMessageOpenedApp(initialMessage);
    }
  }

  Future<void> _createAndroidNotificationChannels() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) {
      return;
    }

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _anniversaryChannelId,
        _anniversaryChannelName,
        description: _anniversaryChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _handleForegroundRemoteMessage(RemoteMessage message) async {
    await _showRemoteMessageNotification(message);
  }

  Future<void> _handleRemoteMessageOpenedApp(RemoteMessage message) async {}

  Future<void> _showRemoteMessageNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    final title = notification?.title ?? _resolveRemoteMessageTitle(data);
    final body = notification?.body ?? _resolveRemoteMessageBody(data);
    if (title == null || body == null) {
      return;
    }

    final payload = _resolveRemoteMessagePayload(data);
    final channelId = payload == _serverAnniversaryPayload
        ? _anniversaryChannelId
        : _channelId;
    final channelName = payload == _serverAnniversaryPayload
        ? _anniversaryChannelName
        : _channelName;
    final channelDescription = payload == _serverAnniversaryPayload
        ? _anniversaryChannelDescription
        : _channelDescription;

    await _plugin.show(
      message.messageId.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  String _resolveRemoteMessagePayload(Map<String, dynamic> data) {
    return switch (data['type']) {
      'anniversary_reminder' || 'anniversary_reminder_test' => _serverAnniversaryPayload,
      _ => _serverCheckInPayload,
    };
  }

  String? _resolveRemoteMessageTitle(Map<String, dynamic> data) {
    final title = data['title'];
    return title is String && title.trim().isNotEmpty ? title : null;
  }

  String? _resolveRemoteMessageBody(Map<String, dynamic> data) {
    final body = data['body'];
    return body is String && body.trim().isNotEmpty ? body : null;
  }

  /// Fail Fast：确保通知服务已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('NotificationService must be initialized before use');
    }
  }

  /// 请求通知权限
  /// 
  /// Android 13+ 和 iOS 需要请求权限
  /// 
  /// 返回 true 如果用户授予权限，否则返回 false
  Future<bool> requestPermission() async {
    _ensureInitialized();

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
  /// [userId] 当前用户 ID，null 表示离线数据
  /// 
  /// 抛出 [ArgumentError] 如果 time 为 null
  Future<void> scheduleCheckInReminder(TimeOfDay time, {String? userId}) async {
    _ensureInitialized();

    // Fail Fast：参数校验
    ArgumentError.checkNotNull(time, 'time');

    await _scheduleNextCheckInReminder(time, userId: userId);
  }

  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationResponse(NotificationResponse response) {}

  Future<void> _handleNotificationResponse(NotificationResponse response) async {
    if (response.payload != _checkInReminderPayload) {
      return;
    }

    final settings = await _loadCurrentUserSettings();
    if (settings == null || !settings.checkInReminderEnabled) {
      await cancelCheckInReminder();
      return;
    }

    await _scheduleNextCheckInReminder(settings.checkInReminderTime);
  }

  Future<void> _scheduleNextCheckInReminder(TimeOfDay time, {String? userId}) async {
    await cancelCheckInReminder();

    final now = _nowProvider();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    final consecutiveDays = _checkInRepository.calculateReminderStreakDays(userId: userId);
    final maxConsecutiveDays = _checkInRepository.calculateMaxConsecutiveDays(userId: userId);
    final content = CheckInReminderHelper.generateContent(
      consecutiveDays: consecutiveDays,
      maxConsecutiveDays: maxConsecutiveDays,
    );

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _checkInReminderId,
      CheckInReminderHelper.title,
      content,
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: _checkInReminderPayload,
    );
  }

  Future<UserSettings?> _loadCurrentUserSettings() async {
    return _storageService?.getUserSettings();
  }

  /// 取消签到提醒通知
  Future<void> cancelCheckInReminder() async {
    _ensureInitialized();
    await _plugin.cancel(_checkInReminderId);
  }

  /// 检查是否有待处理的通知
  /// 
  /// 返回 true 如果有待处理的签到提醒通知
  Future<bool> hasScheduledCheckInReminder() async {
    _ensureInitialized();
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
    _ensureInitialized();

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
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
    _ensureInitialized();
    final pending = await _plugin.pendingNotificationRequests();
    for (final n in pending) {
      if (n.id >= _anniversaryBaseId) {
        await _plugin.cancel(n.id);
      }
    }
  }

  /// 发送服务端签到提醒测试推送（开发测试用）
  Future<TestNotificationResult> sendServerTestCheckInNotification() async {
    if (_remoteDataRepository == null) {
      return TestNotificationResult.unsupportedPlatform;
    }

    try {
      final result = await _remoteDataRepository.sendCheckInReminderTest();
      final sentCount = result['sentCount'] as int? ?? 0;
      return sentCount > 0
          ? TestNotificationResult.scheduled
          : TestNotificationResult.schedulingFailed;
    } catch (_) {
      return TestNotificationResult.schedulingFailed;
    }
  }

  /// 发送服务端纪念日测试推送（开发测试用）
  Future<TestNotificationResult> sendServerTestAnniversaryNotification() async {
    if (_remoteDataRepository == null) {
      return TestNotificationResult.unsupportedPlatform;
    }

    try {
      final result = await _remoteDataRepository.sendAnniversaryReminderTest();
      final sentCount = result['sentCount'] as int? ?? 0;
      return sentCount > 0
          ? TestNotificationResult.scheduled
          : TestNotificationResult.schedulingFailed;
    } catch (_) {
      return TestNotificationResult.schedulingFailed;
    }
  }

  /// 发送签到提醒测试通知（开发测试用）
  ///
  /// 5 秒后触发一条签到提醒通知，用于验证通知权限和渠道配置。
  /// 不受当前提醒时间设置影响。
  /// [userId] 当前用户 ID，null 表示离线数据
  ///
  /// 调用者：ProfilePage 开发测试区
  Future<TestNotificationResult> sendTestCheckInNotification({String? userId}) async {
    if (kIsWeb) {
      return TestNotificationResult.unsupportedPlatform;
    }

    final granted = await requestPermission();
    if (!granted) {
      return TestNotificationResult.permissionDenied;
    }

    final now = DateTime.now();
    final scheduledDate = tz.TZDateTime.from(
      now.add(const Duration(seconds: 5)),
      tz.local,
    );

    final consecutiveDays = _checkInRepository.calculateReminderStreakDays(userId: userId);
    final maxConsecutiveDays = _checkInRepository.calculateMaxConsecutiveDays(userId: userId);
    final content = CheckInReminderHelper.generateContent(
      consecutiveDays: consecutiveDays,
      maxConsecutiveDays: maxConsecutiveDays,
    );

    try {
      await _plugin.zonedSchedule(
        _checkInReminderId + 998,
        CheckInReminderHelper.title,
        '$content（测试通知）',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return TestNotificationResult.scheduled;
    } catch (e) {
      return TestNotificationResult.schedulingFailed;
    }
  }

  /// 发送纪念日测试通知（开发测试用）
  ///
  /// 5 秒后触发一条固定文案的通知，用于验证通知权限和渠道配置。
  /// 不依赖任何记录数据。
  ///
  /// 调用者：ProfilePage 开发测试区
  Future<TestNotificationResult> sendTestAnniversaryNotification() async {
    if (kIsWeb) {
      return TestNotificationResult.unsupportedPlatform;
    }

    final granted = await requestPermission();
    if (!granted) {
      return TestNotificationResult.permissionDenied;
    }

    final now = DateTime.now();
    final scheduledDate = tz.TZDateTime.from(
      now.add(const Duration(seconds: 5)),
      tz.local,
    );

    try {
      await _plugin.zonedSchedule(
        _anniversaryBaseId + 999,
        AnniversaryHelper.notificationTitle,
        '1年前的今天，你在某个地方邂逅了TA（测试通知）',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _anniversaryChannelId,
            _anniversaryChannelName,
            channelDescription: _anniversaryChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return TestNotificationResult.scheduled;
    } catch (e) {
      return TestNotificationResult.schedulingFailed;
    }
  }
}

