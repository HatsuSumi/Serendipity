import 'package:flutter/material.dart';
import 'enums.dart';

/// 用户设置
/// 
/// 设计说明：
/// - 每个设置分组都有独立的 updatedAt 时间戳
/// - 跨设备同步时，比较字段级别的时间戳，取最新版本
/// - 避免因为单一时间戳相同而丢失其他字段的修改
class UserSettings {
  final String id;
  final String userId;
  
  // 主题设置
  final ThemeOption theme;
  final String? accentColor;
  final PageTransitionType pageTransition;
  final DialogAnimationType dialogAnimation;
  final DateTime themeUpdatedAt; // 主题和页面切换动画的更新时间
  final DateTime accentColorUpdatedAt; // 强调色的更新时间（独立追踪）
  
  // 通知设置
  final bool achievementNotification;
  final bool anniversaryReminder;
  final bool checkInReminderEnabled;
  final TimeOfDay checkInReminderTime;
  final DateTime notificationsUpdatedAt; // 通知设置的更新时间
  
  // 签到设置
  final bool checkInVibrationEnabled;
  final bool checkInConfettiEnabled;
  final DateTime checkInUpdatedAt; // 签到设置的更新时间
  
  // 社区设置
  final bool hidePublishWarning;
  final bool hasSeenPublishWarning;
  final bool hasSeenCommunityIntro;
  final DateTime communityUpdatedAt; // 社区设置的更新时间
  
  final DateTime createdAt;
  final DateTime updatedAt; // 整体更新时间（用于排序）

  UserSettings({
    required this.id,
    required this.userId,
    required this.theme,
    this.accentColor,
    required this.pageTransition,
    required this.dialogAnimation,
    required this.themeUpdatedAt,
    required this.accentColorUpdatedAt,
    required this.achievementNotification,
    required this.anniversaryReminder,
    required this.checkInReminderEnabled,
    required this.checkInReminderTime,
    required this.notificationsUpdatedAt,
    required this.checkInVibrationEnabled,
    required this.checkInConfettiEnabled,
    required this.checkInUpdatedAt,
    required this.hidePublishWarning,
    required this.hasSeenPublishWarning,
    required this.hasSeenCommunityIntro,
    required this.communityUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(id.isNotEmpty, 'ID cannot be empty'),
       assert(userId.isNotEmpty, 'User ID cannot be empty'),
       assert(accentColor == null || accentColor.startsWith('#'), 
         'Accent color must be a valid hex color starting with #');

  /// 创建默认设置
  factory UserSettings.createDefault({required String userId}) {
    final now = DateTime.now();
    return UserSettings(
      id: 'settings_$userId',
      userId: userId,
      theme: ThemeOption.system,
      accentColor: null,
      pageTransition: PageTransitionType.random,
      dialogAnimation: DialogAnimationType.random,
      themeUpdatedAt: now,
      accentColorUpdatedAt: now,
      achievementNotification: true,
      anniversaryReminder: true,
      checkInReminderEnabled: true,
      checkInReminderTime: const TimeOfDay(hour: 20, minute: 0),
      notificationsUpdatedAt: now,
      checkInVibrationEnabled: true,
      checkInConfettiEnabled: false,
      checkInUpdatedAt: now,
      hidePublishWarning: false,
      hasSeenPublishWarning: false,
      hasSeenCommunityIntro: false,
      communityUpdatedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 从 JSON 创建 UserSettings（本地存储格式）
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    final reminderTimeData = json['checkInReminderTime'];
    final Map<String, dynamic>? reminderTimeMap = reminderTimeData != null
        ? Map<String, dynamic>.from(reminderTimeData as Map)
        : null;
    final reminderTime = reminderTimeMap != null
        ? TimeOfDay(
            hour: reminderTimeMap['hour'] as int,
            minute: reminderTimeMap['minute'] as int,
          )
        : const TimeOfDay(hour: 20, minute: 0);
    
    final now = DateTime.now();
    
    return UserSettings(
      id: json['id'] as String,
      userId: json['userId'] as String,
      theme: ThemeOption.values.firstWhere(
        (e) => e.value == json['theme'] as String,
        orElse: () => throw StateError(
          'Invalid theme value: ${json['theme']}. '
          'Expected one of: ${ThemeOption.values.map((e) => e.value).join(", ")}'
        ),
      ),
      accentColor: json['accentColor'] as String?,
      pageTransition: PageTransitionType.values.firstWhere(
        (e) => e.value == json['pageTransition'] as String,
        orElse: () => PageTransitionType.random,
      ),
      dialogAnimation: DialogAnimationType.values.firstWhere(
        (e) => e.value == json['dialogAnimation'] as String,
        orElse: () => DialogAnimationType.random,
      ),
      themeUpdatedAt: json['themeUpdatedAt'] != null
          ? DateTime.parse(json['themeUpdatedAt'] as String)
          : now,
      accentColorUpdatedAt: json['accentColorUpdatedAt'] != null
          ? DateTime.parse(json['accentColorUpdatedAt'] as String)
          : now,
      achievementNotification: json['achievementNotification'] as bool,
      anniversaryReminder: json['anniversaryReminder'] as bool,
      checkInReminderEnabled: json['checkInReminderEnabled'] as bool? ?? true,
      checkInReminderTime: reminderTime,
      notificationsUpdatedAt: json['notificationsUpdatedAt'] != null
          ? DateTime.parse(json['notificationsUpdatedAt'] as String)
          : now,
      checkInVibrationEnabled: json['checkInVibrationEnabled'] as bool? ?? true,
      checkInConfettiEnabled: json['checkInConfettiEnabled'] as bool? ?? true,
      checkInUpdatedAt: json['checkInUpdatedAt'] != null
          ? DateTime.parse(json['checkInUpdatedAt'] as String)
          : now,
      hidePublishWarning: json['hidePublishWarning'] as bool? ?? false,
      hasSeenPublishWarning: json['hasSeenPublishWarning'] as bool? ?? false,
      hasSeenCommunityIntro: json['hasSeenCommunityIntro'] as bool? ?? false,
      communityUpdatedAt: json['communityUpdatedAt'] != null
          ? DateTime.parse(json['communityUpdatedAt'] as String)
          : now,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 从后端 DTO 创建 UserSettings
  factory UserSettings.fromServerDto(Map<String, dynamic> dto, String userId) {
    final notifications = dto['notifications'] as Map<String, dynamic>;
    final reminderTimeStr = notifications['checkInReminderTime'] as String;
    final timeParts = reminderTimeStr.split(':');
    final reminderHour = int.parse(timeParts[0]);
    final reminderMinute = int.parse(timeParts[1]);
    
    final checkIn = dto['checkIn'] as Map<String, dynamic>;
    final now = DateTime.now();
    final updatedAt = dto['updatedAt'] != null
        ? DateTime.parse(dto['updatedAt'] as String)
        : now;
    
    return UserSettings(
      id: 'settings_$userId',
      userId: userId,
      theme: ThemeOption.values.firstWhere(
        (e) => e.value == dto['theme'] as String,
        orElse: () => ThemeOption.system,
      ),
      accentColor: dto['accentColor'] as String?,
      pageTransition: PageTransitionType.values.firstWhere(
        (e) => e.value == dto['pageTransition'] as String,
        orElse: () => PageTransitionType.random,
      ),
      dialogAnimation: DialogAnimationType.values.firstWhere(
        (e) => e.value == dto['dialogAnimation'] as String,
        orElse: () => DialogAnimationType.random,
      ),
      themeUpdatedAt: updatedAt,
      accentColorUpdatedAt: updatedAt,
      achievementNotification: notifications['achievementUnlocked'] as bool,
      anniversaryReminder: notifications['anniversaryReminder'] as bool? ?? true,
      checkInReminderEnabled: notifications['checkInReminder'] as bool,
      checkInReminderTime: TimeOfDay(hour: reminderHour, minute: reminderMinute),
      notificationsUpdatedAt: updatedAt,
      checkInVibrationEnabled: checkIn['vibrationEnabled'] as bool,
      checkInConfettiEnabled: checkIn['confettiEnabled'] as bool,
      checkInUpdatedAt: updatedAt,
      hidePublishWarning: dto['hidePublishWarning'] as bool? ?? false,
      hasSeenPublishWarning: dto['hasSeenPublishWarning'] as bool? ?? false,
      hasSeenCommunityIntro: dto['hasSeenCommunityIntro'] as bool? ?? false,
      communityUpdatedAt: updatedAt,
      createdAt: now,
      updatedAt: updatedAt,
    );
  }

  /// 转换为 JSON（本地存储用）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'theme': theme.value,
      'accentColor': accentColor,
      'pageTransition': pageTransition.value,
      'dialogAnimation': dialogAnimation.value,
      'themeUpdatedAt': themeUpdatedAt.toIso8601String(),
      'accentColorUpdatedAt': accentColorUpdatedAt.toIso8601String(),
      'achievementNotification': achievementNotification,
      'anniversaryReminder': anniversaryReminder,
      'checkInReminderEnabled': checkInReminderEnabled,
      'checkInReminderTime': {
        'hour': checkInReminderTime.hour,
        'minute': checkInReminderTime.minute,
      },
      'notificationsUpdatedAt': notificationsUpdatedAt.toIso8601String(),
      'checkInVibrationEnabled': checkInVibrationEnabled,
      'checkInConfettiEnabled': checkInConfettiEnabled,
      'checkInUpdatedAt': checkInUpdatedAt.toIso8601String(),
      'hidePublishWarning': hidePublishWarning,
      'hasSeenPublishWarning': hasSeenPublishWarning,
      'hasSeenCommunityIntro': hasSeenCommunityIntro,
      'communityUpdatedAt': communityUpdatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 转换为后端 DTO 格式（用于上传）
  Map<String, dynamic> toServerDto() {
    final hour = checkInReminderTime.hour.toString().padLeft(2, '0');
    final minute = checkInReminderTime.minute.toString().padLeft(2, '0');
    
    return {
      'theme': theme.value,
      'pageTransition': pageTransition.value,
      'dialogAnimation': dialogAnimation.value,
      'notifications': {
        'checkInReminder': checkInReminderEnabled,
        'checkInReminderTime': '$hour:$minute',
        'achievementUnlocked': achievementNotification,
        'anniversaryReminder': anniversaryReminder,
      },
      'checkIn': {
        'vibrationEnabled': checkInVibrationEnabled,
        'confettiEnabled': checkInConfettiEnabled,
      },
      'hasSeenCommunityIntro': hasSeenCommunityIntro,
      'hasSeenPublishWarning': hasSeenPublishWarning,
      'hidePublishWarning': hidePublishWarning,
    };
  }

  UserSettings copyWith({
    String? id,
    String? userId,
    ThemeOption? theme,
    String? Function()? accentColor,
    PageTransitionType? pageTransition,
    DialogAnimationType? dialogAnimation,
    DateTime? themeUpdatedAt,
    DateTime? accentColorUpdatedAt,
    bool? achievementNotification,
    bool? anniversaryReminder,
    bool? checkInReminderEnabled,
    TimeOfDay? checkInReminderTime,
    DateTime? notificationsUpdatedAt,
    bool? checkInVibrationEnabled,
    bool? checkInConfettiEnabled,
    DateTime? checkInUpdatedAt,
    bool? hidePublishWarning,
    bool? hasSeenPublishWarning,
    bool? hasSeenCommunityIntro,
    DateTime? communityUpdatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      theme: theme ?? this.theme,
      accentColor: accentColor != null ? accentColor() : this.accentColor,
      pageTransition: pageTransition ?? this.pageTransition,
      dialogAnimation: dialogAnimation ?? this.dialogAnimation,
      themeUpdatedAt: themeUpdatedAt ?? this.themeUpdatedAt,
      accentColorUpdatedAt: accentColorUpdatedAt ?? this.accentColorUpdatedAt,
      achievementNotification: achievementNotification ?? this.achievementNotification,
      anniversaryReminder: anniversaryReminder ?? this.anniversaryReminder,
      checkInReminderEnabled: checkInReminderEnabled ?? this.checkInReminderEnabled,
      checkInReminderTime: checkInReminderTime ?? this.checkInReminderTime,
      notificationsUpdatedAt: notificationsUpdatedAt ?? this.notificationsUpdatedAt,
      checkInVibrationEnabled: checkInVibrationEnabled ?? this.checkInVibrationEnabled,
      checkInConfettiEnabled: checkInConfettiEnabled ?? this.checkInConfettiEnabled,
      checkInUpdatedAt: checkInUpdatedAt ?? this.checkInUpdatedAt,
      hidePublishWarning: hidePublishWarning ?? this.hidePublishWarning,
      hasSeenPublishWarning: hasSeenPublishWarning ?? this.hasSeenPublishWarning,
      hasSeenCommunityIntro: hasSeenCommunityIntro ?? this.hasSeenCommunityIntro,
      communityUpdatedAt: communityUpdatedAt ?? this.communityUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserSettings(id: $id, theme: ${theme.label}, checkInReminderEnabled: $checkInReminderEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserSettings &&
        other.id == id &&
        other.userId == userId &&
        other.theme == theme &&
        other.accentColor == accentColor &&
        other.pageTransition == pageTransition &&
        other.dialogAnimation == dialogAnimation &&
        other.themeUpdatedAt == themeUpdatedAt &&
        other.accentColorUpdatedAt == accentColorUpdatedAt &&
        other.achievementNotification == achievementNotification &&
        other.anniversaryReminder == anniversaryReminder &&
        other.checkInReminderEnabled == checkInReminderEnabled &&
        other.checkInReminderTime == checkInReminderTime &&
        other.notificationsUpdatedAt == notificationsUpdatedAt &&
        other.checkInVibrationEnabled == checkInVibrationEnabled &&
        other.checkInConfettiEnabled == checkInConfettiEnabled &&
        other.checkInUpdatedAt == checkInUpdatedAt &&
        other.hidePublishWarning == hidePublishWarning &&
        other.hasSeenPublishWarning == hasSeenPublishWarning &&
        other.hasSeenCommunityIntro == hasSeenCommunityIntro &&
        other.communityUpdatedAt == communityUpdatedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        theme.hashCode ^
        accentColor.hashCode ^
        pageTransition.hashCode ^
        dialogAnimation.hashCode ^
        themeUpdatedAt.hashCode ^
        accentColorUpdatedAt.hashCode ^
        achievementNotification.hashCode ^
        anniversaryReminder.hashCode ^
        checkInReminderEnabled.hashCode ^
        checkInReminderTime.hashCode ^
        notificationsUpdatedAt.hashCode ^
        checkInVibrationEnabled.hashCode ^
        checkInConfettiEnabled.hashCode ^
        checkInUpdatedAt.hashCode ^
        hidePublishWarning.hashCode ^
        hasSeenPublishWarning.hashCode ^
        hasSeenCommunityIntro.hashCode ^
        communityUpdatedAt.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
