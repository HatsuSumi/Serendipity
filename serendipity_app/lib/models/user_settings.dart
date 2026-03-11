import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'enums.dart';

/// 用户设置
class UserSettings {
  final String id;
  final String userId;
  
  // 主题设置
  final ThemeOption theme;
  final String? accentColor;
  final PageTransitionType pageTransition;
  final DialogAnimationType dialogAnimation;
  
  // 隐私设置
  final bool biometricLockEnabled;
  final bool passwordLockEnabled;
  final String? passwordHash;
  final List<String> hiddenRecordIds;
  
  // 通知设置
  final bool achievementNotification;
  final bool anniversaryReminder;
  final bool checkInReminderEnabled;
  final TimeOfDay checkInReminderTime;
  
  // 签到设置
  final bool checkInVibrationEnabled;
  final bool checkInConfettiEnabled;
  
  // 社区设置
  final bool hidePublishWarning;
  final bool hasSeenPublishWarning;
  final bool hasSeenCommunityIntro;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    required this.id,
    required this.userId,
    required this.theme,
    this.accentColor,
    required this.pageTransition,
    required this.dialogAnimation,
    required this.biometricLockEnabled,
    required this.passwordLockEnabled,
    this.passwordHash,
    required this.hiddenRecordIds,
    required this.achievementNotification,
    required this.anniversaryReminder,
    required this.checkInReminderEnabled,
    required this.checkInReminderTime,
    required this.checkInVibrationEnabled,
    required this.checkInConfettiEnabled,
    required this.hidePublishWarning,
    required this.hasSeenPublishWarning,
    required this.hasSeenCommunityIntro,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(id.isNotEmpty, 'ID cannot be empty'),
       assert(userId.isNotEmpty, 'User ID cannot be empty'),
       assert(accentColor == null || accentColor.startsWith('#'), 
         'Accent color must be a valid hex color starting with #'),
       assert(!passwordLockEnabled || passwordHash != null,
         'Password hash is required when password lock is enabled');

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
      biometricLockEnabled: false,
      passwordLockEnabled: false,
      passwordHash: null,
      hiddenRecordIds: [],
      achievementNotification: true,
      anniversaryReminder: true,
      checkInReminderEnabled: true,
      checkInReminderTime: const TimeOfDay(hour: 20, minute: 0),
      checkInVibrationEnabled: true,
      checkInConfettiEnabled: false,
      hidePublishWarning: false,
      hasSeenPublishWarning: false,
      hasSeenCommunityIntro: false,
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
      biometricLockEnabled: json['biometricLockEnabled'] as bool? ?? false,
      passwordLockEnabled: json['passwordLockEnabled'] as bool? ?? false,
      passwordHash: json['passwordHash'] as String?,
      hiddenRecordIds: (json['hiddenRecordIds'] as List? ?? [])
          .map((e) => e as String)
          .toList(),
      achievementNotification: json['achievementNotification'] as bool,
      anniversaryReminder: json['anniversaryReminder'] as bool,
      checkInReminderEnabled: json['checkInReminderEnabled'] as bool? ?? true,
      checkInReminderTime: reminderTime,
      checkInVibrationEnabled: json['checkInVibrationEnabled'] as bool? ?? true,
      checkInConfettiEnabled: json['checkInConfettiEnabled'] as bool? ?? true,
      hidePublishWarning: json['hidePublishWarning'] as bool? ?? false,
      hasSeenPublishWarning: json['hasSeenPublishWarning'] as bool? ?? false,
      hasSeenCommunityIntro: json['hasSeenCommunityIntro'] as bool? ?? false,
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
    
    return UserSettings(
      id: 'settings_$userId',
      userId: userId,
      theme: ThemeOption.values.firstWhere(
        (e) => e.value == dto['theme'] as String,
        orElse: () => ThemeOption.system,
      ),
      accentColor: null,
      pageTransition: PageTransitionType.values.firstWhere(
        (e) => e.value == dto['pageTransition'] as String,
        orElse: () => PageTransitionType.random,
      ),
      dialogAnimation: DialogAnimationType.values.firstWhere(
        (e) => e.value == dto['dialogAnimation'] as String,
        orElse: () => DialogAnimationType.random,
      ),
      biometricLockEnabled: false,
      passwordLockEnabled: false,
      passwordHash: null,
      hiddenRecordIds: [],
      achievementNotification: notifications['achievementUnlocked'] as bool,
      anniversaryReminder: notifications['anniversaryReminder'] as bool? ?? true,
      checkInReminderEnabled: notifications['checkInReminder'] as bool,
      checkInReminderTime: TimeOfDay(hour: reminderHour, minute: reminderMinute),
      checkInVibrationEnabled: checkIn['vibrationEnabled'] as bool,
      checkInConfettiEnabled: checkIn['confettiEnabled'] as bool,
      hidePublishWarning: dto['hidePublishWarning'] as bool? ?? false,
      hasSeenPublishWarning: dto['hasSeenPublishWarning'] as bool? ?? false,
      hasSeenCommunityIntro: dto['hasSeenCommunityIntro'] as bool? ?? false,
      createdAt: now,
      updatedAt: dto['updatedAt'] != null
          ? DateTime.parse(dto['updatedAt'] as String)
          : now,
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
      'biometricLockEnabled': biometricLockEnabled,
      'passwordLockEnabled': passwordLockEnabled,
      'passwordHash': passwordHash,
      'hiddenRecordIds': hiddenRecordIds,
      'achievementNotification': achievementNotification,
      'anniversaryReminder': anniversaryReminder,
      'checkInReminderEnabled': checkInReminderEnabled,
      'checkInReminderTime': {
        'hour': checkInReminderTime.hour,
        'minute': checkInReminderTime.minute,
      },
      'checkInVibrationEnabled': checkInVibrationEnabled,
      'checkInConfettiEnabled': checkInConfettiEnabled,
      'hidePublishWarning': hidePublishWarning,
      'hasSeenPublishWarning': hasSeenPublishWarning,
      'hasSeenCommunityIntro': hasSeenCommunityIntro,
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
    bool? biometricLockEnabled,
    bool? passwordLockEnabled,
    String? Function()? passwordHash,
    List<String>? hiddenRecordIds,
    bool? achievementNotification,
    bool? anniversaryReminder,
    bool? checkInReminderEnabled,
    TimeOfDay? checkInReminderTime,
    bool? checkInVibrationEnabled,
    bool? checkInConfettiEnabled,
    bool? hidePublishWarning,
    bool? hasSeenPublishWarning,
    bool? hasSeenCommunityIntro,
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
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      passwordLockEnabled: passwordLockEnabled ?? this.passwordLockEnabled,
      passwordHash: passwordHash != null ? passwordHash() : this.passwordHash,
      hiddenRecordIds: hiddenRecordIds ?? this.hiddenRecordIds,
      achievementNotification: achievementNotification ?? this.achievementNotification,
      anniversaryReminder: anniversaryReminder ?? this.anniversaryReminder,
      checkInReminderEnabled: checkInReminderEnabled ?? this.checkInReminderEnabled,
      checkInReminderTime: checkInReminderTime ?? this.checkInReminderTime,
      checkInVibrationEnabled: checkInVibrationEnabled ?? this.checkInVibrationEnabled,
      checkInConfettiEnabled: checkInConfettiEnabled ?? this.checkInConfettiEnabled,
      hidePublishWarning: hidePublishWarning ?? this.hidePublishWarning,
      hasSeenPublishWarning: hasSeenPublishWarning ?? this.hasSeenPublishWarning,
      hasSeenCommunityIntro: hasSeenCommunityIntro ?? this.hasSeenCommunityIntro,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserSettings(id: \$id, theme: \${theme.label}, checkInReminderEnabled: \$checkInReminderEnabled)';
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
        other.biometricLockEnabled == biometricLockEnabled &&
        other.passwordLockEnabled == passwordLockEnabled &&
        other.passwordHash == passwordHash &&
        listEquals(other.hiddenRecordIds, hiddenRecordIds) &&
        other.achievementNotification == achievementNotification &&
        other.anniversaryReminder == anniversaryReminder &&
        other.checkInReminderEnabled == checkInReminderEnabled &&
        other.checkInReminderTime == checkInReminderTime &&
        other.checkInVibrationEnabled == checkInVibrationEnabled &&
        other.checkInConfettiEnabled == checkInConfettiEnabled &&
        other.hidePublishWarning == hidePublishWarning &&
        other.hasSeenPublishWarning == hasSeenPublishWarning &&
        other.hasSeenCommunityIntro == hasSeenCommunityIntro &&
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
        biometricLockEnabled.hashCode ^
        passwordLockEnabled.hashCode ^
        passwordHash.hashCode ^
        hiddenRecordIds.hashCode ^
        achievementNotification.hashCode ^
        anniversaryReminder.hashCode ^
        checkInReminderEnabled.hashCode ^
        checkInReminderTime.hashCode ^
        checkInVibrationEnabled.hashCode ^
        checkInConfettiEnabled.hashCode ^
        hidePublishWarning.hashCode ^
        hasSeenPublishWarning.hashCode ^
        hasSeenCommunityIntro.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
