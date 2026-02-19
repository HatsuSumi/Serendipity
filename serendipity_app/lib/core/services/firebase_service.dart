import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

/// Firebase 初始化服务
/// 
/// 负责 Firebase 的初始化和状态管理，遵循单一职责原则（SRP）。
/// 
/// 调用者：
/// - main.dart：应用启动时初始化 Firebase
/// - FirebaseAuthRepository：检查 Firebase 是否已初始化
/// - FirebaseRemoteDataRepository：检查 Firebase 是否已初始化
class FirebaseService {
  // 单例模式
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();
  
  /// Firebase 是否已初始化
  bool _isInitialized = false;
  
  /// 获取 Firebase 初始化状态
  /// 
  /// 调用者：
  /// - FirebaseAuthRepository：在执行认证操作前检查
  /// - FirebaseRemoteDataRepository：在执行数据操作前检查
  bool get isInitialized => _isInitialized;
  
  /// 初始化 Firebase
  /// 
  /// 调用者：
  /// - main.dart：应用启动时调用
  /// 
  /// Fail Fast：
  /// - 如果初始化失败，抛出异常（由 Firebase SDK 抛出）
  /// - 重复初始化不会报错，直接返回
  Future<void> initialize() async {
    // 如果已经初始化，直接返回
    if (_isInitialized) {
      return;
    }
    
    try {
      // 初始化 Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
    } catch (e) {
      // Fail Fast：初始化失败立即抛出异常
      // 不隐藏错误，让调用者知道初始化失败
      rethrow;
    }
  }
}

