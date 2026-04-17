import '../../models/enums.dart';
import '../../models/user.dart';

class CustomServerAuthUserMapper {
  const CustomServerAuthUserMapper();

  User fromResponse(Map<String, dynamic> data) {
    final id = data['id'] as String?;
    final createdAtStr = data['createdAt'] as String?;
    final updatedAtStr = data['updatedAt'] as String?;

    if (id == null || id.isEmpty) {
      throw ArgumentError('用户 ID 不能为空');
    }
    if (createdAtStr == null || createdAtStr.isEmpty) {
      throw ArgumentError('创建时间不能为空');
    }
    if (updatedAtStr == null || updatedAtStr.isEmpty) {
      throw ArgumentError('更新时间不能为空');
    }

    final createdAt = DateTime.parse(createdAtStr);
    final updatedAt = DateTime.parse(updatedAtStr);
    final lastLoginAt = data['lastLoginAt'] != null
        ? DateTime.parse(data['lastLoginAt'] as String)
        : null;

    return User(
      id: id,
      email: data['email'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      displayName: data['displayName'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
      authProvider: _parseAuthProvider(data['authProvider'] as String?),
      isEmailVerified: data['isEmailVerified'] as bool,
      isPhoneVerified: data['isPhoneVerified'] as bool,
      lastLoginAt: lastLoginAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  AuthProvider _parseAuthProvider(String? provider) {
    if (provider == null) {
      return AuthProvider.email;
    }

    switch (provider.toLowerCase()) {
      case 'email':
        return AuthProvider.email;
      case 'phone':
        return AuthProvider.phone;
      default:
        return AuthProvider.email;
    }
  }
}

