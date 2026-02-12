import 'enums.dart';

/// 用户设置
class UserSettings {
  final String id;
  final String userId;
  final AppTheme theme;
  final String? accentColor;
  final bool cloudSyncEnabled;
  final bool biometricLockEnabled;
  final bool passwordLockEnabled;
  final String? passwordHash;
  final List<String> hiddenRecordIds;
  final bool achievementNotification;
  final bool anniversaryReminder;
  final bool locationReminder;
  final bool matchNotification;
  final bool messageNotification;
  final bool matchingEnabled;
  final bool gpsVerificationEnabled;
  final bool autoPublishToCommunity;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    required this.id,
    required this.userId,
    required this.theme,
    this.accentColor,
    required this.cloudSyncEnabled,
    required this.biometricLockEnabled,
    required this.passwordLockEnabled,
    this.passwordHash,
    required this.hiddenRecordIds,
    required this.achievementNotification,
    required this.anniversaryReminder,
    required this.locationReminder,
    required this.matchNotification,
    required this.messageNotification,
    required this.matchingEnabled,
    required this.gpsVerificationEnabled,
    required this.autoPublishToCommunity,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON 创建 UserSettings
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'] as String,
      userId: json['userId'] as String,
      theme: AppTheme.values
          .firstWhere((e) => e.value == json['theme'] as String),
      accentColor: json['accentColor'] as String?,
      cloudSyncEnabled: json['cloudSyncEnabled'] as bool,
      biometricLockEnabled: json['biometricLockEnabled'] as bool,
      passwordLockEnabled: json['passwordLockEnabled'] as bool,
      passwordHash: json['passwordHash'] as String?,
      hiddenRecordIds: (json['hiddenRecordIds'] as List)
          .map((e) => e as String)
          .toList(),
      achievementNotification: json['achievementNotification'] as bool,
      anniversaryReminder: json['anniversaryReminder'] as bool,
      locationReminder: json['locationReminder'] as bool,
      matchNotification: json['matchNotification'] as bool,
      messageNotification: json['messageNotification'] as bool,
      matchingEnabled: json['matchingEnabled'] as bool,
      gpsVerificationEnabled: json['gpsVerificationEnabled'] as bool,
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
      'cloudSyncEnabled': cloudSyncEnabled,
      'biometricLockEnabled': biometricLockEnabled,
      'passwordLockEnabled': passwordLockEnabled,
      'passwordHash': passwordHash,
      'hiddenRecordIds': hiddenRecordIds,
      'achievementNotification': achievementNotification,
      'anniversaryReminder': anniversaryReminder,
      'locationReminder': locationReminder,
      'matchNotification': matchNotification,
      'messageNotification': messageNotification,
      'matchingEnabled': matchingEnabled,
      'gpsVerificationEnabled': gpsVerificationEnabled,
      'autoPublishToCommunity': autoPublishToCommunity,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  UserSettings copyWith({
    String? id,
    String? userId,
    AppTheme? theme,
    String? accentColor,
    bool? cloudSyncEnabled,
    bool? biometricLockEnabled,
    bool? passwordLockEnabled,
    String? passwordHash,
    List<String>? hiddenRecordIds,
    bool? achievementNotification,
    bool? anniversaryReminder,
    bool? locationReminder,
    bool? matchNotification,
    bool? messageNotification,
    bool? matchingEnabled,
    bool? gpsVerificationEnabled,
    bool? autoPublishToCommunity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      theme: theme ?? this.theme,
      accentColor: accentColor ?? this.accentColor,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      passwordLockEnabled: passwordLockEnabled ?? this.passwordLockEnabled,
      passwordHash: passwordHash ?? this.passwordHash,
      hiddenRecordIds: hiddenRecordIds ?? this.hiddenRecordIds,
      achievementNotification: achievementNotification ?? this.achievementNotification,
      anniversaryReminder: anniversaryReminder ?? this.anniversaryReminder,
      locationReminder: locationReminder ?? this.locationReminder,
      matchNotification: matchNotification ?? this.matchNotification,
      messageNotification: messageNotification ?? this.messageNotification,
      matchingEnabled: matchingEnabled ?? this.matchingEnabled,
      gpsVerificationEnabled: gpsVerificationEnabled ?? this.gpsVerificationEnabled,
      autoPublishToCommunity: autoPublishToCommunity ?? this.autoPublishToCommunity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserSettings(id: $id, theme: ${theme.label}, matchingEnabled: $matchingEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserSettings &&
        other.id == id &&
        other.userId == userId &&
        other.theme == theme &&
        other.accentColor == accentColor &&
        other.cloudSyncEnabled == cloudSyncEnabled &&
        other.biometricLockEnabled == biometricLockEnabled &&
        other.passwordLockEnabled == passwordLockEnabled &&
        other.passwordHash == passwordHash &&
        other.hiddenRecordIds.length == hiddenRecordIds.length &&
        other.achievementNotification == achievementNotification &&
        other.anniversaryReminder == anniversaryReminder &&
        other.locationReminder == locationReminder &&
        other.matchNotification == matchNotification &&
        other.messageNotification == messageNotification &&
        other.matchingEnabled == matchingEnabled &&
        other.gpsVerificationEnabled == gpsVerificationEnabled &&
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
        cloudSyncEnabled.hashCode ^
        biometricLockEnabled.hashCode ^
        passwordLockEnabled.hashCode ^
        passwordHash.hashCode ^
        hiddenRecordIds.length.hashCode ^
        achievementNotification.hashCode ^
        anniversaryReminder.hashCode ^
        locationReminder.hashCode ^
        matchNotification.hashCode ^
        messageNotification.hashCode ^
        matchingEnabled.hashCode ^
        gpsVerificationEnabled.hashCode ^
        autoPublishToCommunity.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

