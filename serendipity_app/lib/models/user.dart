import 'package:hive/hive.dart';
import 'enums.dart';

part 'user.g.dart';

/// 用户
@HiveType(typeId: 4)
class User extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String? email;
  
  @HiveField(2)
  final String? phoneNumber;
  
  @HiveField(3)
  final String? displayName;
  
  @HiveField(4)
  final String? avatarUrl;
  
  @HiveField(5)
  final AuthProvider authProvider;
  
  @HiveField(6)
  final bool isEmailVerified;
  
  @HiveField(7)
  final bool isPhoneVerified;
  
  @HiveField(8)
  final DateTime? lastLoginAt;
  
  @HiveField(9)
  final DateTime createdAt;
  
  @HiveField(10)
  final DateTime? updatedAt;

  User({
    required String id,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.avatarUrl,
    required this.authProvider,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    this.lastLoginAt,
    required this.createdAt,
    DateTime? updatedAt,
  }) : id = id.trim(),
       updatedAt = updatedAt ?? createdAt {  // 默认使用 createdAt
    // Fail Fast：参数验证
    if (this.id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    
    // 至少要有邮箱或手机号之一
    if (email == null && phoneNumber == null) {
      throw ArgumentError('邮箱和手机号至少需要提供一个');
    }
  }
  
  /// 获取显示名称（优先使用 displayName，否则使用邮箱/手机号）
  String get displayNameOrFallback {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    return email ?? phoneNumber ?? 'Unknown User';
  }

  /// 是否已验证（邮箱或手机号至少验证一个）
  bool get isVerified => isEmailVerified || isPhoneVerified;

  /// 主要联系方式
  String? get primaryContact => email ?? phoneNumber;

  /// 从 JSON 创建 User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      authProvider: AuthProvider.values
          .firstWhere((e) => e.value == json['authProvider'] as String),
      isEmailVerified: json['isEmailVerified'] as bool,
      isPhoneVerified: json['isPhoneVerified'] as bool,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,  // 如果没有 updatedAt，构造函数会使用 createdAt
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'authProvider': authProvider.value,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  /// 
  /// 对于可空字段，使用函数包装来区分"未传递"和"传递 null"：
  /// - 不传参数：保持原值
  /// - 传递函数返回 null：清空字段
  /// - 传递函数返回新值：更新字段
  /// 
  /// 示例：
  /// ```dart
  /// // 清空邮箱
  /// user.copyWith(email: () => null)
  /// 
  /// // 修改邮箱
  /// user.copyWith(email: () => 'new@example.com')
  /// 
  /// // 保持邮箱不变
  /// user.copyWith(displayName: 'New Name')
  /// ```
  User copyWith({
    String? id,
    String? Function()? email,
    String? Function()? phoneNumber,
    String? Function()? displayName,
    String? Function()? avatarUrl,
    AuthProvider? authProvider,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    DateTime? Function()? lastLoginAt,
    DateTime? createdAt,
    DateTime? Function()? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email != null ? email() : this.email,
      phoneNumber: phoneNumber != null ? phoneNumber() : this.phoneNumber,
      displayName: displayName != null ? displayName() : this.displayName,
      avatarUrl: avatarUrl != null ? avatarUrl() : this.avatarUrl,
      authProvider: authProvider ?? this.authProvider,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      lastLoginAt: lastLoginAt != null ? lastLoginAt() : this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt != null ? updatedAt() : this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, authProvider: ${authProvider.label}, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.email == email &&
        other.phoneNumber == phoneNumber &&
        other.displayName == displayName &&
        other.avatarUrl == avatarUrl &&
        other.authProvider == authProvider &&
        other.isEmailVerified == isEmailVerified &&
        other.isPhoneVerified == isPhoneVerified &&
        other.lastLoginAt == lastLoginAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        phoneNumber.hashCode ^
        displayName.hashCode ^
        avatarUrl.hashCode ^
        authProvider.hashCode ^
        isEmailVerified.hashCode ^
        isPhoneVerified.hashCode ^
        lastLoginAt.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}

