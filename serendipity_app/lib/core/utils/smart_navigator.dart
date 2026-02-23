import 'package:flutter/material.dart';

/// 智能导航器
/// 
/// 自动检测页面之间的循环跳转，避免导航栈累积
/// 
/// ## 使用方式
/// 
/// ### 步骤1：在 main.dart 中注册循环页面对
/// ```dart
/// void main() async {
///   // ...
///   SmartNavigator.registerCyclicPair(RecordDetailPage, StoryLineDetailPage);
///   // ...
/// }
/// ```
/// 
/// ### 步骤2：使用 SmartNavigator.push() 导航
/// ```dart
/// SmartNavigator.push(
///   context: context,
///   targetPage: StoryLineDetailPage(storyLineId: id),
///   currentPageType: RecordDetailPage,
///   targetPageType: StoryLineDetailPage,
/// );
/// ```
/// 
/// ### 或使用扩展方法
/// ```dart
/// context.smartPush(
///   targetPage: StoryLineDetailPage(storyLineId: id),
///   currentPageType: RecordDetailPage,
///   targetPageType: StoryLineDetailPage,
/// );
/// ```
class SmartNavigator {
  /// 导航历史记录（用于检测循环跳转）
  static final List<Type> _navigationHistory = [];
  
  /// 已注册的循环页面对（用于优化检测）
  /// 例如：{RecordDetailPage: StoryLineDetailPage, StoryLineDetailPage: RecordDetailPage}
  static final Map<Type, Set<Type>> _cyclicPairs = {};
  
  /// 最大历史记录长度
  static const int _maxHistoryLength = 10;
  
  /// 是否启用调试日志
  static bool debugMode = false;
  
  /// 注册循环页面对
  /// 
  /// 例如：记录详情页 ⇄ 故事线详情页
  /// ```dart
  /// SmartNavigator.registerCyclicPair(RecordDetailPage, StoryLineDetailPage);
  /// ```
  static void registerCyclicPair(Type pageA, Type pageB) {
    _cyclicPairs.putIfAbsent(pageA, () => {}).add(pageB);
    _cyclicPairs.putIfAbsent(pageB, () => {}).add(pageA);
  }
  
  /// 智能导航
  /// 
  /// 自动判断是使用 push 还是 pushReplacement：
  /// - 如果检测到循环跳转（A→B→A），使用 pushReplacement
  /// - 否则使用 push
  /// 
  /// Fail Fast:
  /// - 如果 currentPageType == targetPageType，抛出 ArgumentError
  static Future<T?> push<T>({
    required BuildContext context,
    required Widget targetPage,
    required Type currentPageType,
    required Type targetPageType,
    Duration? transitionDuration,
    RouteTransitionsBuilder? transitionsBuilder,
  }) {
    // Fail Fast: 参数验证
    if (currentPageType == targetPageType) {
      throw ArgumentError(
        'currentPageType and targetPageType cannot be the same: $currentPageType. '
        'This indicates a navigation logic error.',
      );
    }
    
    // 检测是否为循环跳转
    final shouldReplace = _shouldUseReplacement(currentPageType, targetPageType);
    
    // 更新导航历史
    _updateHistory(targetPageType);
    
    // 构建路由
    final route = PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => targetPage,
      transitionsBuilder: transitionsBuilder ?? _defaultTransition,
      transitionDuration: transitionDuration ?? const Duration(milliseconds: 300),
    );
    
    // 根据检测结果选择导航方式
    if (shouldReplace) {
      return Navigator.of(context).pushReplacement(route);
    } else {
      return Navigator.of(context).push(route);
    }
  }
  
  /// 检测是否应该使用 pushReplacement
  /// 
  /// 检测规则：
  /// 只有当满足以下所有条件时，才使用 pushReplacement：
  /// 1. 两个页面已注册为循环页面对
  /// 2. 历史记录中至少有 3 个页面（说明已经发生过至少一次跳转）
  /// 3. 历史中倒数第二个页面类型 == 目标页面类型（说明是 A→B→A 的循环）
  /// 
  /// 例如：
  /// - 主页 → 记录详情：历史 [RecordDetailPage]
  ///   点击故事线 → 目标 StoryLineDetailPage
  ///   历史长度 1 < 3，使用 push ✓
  ///   结果：主页 → 记录详情 → 故事线详情
  /// 
  /// - 主页 → 记录详情 → 故事线详情：历史 [RecordDetailPage, StoryLineDetailPage]
  ///   点击记录 → 目标 RecordDetailPage
  ///   历史长度 2 < 3，使用 push ✓
  ///   结果：主页 → 记录详情 → 故事线详情 → 记录详情
  /// 
  /// - 主页 → 记录详情 → 故事线详情 → 记录详情：历史 [RecordDetailPage, StoryLineDetailPage, RecordDetailPage]
  ///   点击故事线 → 目标 StoryLineDetailPage
  ///   历史长度 3，倒数第二个是 StoryLineDetailPage == 目标
  ///   使用 pushReplacement ✓
  ///   结果：主页 → 记录详情 → 故事线详情（替换了记录详情）
  static bool _shouldUseReplacement(Type currentPageType, Type targetPageType) {
    // 必须是已注册的循环页面对
    if (!_cyclicPairs.containsKey(currentPageType)) return false;
    
    final cyclicTargets = _cyclicPairs[currentPageType]!;
    if (!cyclicTargets.contains(targetPageType)) return false;
    
    // 历史记录至少要有 3 个页面（说明已经发生过至少一次完整的 A→B→A 跳转）
    if (_navigationHistory.length < 3) return false;
    
    // 检查历史中倒数第二个页面是否是目标页面类型
    // 这说明是 A→B→A→B 的循环模式，应该替换
    final secondLastPageType = _navigationHistory[_navigationHistory.length - 2];
    
    return secondLastPageType == targetPageType;
  }
  
  /// 更新导航历史
  static void _updateHistory(Type pageType) {
    _navigationHistory.add(pageType);
    
    // 限制历史记录长度
    if (_navigationHistory.length > _maxHistoryLength) {
      _navigationHistory.removeAt(0);
    }
  }
  
  /// 默认过渡动画
  static Widget _defaultTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
  
  /// 获取当前导航历史（用于调试）
  static List<Type> get navigationHistory => List.unmodifiable(_navigationHistory);
  
  /// 获取已注册的循环页面对（用于调试）
  static Map<Type, Set<Type>> get cyclicPairs => Map.unmodifiable(_cyclicPairs);
  
  /// 清除导航历史（用于测试）
  @visibleForTesting
  static void clearHistoryForTesting() {
    _navigationHistory.clear();
  }
}

/// 扩展方法：为 BuildContext 添加智能导航
extension SmartNavigatorExtension on BuildContext {
  /// 智能导航到目标页面
  Future<T?> smartPush<T>({
    required Widget targetPage,
    required Type currentPageType,
    required Type targetPageType,
    Duration? transitionDuration,
    RouteTransitionsBuilder? transitionsBuilder,
  }) {
    return SmartNavigator.push<T>(
      context: this,
      targetPage: targetPage,
      currentPageType: currentPageType,
      targetPageType: targetPageType,
      transitionDuration: transitionDuration,
      transitionsBuilder: transitionsBuilder,
    );
  }
}

