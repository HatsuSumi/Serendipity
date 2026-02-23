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
  final bool cloudSyncEnabled;
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
  final bool autoPublishToCommunity;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    required this.id,
    required this.userId,
    required this.theme,
    this.accentColor,
    required this.pageTransition,
    required this.dialogAnimation,
    required this.cloudSyncEnabled,
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
    required this.autoPublishToCommunity,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(id.isNotEmpty, 'ID cannot be empty'),
       assert(userId.isNotEmpty, 'User ID cannot be empty'),
       assert(accentColor == null || accentColor.startsWith('#'), 
         'Accent color must be a valid hex color starting with #'),
       assert(!passwordLockEnabled || passwordHash != null,
         'Password hash is required when password lock is enabled');

  /// 从 JSON 创建 UserSettings
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    // 解析签到提醒时间
    final reminderTimeMap = json['checkInReminderTime'] as Map<String, dynamic>?;
    final reminderTime = reminderTimeMap != null
        ? TimeOfDay(
            hour: reminderTimeMap['hour'] as int,
            minute: reminderTimeMap['minute'] as int,
          )
        : const TimeOfDay(hour: 20, minute: 0); // 默认 20:00
    
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
      cloudSyncEnabled: json['cloudSyncEnabled'] as bool,
      biometricLockEnabled: json['biometricLockEnabled'] as bool,
      passwordLockEnabled: json['passwordLockEnabled'] as bool,
      passwordHash: json['passwordHash'] as String?,
      hiddenRecordIds: (json['hiddenRecordIds'] as List)
          .map((e) => e as String)
          .toList(),
      achievementNotification: json['achievementNotification'] as bool,
      anniversaryReminder: json['anniversaryReminder'] as bool,
      checkInReminderEnabled: json['checkInReminderEnabled'] as bool? ?? true,
      checkInReminderTime: reminderTime,
      checkInVibrationEnabled: json['checkInVibrationEnabled'] as bool? ?? true,
      checkInConfettiEnabled: json['checkInConfettiEnabled'] as bool? ?? true,
      autoPublishToCommunity: json['autoPublishToCommunity'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'theme': theme.value,
      'accentColor': accentColor,
      'pageTransition': pageTransition.value,
      'dialogAnimation': dialogAnimation.value,
      'cloudSyncEnabled': cloudSyncEnabled,
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
      'autoPublishToCommunity': autoPublishToCommunity,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  /// 
  /// 对于可空字段（accentColor, passwordHash），使用函数包装来区分"未传递"和"传递 null"：
  /// - 不传参数：保持原值
  /// - 传递函数返回 null：清空字段
  /// - 传递函数返回新值：更新字段
  /// 
  /// 示例：
  /// ```dart
  /// // 清空强调色
  /// settings.copyWith(accentColor: () => null)
  /// 
  /// // 修改强调色
  /// settings.copyWith(accentColor: () => '#FF5722')
  /// 
  /// // 保持强调色不变
  /// settings.copyWith(theme: ThemeOption.dark)
  /// ```
  UserSettings copyWith({
    String? id,
    String? userId,
    ThemeOption? theme,
    String? Function()? accentColor,
    PageTransitionType? pageTransition,
    DialogAnimationType? dialogAnimation,
    bool? cloudSyncEnabled,
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
    bool? autoPublishToCommunity,
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
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
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
      autoPublishToCommunity: autoPublishToCommunity ?? this.autoPublishToCommunity,
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
        other.cloudSyncEnabled == cloudSyncEnabled &&
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
        other.autoPublishToCommunity == autoPublishToCommunity &&
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
        cloudSyncEnabled.hashCode ^
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
        autoPublishToCommunity.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

