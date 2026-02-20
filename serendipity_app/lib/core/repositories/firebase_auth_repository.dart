import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../../models/user.dart';
import '../../models/enums.dart';
import 'i_auth_repository.dart';

/// Firebase 认证仓库实现
/// 
/// 实现 IAuthRepository 接口，使用 Firebase Authentication 作为认证服务。
/// 遵循单一职责原则（SRP）和依赖倒置原则（DIP）。
/// 
/// 无状态设计：不保存临时状态（如 verificationId），由调用者管理。
/// 
/// 调用者：
/// - AuthProvider：通过接口调用所有方法
class FirebaseAuthRepository implements IAuthRepository {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  
  @override
  Future<User?> get currentUser async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return null;
    }
    
    return _mapFirebaseUserToUser(firebaseUser);
  }
  
  @override
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) {
        return null;
      }
      return _mapFirebaseUserToUser(firebaseUser);
    });
  }
  
  @override
  Future<User> signInWithEmail(String email, String password) async {
    // Fail Fast：参数验证
    _validateEmail(email);
    _validatePassword(password);
    
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Fail Fast：登录成功但用户为 null（不应该发生）
      if (credential.user == null) {
        throw StateError('Sign in succeeded but user is null');
      }
      
      return _mapFirebaseUserToUser(credential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapAuthErrorCode(e.code, e.message);
    }
  }
  
  @override
  Future<User> signUpWithEmail(String email, String password) async {
    // Fail Fast：参数验证
    _validateEmail(email);
    _validatePassword(password);
    
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Fail Fast：注册成功但用户为 null（不应该发生）
      if (credential.user == null) {
        throw StateError('Sign up succeeded but user is null');
      }
      
      return _mapFirebaseUserToUser(credential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapAuthErrorCode(e.code, e.message);
    }
  }
  
  @override
  Future<String> sendPhoneVerificationCode(String phoneNumber) async {
    // Fail Fast：参数验证
    _validatePhoneNumber(phoneNumber);
    
    // 使用 Completer 等待验证码发送完成
    final completer = Completer<String>();
    
    try {
      // Web 平台需要显式配置 reCAPTCHA
      if (kIsWeb) {
        // 确保 reCAPTCHA 容器存在
        await _auth.setSettings(
          appVerificationDisabledForTesting: false,
        );
      }
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
          // 自动验证完成（Android 上可能发生）
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          // Fail Fast：验证失败立即抛出异常
          if (!completer.isCompleted) {
            completer.completeError(_mapAuthErrorCode(e.code, e.message));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          // 返回验证 ID
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // 自动检索超时，返回验证 ID
          if (!completer.isCompleted) {
            completer.complete(verificationId);
          }
        },
      );
      
      // 等待验证码发送完成（或失败）
      return await completer.future;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapAuthErrorCode(e.code, e.message);
    }
  }
  
  @override
  Future<User> signInWithPhone(
    String phoneNumber,
    String verificationCode,
    String verificationId,
  ) async {
    // Fail Fast：参数验证
    _validatePhoneNumber(phoneNumber);
    if (verificationCode.isEmpty) {
      throw ArgumentError('Verification code cannot be empty');
    }
    if (verificationId.isEmpty) {
      throw ArgumentError('Verification ID cannot be empty');
    }
    
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: verificationCode,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Fail Fast：登录成功但用户为 null（不应该发生）
      if (userCredential.user == null) {
        throw StateError('Sign in succeeded but user is null');
      }
      
      return _mapFirebaseUserToUser(userCredential.user!);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapAuthErrorCode(e.code, e.message);
    }
  }
  
  @override
  Future<User> signUpWithPhone(
    String phoneNumber,
    String verificationCode,
    String verificationId,
  ) async {
    // 手机号注册和登录逻辑相同（Firebase 会自动创建账号）
    return signInWithPhone(phoneNumber, verificationCode, verificationId);
  }
  
  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapAuthErrorCode(e.code, e.message);
    }
  }
  
  @override
  Future<void> resetPassword(String email) async {
    // Fail Fast：参数验证
    _validateEmail(email);
    
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapAuthErrorCode(e.code, e.message);
    }
  }
  
  // ==================== 私有辅助方法 ====================
  
  /// 验证邮箱格式
  /// 
  /// 调用者：
  /// - signInWithEmail
  /// - signUpWithEmail
  /// - resetPassword
  /// 
  /// Fail Fast：邮箱格式不正确立即抛出异常
  void _validateEmail(String email) {
    if (email.isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }
    
    // 邮箱格式验证（支持 Gmail 别名和长 TLD）
    // 示例：user+tag@gmail.com, user@example.museum
    final emailRegex = RegExp(r'^[\w\-\.+]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      throw ArgumentError('Invalid email format');
    }
  }
  
  /// 验证密码长度
  /// 
  /// 调用者：
  /// - signInWithEmail
  /// - signUpWithEmail
  /// 
  /// Fail Fast：密码长度不足立即抛出异常
  void _validatePassword(String password) {
    if (password.isEmpty) {
      throw ArgumentError('Password cannot be empty');
    }
    
    if (password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters');
    }
  }
  
  /// 验证手机号格式
  /// 
  /// 调用者：
  /// - signInWithPhone
  /// - signUpWithPhone
  /// - sendPhoneVerificationCode
  /// 
  /// Fail Fast：手机号格式不正确立即抛出异常
  void _validatePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      throw ArgumentError('Phone number cannot be empty');
    }
    
    // 手机号必须包含国家代码（如 +86）
    if (!phoneNumber.startsWith('+')) {
      throw ArgumentError('Phone number must include country code (e.g., +86)');
    }
    
    // 简单验证：+ 号后面至少有 10 位数字
    final digitsOnly = phoneNumber.substring(1).replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) {
      throw ArgumentError('Invalid phone number format');
    }
  }
  
  /// 将 Firebase User 转换为应用 User
  /// 
  /// 调用者：
  /// - currentUser
  /// - authStateChanges
  /// - signInWithEmail
  /// - signUpWithEmail
  /// - signInWithPhone
  /// - signUpWithPhone
  User _mapFirebaseUserToUser(firebase_auth.User firebaseUser) {
    // 确定认证方式
    AuthProvider authProvider = AuthProvider.email;
    if (firebaseUser.providerData.isNotEmpty) {
      final providerId = firebaseUser.providerData.first.providerId;
      if (providerId == 'phone') {
        authProvider = AuthProvider.phone;
      }
    }
    
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email,
      phoneNumber: firebaseUser.phoneNumber,
      displayName: firebaseUser.displayName,
      avatarUrl: firebaseUser.photoURL,
      authProvider: authProvider,
      isEmailVerified: firebaseUser.emailVerified,
      isPhoneVerified: firebaseUser.phoneNumber != null,
      lastLoginAt: DateTime.now(),
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// 将错误代码映射为友好的错误信息
  /// 
  /// 调用者：所有捕获异常的方法
  Exception _mapAuthErrorCode(String code, String? message) {
    switch (code) {
      // 登录相关错误
      case 'user-not-found':
        return Exception('该邮箱尚未注册');
      case 'wrong-password':
        return Exception('密码错误');
      case 'invalid-credential':
        return Exception('邮箱或密码错误');
      case 'invalid-email':
        return Exception('邮箱格式不正确');
      case 'user-disabled':
        return Exception('账号已被禁用');
      
      // 注册相关错误
      case 'email-already-in-use':
        return Exception('该邮箱已被注册');
      case 'weak-password':
        return Exception('密码强度不足，至少需要6位');
      
      // 手机号相关错误
      case 'invalid-phone-number':
        return Exception('手机号格式不正确');
      case 'invalid-verification-code':
        return Exception('验证码错误');
      case 'invalid-verification-id':
        return Exception('验证码已过期，请重新获取');
      case 'session-expired':
        return Exception('验证码已过期，请重新获取');
      
      // 频率限制
      case 'too-many-requests':
        return Exception('操作过于频繁，请稍后再试');
      
      // 网络相关错误
      case 'network-request-failed':
        return Exception('网络连接失败，请检查网络');
      
      // 其他错误
      case 'operation-not-allowed':
        return Exception('该登录方式未启用');
      case 'requires-recent-login':
        return Exception('请重新登录后再试');
      
      default:
        // 如果是未知错误，返回详细的错误信息
        final msg = message ?? code;
        final details = code != msg ? ' ($code)' : '';
        return Exception('登录失败：$msg$details');
    }
  }
}

