# 社区系统架构重构文档

**重构日期**：2026-03-06  
**重构原因**：优化架构设计，遵循单一职责原则（SRP）

---

## 📋 重构概述

### 问题分析

原 `CommunityNotifier` 承担了过多职责（593行，11个方法）：
- ❌ 列表管理（加载、刷新、分页）
- ❌ 发布管理（发布、批量发布、检查状态）
- ❌ 删除管理（删除、权限判断）
- ❌ 筛选管理（筛选、清除筛选）

违反了**单一职责原则（SRP）**。

### 重构方案

**拆分为两个 Provider：**

1. **CommunityNotifier**（列表管理）
   - ✅ 加载帖子列表
   - ✅ 刷新列表
   - ✅ 加载更多（分页）
   - ✅ 筛选帖子
   - ✅ 清除筛选
   - ✅ 删除帖子

2. **CommunityPublishNotifier**（发布管理）- 新增
   - ✅ 发布单条记录
   - ✅ 批量发布记录
   - ✅ 检查发布状态

---

## 🔄 迁移指南

### 旧代码（已废弃）

```dart
// ❌ 旧方式（已标记为 @deprecated）
final communityNotifier = ref.read(communityProvider.notifier);

// 发布记录
await communityNotifier.publishPost(record);

// 批量发布
await communityNotifier.publishPosts(records);

// 检查发布状态
await communityNotifier.checkPublishStatus(records);
```

### 新代码（推荐）

```dart
// ✅ 新方式（推荐）
final publishNotifier = ref.read(communityPublishProvider.notifier);

// 发布记录
await publishNotifier.publishPost(record);

// 批量发布
await publishNotifier.publishPosts(records);

// 检查发布状态
await publishNotifier.checkPublishStatus(records);
```

---

## 📁 文件变更

### 新增文件

- `lib/core/providers/community_publish_provider.dart` - 社区发布 Provider

### 修改文件

- `lib/core/providers/community_provider.dart` - 重构为列表管理 Provider
  - 保留向后兼容的方法（标记为 @deprecated）
  - 委托给新的 `CommunityPublishNotifier`

### 需要更新的调用方（可选，旧代码仍可工作）

- `lib/features/community/dialogs/publish_to_community_dialog.dart`
- `lib/features/record/record_detail_page.dart`
- `lib/features/timeline/timeline_page.dart`
- `lib/features/record/create_record_page.dart`

---

## ✅ 向后兼容性

**重要：旧代码仍然可以正常工作！**

- ✅ 所有旧的 API 都保留了
- ✅ 旧方法委托给新 Provider
- ✅ 标记为 `@deprecated`，IDE 会显示警告
- ✅ 可以逐步迁移，不需要一次性修改所有代码

---

## 🎯 优势

### 架构优势

1. **单一职责**：每个 Provider 只负责一件事
2. **更易测试**：职责单一，测试更简单
3. **更易维护**：修改发布逻辑不影响列表逻辑
4. **更易扩展**：添加新功能不会让类变得更臃肿

### 代码质量

| 指标 | 重构前 | 重构后 |
|------|--------|--------|
| CommunityNotifier 行数 | 593 行 | ~400 行 |
| CommunityNotifier 方法数 | 11 个 | 8 个 |
| 职责数量 | 4 个 | 1 个 |
| 符合 SRP | ❌ | ✅ |

---

## 📝 后续计划

### 第二阶段（可选）

1. 逐步迁移调用方到新 API
2. 移除 `@deprecated` 方法
3. 进一步优化筛选逻辑（分离到独立 Provider）

### 第三阶段（可选）

1. 优化后端路由（合并 `/posts/filter` 到 `/posts`）
2. 优化 Service 层对象比较逻辑
3. 使用策略模式重构 Repository 层

---

## 🔍 测试建议

### 单元测试

```dart
// 测试发布功能
test('publishPost should publish record successfully', () async {
  final container = ProviderContainer();
  final publishNotifier = container.read(communityPublishProvider.notifier);
  
  final result = await publishNotifier.publishPost(mockRecord);
  
  expect(result, isFalse); // 未替换旧帖
});

// 测试列表功能
test('refresh should reload posts', () async {
  final container = ProviderContainer();
  final communityNotifier = container.read(communityProvider.notifier);
  
  await communityNotifier.refresh();
  
  final state = container.read(communityProvider).value;
  expect(state?.posts, isNotEmpty);
});
```

---

## 📚 参考资料

- [SOLID 原则](https://en.wikipedia.org/wiki/SOLID)
- [单一职责原则（SRP）](https://en.wikipedia.org/wiki/Single-responsibility_principle)
- [Riverpod 最佳实践](https://riverpod.dev/docs/concepts/providers)

---

**最后更新**：2026-03-06  
**维护者**：开发团队


