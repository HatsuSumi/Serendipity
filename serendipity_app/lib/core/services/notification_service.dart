import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../models/user_settings.dart';
import '../repositories/check_in_repository.dart';
import '../repositories/i_remote_data_repository.dart'
    show IRemoteDataRepository, RepositoryServerTestPushSummary;
import '../utils/check_in_reminder_helper.dart';
import 'i_storage_service.dart';
import 'push_models.dart';

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
  Future<bool>? _activePermissionRequest;

  /// 签到提醒通知ID（固定值，用于更新/取消通知）
  static const int _checkInReminderId = 0;
  static const String _checkInReminderPayload = 'check_in_reminder';

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

    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
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
      onDidReceiveBackgroundNotificationResponse:
          _handleBackgroundNotificationResponse,
    );

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
      'anniversary_reminder' || 'anniversary_reminder_test' =>
        _serverAnniversaryPayload,
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

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('NotificationService must be initialized before use');
    }
  }

  Future<bool> requestPermission() async {
    _ensureInitialized();

    final activeRequest = _activePermissionRequest;
    if (activeRequest != null) {
      return activeRequest;
    }

    final requestFuture = _performPermissionRequest();
    _activePermissionRequest = requestFuture;
    try {
      return await requestFuture;
    } finally {
      if (identical(_activePermissionRequest, requestFuture)) {
        _activePermissionRequest = null;
      }
    }
  }

  Future<bool> _performPermissionRequest() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      if (granted != true) {
        return false;
      }
    }

    final iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
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

  Future<void> scheduleCheckInReminder(TimeOfDay time, {String? userId}) async {
    _ensureInitialized();
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
    final consecutiveDays =
        _checkInRepository.calculateReminderStreakDays(userId: userId);
    final maxConsecutiveDays =
        _checkInRepository.calculateMaxConsecutiveDays(userId: userId);
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

  Future<void> cancelCheckInReminder() async {
    _ensureInitialized();
    await _plugin.cancel(_checkInReminderId);
  }

  Future<bool> hasScheduledCheckInReminder() async {
    _ensureInitialized();
    final pendingNotifications = await _plugin.pendingNotificationRequests();
    return pendingNotifications.any((n) => n.id == _checkInReminderId);
  }

  Future<ServerPushTestResult> sendServerTestCheckInNotification() async {
    if (_remoteDataRepository == null) {
      return const ServerPushTestResult(
        status: TestNotificationResult.unsupportedPlatform,
        message: '当前环境未配置服务端推送测试能力',
      );
    }

    final granted = await requestPermission();
    if (!granted) {
      return const ServerPushTestResult(
        status: TestNotificationResult.permissionDenied,
        message: '通知权限未授予，无法发送测试推送',
      );
    }

    try {
      final result = await _remoteDataRepository.sendCheckInReminderTest();
      return _buildServerPushTestResult(
        result,
        successPrefix: '服务端已提交签到提醒测试推送',
      );
    } catch (error) {
      return ServerPushTestResult(
        status: TestNotificationResult.schedulingFailed,
        message: '签到提醒测试推送发送失败',
        details: error.toString(),
      );
    }
  }

  Future<ServerPushTestResult> sendServerTestAnniversaryNotification() async {
    if (_remoteDataRepository == null) {
      return const ServerPushTestResult(
        status: TestNotificationResult.unsupportedPlatform,
        message: '当前环境未配置服务端推送测试能力',
      );
    }

    final granted = await requestPermission();
    if (!granted) {
      return const ServerPushTestResult(
        status: TestNotificationResult.permissionDenied,
        message: '通知权限未授予，无法发送测试推送',
      );
    }

    try {
      final result = await _remoteDataRepository.sendAnniversaryReminderTest();
      return _buildServerPushTestResult(
        result,
        successPrefix: '服务端已提交纪念日测试推送',
      );
    } catch (error) {
      return ServerPushTestResult(
        status: TestNotificationResult.schedulingFailed,
        message: '纪念日测试推送发送失败',
        details: error.toString(),
      );
    }
  }

  ServerPushTestResult _buildServerPushTestResult(
    RepositoryServerTestPushSummary summary, {
    required String successPrefix,
  }) {
    final details =
        '${summary.toShortText()}；该结果只表示服务端已提交到 provider，设备是否收到仍取决于系统与网络环境';

    if (summary.sentCount <= 0) {
      return ServerPushTestResult(
        status: TestNotificationResult.schedulingFailed,
        message: '服务端未成功提交任何测试推送',
        details: details,
        summary: summary,
      );
    }

    return ServerPushTestResult(
      status: TestNotificationResult.scheduled,
      message: '$successPrefix，请检查设备通知与当前网络环境',
      details: details,
      summary: summary,
    );
  }

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

    final consecutiveDays =
        _checkInRepository.calculateReminderStreakDays(userId: userId);
    final maxConsecutiveDays =
        _checkInRepository.calculateMaxConsecutiveDays(userId: userId);
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
    } catch (_) {
      return TestNotificationResult.schedulingFailed;
    }
  }

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
        999,
        '今天是一个特别的纪念日 🌸',
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
    } catch (_) {
      return TestNotificationResult.schedulingFailed;
    }
  }
}
