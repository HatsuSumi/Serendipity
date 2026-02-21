# SmartNavigator 使用指南

## 概述

`SmartNavigator` 是一个智能导航管理器，自动检测页面之间的循环跳转，避免导航栈累积。

## 问题场景

在应用中，某些页面之间存在互相跳转的关系：

```
记录详情页 ⇄ 故事线详情页
用户详情页 ⇄ 关注列表页
文章详情页 ⇄ 评论详情页
```

如果使用普通的 `Navigator.push()`，会导致导航栈不断累积：

```
主页 → 记录详情 → 故事线详情 → 记录详情 → 故事线详情 → ...
```

用户需要点击很多次返回按钮才能回到主页。

## 解决方案

`SmartNavigator` 自动检测循环跳转，在合适的时候使用 `pushReplacement` 替换页面，保持导航栈深度。

## 使用方式

### 步骤1：在 main.dart 中注册循环页面对

```dart
void main() async {
  // ...初始化代码...
  
  // 注册循环页面对（用于智能导航）
  SmartNavigator.registerCyclicPair(RecordDetailPage, StoryLineDetailPage);
  
  // 启用调试模式（仅在开发模式下）
  if (kDebugMode) {
    SmartNavigator.debugMode = true;
  }
  
  runApp(const MyApp());
}
```

### 步骤2：在页面中使用 SmartNavigator

**方式1：使用静态方法（推荐）**

```dart
SmartNavigator.push(
  context: context,
  targetPage: StoryLineDetailPage(storyLineId: storyLineId),
  currentPageType: RecordDetailPage,
  targetPageType: StoryLineDetailPage,
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return PageTransitionBuilder.buildTransition(
      transitionType,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  },
);
```

**方式2：使用扩展方法**

```dart
context.smartPush(
  targetPage: StoryLineDetailPage(storyLineId: storyLineId),
  currentPageType: RecordDetailPage,
  targetPageType: StoryLineDetailPage,
  transitionsBuilder: myTransition,
);
```

## 工作原理

### 检测规则（按优先级）

1. **已注册的循环页面对**：如果两个页面已注册为循环对，且历史中存在目标页面，使用 `pushReplacement`
2. **自动检测循环模式**：如果导航历史中存在 A→B→A 的模式，使用 `pushReplacement`
3. **默认行为**：使用 `push`

### 导航栈变化示例

```
场景1：首次进入
主页 → 记录详情（push）
点击故事线 → 主页 → 记录详情 → 故事线详情（push）
点击返回 → 回到记录详情 ✓

场景2：循环跳转
主页 → 记录详情 → 故事线详情
点击记录 → 主页 → 记录详情（pushReplacement，替换故事线详情）
点击故事线 → 主页 → 故事线详情（pushReplacement，替换记录详情）
点击记录 → 主页 → 记录详情（pushReplacement）
...
无论跳转多少次，栈深度保持为2
```

## 调试

启用调试模式查看导航日志：

```dart
SmartNavigator.debugMode = true;
```

输出示例：

```
[SmartNavigator] 注册循环页面对: RecordDetailPage ⇄ StoryLineDetailPage
[SmartNavigator] 导航: RecordDetailPage → StoryLineDetailPage
[SmartNavigator] 使用: push
[SmartNavigator] 历史: [RecordDetailPage, StoryLineDetailPage]
[SmartNavigator] 导航: StoryLineDetailPage → RecordDetailPage
[SmartNavigator] 使用: pushReplacement
[SmartNavigator] 历史: [RecordDetailPage, StoryLineDetailPage, RecordDetailPage]
```

## API 参考

### SmartNavigator.registerCyclicPair()

注册循环页面对。

**参数：**
- `pageA`: 页面A类型
- `pageB`: 页面B类型

**示例：**
```dart
SmartNavigator.registerCyclicPair(RecordDetailPage, StoryLineDetailPage);
```

### SmartNavigator.push()

智能导航到目标页面。

**参数：**
- `context`: BuildContext
- `targetPage`: 目标页面 Widget
- `currentPageType`: 当前页面类型（Type）
- `targetPageType`: 目标页面类型（Type）
- `transitionDuration`: 过渡动画时长（可选）
- `transitionsBuilder`: 自定义过渡动画（可选）

**返回：**
- `Future<T?>`: 导航结果

**Fail Fast：**
- 如果 `currentPageType == targetPageType`，抛出 `ArgumentError`

### SmartNavigator.debugMode

启用/禁用调试日志。

**类型：** `bool`

**默认值：** `false`

**示例：**
```dart
if (kDebugMode) {
  SmartNavigator.debugMode = true;
}
```

### SmartNavigator.navigationHistory

获取当前导航历史（用于调试）。

**类型：** `List<Type>`（只读）

### SmartNavigator.cyclicPairs

获取已注册的循环页面对（用于调试）。

**类型：** `Map<Type, Set<Type>>`（只读）

## 迁移指南

### 从手动管理迁移到 SmartNavigator

**之前的代码：**

```dart
class RecordDetailPage extends ConsumerStatefulWidget {
  final EncounterRecord record;
  final bool fromStoryLineDetail; // 手动管理来源
  
  const RecordDetailPage({
    super.key,
    required this.record,
    this.fromStoryLineDetail = false,
  });
}

void _navigateToStoryLineDetail(BuildContext context) {
  // 手动判断是否使用 pushReplacement
  if (widget.fromStoryLineDetail) {
    Navigator.of(context).pushReplacement(/* ... */);
  } else {
    Navigator.of(context).push(/* ... */);
  }
}
```

**迁移后的代码：**

```dart
class RecordDetailPage extends ConsumerStatefulWidget {
  final EncounterRecord record;
  // 不再需要 fromStoryLineDetail 参数
  
  const RecordDetailPage({
    super.key,
    required this.record,
  });
}

void _navigateToStoryLineDetail(BuildContext context) {
  // 自动检测，无需手动判断
  SmartNavigator.push(
    context: context,
    targetPage: StoryLineDetailPage(storyLineId: storyLineId),
    currentPageType: RecordDetailPage,
    targetPageType: StoryLineDetailPage,
  );
}
```

**优势：**
- ✅ 代码更简洁
- ✅ 无需手动管理来源标识
- ✅ 自动处理所有循环跳转场景
- ✅ 符合 DRY 原则

## 注意事项

1. **页面类型必须准确**：`currentPageType` 和 `targetPageType` 必须是实际的页面类型
2. **必须注册循环页面对**：在 `main.dart` 中使用 `registerCyclicPair` 注册
3. **调试模式**：生产环境记得关闭 `debugMode`
4. **Fail Fast**：如果 `currentPageType == targetPageType`，会抛出异常

## 未来扩展

可以考虑的增强功能：

1. **自动注册**：通过注解自动检测和注册循环页面对
2. **路由守卫**：集成权限检查、登录验证等
3. **导航分析**：统计用户导航路径，优化应用流程
4. **持久化历史**：保存导航历史，支持应用重启后恢复

